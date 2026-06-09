"""UI components for sidebar configuration and display logic."""
import streamlit as st
from constants import (
    DEFAULT_CHAT_MODEL, DEFAULT_EMBED_MODEL, DEFAULT_CHUNK_SIZE,
    DEFAULT_CHUNK_OVERLAP, DEFAULT_TOP_K, MODE_UPLOAD, MODE_SNOWFLAKE
)
from helpers import extract_text, chunk_text, doc_hash
from ollama import embed, list_models

# Try to import snowflake functions, but don't fail if module is not installed
try:
    from snowflake_methods import query_patient_data, search_patients, SNOWFLAKE_AVAILABLE
except ImportError:
    SNOWFLAKE_AVAILABLE = False
    query_patient_data = None
    search_patients = None


def render_sidebar(ollama_url: str) -> tuple[str, str, str, int, int, int, dict]:
    """Render sidebar configuration and return settings, mode, and document info."""
    with st.sidebar:
        st.markdown("### ⚙️ Configuration")
        ollama_url = st.text_input("Ollama base URL", value=ollama_url)

        models = list_models(ollama_url)
        if models:
            chat_model  = st.selectbox("Chat model",      models, index=0)
            embed_model = st.selectbox("Embedding model", models, index=0)
            st.markdown(
                f'<span class="pill pill-green">✓ Connected · {len(models)} models</span>',
                unsafe_allow_html=True
            )
        else:
            chat_model  = st.text_input("Chat model",      value=DEFAULT_CHAT_MODEL)
            embed_model = st.text_input("Embedding model", value=DEFAULT_EMBED_MODEL)
            st.markdown('<span class="pill pill-red">✗ Ollama unreachable</span>', unsafe_allow_html=True)

        st.markdown("---")
        st.markdown("### 📊 Mode")
        mode = st.radio("Select mode:", [MODE_UPLOAD, MODE_SNOWFLAKE], label_visibility="collapsed")

        st.markdown("---")

        # Upload mode settings
        if mode == MODE_UPLOAD:
            st.markdown("### 📄 Document Upload")
            uploaded = st.file_uploader(
                "Upload a file",
                type=["txt", "md", "pdf"],
                label_visibility="collapsed",
            )

            chunk_size    = st.slider("Chunk size (words)",    200, 1000, DEFAULT_CHUNK_SIZE, 50)
            chunk_overlap = st.slider("Overlap (words)",        0,  200,  DEFAULT_CHUNK_OVERLAP, 10)
            top_k         = st.slider("Top-K chunks to use",   1,   10,   DEFAULT_TOP_K,  1)

            document_info = {
                "uploaded": uploaded,
                "chunk_size": chunk_size,
                "chunk_overlap": chunk_overlap,
            }
        # Snowflake mode settings
        else:
            st.markdown("### ❄️ Patient Query")
            patient_id = st.text_input("Patient ID", placeholder="Enter patient ID...")
            search_term = st.text_input("Or search by name", placeholder="Search patient name...")

            document_info = {
                "patient_id": patient_id,
                "search_term": search_term,
            }
            uploaded = None
            chunk_size = DEFAULT_CHUNK_SIZE
            chunk_overlap = DEFAULT_CHUNK_OVERLAP
            top_k = DEFAULT_TOP_K

        if st.button("🗑 Clear conversation"):
            st.session_state.chat_history = []
            st.rerun()

    return ollama_url, chat_model, embed_model, top_k, mode, document_info


def process_document(
    uploaded,
    chunk_size: int,
    chunk_overlap: int,
    embed_model: str,
    ollama_url: str,
) -> bool:
    """Process uploaded document and update session state."""
    if not uploaded:
        return False

    text = extract_text(uploaded)
    h = doc_hash(text)

    if h != st.session_state.doc_hash:
        with st.spinner("Indexing document…"):
            chunks = chunk_text(text, chunk_size, chunk_overlap)
            store = []
            bar = st.progress(0)
            for i, chunk in enumerate(chunks):
                vec = embed(chunk, embed_model, ollama_url)
                if vec:
                    store.append({"text": chunk, "vec": vec, "id": i})
                bar.progress((i + 1) / len(chunks))
            bar.empty()

        st.session_state.vector_store = store
        st.session_state.doc_hash = h
        st.session_state.doc_loaded = True
        st.session_state.chat_history = []
        st.success(f"Indexed {len(store)} chunks from **{uploaded.name}**")
    else:
        st.markdown(
            f'<span class="pill pill-blue">✓ {uploaded.name} already indexed</span>',
            unsafe_allow_html=True
        )

    return st.session_state.doc_loaded


def process_snowflake_data(patient_id: str, search_term: str, embed_model: str, ollama_url: str) -> bool:
    """Process Snowflake patient data and prepare for querying."""
    # if not SNOWFLAKE_AVAILABLE:
    #     st.error("Snowflake module not installed. Install with: pip install snowflake-connector-python")
    #     return False

    patient_data = None

    # First try exact patient ID match
    if patient_id and patient_id.strip():
        with st.spinner("Loading patient data…"):
            patient_data = query_patient_data(patient_id.strip())
            if patient_data:
                st.success(f"✓ Patient data loaded for ID: {patient_id}")
            else:
                st.warning(f"No patient found with ID: {patient_id}")
    # Then try search by name
    elif search_term and search_term.strip():
        with st.spinner("Searching patients…"):
            results = search_patients(search_term.strip())
            if results:
                st.info(f"Found {len(results)} patient(s)")
                # Create display options
                options = [f"{r['patient_id']} - {r['patient_name']}" for r in results]
                selected = st.selectbox("Select a patient:", options, key="patient_select")
                if selected:
                    selected_id = selected.split(" - ")[0]
                    patient_data = query_patient_data(selected_id)
            else:
                st.warning(f"No patients found matching: {search_term}")
    else:
        st.info("Enter a patient ID or search term to begin")
        return False

    # If we have patient data, convert to document format
    if patient_data:
        # Convert patient data to a readable format for RAG
        text_content = "Patient Information:\n\n"
        for key, value in patient_data.items():
            text_content += f"• {key}: {value}\n"

        h = doc_hash(text_content)

        if h != st.session_state.doc_hash:
            with st.spinner("Indexing patient data…"):
                # Create a single chunk with the patient data
                vec = embed(text_content, embed_model, ollama_url)
                if vec:
                    st.session_state.vector_store = [{"text": text_content, "vec": vec, "id": 0}]
                    st.session_state.doc_hash = h
                    st.session_state.doc_loaded = True
                    st.session_state.chat_history = []
                    st.session_state.patient_data = patient_data
                    st.success("✓ Patient data indexed and ready for queries")
                    return True

    return False


def render_chat_history():
    """Render the chat history with styling."""
    chat_html = '<div class="chat-scroll">'
    for msg in st.session_state.chat_history:
        if msg["role"] == "user":
            chat_html += f'<div class="msg-user"><div class="bubble">{msg["content"]}</div></div>'
        else:
            answer = msg["content"]
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


def render_header():
    """Render main header."""
    st.markdown('<div class="app-title">DocChat</div>', unsafe_allow_html=True)
    st.markdown(
        '<div class="app-sub">Retrieval-Augmented Generation · Powered by Ollama</div>',
        unsafe_allow_html=True
    )
