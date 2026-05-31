# Start ChromaDB with Docker
Write-Host "Starting Docker Desktop..." -ForegroundColor Green
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

Write-Host "Waiting for Docker to start (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host "Checking Docker status..." -ForegroundColor Cyan
try {
    $dockerCheck = docker ps 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Docker is ready! Starting ChromaDB..." -ForegroundColor Green
        docker run -d -p 8000:8000 --name chromadb chromadb/chroma
        Write-Host "ChromaDB started successfully!" -ForegroundColor Green
        Write-Host "You can now use the RAG chatbot application." -ForegroundColor Green
    } else {
        Write-Host "Docker is not ready yet. Please wait a moment and try again." -ForegroundColor Red
        Write-Host "You can also start Docker Desktop manually." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error checking Docker status: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please ensure Docker Desktop is installed and running." -ForegroundColor Yellow
}

Read-Host "Press Enter to exit"