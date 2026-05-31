const uploadBox = document.getElementById('uploadBox');
const uploadContent = document.getElementById('uploadContent');
const fileInput = document.getElementById('fileInput');
const uploadForm = document.getElementById('uploadForm');
const uploadBtn = document.getElementById('uploadBtn');
const resetFileBtn = document.getElementById('resetFileBtn');
const uploadStatus = document.getElementById('uploadStatus');
const uploadPill = document.getElementById('uploadPill');
const chatPill = document.getElementById('chatPill');
const messageInput = document.getElementById('messageInput');
const chatForm = document.getElementById('chatForm');
const sendBtn = document.getElementById('sendBtn');
const clearBtn = document.getElementById('clearBtn');
const chatMessages = document.getElementById('chatMessages');
const sidebarFileName = document.getElementById('sidebarFileName');
const sidebarFileHint = document.getElementById('sidebarFileHint');
const heroStatusLabel = document.getElementById('heroStatusLabel');
const heroStatusText = document.getElementById('heroStatusText');
const messageCount = document.getElementById('messageCount');
const systemMode = document.getElementById('systemMode');
const refreshStatusBtn = document.getElementById('refreshStatus');

const allowedMimeTypes = new Set([
    'text/plain',
    'application/pdf',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
]);
const allowedExtensions = new Set(['.txt', '.pdf', '.docx']);

let selectedFile = null;
let isUploaded = false;
let serverAvailable = false;
let chromadbAvailable = false;
let serverUrl = 'http://localhost:3000';

function fetchWithTimeout(url, options = {}, timeout = 2500) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);

    return fetch(url, { ...options, signal: controller.signal }).finally(() => clearTimeout(timeoutId));
}

function isAllowedFile(file) {
    const extension = file.name.slice(file.name.lastIndexOf('.')).toLowerCase();
    return allowedMimeTypes.has((file.type || '').toLowerCase()) || allowedExtensions.has(extension);
}

function formatFileSize(bytes) {
    return `${(bytes / 1024 / 1024).toFixed(2)} MB`;
}

function renderUploadPlaceholder() {
    uploadContent.innerHTML = `
        <div class="upload-badge">DOC</div>
        <p class="upload-title">Drag and drop a file here or browse your machine</p>
        <p class="upload-copy">Supported formats: TXT, PDF, DOCX</p>
    `;
}

function renderSelectedFile(file) {
    uploadContent.innerHTML = `
        <div class="upload-badge">OK</div>
        <p class="upload-title">${file.name}</p>
        <p class="upload-copy">${formatFileSize(file.size)} | ready for indexing</p>
    `;
}

function renderEmptyChat() {
    chatMessages.innerHTML = `
        <div class="empty-chat">
            <div>
                <strong>Upload a document to begin.</strong>
                <p>The chat will unlock once indexing finishes successfully.</p>
            </div>
        </div>
    `;
    updateMessageCount();
}

function updateMessageCount() {
    messageCount.textContent = String(chatMessages.querySelectorAll('.message').length);
}

function updateStatus(elementId, status, text) {
    const textElement = document.getElementById(`${elementId}Text`);
    const dotElement = document.getElementById(elementId.replace('Status', 'Dot'));

    if (textElement) {
        textElement.textContent = text;
    }

    if (dotElement) {
        dotElement.className = `status-dot ${status}`;
    }
}

function updateStep(stepId, state) {
    const step = document.getElementById(stepId);
    if (!step) {
        return;
    }

    step.classList.remove('active', 'completed');
    if (state) {
        step.classList.add(state);
    }
}

function resetSteps() {
    ['step-file', 'step-chunk', 'step-embed', 'step-context'].forEach((stepId) => updateStep(stepId, ''));
}

function updateDocumentUi() {
    if (!selectedFile) {
        sidebarFileName.textContent = 'No file selected yet';
        sidebarFileHint.textContent = 'Upload a file to unlock the chat panel.';
        heroStatusLabel.textContent = 'No document yet';
        heroStatusText.textContent = 'Choose a file to get started.';
        uploadPill.textContent = 'Waiting for file';
        chatPill.textContent = 'Upload required';
        systemMode.textContent = 'Standby';
        messageInput.placeholder = 'Upload a document to start chatting';
        resetFileBtn.disabled = true;
        return;
    }

    sidebarFileName.textContent = selectedFile.name;
    resetFileBtn.disabled = false;

    if (isUploaded) {
        sidebarFileHint.textContent = 'Indexed successfully and ready for questions.';
        heroStatusLabel.textContent = 'Ready to chat';
        heroStatusText.textContent = `${selectedFile.name} is indexed and available for retrieval.`;
        uploadPill.textContent = 'Indexed';
        chatPill.textContent = 'Context ready';
        systemMode.textContent = 'Live';
        messageInput.placeholder = 'Ask a question about the uploaded document';
        return;
    }

    sidebarFileHint.textContent = 'Selected and waiting for upload.';
    heroStatusLabel.textContent = 'Awaiting upload';
    heroStatusText.textContent = `${selectedFile.name} is ready to be indexed.`;
    uploadPill.textContent = 'Ready to upload';
    chatPill.textContent = 'Upload required';
    systemMode.textContent = 'Standby';
    messageInput.placeholder = 'Upload a document to start chatting';
}

function setChatAvailability(enabled) {
    messageInput.disabled = !enabled;
    sendBtn.disabled = !enabled;
    chatPill.textContent = enabled ? 'Context ready' : 'Upload required';
    systemMode.textContent = enabled ? 'Live' : 'Standby';
}

function showStatus(message, type) {
    uploadStatus.textContent = message;
    uploadStatus.className = `status-message ${type}`;
}

function addMessage(text, type, isLoading = false) {
    const emptyState = chatMessages.querySelector('.empty-chat');
    if (emptyState) {
        emptyState.remove();
    }

    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${type}${isLoading ? ' loading' : ''}`;
    messageDiv.textContent = text;
    chatMessages.appendChild(messageDiv);
    chatMessages.scrollTop = chatMessages.scrollHeight;
    updateMessageCount();
    return messageDiv;
}

function clearSelection() {
    selectedFile = null;
    isUploaded = false;
    uploadBtn.disabled = true;
    fileInput.value = '';
    setChatAvailability(false);
    resetSteps();
    renderUploadPlaceholder();
    renderEmptyChat();
    updateDocumentUi();
}

async function checkAvailability() {
    serverAvailable = false;
    chromadbAvailable = false;

    updateStatus('serverStatus', 'checking', 'Checking...');
    updateStatus('chromadbStatus', 'checking', 'Checking...');

    for (let port = 3000; port <= 3010; port += 1) {
        try {
            const response = await fetchWithTimeout(`http://localhost:${port}/health`);
            if (response.ok) {
                serverAvailable = true;
                serverUrl = `http://localhost:${port}`;
                updateStatus('serverStatus', 'connected', `Connected on port ${port}`);
                break;
            }
        } catch (error) {
            // Continue scanning ports.
        }
    }

    if (!serverAvailable) {
        updateStatus('serverStatus', 'disconnected', 'Not found');
        updateStatus('chromadbStatus', 'disconnected', 'Unavailable');
        showStatus('Backend server is not running. Start it with: npm start', 'error');
        return;
    }

    try {
        const response = await fetchWithTimeout(`${serverUrl}/api/test-chromadb`, {}, 4000);
        if (response.ok) {
            chromadbAvailable = true;
            updateStatus('chromadbStatus', 'connected', 'Connected');
        } else {
            updateStatus('chromadbStatus', 'disconnected', 'Not connected');
            showStatus('ChromaDB is not connected yet. Start it before uploading.', 'error');
        }
    } catch (error) {
        updateStatus('chromadbStatus', 'disconnected', 'Not connected');
        showStatus('ChromaDB check failed. Start it before uploading.', 'error');
    }
}

function handleFileSelect(file) {
    if (!isAllowedFile(file)) {
        clearSelection();
        showStatus('Invalid file type. Please select a TXT, PDF, or DOCX file.', 'error');
        return;
    }

    selectedFile = file;
    isUploaded = false;
    uploadBtn.disabled = false;
    setChatAvailability(false);
    resetSteps();
    renderEmptyChat();
    updateStep('step-file', 'active');
    renderSelectedFile(file);
    updateDocumentUi();
    showStatus(`${file.name} is selected. Upload it to build the retrieval index.`, 'info');
}

async function uploadSelectedFile() {
    if (!selectedFile) {
        showStatus('Choose a file first so the upload can start.', 'error');
        return;
    }

    if (!serverAvailable) {
        showStatus('Backend server is not running. Start it with: npm start', 'error');
        return;
    }

    if (!chromadbAvailable) {
        showStatus('ChromaDB is not running. Start it before uploading the file.', 'error');
        return;
    }

    const formData = new FormData();
    formData.append('file', selectedFile);

    uploadBtn.disabled = true;
    resetFileBtn.disabled = true;
    uploadBtn.textContent = 'Uploading...';
    showStatus(`Uploading ${selectedFile.name} and preparing embeddings...`, 'info');
    updateStep('step-file', 'active');

    try {
        const response = await fetch(`${serverUrl}/api/upload`, {
            method: 'POST',
            body: formData
        });
        const result = await response.json();

        if (!response.ok) {
            throw new Error(result.error || 'Upload failed');
        }

        isUploaded = true;
        setChatAvailability(true);
        updateStep('step-file', 'completed');
        updateStep('step-chunk', 'completed');
        updateStep('step-embed', 'completed');
        showStatus(`${selectedFile.name} was processed successfully and is ready for chat.`, 'success');
        updateDocumentUi();
    } catch (error) {
        isUploaded = false;
        setChatAvailability(false);
        updateStep('step-file', 'active');
        showStatus(error.message || 'Upload failed', 'error');
        updateDocumentUi();
    } finally {
        uploadBtn.disabled = !selectedFile;
        resetFileBtn.disabled = !selectedFile;
        uploadBtn.textContent = 'Upload and index';
    }
}

async function sendMessage() {
    const question = messageInput.value.trim();
    if (!question || !isUploaded) {
        return;
    }

    if (!serverAvailable) {
        addMessage('Backend server is not running. Start it with: npm start', 'bot');
        return;
    }

    if (!chromadbAvailable) {
        addMessage('ChromaDB is not running. Start it before asking questions.', 'bot');
        return;
    }

    addMessage(question, 'user');
    messageInput.value = '';
    sendBtn.disabled = true;
    messageInput.disabled = true;
    updateStep('step-context', 'active');

    const loadingMessage = addMessage('Thinking through the retrieved context...', 'bot', true);

    try {
        const response = await fetch(`${serverUrl}/api/chat`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ question })
        });
        const result = await response.json();
        loadingMessage.remove();

        if (!response.ok) {
            throw new Error(result.error || 'Failed to get answer');
        }

        updateStep('step-context', 'completed');
        addMessage(result.answer, 'bot');
    } catch (error) {
        loadingMessage.remove();
        addMessage(error.message || 'Failed to get answer', 'bot');
    } finally {
        sendBtn.disabled = false;
        messageInput.disabled = false;
        messageInput.focus();
        updateMessageCount();
    }
}

document.addEventListener('dragover', (event) => {
    event.preventDefault();
});

document.addEventListener('drop', (event) => {
    event.preventDefault();
});

document.addEventListener('DOMContentLoaded', () => {
    renderUploadPlaceholder();
    renderEmptyChat();
    updateDocumentUi();
    setChatAvailability(false);
    checkAvailability();
});

refreshStatusBtn.addEventListener('click', () => {
    checkAvailability();
});

uploadBox.addEventListener('click', () => fileInput.click());

uploadBox.addEventListener('keydown', (event) => {
    if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        fileInput.click();
    }
});

uploadBox.addEventListener('dragover', (event) => {
    event.preventDefault();
    uploadBox.classList.add('dragover');
});

uploadBox.addEventListener('dragleave', () => {
    uploadBox.classList.remove('dragover');
});

uploadBox.addEventListener('drop', (event) => {
    event.preventDefault();
    uploadBox.classList.remove('dragover');
    const file = event.dataTransfer.files?.[0];
    if (file) {
        handleFileSelect(file);
    }
});

fileInput.addEventListener('change', (event) => {
    const file = event.target.files?.[0];
    if (file) {
        handleFileSelect(file);
    }
});

uploadForm.addEventListener('submit', (event) => {
    event.preventDefault();
    uploadSelectedFile();
});

resetFileBtn.addEventListener('click', () => {
    clearSelection();
    showStatus('Pick another file whenever you are ready.', 'info');
});

chatForm.addEventListener('submit', (event) => {
    event.preventDefault();
    sendMessage();
});

clearBtn.addEventListener('click', () => {
    renderEmptyChat();
});
