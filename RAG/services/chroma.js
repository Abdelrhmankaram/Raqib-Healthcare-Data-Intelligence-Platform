import { ChromaClient } from 'chromadb';

class ChromaService {
    constructor() {
        this.client = null;
        this.collection = null;
        this.isConnected = false;
    }

    async initializeCollection() {
        if (!this.collection) {
            try {
                this.client = new ChromaClient({
                    host: "localhost",
                    port: "8000",
                    ssl: false
                });

                this.collection = await this.client.getOrCreateCollection({
                    name: "rag_chatbot_collection",
                    embeddingFunction: null
                });

                this.isConnected = true;
                console.log('✅ ChromaDB collection initialized successfully');
            } catch (error) {
                console.error('❌ ChromaDB connection error:', error.message);
                this.isConnected = false;
                throw new Error('Failed to connect to ChromaDB. Please start ChromaDB with: docker run -p 8000:8000 chromadb/chroma');
            }
        }
        return this.collection;
    }

    async addVectors(vectors) {
        if (!this.isConnected) {
            throw new Error('ChromaDB not connected. Please start ChromaDB first.');
        }
        const collection = await this.initializeCollection();
        await collection.add({
            ids: vectors.map(v => v.id),
            embeddings: vectors.map(v => v.embedding),
            metadatas: vectors.map(v => v.metadata)
        });
    }

    async searchRelevantChunks(queryEmbedding, topK = 3) {
        if (!this.isConnected) {
            throw new Error('ChromaDB not connected. Please start ChromaDB first.');
        }
        const collection = await this.initializeCollection();
        const results = await collection.query({
            queryEmbeddings: [queryEmbedding],
            nResults: topK,
            include: ["metadatas", "distances"]
        });
        return results.metadatas[0].map(m => m.text);
    }

    async clearCollection() {
        if (!this.isConnected) {
            console.log('ChromaDB not connected, skipping clear');
            return;
        }
        try {
            await this.client.deleteCollection({ name: "rag_chatbot_collection" });
            this.collection = null;
        } catch (error) {
            console.log("Collection might not exist:", error.message);
        }
    }

    getStatus() {
        return {
            connected: this.isConnected,
            message: this.isConnected ? 'Connected' : 'Not Connected'
        };
    }
}

export default new ChromaService();