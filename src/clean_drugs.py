import pandas as pd
import re

INPUT_FILE  = "fda_downloads/openfda_master_drug_labels.csv"   # ← change to your file path
OUTPUT_FILE = "cleaned_drugs.csv"

TEXT_COLS = ["indications", "dosage", "contraindications", "side_effects", "warnings", "do_not_use", "use_when"]

GROUP_KEY  = ["brand_name", "generic_name", "route"]

HEADER_PATTERNS = [
    r"^INDICATIONS AND USAGE\s*",
    r"^Indications and Usage Section\s*",
    r"^CONTRAINDICATIONS\s*",
    r"^Contraindications Section\s*",
    r"^ADVERSE REACTIONS\s*",
    r"^Adverse Reactions\s*",
    r"^WARNINGS\s*",
    r"^DIRECTIONS\s*",
    r"^Directions\s*",
    r"^DOSAGE AND ADMINISTRATION\s*",
    r"^Directions\s*",
    r"^Dosage and Administration\s*",
    r"^DOSAGE & ADMINISTRATION\s*",
    r"^Do not use\s*",
]

STRIP_RE = re.compile("|".join(HEADER_PATTERNS), flags=re.IGNORECASE)


def clean_text(value) -> str | None:
    """Strip whitespace, remove section headers, treat sentinel as null."""
    if pd.isna(value):
        return None
    s = str(value).strip()
    if s.lower() == "missing value":
        return None
    s = STRIP_RE.sub("", s).strip()
    return s if s else None


def best_value(series: pd.Series) -> str | None:
    """From a group's values pick the longest non-null cleaned text."""
    candidates = [v for v in (clean_text(x) for x in series) if v]
    if not candidates:
        return None
    return max(candidates, key=len)


def main():
    df = pd.read_csv(INPUT_FILE)
    print(f"Loaded {len(df):,} rows, {df['brand_name'].nunique()} unique brand names.")

    for col in TEXT_COLS:
        if col in df.columns:
            df[col] = df[col].apply(clean_text)

    agg_rules = {}
    for col in df.columns:
        if col in GROUP_KEY:
            continue
        if col in TEXT_COLS:
            agg_rules[col] = lambda s: max(
                (v for v in s if pd.notna(v) and v), key=len, default=None
            )
        else:
            agg_rules[col] = lambda s: next((v for v in s if pd.notna(v)), None)

    cleaned = (
        df.groupby(GROUP_KEY, sort=False, dropna=False)
        .agg(agg_rules)
        .reset_index()
    )

    before = len(cleaned)
    cleaned = cleaned.dropna(subset=TEXT_COLS, how="all")
    print(f"Dropped {before - len(cleaned)} fully-empty rows.")
    print(f"Final dataset: {len(cleaned):,} rows.")

    cleaned.to_csv(OUTPUT_FILE, index=False)
    print(f"Saved → {OUTPUT_FILE}")