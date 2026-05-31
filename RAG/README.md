# RAG Chatbot Web Application

A complete RAG (Retrieval-Augmented Generation) based chatbot web application built with Node.js, Express, and vanilla JavaScript.

## Features

- **File Upload**: Support for TXT, PDF, and DOCX files
- **Text Processing**: Automatic chunking and embedding generation
- **Vector Storage**: ChromaDB for efficient vector storage and retrieval
- **Chat Interface**: Real-time chat with context-aware responses
- **Modern UI**: Clean, responsive design with step-by-step process visualization

## Prerequisites

- Node.js (v16 or higher)
- Docker (for ChromaDB)
- OpenAI API key

## Quick Start

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Start ChromaDB:**
   ```bash
   # Option 1: Windows batch script (recommended)
   .\start-chromadb.bat

   # Option 2: PowerShell script
   .\start-chromadb.ps1

   # Option 3: Manual Docker command
   docker run -p 8000:8000 chromadb/chroma
   ```

3. **Start the server:**
   ```bash
   npm start
   ```

4. **Open your browser:**
   ```
   http://localhost:3000
   ```

## Alternative: Start Everything Automatically

```bash
npm run start:all
```

This will attempt to start ChromaDB and the server automatically.

## Manual Setup

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Set up environment variables:**
   - Copy `.env` file and add your OpenAI API key:
   ```
   OPENAI_API_KEY=your_actual_openai_api_key_here
   ```

4. **Test the setup:**
   ```bash
   npm run test
   ```

5. **Start ChromaDB:**
   ```bash
   docker run -p 8000:8000 chromadb/chroma
   ```

6. **Start the application:**
   ```bash
   npm start
   ```

6. **Open your browser and navigate to:**
   ```
   http://localhost:3000
   ```

## API Endpoints

- `POST /api/upload` - Upload and process a document
- `POST /api/chat` - Send a question and get an AI response
- `GET /health` - Health check endpoint

## Project Structure

```
├── server.js              # Main Express server
├── routes/
│   ├── upload.js         # File upload route
│   └── chat.js           # Chat route
├── services/
│   ├── embedding.js      # OpenAI embedding service
│   ├── chroma.js         # ChromaDB service
│   ├── chat.js           # OpenAI chat completion service
│   └── fileProcessor.js  # File reading utilities
├── public/
│   ├── index.html        # Main HTML page
│   ├── style.css         # CSS styles
│   └── script.js         # Frontend JavaScript
├── uploads/              # Temporary file storage
├── package.json          # Dependencies and scripts
└── .env                  # Environment variables
```

## Usage

1. **Upload a Document:**
   - Drag and drop or click to select a TXT, PDF, or DOCX file
   - Click "Upload File" to process the document
   - The system will chunk the text, generate embeddings, and store them in ChromaDB

2. **Chat with the Document:**
   - Once uploaded, type your questions in the chat input
   - The system will retrieve relevant context and generate answers using OpenAI

3. **Clear Chat:**
   - Use the "Clear Chat" button to reset the conversation

## Troubleshooting

### "Network error occurred" when uploading files

1. **Check if backend server is running:**
   ```bash
   curl http://localhost:3000/health
   ```
   Should return: `{"status":"OK","timestamp":"..."}`

2. **Check if ChromaDB is running:**
   ```bash
   curl http://localhost:8000/api/v1/heartbeat
   ```

3. **Check browser console for errors:**
   - Open Developer Tools (F12)
   - Look for CORS errors or network failures

4. **Verify OpenAI API key:**
   - Check `.env` file has valid `OPENAI_API_KEY`

5. **Check file upload:**
   - Files must be TXT, PDF, or DOCX
   - Maximum size: 10MB

### ChromaDB Connection Issues

**Error: "ChromaDB is not running"**

1. **Start Docker Desktop:**
   - Open Docker Desktop application
   - Wait for it to fully start (may take 1-2 minutes)

2. **Start ChromaDB:**
   ```bash
   # Use the provided script
   .\start-chromadb.bat

   # Or manually
   docker run -p 8000:8000 chromadb/chroma
   ```

3. **Verify ChromaDB is running:**
   ```bash
   curl http://localhost:8000/api/v1/heartbeat
   ```
   Should return: `{"status":"ok"}`

4. **Check application status:**
   - Refresh the browser page
   - The ChromaDB status should show "Connected"

### Docker Issues

- **"docker command not found":** Install Docker Desktop from https://www.docker.com/products/docker-desktop
- **"Cannot connect to Docker daemon":** Start Docker Desktop and wait for it to initialize
- **Permission denied:** Make sure Docker Desktop is running as administrator

### Alternative Solutions

If Docker is not available, you can:
1. Use a cloud-hosted ChromaDB instance
2. Modify the application to use a different vector database
3. Use in-memory storage for testing (limited functionality)

## Error Handling

The application includes comprehensive error handling for:
- Invalid file types
- Empty files
- API failures
- Network errors
- File processing errors

## Security Notes

- File uploads are limited to 10MB
- Only TXT, PDF, and DOCX files are accepted
- Uploaded files are processed and then deleted from the server
- CORS is enabled for cross-origin requests

## Development

For development with auto-restart:
```bash
npm run dev
```

This requires `nodemon` to be installed globally or as a dev dependency.