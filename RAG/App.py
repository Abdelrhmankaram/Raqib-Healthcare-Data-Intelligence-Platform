import streamlit as st
import requests
import json
import re
import hashlib
from pathlib import Path

# ── Page config ──────────────────────────────────────────────────────────────
st.set_page_config(
    page_title="DocChat · Ollama RAG",
    page_icon="📄",
    layout="wide",
)

# ── Custom CSS ────────────────────────────────────────────────────────────────
st.markdown("""
<style>
@import url('https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=DM+Mono:wght@400;500&display=swap');

:root {
    --ink:    #1a1a2e;
    --paper:  #f5f0e8;
    --cream:  #ede7d9;
    --accent: #c0392b;
    --muted:  #7a7368;
    --border: #d4cfc6;
    --card:   #ffffff;
}

html, body, [data-testid="stAppViewContainer"] {
    background: var(--paper) !important;
    color: var(--ink);
    font-family: 'DM Mono', monospace;
}

/* Hide default header */
[data-testid="stHeader"] { display: none; }

/* Sidebar */
[data-testid="stSidebar"] {
    background: var(--ink) !important;
    border-right: 1px solid #2e2e4a;
}
[data-testid="stSidebar"] * { color: #e8e4dc !important; }
[data-testid="stSidebar"] .pill * { color: inherit !important; }
[data-testid="stSidebar"] .stFileUploader label { color: #a09892 !important; font-size: 0.75rem; }
[data-testid="stSidebar"] input,
[data-testid="stSidebar"] .stTextInput input {
    background: #2a2a3e !important;
    border: 1px solid #3a3a5a !important;
    color: #e8e4dc !important;
    border-radius: 4px;
}

/* Fix selectbox and other white background elements */
[data-testid="stSidebar"] div[data-baseweb="select"],
[data-testid="stSidebar"] .stSelectbox,
[data-testid="stSidebar"] .stNumberInput,
[data-testid="stSidebar"] .stSlider {
    color: var(--ink) !important;
}

[data-testid="stSidebar"] div[data-baseweb="select"] div,
[data-testid="stSidebar"] .stSelectbox div,
[data-testid="stSidebar"] .stNumberInput div,
[data-testid="stSidebar"] .stSlider div {
    color: var(--ink) !important;
}

[data-testid="stSidebar"] span, 
[data-testid="stSidebar"] p,
[data-testid="stSidebar"] label {
    color: #e8e4dc !important;
}

/* File uploader styling */
[data-testid="stSidebar"] .stFileUploader {
    color: var(--ink) !important;
}
[data-testid="stSidebar"] .stFileUploader * {
    color: var(--ink) !important;
}
[data-testid="stSidebar"] .stFileUploader button {
    color: var(--ink) !important;
}
[data-testid="stSidebar"] .stFileUploader div span,
[data-testid="stSidebar"] .stFileUploader div p {
    color: var(--ink) !important;
}

/* Main title */
.app-title {
    font-family: 'Instrument Serif', serif;
    font-size: 2.6rem;
    color: var(--ink);
    letter-spacing: -0.5px;
    line-height: 1.1;
    margin-bottom: 0.2rem;
}
.app-sub {
    font-size: 0.72rem;
    color: var(--muted);
    letter-spacing: 0.12em;
    text-transform: uppercase;
    margin-bottom: 2rem;
}

/* Chat messages */
.msg-user {
    display: flex;
    justify-content: flex-end;
    margin: 0.6rem 0;
}
.msg-user .bubble {
    background: var(--ink);
    color: #f0ece4;
    padding: 0.7rem 1rem;
    border-radius: 12px 12px 2px 12px;
    max-width: 72%;
    font-size: 0.85rem;
    line-height: 1.55;
}
.msg-bot {
    display: flex;
    justify-content: flex-start;
    margin: 0.6rem 0;
}
.msg-bot .bubble {
    background: var(--card);
    color: var(--ink);
    padding: 0.7rem 1rem;
    border-radius: 12px 12px 12px 2px;
    max-width: 72%;
    font-size: 0.85rem;
    line-height: 1.7;
    border: 1px solid var(--border);
    box-shadow: 0 1px 4px rgba(0,0,0,0.04);
}
.msg-bot .label {
    font-size: 0.65rem;
    color: var(--muted);
    letter-spacing: 0.1em;
    text-transform: uppercase;
    margin-bottom: 0.3rem;
}

/* Source chunk box */
.source-box {
    background: var(--cream);
    border-left: 3px solid var(--accent);
    padding: 0.6rem 0.8rem;
    margin-top: 0.5rem;
    font-size: 0.75rem;
    color: var(--muted);
    border-radius: 0 6px 6px 0;
    font-style: italic;
}

/* Status pills */
.pill {
    display: inline-block;
    padding: 0.2rem 0.6rem;
    border-radius: 20px;
    font-size: 0.68rem;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    font-weight: 500;
}
.pill-green { background: #000000; color: #1a5c2a; }
.pill-red   { background: #fde8e8; color: #8b1c1c; }
.pill-blue  { background: #dbeafe; color: #1e3a8a; }

/* Input area */
.stTextInput input {
    border: 1.5px solid var(--border) !important;
    border-radius: 8px !important;
    background: var(--card) !important;
    font-family: 'DM Mono', monospace !important;
    font-size: 0.85rem !important;
    padding: 0.6rem 1rem !important;
    color: var(--ink) !important;
}
.stTextInput input:focus {
    border-color: var(--accent) !important;
    box-shadow: 0 0 0 2px rgba(192,57,43,0.1) !important;
}

/* Buttons */
.stButton > button {
    background: var(--accent) !important;
    color: white !important;
    border: none !important;
    border-radius: 6px !important;
    font-family: 'DM Mono', monospace !important;
    font-size: 0.78rem !important;
    letter-spacing: 0.05em !important;
    padding: 0.45rem 1rem !important;
    transition: opacity 0.15s;
}
.stButton > button:hover { opacity: 0.85 !important; }

/* Divider */
hr { border-color: var(--border); margin: 1.2rem 0; }

/* Scrollable chat area */
.chat-scroll {
    max-height: 58vh;
    overflow-y: auto;
    padding-right: 4px;
}
</style>
""", unsafe_allow_html=True)

# ── Helpers ───────────────────────────────────────────────────────────────────

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


def chunk_text(text: str, size: int = 500, overlap: int = 80) -> list[str]:
    """Split text into overlapping word-level chunks."""
    words = text.split()
    chunks, i = [], 0
    while i < len(words):
        chunk = " ".join(words[i : i + size])
        if chunk.strip():
            chunks.append(chunk)
        i += size - overlap
    return chunks


def embed(text: str, model: str, base_url: str) -> list[float] | None:
    """Get embedding from Ollama /api/embed."""
    try:
        r = requests.post(
            f"{base_url}/api/embed",
            json={"model": model, "input": text},
            timeout=60,
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


def cosine_sim(a: list[float], b: list[float]) -> float:
    dot = sum(x * y for x, y in zip(a, b))
    na  = sum(x * x for x in a) ** 0.5
    nb  = sum(x * x for x in b) ** 0.5
    return dot / (na * nb + 1e-9)


def retrieve(query_vec: list[float], store: list[dict], top_k: int = 4) -> list[dict]:
    scored = sorted(store, key=lambda c: cosine_sim(query_vec, c["vec"]), reverse=True)
    return scored[:top_k]


def chat(messages: list[dict], model: str, base_url: str) -> str:
    """Call Ollama /api/chat."""
    try:
        r = requests.post(
            f"{base_url}/api/chat",
            json={"model": model, "messages": messages, "stream": False},
            timeout=120,
        )
        r.raise_for_status()
        return r.json()["message"]["content"]
    except Exception as e:
        return f"⚠️ Chat error: {e}"


def list_models(base_url: str) -> list[str]:
    try:
        r = requests.get(f"{base_url}/api/tags", timeout=8)
        r.raise_for_status()
        return [m["name"] for m in r.json().get("models", [])]
    except Exception:
        return []


def doc_hash(text: str) -> str:
    return hashlib.md5(text.encode()).hexdigest()


# ── Session state init ────────────────────────────────────────────────────────
for key, val in {
    "vector_store": [],
    "chat_history":  [],
    "doc_loaded":    False,
    "doc_hash":      "",
}.items():
    if key not in st.session_state:
        st.session_state[key] = val

# ── Sidebar ───────────────────────────────────────────────────────────────────
with st.sidebar:
    st.markdown("### ⚙️ Configuration")
    ollama_url = st.text_input("Ollama base URL", value="http://localhost:11434")

    models = list_models(ollama_url)
    if models:
        chat_model  = st.selectbox("Chat model",      models, index=0)
        embed_model = st.selectbox("Embedding model", models, index=0)
        st.markdown(f'<span class="pill pill-green">✓ Connected · {len(models)} models</span>', unsafe_allow_html=True)
    else:
        chat_model  = st.text_input("Chat model",      value="llama3")
        embed_model = st.text_input("Embedding model", value="nomic-embed-text")
        st.markdown('<span class="pill pill-red">✗ Ollama unreachable</span>', unsafe_allow_html=True)

    st.markdown("---")
    st.markdown("### 📄 Document")
    uploaded = st.file_uploader(
        "Upload a file",
        type=["txt", "md", "pdf"],
        label_visibility="collapsed",
    )

    chunk_size    = st.slider("Chunk size (words)",    200, 1000, 500, 50)
    chunk_overlap = st.slider("Overlap (words)",        0,  200,  80, 10)
    top_k         = st.slider("Top-K chunks to use",   1,   10,   4,  1)

    if uploaded:
        text = extract_text(uploaded)
        h    = doc_hash(text)

        if h != st.session_state.doc_hash:
            with st.spinner("Indexing document…"):
                chunks = chunk_text(text, chunk_size, chunk_overlap)
                store  = []
                bar    = st.progress(0)
                for i, chunk in enumerate(chunks):
                    vec = embed(chunk, embed_model, ollama_url)
                    if vec:
                        store.append({"text": chunk, "vec": vec, "id": i})
                    bar.progress((i + 1) / len(chunks))
                bar.empty()

            st.session_state.vector_store = store
            st.session_state.doc_hash     = h
            st.session_state.doc_loaded   = True
            st.session_state.chat_history = []
            st.success(f"Indexed {len(store)} chunks from **{uploaded.name}**")
        else:
            st.markdown(f'<span class="pill pill-blue">✓ {uploaded.name} already indexed</span>', unsafe_allow_html=True)

    if st.button("🗑 Clear conversation"):
        st.session_state.chat_history = []
        st.rerun()

# ── Main area ─────────────────────────────────────────────────────────────────
st.markdown('<div class="app-title">DocChat</div>', unsafe_allow_html=True)
st.markdown('<div class="app-sub">Retrieval-Augmented Generation · Powered by Ollama</div>', unsafe_allow_html=True)

if not st.session_state.doc_loaded:
    st.info("👈 Upload a document in the sidebar to get started.")
else:
    # Render chat history
    with st.container():
        chat_html = '<div class="chat-scroll">'
        for msg in st.session_state.chat_history:
            if msg["role"] == "user":
                chat_html += f'<div class="msg-user"><div class="bubble">{msg["content"]}</div></div>'
            else:
                answer  = msg["content"]
                sources = msg.get("sources", [])
                src_html = ""
                for s in sources:
                    snippet = s["text"][:180].replace("<", "&lt;").replace(">", "&gt;")
                    src_html += f'<div class="source-box">…{snippet}…</div>'
                chat_html += (
                    f'<div class="msg-bot"><div class="bubble">'
                    f'<div class="label">DocChat</div>'
                    f'{answer}{src_html}'
                    f'</div></div>'
                )
        chat_html += "</div>"
        st.markdown(chat_html, unsafe_allow_html=True)

    st.markdown("---")

    # Input row
    col1, col2 = st.columns([8, 1])
    with col1:
        question = st.text_input(
            "Ask a question",
            placeholder="Ask anything about the document…",
            label_visibility="collapsed",
            key="q_input",
        )
    with col2:
        send = st.button("Send →")

    if send and question.strip():
        q = question.strip()

        with st.spinner("Thinking…"):
            # 1. Embed the question
            q_vec = embed(q, embed_model, ollama_url)
            if q_vec is None:
                st.error("Could not embed your question. Check Ollama.")
            else:
                # 2. Retrieve relevant chunks
                chunks = retrieve(q_vec, st.session_state.vector_store, top_k)
                context = "\n\n---\n\n".join(c["text"] for c in chunks)

                # 3. Build prompt
                system_prompt = (
                    "You are a helpful assistant that answers questions strictly based on "
                    "the provided document context. If the answer is not in the context, "
                    "say so clearly. Be concise and precise.\n\n"
                    f"DOCUMENT CONTEXT:\n{context}"
                )
                ollama_messages = [
                    {"role": "system",    "content": system_prompt},
                    {"role": "user",      "content": q},
                ]

                # 4. Chat
                answer = chat(ollama_messages, chat_model, ollama_url)

                # 5. Save
                st.session_state.chat_history.append({"role": "user",      "content": q})
                st.session_state.chat_history.append({"role": "assistant", "content": answer, "sources": chunks})
                st.rerun()