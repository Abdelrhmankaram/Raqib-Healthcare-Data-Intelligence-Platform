"""Page configuration and styling for DocChat."""
import streamlit as st

# ── Page config ──────────────────────────────────────────────────────────────
def setup_page_config():
    """Configure Streamlit page settings."""
    st.set_page_config(
        page_title="DocChat · Ollama RAG",
        page_icon="📄",
        layout="wide",
    )


# ── Custom CSS ────────────────────────────────────────────────────────────────
CUSTOM_CSS = """
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
"""


def apply_custom_css():
    """Apply custom CSS to the Streamlit app."""
    st.markdown(CUSTOM_CSS, unsafe_allow_html=True)
