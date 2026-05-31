import express from 'express';
import cors from 'cors';
import 'dotenv/config';
import uploadRouter from './routes/upload.js';
import chatRouter from './routes/chat.js';
import { createServer } from 'http';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors()); // Enable CORS for cross-origin requests
app.use(express.json());
app.use(express.static('public')); // Serve static files from public directory

// Routes
app.use('/api', uploadRouter);
app.use('/api', chatRouter);

// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        services: {
            server: 'running',
            chromadb: 'checking...'
        }
    });
});

// Test ChromaDB connection
app.get('/api/test-chromadb', async (req, res) => {
    try {
        const chromaService = (await import('./services/chroma.js')).default;
        await chromaService.initializeCollection();
        const status = chromaService.getStatus();
        res.json({
            status: 'OK',
            message: 'ChromaDB connected successfully',
            connected: status.connected
        });
    } catch (error) {
        res.status(500).json({
            status: 'ERROR',
            message: 'ChromaDB connection failed',
            error: error.message,
            connected: false,
            solution: 'Start ChromaDB with: docker run -p 8000:8000 chromadb/chroma'
        });
    }
});

// Auto-detect available port and start server
function findAvailablePort(startPort) {
    return new Promise((resolve, reject) => {
        const testServer = createServer();
        testServer.listen(startPort, () => {
            testServer.close(() => resolve(startPort));
        });
        testServer.on('error', (err) => {
            if (err.code === 'EADDRINUSE') {
                console.log(`Port ${startPort} is busy, trying ${startPort + 1}...`);
                resolve(findAvailablePort(startPort + 1));
            } else {
                reject(err);
            }
        });
    });
}

async function startServer() {
    try {
        const PORT = await findAvailablePort(3000);

        // Add request logging middleware
        app.use((req, res, next) => {
            console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
            next();
        });

        app.listen(PORT, () => {
            console.log(`🚀 Server running on http://localhost:${PORT}`);
            console.log(`📁 Static files served from: ${process.cwd()}/public`);
            console.log(`🔗 Health check: http://localhost:${PORT}/health`);
            console.log(`💾 ChromaDB should be running on: http://localhost:8000`);
            console.log(`\n📋 To start ChromaDB, run:`);
            console.log(`   docker run -p 8000:8000 chromadb/chroma`);
        });

    } catch (error) {
        console.error('❌ Failed to start server:', error.message);
        console.log('\n🔧 Troubleshooting:');
        console.log('1. Make sure no other application is using ports 3000+');
        console.log('2. Run: npm install');
        console.log('3. Run: npm start');
        process.exit(1);
    }
}

startServer();