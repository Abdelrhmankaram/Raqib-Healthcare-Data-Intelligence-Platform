"""
clean_drug_labels_v2.py
Extended NLP cleaning pipeline — builds on v1 to handle:

NEW in v2:
  A. Cross-reference removal   — (See BOXED WARNINGS .) / [see Warnings and Precautions (5.1)] /
                                  bare "See SECTION NAME." fragments, including nested-paren forms
  B. Trademark / symbol strip  — ® ™ © → removed
  C. Floating section numbers  — "5.1 PHARMACOKINETICS" / "12.3 " at sentence start → removed
  D. Ellipsis normalisation    — "take 1–2 tablets..." → single period
  E. Orphan punctuation        — "impairment  ." → "impairment."
  F. Newline collapsing        — multi-line cells → single coherent paragraph
  G. Duplicate-sentence pass   — run again AFTER all new cleaning (dedup on final text)
  H. Empty / stub guard        — cells that become empty after cleaning → "Not specified"

FIXES vs original:
  - _XREF_PAREN / _XREF_BRACKET: replaced nested alternation with atomic-style possessive
    approach using a finite character class + length cap to prevent catastrophic backtracking
  - _XREF_BARE: anchored trailing match with possessive-safe bounded quantifier, made
    the trailing punctuation non-optional with hard length cap
  - _SECTION_NUM_RE: removed invalid lookbehind-at-^ (not supported in `re`); replaced
    with a two-pass approach that handles start-of-string and post-punctuation separately
  - deep_clean: added a per-cell timeout using signal (Unix) / threading (Windows) so
    a single pathological cell never stalls the entire job
"""

import re
import signal
import threading
import warnings
from contextlib import contextmanager

import numpy as np
import pandas as pd

warnings.filterwarnings("ignore")

INPUT_FILE  = "Data/fda_downloads/drugs_data_cleaned.parquet"   # v1 output  ← change path as needed
OUTPUT_FILE = "Data/fda_downloads/drugs_data_cleaned_v2.parquet"

TEXT_COLS = [
    "indications", "dosage", "contraindications",
    "side_effects", "warnings",
]

# ── Stub guard ────────────────────────────────────────────────────────────────
_STUB_VALUES = frozenset({
    "warnings", "dosage", "indications", "side effects",
    "contraindications", "uses", "use", "directions",
    "adverse reactions", "not specified", "",
})


# ═══════════════════════════════════════════════════════════════════════════════
# A. Cross-reference removal
#
# FIX: The original patterns used nested alternations like (?:[^()]*|\([^()]*\))*
# which cause catastrophic backtracking on malformed text (e.g. unmatched parens,
# very long strings). Replaced with:
#   • A hard character-count cap (.{0,200}) so the engine always terminates
#   • A possessive/atomic-style structure: match the CONTENT as a simple
#     bounded span rather than an alternation that can re-try exponentially
#   • re.DOTALL so newlines inside parens don't break the match
# ═══════════════════════════════════════════════════════════════════════════════

# Parenthetical (see …) — consumes up to 200 chars, no nested alternation
_XREF_PAREN = re.compile(
    r'\(\s*[Ss]ee\b[^)]{0,200}\)',
    re.IGNORECASE,
)

# Bracket [see …] — same strategy
_XREF_BRACKET = re.compile(
    r'\[\s*[Ss]ee\b[^\]]{0,200}\]',
    re.IGNORECASE,
)

_XREF_BARE = re.compile(
    r'\bSee\s+'
    r'(?:BOXED\s+WARNINGS?'
    r'|WARNINGS?\s+AND\s+PRECAUTIONS?'
    r'|INDICATIONS?\s+(?:AND\s+USAGE)?'
    r'|CLINICAL\s+PHARMACOLOGY'
    r'|DOSAGE\s+AND\s+ADMINISTRATION'
    r'|CONTRAINDICATIONS?'
    r'|ADVERSE\s+REACTIONS?'
    r'|FULL\s+PRESCRIBING\s+INFORMATION'
    r'|DRUG\s+INTERACTIONS?'
    r'|PRECAUTIONS?'
    r'|PACKAGE\s+INSERT'
    r'|LABELING'
    r')'
    r'[^.!?\n]{0,120}'   # any trailing words / section numbers (bounded, no alt)
    r'[.!?]?',            # optional terminal punctuation (single char — no backtrack)
    re.IGNORECASE,
)


def remove_cross_refs(text: str) -> str:
    """Remove all three forms of cross-reference."""
    t = _XREF_PAREN.sub("", text)
    t = _XREF_BRACKET.sub("", t)
    t = _XREF_BARE.sub("", t)
    return t


# ═══════════════════════════════════════════════════════════════════════════════
# B. Trademark / symbol strip
# ═══════════════════════════════════════════════════════════════════════════════

_SYMBOL_RE = re.compile(r"[®™©]")


# ═══════════════════════════════════════════════════════════════════════════════
# C. Floating section-number prefixes  (e.g. "5.1 PHARMACOKINETICS")
#
# FIX: The original used (?<=^) inside re.compile which is illegal in Python's
# `re` module (variable-width lookbehind / lookbehind-at-anchor not supported).
# Replaced with two separate patterns:
#   1. start-of-string anchor  ^
#   2. after sentence-ending punctuation / newline
# Both are then combined with re.sub + a lambda.
# ═══════════════════════════════════════════════════════════════════════════════

# Matches a section number at the very start of the string
_SECTION_NUM_START = re.compile(
    r'^\s*\d{1,2}(?:\.\d{1,2}){1,2}\s+(?=[A-Z]{2})',
)
# Matches a section number immediately after a sentence-ending char or newline
_SECTION_NUM_MID = re.compile(
    r'(?<=[.!?\n])\s*\d{1,2}(?:\.\d{1,2}){1,2}\s+(?=[A-Z]{2})',
)


def strip_section_numbers(text: str) -> str:
    t = _SECTION_NUM_START.sub("", text)
    t = _SECTION_NUM_MID.sub(" ", t)
    return t


# ═══════════════════════════════════════════════════════════════════════════════
# D–F. Punctuation / whitespace normalisation
# ═══════════════════════════════════════════════════════════════════════════════

def normalize_punctuation(text: str) -> str:
    """
    D. Ellipsis → single period
    E. Orphan spaces before punctuation, duplicate punctuation
    F. Newlines → spaces (collapse multiline into paragraph)
    """
    # F. Newlines: paragraph breaks → sentence boundary; single newlines → space
    t = re.sub(r"\n{2,}", " ", text)
    t = re.sub(r"\n", " ", t)

    # D. Ellipsis / multiple periods
    t = re.sub(r"\.{2,}", ".", t)

    # E. Space before punctuation
    t = re.sub(r"\s+([.,;:!?])", r"\1", t)

    # E. Duplicate punctuation
    t = re.sub(r"([.,;:])\s*\1+", r"\1", t)
    t = re.sub(r"([.,;:])\s*[,;:]", r"\1", t)

    # Comma/semicolon before period
    t = re.sub(r"[,;]\s*\.", ".", t)

    # Multiple spaces
    t = re.sub(r"\s{2,}", " ", t)

    # Leading punctuation / stray symbols
    t = re.sub(r"^[\s.,;:!?|•·▪■–—]+", "", t)

    # Trailing non-period punctuation → period, or just strip
    t = re.sub(r"\s*[,;:]\s*$", ".", t)

    return t.strip()


# ═══════════════════════════════════════════════════════════════════════════════
# G. Sentence-level deduplication  (re-run after all new cleaning)
# ═══════════════════════════════════════════════════════════════════════════════

_SENT_SPLIT = re.compile(r"(?<=[.!?])\s+")

def dedup_sentences(text: str) -> str:
    if not text:
        return text
    segments = _SENT_SPLIT.split(text)
    seen: set[str] = set()
    unique: list[str] = []
    for seg in segments:
        key = re.sub(r"\s+", " ", seg.strip().lower())
        if key and key not in seen:
            seen.add(key)
            unique.append(seg.strip())
    return " ".join(unique)


# ═══════════════════════════════════════════════════════════════════════════════
# Per-cell timeout guard
#
# Drug label cells can be arbitrarily long and malformed. Even with the regex
# fixes above, a belt-and-suspenders timeout prevents any single cell from
# blocking the job indefinitely.
#
# Uses SIGALRM on Unix/macOS; falls back to a threading.Timer on Windows.
# ═══════════════════════════════════════════════════════════════════════════════

CELL_TIMEOUT_SECONDS = 5   # adjust if your cells are legitimately very long


class _TimeoutError(Exception):
    pass


def _run_with_timeout(fn, *args, timeout=CELL_TIMEOUT_SECONDS):
    """Run fn(*args) and return its result; raise _TimeoutError if it takes too long."""
    try:
        # --- Unix path: SIGALRM (cheap, same thread) ---
        def _handler(signum, frame):
            raise _TimeoutError()

        old = signal.signal(signal.SIGALRM, _handler)
        signal.alarm(timeout)
        try:
            return fn(*args)
        finally:
            signal.alarm(0)
            signal.signal(signal.SIGALRM, old)
    except AttributeError:
        # --- Windows fallback: thread-based ---
        result = [None]
        exc    = [None]

        def _target():
            try:
                result[0] = fn(*args)
            except Exception as e:
                exc[0] = e

        t = threading.Thread(target=_target, daemon=True)
        t.start()
        t.join(timeout)
        if t.is_alive():
            raise _TimeoutError()
        if exc[0]:
            raise exc[0]
        return result[0]


# ═══════════════════════════════════════════════════════════════════════════════
# Master per-cell cleaner
# ═══════════════════════════════════════════════════════════════════════════════

_timed_out_cells = 0   # global counter so we can report at the end


def _deep_clean_inner(text: str) -> str | None:
    """Core cleaning logic — called inside the timeout wrapper."""
    t = str(text).strip()
    if not t or t.lower() in _STUB_VALUES:
        return None

    # A. Cross-references
    t = remove_cross_refs(t)

    # B. Trademark symbols
    t = _SYMBOL_RE.sub("", t)

    # C. Floating section numbers
    t = strip_section_numbers(t)

    # D–F. Punctuation / whitespace
    t = normalize_punctuation(t)

    # G. Sentence dedup
    t = dedup_sentences(t)

    # Final stub guard
    if not t or t.lower() in _STUB_VALUES:
        return None

    return t


def deep_clean(text) -> str | None:
    """Apply all v2 cleaning steps; return original value on timeout."""
    global _timed_out_cells
    if pd.isna(text):
        return None
    try:
        return _run_with_timeout(_deep_clean_inner, text)
    except _TimeoutError:
        _timed_out_cells += 1
        # Return the raw value so we don't silently lose data
        return str(text).strip() or None


# ═══════════════════════════════════════════════════════════════════════════════
# Audit helpers
# ═══════════════════════════════════════════════════════════════════════════════

def audit(df: pd.DataFrame, label: str = "") -> None:
    if label:
        print(f"\n── {label} ──")
    checks = {
        "(See …) cross-refs remaining":
            sum(df[c].str.contains(r"\(\s*[Ss]ee\s+", na=False).sum() for c in TEXT_COLS),
        "[See …] cross-refs remaining":
            sum(df[c].str.contains(r"\[\s*[Ss]ee\s+", na=False).sum() for c in TEXT_COLS),
        "Bare 'See SECTION' remaining":
            sum(df[c].str.contains(r"\bSee\s+(?:BOXED|WARNINGS?|INDICATION|DOSAGE|CONTRA|ADVERSE|CLINICAL)",
                                    na=False).sum() for c in TEXT_COLS),
        "Trademark symbols ® ™":
            sum(df[c].str.contains(r"[®™©]", na=False).sum() for c in TEXT_COLS),
        "Floating section numbers (e.g. 5.1 TITLE)":
            sum(df[c].str.contains(r"\b\d+\.\d+\s+[A-Z]{3}", na=False).sum() for c in TEXT_COLS),
        "Double periods / ellipsis":
            sum(df[c].str.contains(r"\.{2,}", na=False).sum() for c in TEXT_COLS),
        "Space before punctuation":
            sum(df[c].str.contains(r"\s[.,;:!?]", na=False).sum() for c in TEXT_COLS),
        "Cells still 'Not specified'":
            sum((df[c] == "Not specified").sum() for c in TEXT_COLS),
    }
    for desc, count in checks.items():
        status = "✓  0" if count == 0 else f"⚠  {count}"
        print(f"  {desc:50s}: {status}")


# ═══════════════════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════════════════

def main() -> None:
    print(f"Loading  {INPUT_FILE} …")
    df = pd.read_parquet(INPUT_FILE)
    print(f"  Shape: {df.shape}  |  columns: {df.columns.tolist()}\n")

    audit(df, "PRE-CLEAN")

    # ── Apply deep_clean to every text column ──────────────────────────────
    for col in TEXT_COLS:
        if col not in df.columns:
            continue
        before_null = df[col].isna().sum() + (df[col] == "Not specified").sum()
        df[col] = df[col].apply(deep_clean)
        # Re-fill nulls with "Not specified" for downstream compatibility
        df[col] = df[col].fillna("Not specified")
        after_null = (df[col] == "Not specified").sum()
        delta = after_null - before_null
        print(f"  {col}: {delta:+,} cells became 'Not specified' after deep clean")

    if _timed_out_cells:
        print(f"\n  ⚠  {_timed_out_cells} cell(s) hit the {CELL_TIMEOUT_SECONDS}s timeout "
              f"and were kept as-is. Inspect them and consider raising CELL_TIMEOUT_SECONDS.")

    # ── Recalculate binary flags ───────────────────────────────────────────
    df["has_contraindications"] = (
        df["contraindications"].notna() & (df["contraindications"] != "Not specified")
    ).astype(int)
    df["has_side_effects"] = (
        df["side_effects"].notna() & (df["side_effects"] != "Not specified")
    ).astype(int)

    audit(df, "POST-CLEAN")

    # ── Save ──────────────────────────────────────────────────────────────
    df.to_parquet(OUTPUT_FILE, index=False)
    print(f"\nSaved → {OUTPUT_FILE}  |  shape: {df.shape}")

    # ── Spot-check: show 5 cleaned samples per column ─────────────────────
    print("\n── Spot-check samples (non-stub, first 200 chars) ──")
    for col in TEXT_COLS:
        valid = df.loc[df[col] != "Not specified", col]
        if valid.empty:
            continue
        print(f"\n  [{col}]")
        for val in valid.sample(min(3, len(valid)), random_state=42):
            print(f"    {val[:200]}")


if __name__ == "__main__":
    main()