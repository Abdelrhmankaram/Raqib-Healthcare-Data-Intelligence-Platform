"""
clean_drug_labels.py
Full NLP cleaning pipeline for the OpenFDA drug labels dataset.

Steps:
    1. Load
    2. Strip per-column section header boilerplate — including multi-variant
       forms (INDICATIONS AND USAGE, & USAGE, SECTION WARNINGS, /PRECAUTIONS…)
    3. Normalize casing (brand/generic → smart Title Case that preserves
       abbreviations/codes like E.E.S, T-26, OTC, IV)
    4. Remove special characters & Unicode artifacts
    5. Deduplicate repeated sentences within cells
    6. Merge sparse columns (do_not_use → warnings, use_when → indications)
    7. Normalize route to a controlled vocabulary
    8. Deduplicate brand+generic pairs (keep most informative row)
    9. Drop rows where both brand_name AND generic_name are null
   10. Recalculate has_contraindications / has_side_effects binary flags
   11. Export to parquet
"""

import re
import warnings

import numpy as np
import pandas as pd

warnings.filterwarnings("ignore")

INPUT_FILE  = "Data/fda_downloads/drugs_data.parquet"
OUTPUT_FILE = "Data/fda_downloads/drugs_data_cleaned.parquet"

TEXT_COLS = [
    "indications", "dosage", "contraindications",
    "side_effects", "warnings", "do_not_use", "use_when",
]

# ---------------------------------------------------------------------------
# Header-stripping patterns per column
#
# Each entry is a list of regex patterns applied LEFT-TO-RIGHT, anchored at
# the start of the string.  We iterate until no pattern matches (convergence)
# so that compound fragments like "& USAGE SECTION INDICATIONS & USAGE …"
# are fully unwound.
# ---------------------------------------------------------------------------
HEADER_STRIP = {
    "indications": [
        # Full keyword forms
        r"^[\d\s]*\b(INDICATIONS?\s+AND\s+USAGES?|INDICATIONS?\s+AND\s+USE|INDICATIONS?|USES?|HOMEOPATHIC USES?)\b[\s:\-–—]*",
        # Partial suffix left after the keyword was already stripped
        r"^(&\s*USAGE[S]?\s*(SECTION\s+[A-Z ]+)?|AND\s+USAGES?|&\s*USE)\s*",
        r"^SECTION\s+\S+\s*",          # "SECTION <word>" sentinels
        r"^[:\-–—&/]\s*",              # bare leading punctuation / ampersand / slash
    ],
    "dosage": [
        r"^[\d\s]*\b(DOSAGE\s+AND\s+ADMINISTRATION|DOSAGE|DIRECTIONS?)\b[\s:\-–—]*",
        r"^(&\s*ADMINISTRATION|AND\s+ADMINISTRATION)\s*",
        r"^SECTION\s+\S+\s*",
        r"^[:\-–—&/]\s*",
    ],
    "contraindications": [
        r"^[\d\s]*\bCONTRAINDICATIONS?\b[\s:\-–—]*",
        r"^SECTION\s+\S+\s*",
        r"^[:\-–—&/]\s*",
    ],
    "side_effects": [
        r"^[\d\s]*\b(ADVERSE\s+REACTIONS?|SIDE\s+EFFECTS?)\b[\s:\-–—]*",
        r"^SECTION\s+\S+\s*",
        r"^[:\-–—&/]\s*",
    ],
    "warnings": [
        r"^[\d\s]*\b(WARNINGS?\s+AND\s+PRECAUTIONS?|WARNINGS?)\b[\s:\-–—]*",
        r"^(&\s*PRECAUTIONS?|AND\s+PRECAUTIONS?|/PRECAUTIONS?)\s*[:\-–—]?\s*",
        r"^SECTION\s+\S+\s*",
        r"^[:\-–—&/]\s*",
    ],
    "do_not_use": [
        r"^[\d\s]*\b(DO\s+NOT\s+USE|CONTRAINDICATIONS?)\b[\s:\-–—]*",
        r"^[:\-–—&/]\s*",
    ],
    "use_when": [
        r"^[\d\s]*\b(WHEN\s+USING|USE\s+WHEN)\b[\s:\-–—]*",
        r"^[:\-–—&/]\s*",
    ],
}

# Stub values that contain nothing useful after stripping
_STUB_VALUES = {
    "warnings", "dosage", "indications", "side effects",
    "contraindications", "uses", "use", "directions", "adverse reactions",
}

KNOWN_ROUTES = {
    "oral", "topical", "ophthalmic", "intravenous", "subcutaneous",
    "intramuscular", "nasal", "rectal", "vaginal", "transdermal",
    "inhalation", "otic", "dental", "intrathecal", "intraarticular",
    "sublingual", "buccal",
}

ROUTE_RENAMES = {
    "auricular (otic)": "otic",
}

# Tokens that should remain ALL-CAPS after title-casing
_ALLCAPS_RE = re.compile(
    r"^(?:[A-Z0-9][.\-])+[A-Z0-9]?$"   # dotted/dashed abbreviation: E.E.S, T-26
    r"|^[A-Z]{2,5}$"                     # short caps token: OTC, IV, HCI
    r"|^[IVXLCDM]+$"                     # Roman numerals
)


# ── Step 2: strip section headers (convergent multi-pass) ────────────────────

def strip_header(text, patterns: list[str]) -> str | None:
    if pd.isna(text):
        return text
    t = str(text)
    # Iterate until no pattern fires (handles stacked fragments like "& USAGE SECTION …")
    for _ in range(6):
        changed = False
        for pat in patterns:
            new = re.sub(pat, "", t, flags=re.IGNORECASE).strip()
            if new != t:
                t = new
                changed = True
        if not changed:
            break
    # Remove any remaining bare leading punctuation
    t = re.sub(r"^[:\-–—]\s*", "", t).strip()
    # Discard bare stub values
    if t.lower() in _STUB_VALUES:
        return None
    return t if t else None


# ── Step 3: smart Title Case ──────────────────────────────────────────────────

def smart_title(text) -> str | None:
    if pd.isna(text) or not str(text).strip():
        return text
    tokens = str(text).split()
    return " ".join(tok if _ALLCAPS_RE.match(tok) else tok.capitalize() for tok in tokens)


# ── Step 4: remove special characters & Unicode artifacts ────────────────────

_UNICODE_MAP = str.maketrans({
    "\u200b": " ",   "\u00a0": " ",
    "\u2018": "'",   "\u2019": "'",
    "\u201c": '"',   "\u201d": '"',
    "\u2013": "-",   "\u2014": "-",
})

def clean_special_chars(text):
    if pd.isna(text):
        return text
    t = str(text).translate(_UNICODE_MAP)
    t = re.sub(r"\*{1,3}", "", t)
    # [see X] — closed and unclosed bracket variants
    t = re.sub(r"\[see\s+[^\]\n]{0,120}?\]", "", t, flags=re.IGNORECASE)
    t = re.sub(r"\[see\s+[^\]\n]{0,120}",    "", t, flags=re.IGNORECASE)
    t = re.sub(r"\(\s*\d+\.\d+\s*\)", "", t)          # section refs like (5.1)
    t = re.sub(r"[ \t]{2,}", " ", t)
    t = re.sub(r"\n{3,}", "\n\n", t)
    t = re.sub(r"^\s*[■•▪·]\s*", "", t, flags=re.MULTILINE)
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

    # Drop rows where BOTH name columns are null
    null_both = df["brand_name"].isna() & df["generic_name"].isna()
    if null_both.any():
        print(f"Dropping {null_both.sum():,} rows with null brand_name AND generic_name")
        df = df[~null_both].reset_index(drop=True)

    # Strip leading/trailing whitespace from name columns
    for col in ["brand_name", "generic_name"]:
        if col in df.columns:
            df[col] = df[col].str.strip()

    # 2. Strip section headers (convergent multi-pass per column)
    for col, patterns in HEADER_STRIP.items():
        if col in df.columns:
            df[col] = df[col].apply(lambda x: strip_header(x, patterns))

    # 3. Normalize casing
    df["brand_name"]   = df["brand_name"].apply(smart_title)
    df["generic_name"] = df["generic_name"].apply(smart_title)
    df["route"]        = df["route"].str.strip().str.lower()

    # 4. Remove special characters & Unicode artifacts
    for col in TEXT_COLS:
        if col in df.columns:
            df[col] = df[col].apply(clean_special_chars)

    # 5. Deduplicate repeated sentences
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

    # Fill remaining nulls
    fill_cols = ["indications", "dosage", "contraindications", "side_effects", "warnings"]
    df[fill_cols] = df[fill_cols].fillna("Not specified")

    # 10. Recalculate binary flags AFTER cleaning & fill
    df["has_contraindications"] = (
        df["contraindications"].notna() & (df["contraindications"] != "Not specified")
    ).astype(int)
    df["has_side_effects"] = (
        df["side_effects"].notna() & (df["side_effects"] != "Not specified")
    ).astype(int)

    # 7. Normalize route
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

    # 11. Export
    df.to_parquet(OUTPUT_FILE, index=False)
    print(f"Saved  → {OUTPUT_FILE}  |  shape: {df.shape}")

    # ── Post-clean audit ──────────────────────────────────────────────────────
    print("\n── Post-clean audit ──")
    print(f"Null brand_name:   {df['brand_name'].isna().sum()}")
    print(f"Null generic_name: {df['generic_name'].isna().sum()}")

    residual_checks = {
        "indications | '& USAGE' prefix":    (df["indications"].str.match(r"^&?\s*USAGE", na=False).sum()),
        "indications | 'AND USAGE' prefix":   (df["indications"].str.startswith("AND USAGE", na=False).sum()),
        "dosage | '& ADMIN' prefix":          (df["dosage"].str.match(r"^&?\s*ADMIN", na=False).sum()),
        "warnings | '/PRECAUTIONS' prefix":   (df["warnings"].str.startswith("/PRECAUTIONS", na=False).sum()),
        "any col | 'SECTION' sentinel":       sum(
            df[c].str.match(r"^SECTION\s", na=False).sum()
            for c in quality_cols
        ),
    }
    for label, count in residual_checks.items():
        status = "✓" if count == 0 else f"⚠  {count} remaining"
        print(f"  {label}: {status}")

    print(f"\nRoute distribution:\n{df['route'].value_counts().to_string()}")


if __name__ == "__main__":
    main()