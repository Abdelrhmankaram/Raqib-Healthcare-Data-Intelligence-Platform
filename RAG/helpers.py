"""Utility functions for text processing and document handling."""
import hashlib
import streamlit as st
from constants import DEFAULT_CHUNK_SIZE, DEFAULT_CHUNK_OVERLAP


def extract_text(uploaded_file) -> str:
    """Extract plain text from uploaded file (txt, md, pdf)."""
    name = uploaded_file.name.lower()
    raw = uploaded_file.read()

    if name.endswith(".pdf"):
        try:
            import pypdf, io
            reader = pypdf.PdfReader(io.BytesIO(raw))
            return "\n\n".join(p.extract_text() or "" for p in reader.pages)
        except ImportError:
            st.sidebar.warning("pypdf not installed — install it for PDF support.")
            return raw.decode("utf-8", errors="ignore")
    else:
        return raw.decode("utf-8", errors="ignore")


def chunk_text(text: str, size: int = DEFAULT_CHUNK_SIZE, overlap: int = DEFAULT_CHUNK_OVERLAP) -> list[str]:
    """Split text into overlapping word-level chunks."""
    words = text.split()
    chunks, i = [], 0
    while i < len(words):
        chunk = " ".join(words[i : i + size])
        if chunk.strip():
            chunks.append(chunk)
        i += size - overlap
    return chunks


def cosine_sim(a: list[float], b: list[float]) -> float:
    """Calculate cosine similarity between two vectors."""
    dot = sum(x * y for x, y in zip(a, b))
    na  = sum(x * x for x in a) ** 0.5
    nb  = sum(x * x for x in b) ** 0.5
    return dot / (na * nb + 1e-9)


def doc_hash(text: str) -> str:
    """Generate MD5 hash of document text for change detection."""
    return hashlib.md5(text.encode()).hexdigest()
