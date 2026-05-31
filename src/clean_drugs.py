"""
clean_drug_labels.py
Full NLP cleaning pipeline for the OpenFDA drug labels dataset.

Steps:
    1. Load
    2. Strip per-column section header boilerplate
    3. Normalize casing (brand/generic → Title Case, route → UPPER)
    4. Remove special characters & Unicode artifacts
    5. Deduplicate repeated sentences within cells
    6. Merge sparse columns (do_not_use → warnings, use_when → indications)
    7. Normalize route to a controlled vocabulary
    8. Deduplicate brand+generic pairs (keep most informative row)
    9. Export to parquet
"""

import re
import warnings

import numpy as np
import pandas as pd

warnings.filterwarnings("ignore")

INPUT_FILE  = "drugs_data.parquet"
OUTPUT_FILE = "drugs_data_cleaned.parquet"

TEXT_COLS = [
    "indications", "dosage", "contraindications",
    "side_effects", "warnings", "do_not_use", "use_when",
]

# Per-column header patterns (anchored, case-insensitive)
HEADER_PATTERNS = {
    "indications":       r"^[\d\s]*\b(INDICATIONS?|USES?|USE|HOMEOPATHIC USES?)\b[\s:\-]*",
    "dosage":            r"^[\d\s]*\b(DOSAGE(\s+AND\s+ADMINISTRATION)?|DIRECTIONS?)\b[\s:\-]*",
    "contraindications": r"^[\d\s]*\b(CONTRAINDICATIONS?)\b[\s:\-]*",
    "side_effects":      r"^[\d\s]*\b(ADVERSE\s+REACTIONS?|SIDE\s+EFFECTS?)\b[\s:\-]*",
    "warnings":          r"^[\d\s]*\b(WARNINGS?(\s+AND\s+PRECAUTIONS?)?)\b[\s:\-]*",
    "do_not_use":        r"^[\d\s]*\b(DO\s+NOT\s+USE|CONTRAINDICATIONS?)\b[\s:\-]*",
    "use_when":          r"^[\d\s]*\b(WHEN\s+USING|USE\s+WHEN)\b[\s:\-]*",
}

KNOWN_ROUTES = {
    "oral", "topical", "ophthalmic", "intravenous", "subcutaneous",
    "intramuscular", "nasal", "rectal", "vaginal", "transdermal",
    "inhalation", "otic", "dental", "intrathecal", "intraarticular",
    "sublingual", "buccal",
}

ROUTE_RENAMES = {
    "auricular (otic)": "otic",  # only value that needs renaming
}


# ── Step 2: strip section headers ────────────────────────────────────────────

def strip_header(text, pattern: str):
    if pd.isna(text):
        return text
    cleaned = re.sub(pattern, "", str(text), flags=re.IGNORECASE).strip()
    cleaned = re.sub(r"^[:\-–—]\s*", "", cleaned)   # remove leftover leading punctuation
    return cleaned if cleaned else text              # fallback to original if result is empty


# ── Step 4: remove special characters & Unicode artifacts ────────────────────

_UNICODE_MAP = str.maketrans({
    "\u200b": " ",   # zero-width space
    "\u00a0": " ",   # non-breaking space
    "\u2018": "'",   # left single quote
    "\u2019": "'",   # right single quote
    "\u201c": '"',   # left double quote
    "\u201d": '"',   # right double quote
    "\u2013": "-",   # en dash
    "\u2014": "-",   # em dash
})

def clean_special_chars(text):
    if pd.isna(text):
        return text
    t = str(text).translate(_UNICODE_MAP)
    t = re.sub(r"\*{1,3}", "", t)                          # markdown bold/italic
    t = re.sub(r"\[see [^\]]+\]", "", t, flags=re.IGNORECASE)  # cross-reference anchors
    t = re.sub(r"\(\s*\d+\.\d+\s*\)", "", t)               # numbered section refs like (5.1)
    t = re.sub(r"[ \t]{2,}", " ", t)                       # excess horizontal whitespace
    t = re.sub(r"\n{3,}", "\n\n", t)                       # excess blank lines
    return t.strip()


# ── Step 5: deduplicate repeated sentences within a cell ─────────────────────

def dedup_sentences(text):
    if pd.isna(text):
        return text
    segments = re.split(r"(?<=[.!?])\s+|\n{2,}", str(text))
    seen, unique = set(), []
    for seg in segments:
        key = re.sub(r"\s+", " ", seg.strip().lower())
        if key and key not in seen:
            seen.add(key)
            unique.append(seg.strip())
    return " ".join(unique)


# ── Step 6: merge sparse columns ─────────────────────────────────────────────

def merge_fields(base, extra, separator):
    extra_s = str(extra).strip() if pd.notna(extra) else ""
    base_s  = str(base).strip()  if pd.notna(base)  else ""
    if not extra_s:
        return base_s or None
    if not base_s:
        return extra_s
    return base_s + separator + extra_s


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    # 1. Load
    df = pd.read_parquet(INPUT_FILE)
    print(f"Loaded  {len(df):,} rows | {df['brand_name'].nunique():,} unique brand names")
    print(f"Columns: {df.columns.tolist()}\n")

    # 2. Strip section headers (per-column patterns)
    for col, pattern in HEADER_PATTERNS.items():
        if col in df.columns:
            df[col] = df[col].apply(lambda x: strip_header(x, pattern))

    # 3. Normalize casing
    df["brand_name"]   = df["brand_name"].str.strip().str.title()
    df["generic_name"] = df["generic_name"].str.strip().str.title()
    df["route"]        = df["route"].str.strip().str.lower()

    # 4. Remove special characters & Unicode artifacts
    for col in TEXT_COLS:
        if col in df.columns:
            df[col] = df[col].apply(clean_special_chars)

    # 5. Deduplicate repeated sentences (columns known to have copy-paste duplication)
    for col in ["side_effects", "warnings", "contraindications"]:
        if col in df.columns:
            df[col] = df[col].apply(dedup_sentences)

    # 6. Merge sparse columns, then drop them
    if "do_not_use" in df.columns:
        df["warnings"] = df.apply(
            lambda r: merge_fields(r["warnings"], r["do_not_use"], " | DO NOT USE: "), axis=1
        )
        df.drop(columns=["do_not_use"], inplace=True)

    if "use_when" in df.columns:
        df["indications"] = df.apply(
            lambda r: merge_fields(r["indications"], r["use_when"], " | USE WHEN: "), axis=1
        )
        df.drop(columns=["use_when"], inplace=True)

    # Add binary presence indicators for sparse columns
    df["has_contraindications"] = df["contraindications"].notna().astype(int)
    df["has_side_effects"]      = df["side_effects"].notna().astype(int)

    # Fill remaining nulls so rows are preserved
    fill_cols = ["indications", "dosage", "contraindications", "side_effects", "warnings"]
    df[fill_cols] = df[fill_cols].fillna("Not specified")

    # 7. Normalize route: rename exceptions, mark anything unrecognized as "unknown"
    df["route"] = df["route"].replace(ROUTE_RENAMES)
    df["route"] = df["route"].where(df["route"].isin(KNOWN_ROUTES), other="unknown")

    # 8. Deduplicate brand+generic pairs — keep most informative row
    quality_cols = ["indications", "dosage", "contraindications", "side_effects", "warnings"]
    df["_quality"] = df[quality_cols].apply(
        lambda row: sum(
            1 for v in row
            if pd.notna(v) and str(v).strip() not in ("", "Not specified")
        ),
        axis=1,
    )
    before = len(df)
    df = (
        df.sort_values("_quality", ascending=False)
        .drop_duplicates(subset=["brand_name", "generic_name"], keep="first")
        .drop(columns=["_quality"])
        .reset_index(drop=True)
    )
    print(f"Deduplication: {before:,} → {len(df):,} rows "
          f"({before - len(df):,} duplicates removed)")

    # 9. Export
    df.to_parquet(OUTPUT_FILE, index=False)
    print(f"Saved  → {OUTPUT_FILE}  |  shape: {df.shape}")


if __name__ == "__main__":
    main()