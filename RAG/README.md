# DocChat - Project Structure

This project has been refactored from a single `App.py` file into modular components for better maintainability and navigation. It now supports two modes: **Document Upload** and **Snowflake Patient Query**.

## File Structure

```
├── App.py                 # Main entry point (minimal orchestration)
├── config.py             # Page configuration and CSS styling
├── constants.py          # Application constants and settings
├── helpers.py            # Text processing utilities
├── ollama.py             # Ollama API interactions
├── rag.py                # RAG logic (retrieval & answer generation)
├── snowflake.py          # Snowflake database interactions (NEW)
├── ui.py                 # UI components and sidebar rendering
└── README.md             # This file
```

## Module Descriptions

### `App.py` (Main Entry Point)
The central application file that orchestrates all modules. It:
- Initializes the Streamlit page and CSS
- Sets up session state
- Manages sidebar and mode selection
- Handles document processing or Snowflake data queries
- Coordinates chat interactions

**Key responsibilities:**
- Streamlit app lifecycle
- State management
- Mode orchestration (Upload vs Snowflake)
- User input handling

---

### `constants.py` (Configuration & Settings)
Contains all hardcoded values and configuration constants.

**Key constants:**
- `DEFAULT_CHAT_MODEL` - Ollama chat model (llama3)
- `DEFAULT_EMBED_MODEL` - Ollama embedding model (nomic-embed-text)
- `DEFAULT_OLLAMA_URL` - Ollama server URL
- `SNOWFLAKE_CONFIG` - Snowflake connection credentials
- Timeout values and default chunk sizes

**Why separate?** Makes it easy to change settings without modifying code logic.

---

### `config.py` (Configuration & Styling)
Contains page configuration and CSS styling.

**Key functions:**
- `setup_page_config()` - Configures Streamlit page title, icon, and layout
- `apply_custom_css()` - Applies custom CSS for the entire app
- `CUSTOM_CSS` - All CSS styling constants

**Why separate?** Makes it easy to update styling without touching logic.

---

### `helpers.py` (Utilities)
Low-level text processing and utility functions.

**Key functions:**
- `extract_text(uploaded_file)` - Extracts text from TXT, MD, or PDF files
- `chunk_text(text, size, overlap)` - Splits text into overlapping word-level chunks
- `cosine_sim(a, b)` - Calculates cosine similarity between vectors
- `doc_hash(text)` - Generates MD5 hash for change detection

**Why separate?** Pure utility functions with no Streamlit dependencies.

---

### `ollama.py` (API Client)
Handles all communication with the Ollama server.

**Key functions:**
- `embed(text, model, base_url)` - Gets embeddings from Ollama
- `chat(messages, model, base_url)` - Sends chat requests to Ollama
- `list_models(base_url)` - Fetches available models from Ollama

**Why separate?** Centralizes all external API calls, making them easy to test or swap out.

---

### `rag.py` (RAG Logic)
Core retrieval-augmented generation functionality.

**Key functions:**
- `retrieve(query_vec, store, top_k)` - Finds top-k similar chunks
- `generate_answer(question, chunks, chat_model, base_url)` - Generates LLM response using retrieved chunks

**Why separate?** Isolates the RAG algorithm from UI concerns.

---

### `snowflake.py` (Database Integration) - NEW
Handles Snowflake database interactions for patient data queries.

**Key functions:**
- `get_snowflake_connection()` - Creates Snowflake connection using credentials
- `query_patient_data(patient_id)` - Fetches patient data by ID
- `search_patients(search_term, field)` - Searches for patients by name or other fields

**Why separate?** Centralizes all Snowflake logic, easy to modify queries or connection details.

**Setup Required:**
Update `constants.py` with your Snowflake credentials:
```python
SNOWFLAKE_CONFIG = {
    "account": "xy12345.us-east-1",    # Your account ID
    "user": "your_user",
    "password": "your_password",
    "warehouse": "your_warehouse",
    "database": "your_database",
    "schema": "your_schema",
}
```

---

### `ui.py` (UI Components)
All Streamlit UI components and rendering logic.

**Key functions:**
- `render_sidebar(ollama_url)` - Renders configuration sidebar with mode selection
- `process_document(uploaded, chunk_size, chunk_overlap, embed_model, ollama_url)` - Processes and indexes documents
- `process_snowflake_data(patient_id, search_term, embed_model, ollama_url)` - Queries Snowflake and prepares patient data
- `render_chat_history()` - Renders styled chat messages
- `render_header()` - Renders main page header

**Why separate?** Keeps UI logic organized and makes it easy to modify layouts or add new UI components.

---

## How to Use

### Running the app:
```bash
streamlit run App.py
```

### Mode Selection:
The sidebar provides two modes:
- **📄 Upload Document**: Upload a text, markdown, or PDF file for querying
- **❄️ Query Snowflake**: Query patient data from Snowflake by patient ID

### Upload Mode:
1. Select "📄 Upload Document" mode
2. Upload a file (TXT, MD, or PDF)
3. Adjust chunk size, overlap, and top-K settings
4. Ask questions about the document

### Snowflake Mode:
1. Update `SNOWFLAKE_CONFIG` in `constants.py` with your credentials
2. Select "❄️ Query Snowflake" mode
3. Either:
   - Enter a patient ID to fetch specific records
   - Search by patient name
4. Ask questions about the patient data

### Modifying sections:
- **Change styling?** → Edit `config.py`
- **Change constants?** → Edit `constants.py`
- **Add text processing?** → Add to `helpers.py`
- **Add Ollama features?** → Add to `ollama.py`
- **Adjust RAG algorithm?** → Modify `rag.py`
- **Modify Snowflake queries?** → Edit `snowflake.py`
- **Update UI/sidebar?** → Modify `ui.py`
- **Change main flow?** → Modify `App.py`

## Benefits

✅ **Easier Navigation** - Find code faster with clear module boundaries
✅ **Better Testing** - Test individual functions without Streamlit
✅ **Reusability** - Import functions from modules elsewhere
✅ **Maintainability** - Changes isolated to relevant modules
✅ **Scalability** - Easy to add new features or expand
✅ **Readability** - Smaller files are easier to understand
✅ **Flexibility** - Switch between multiple data sources (Files, Snowflake, etc.)

## Dependencies

Required packages:
- `streamlit` - Web framework
- `requests` - HTTP client for Ollama
- `snowflake-connector-python` - Snowflake database client (for Snowflake mode)

Optional packages:
- `pypdf` - PDF text extraction (for PDF support in upload mode)

Install dependencies:
```bash
pip install streamlit requests snowflake-connector-python pypdf
```

## Configuration

### Snowflake Setup:
Before using Snowflake mode, update your credentials in `constants.py`:

```python
SNOWFLAKE_CONFIG = {
    "account": "your_snowflake_account",
    "user": "your_username",
    "password": "your_password",
    "warehouse": "your_warehouse_name",
    "database": "your_database_name",
    "schema": "your_schema_name",
}
```

The default Snowflake query expects a `patients` table with at least these columns:
- `patient_id` (primary key)
- `patient_name`
- `date_of_birth`

Modify the queries in `snowflake.py` to match your actual schema.

## Future Improvements

Potential enhancements:
- Add more database sources (PostgreSQL, MySQL, etc.)
- Support for streaming responses from Ollama
- Conversation history persistence
- User authentication and multi-user support
- Caching for frequently asked questions
- More advanced RAG features (reranking, metadata filtering)
- Web UI for configuration instead of environment variables

