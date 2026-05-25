import requests
import os

def download_all_drug_labels(output_folder="fda_downloads"):

    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
        
    manifest_url = "https://api.fda.gov/download.json"
    print("Fetching the openFDA download manifest...")
    response = requests.get(manifest_url).json()
    
    try:
        label_data = response['results']['drug']['label']
        partitions = label_data['partitions']
        print(f"Found {len(partitions)} total zip files to download. Total records: {label_data['total_records']}")
    except KeyError:
        print("Error parsing manifest. Check if structure changed.")
        return

    for part in partitions:
        download_url = part['file']
        file_name = os.path.join(output_folder, download_url.split('/')[-1])
        
        print(f"Downloading {file_name} ({part['size_mb']} MB)...")
        
        with requests.get(download_url, stream=True) as r:
            r.raise_for_status()
            with open(file_name, 'wb') as f:
                for chunk in r.iter_content(chunk_size=8192):
                    f.write(chunk)
                    
    print("\n All drug label zip archives downloaded successfully!")

if __name__ == "__main__":
    download_all_drug_labels()