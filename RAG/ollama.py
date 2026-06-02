"""Ollama API interactions for embeddings, chat, and model management."""
import requests
import streamlit as st
from constants import EMBED_TIMEOUT, CHAT_TIMEOUT, API_TIMEOUT


def embed(text: str, model: str, base_url: str) -> list[float] | None:
    """Get embedding from Ollama /api/embed endpoint."""
    try:
        r = requests.post(
            f"{base_url}/api/embed",
            json={"model": model, "input": text},
            timeout=EMBED_TIMEOUT,
        )
        r.raise_for_status()
        data = r.json()
        # Ollama returns {"embeddings": [[...]]}
        embs = data.get("embeddings") or data.get("embedding")
        if isinstance(embs, list) and embs:
            return embs[0] if isinstance(embs[0], list) else embs
    except Exception as e:
        st.error(f"Embedding error: {e}")
    return None


def chat(messages: list[dict], model: str, base_url: str) -> str:
    """Call Ollama /api/chat endpoint."""
    try:
        r = requests.post(
            f"{base_url}/api/chat",
            json={"model": model, "messages": messages, "stream": False},
            timeout=CHAT_TIMEOUT,
        )
        r.raise_for_status()
        return r.json()["message"]["content"]
    except Exception as e:
        return f"⚠️ Chat error: {e}"


def list_models(base_url: str) -> list[str]:
    """Fetch list of available models from Ollama."""
    try:
        r = requests.get(f"{base_url}/api/tags", timeout=API_TIMEOUT)
        r.raise_for_status()
        return [m["name"] for m in r.json().get("models", [])]
    except Exception:
        return []
