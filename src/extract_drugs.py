import zipfile
import json
import os
import glob
import pandas as pd


def parse_single_zip(zip_file_path):
    """
    Opens an openFDA zip archive and extracts records into a flat list of dictionaries.
    """
    flattened_records = []

    with zipfile.ZipFile(zip_file_path, 'r') as z:
        json_filename = z.namelist()[0]
        with z.open(json_filename) as f:
            raw_data = json.load(f)

    records = raw_data.get('results', [])

    for item in records:
        openfda_meta = item.get('openfda', {})

        brand_name = openfda_meta.get('brand_name', [None])[0]
        generic_name = openfda_meta.get('generic_name', [None])[0]
        route = openfda_meta.get('route', [None])[0]

        indications = " ".join(item.get('indications_and_usage', []))
        contraindications = " ".join(item.get('contraindications', []))
        adverse_reactions = " ".join(item.get('adverse_reactions', []))
        warnings = " ".join(item.get('warnings', []))
        do_not_use = " ".join(item.get('do_not_use', []))
        use_when = " ".join(item.get('when_using', []))
        dosage = " ".join(item.get('dosage_and_administration', []))

        has_primary   = any([indications, contraindications, dosage, do_not_use])
        has_secondary = any([adverse_reactions, warnings, use_when])
        has_identity  = brand_name and generic_name

        if not has_identity or not (has_primary or has_secondary):
            continue

        flattened_records.append({
            "brand_name": brand_name,
            "generic_name": generic_name,
            "route": route,
            "indications": indications if indications else None,
            "dosage": dosage if dosage else None,
            "contraindications": contraindications if contraindications else None,
            "side_effects": adverse_reactions if adverse_reactions else None,
            "warnings": warnings if warnings else None,
            "do_not_use": do_not_use if do_not_use else None,
            "use_when": use_when if use_when else None
        })

    return flattened_records


def build_single_master_csv(download_dir="fda_downloads"):
    """
    Iterates through all zip archives, accumulates structured rows,
    and exports one comprehensive master CSV file.
    """
    zip_files = glob.glob(os.path.join(download_dir, "*.json.zip"))

    if not zip_files:
        print(f"Aborting: No matching .json.zip archives found inside '{download_dir}'.")
        return

    print(f"Found {len(zip_files)} partition files. Initiating master compilation pipeline...")

    all_compiled_records = []

    for index, file_path in enumerate(zip_files, 1):
        base_name = os.path.basename(file_path)
        try:
            records = parse_single_zip(file_path)
            all_compiled_records.extend(records)
            print(f"  [{index}/{len(zip_files)}] Successfully parsed {base_name} (+{len(records)} medical rows)")
        except Exception as e:
            print(f"Error processing file {base_name}: {e}")

    if all_compiled_records:
        print("\nProcessing structural consolidation into an integrated DataFrame...")
        master_df = pd.DataFrame(all_compiled_records)

        output_csv_path = os.path.join(download_dir, "openfda_master_drug_labels.csv")

        print(f"Writing dataset to storage target...")
        master_df.to_csv(output_csv_path, index=False, encoding='utf-8')

        print("\n" + "=" * 50)
        print(f"SUCCESS: Unified Master CSV Generated!")
        print(f"File Location: {output_csv_path}")
        print(f"Total Active Medical Profiles: {master_df.shape[0]}")
        print("=" * 50)
    else:
        print("Pipeline completed but zero valid drug records were compiled.")


if __name__ == "__main__":

    target_directory = "fda_downloads"
    build_single_master_csv(download_dir=target_directory)