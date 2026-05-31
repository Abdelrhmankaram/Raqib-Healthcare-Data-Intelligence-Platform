@echo off
echo Starting Docker Desktop...
start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"

echo Waiting for Docker to start (this may take a minute)...
timeout /t 30 /nobreak > nul

echo Checking Docker status...
docker ps >nul 2>&1
if %errorlevel% neq 0 (
    echo Docker is not ready yet. Please wait a moment and try again.
    echo You can also start Docker Desktop manually.
    pause
    exit /b 1
)

echo Docker is ready! Starting ChromaDB...
docker run -d -p 8000:8000 --name chromadb chromadb/chroma

echo ChromaDB started successfully!
echo You can now use the RAG chatbot application.
pause