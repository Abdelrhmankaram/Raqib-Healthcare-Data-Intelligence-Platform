"""Application constants and configuration values."""

# Ollama Models
DEFAULT_CHAT_MODEL = "llama3"
DEFAULT_EMBED_MODEL = "nomic-embed-text"
DEFAULT_OLLAMA_URL = "http://localhost:11434"

# Text Processing
DEFAULT_CHUNK_SIZE = 500
DEFAULT_CHUNK_OVERLAP = 80
DEFAULT_TOP_K = 4

# Timeouts (seconds)
EMBED_TIMEOUT = 60
CHAT_TIMEOUT = 120
API_TIMEOUT = 8

# Application Modes
MODE_UPLOAD = "📄 Upload Document"
MODE_SNOWFLAKE = "❄️ Query Snowflake"

# Snowflake Configuration (update with your credentials)
SNOWFLAKE_CONFIG = {
    "account": "your_account",      # e.g., "xy12345.us-east-1"
    "user": "your_user",
    "password": "your_password",
    "warehouse": "your_warehouse",
    "database": "your_database",
    "schema": "your_schema",
}
