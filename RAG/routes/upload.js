import express from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs/promises';
import { RecursiveCharacterTextSplitter } from '@langchain/textsplitters';
import { getEmbedding } from '../services/embedding.js';
import chromaService from '../services/chroma.js';
import { readFileContent } from '../services/fileProcessor.js';

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/');
    },
    filename: (req, file, cb) => {
        cb(null, Date.now() + path.extname(file.originalname));
    }
});

const upload = multer({
    storage: storage,
    fileFilter: (req, file, cb) => {
        const allowedTypes = new Set([
            'text/plain',
            'application/pdf',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        ]);
        const allowedExtensions = new Set(['.txt', '.pdf', '.docx']);
        const fileExtension = path.extname(file.originalname || '').toLowerCase();
        const mimeType = (file.mimetype || '').toLowerCase();

        if (allowedTypes.has(mimeType) || allowedExtensions.has(fileExtension)) {
            cb(null, true);
        } else {
            cb(new Error('Invalid file type. Only txt, pdf, and docx are allowed.'));
        }
    },
    limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
});

// Ensure uploads directory exists
try {
    await fs.mkdir('uploads', { recursive: true });
} catch (error) {
    // Directory might already exist
}

router.post('/upload', upload.single('file'), async (req, res) => {
    console.log('Upload request received');
    console.log('File:', req.file);

    try {
        if (!req.file) {
            console.log('No file uploaded');
            return res.status(400).json({ error: 'No file uploaded' });
        }

        // Clear previous collection
        await chromaService.clearCollection();

        // Read file content
        const text = await readFileContent(req.file.path, req.file.mimetype);

        if (!text.trim()) {
            return res.status(400).json({ error: 'File is empty or could not be read' });
        }

        // Split text into chunks
        const splitter = new RecursiveCharacterTextSplitter({
            chunkSize: 300,
            chunkOverlap: 50
        });
        const chunks = await splitter.splitText(text);

        // Generate embeddings
        const vectors = [];
        for (let i = 0; i < chunks.length; i++) {
            const embedding = await getEmbedding(chunks[i]);
            vectors.push({
                id: `chunk-${i}`,
                embedding: embedding,
                metadata: { text: chunks[i] }
            });
        }

        // Store in ChromaDB
        await chromaService.addVectors(vectors);

        // Clean up uploaded file
        await fs.unlink(req.file.path);

        res.json({ message: 'File processed and stored successfully' });
    } catch (error) {
        console.error('Upload error:', error);
        res.status(500).json({ error: error.message });
    }
});

export default router;
