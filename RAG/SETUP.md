# DocChat Setup Guide

## Installation

1. **Install dependencies:**
```bash
pip install -r requirements.txt
```

2. **Configure constants (optional but recommended for Snowflake mode):**
   Edit `constants.py` and update the settings:
   ```python
   # Ollama Configuration
   DEFAULT_CHAT_MODEL = "llama3"      # Change if using different model
   DEFAULT_EMBED_MODEL = "nomic-embed-text"
   DEFAULT_OLLAMA_URL = "http://localhost:11434"
   
   # Snowflake Configuration (only if using Snowflake mode)
   SNOWFLAKE_CONFIG = {
       "account": "your_account",
       "user": "your_user",
       "password": "your_password",
       "warehouse": "your_warehouse",
       "database": "your_database",
       "schema": "your_schema",
   }
   ```

3. **Run the app:**
```bash
streamlit run App.py
```

## Usage Modes

### Mode 1: Upload Document
Perfect for querying documents (TXT, MD, PDF)
- Upload a document from your computer
- Adjust text chunking parameters
- Ask questions about the content
- Chat history is maintained per document

### Mode 2: Query Snowflake  
Perfect for querying patient data from a database
- Enter patient ID or search by name
- Patient data is automatically formatted for Q&A
- Supports searching across multiple patient records
- Perfect for healthcare applications

## Features Included

✅ **Two Operating Modes**
- Document Upload & RAG
- Snowflake Patient Data Query

✅ **Model Configuration**
- All models verified in constants
- Easy to switch between LLMs
- Auto-detection of Ollama models

✅ **Text Processing**
- Automatic text chunking with configurable overlap
- PDF, Markdown, and TXT file support
- Cosine similarity-based retrieval

✅ **Styling**
- Custom dark theme for sidebar
- Chat bubble UI
- Status indicators and pills
- Responsive design

## Requirements

- **Ollama**: Local Ollama instance running (http://localhost:11434 by default)
- **Models**: 
  - Chat: `llama3` (or your preferred model)
  - Embedding: `nomic-embed-text` (or your preferred embedding model)
- **Snowflake** (for Snowflake mode): Active Snowflake account with credentials

## Troubleshooting

**Ollama Connection Error:**
- Check that Ollama is running
- Verify the base URL in the sidebar matches your Ollama instance
- Default: `http://localhost:11434`

**Snowflake Connection Error:**
- Verify credentials in `constants.py`
- Check network connectivity to Snowflake
- Ensure your user has permissions on the database/schema

**Model Not Found:**
- Pull the model with: `ollama pull llama3`
- Pull embedding model with: `ollama pull nomic-embed-text`

**PDF Extraction Issues:**
- Install pypdf: `pip install pypdf`
- PDFs with scanned images may not extract text properly

## File Organization

```
App.py              ← Main entry point
├── config.py       ← Styling and page config
├── constants.py    ← All configuration values
├── helpers.py      ← Text utilities
├── ollama.py       ← Ollama API
├── rag.py          ← RAG logic
├── snowflake.py    ← Snowflake integration
└── ui.py           ← UI components
```

## Next Steps

1. Start with **Upload Document** mode to test basic functionality
2. Configure Snowflake credentials for **Query Snowflake** mode
3. Customize the Snowflake queries in `snowflake.py` to match your schema
4. Modify CSS in `config.py` for custom branding

## Support

For issues or questions:
1. Check the README.md for detailed module documentation
2. Review `constants.py` for configuration options
3. Check error messages in the Streamlit UI for specific issues
