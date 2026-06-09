"""
DocChat: Retrieval-Augmented Generation with Ollama
Main entry point for the Streamlit application.
Supports both document upload and Snowflake patient data query modes.
"""
import streamlit as st
from config import setup_page_config, apply_custom_css
from ui import render_sidebar, process_document, process_snowflake_data, render_chat_history, render_header
from ollama import embed
from rag import retrieve, generate_answer
from constants import DEFAULT_OLLAMA_URL, MODE_UPLOAD, MODE_SNOWFLAKE


# ── Initialize Page ──────────────────────────────────────────────────────────
setup_page_config()
apply_custom_css()


# ── Initialize Session State ─────────────────────────────────────────────────
for key, val in {
    "vector_store": [],
    "chat_history": [],
    "doc_loaded": False,
    "doc_hash": "",
    "patient_data": None,
    "search_results": [],
}.items():
    if key not in st.session_state:
        st.session_state[key] = val


# ── Sidebar ──────────────────────────────────────────────────────────────────
ollama_url, chat_model, embed_model, top_k, mode, document_info = render_sidebar(DEFAULT_OLLAMA_URL)

# Process based on mode
if mode == MODE_UPLOAD:
    process_document(
        document_info.get("uploaded"),
        document_info.get("chunk_size"),
        document_info.get("chunk_overlap"),
        embed_model,
        ollama_url,
    )
elif mode == MODE_SNOWFLAKE:
    patient_id = document_info.get("patient_id", "")
    search_term = document_info.get("search_term", "")
    # Only process if there's input and document hasn't been loaded yet
    if not st.session_state.doc_loaded and (patient_id or search_term):
        process_snowflake_data(patient_id, search_term, embed_model, ollama_url)


# ── Main Area ────────────────────────────────────────────────────────────────
render_header()

if not st.session_state.doc_loaded:
    if mode == MODE_UPLOAD:
        st.info("👈 Upload a document in the sidebar to get started.")
    else:
        st.info("👈 Enter a patient ID or search by name in the sidebar to query Snowflake data.")
else:
    # Display patient info if in Snowflake mode
    if mode == MODE_SNOWFLAKE and st.session_state.patient_data:
        with st.expander("📋 Patient Information", expanded=False):
            for key, value in st.session_state.patient_data.items():
                st.write(f"**{key}:** {value}")

    # Render chat history
    with st.container():
        render_chat_history()

    st.markdown("---")

    # Input row
    col1, col2 = st.columns([8, 1])
    with col1:
        question = st.text_input(
            "Ask a question",
            placeholder="Ask anything about the document or patient data…",
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

                # 3. Generate answer
                answer = generate_answer(q, chunks, chat_model, ollama_url)

                # 4. Save to history
                st.session_state.chat_history.append({"role": "user", "content": q})
                st.session_state.chat_history.append({
                    "role": "assistant",
                    "content": answer,
                    "sources": chunks
                })
                st.rerun()