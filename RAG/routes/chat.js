import express from 'express';
import { getEmbedding } from '../services/embedding.js';
import chromaService from '../services/chroma.js';
import { getAnswerFromOpenAI } from '../services/chat.js';

const router = express.Router();

router.post('/chat', async (req, res) => {
    console.log('Chat request received:', req.body);

    try {
        const { question } = req.body;

        if (!question || typeof question !== 'string' || !question.trim()) {
            console.log('Invalid question:', question);
            return res.status(400).json({ error: 'Question is required' });
        }

        // Generate embedding for question
        const queryEmbedding = await getEmbedding(question);

        // Search for relevant chunks
        const relevantChunks = await chromaService.searchRelevantChunks(queryEmbedding);

        if (relevantChunks.length === 0) {
            return res.json({ answer: 'No relevant information found in the uploaded document.' });
        }

        // Generate answer
        const answer = await getAnswerFromOpenAI(question, relevantChunks);

        res.json({ answer });
    } catch (error) {
        console.error('Chat error:', error);
        res.status(500).json({ error: error.message });
    }
});

export default router;