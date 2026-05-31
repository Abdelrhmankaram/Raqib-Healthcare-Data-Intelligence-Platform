const fs = require('fs');
const { RecursiveCharacterTextSplitter } = require('langchain/text_splitters');
const embeddingService = require('./embeddingService');
const chromaService = require('./chromaService');

async function indexDocument(filePath) {
  // Step 1: read file
  const text = fs.readFileSync(filePath, 'utf-8');
  // Step 2: chunk text
  const splitter = new RecursiveCharacterTextSplitter({
    chunkSize: 300,
    chunkOverlap: 50,
  });
  const chunks = await splitter.splitText(text);
  // Step 3: embed chunks
  const embeddings = await embeddingService.generateEmbeddings(chunks);
  // Step 4: store in ChromaDB
  await chromaService.storeChunks(chunks, embeddings);
}

async function answerQuestion(question) {
  // Step 1: embed query
  const queryEmbedding = await embeddingService.generateEmbedding(question);
  // Step 2: search topK
  const relevantChunks = await chromaService.queryChunks(queryEmbedding, 3);
  // Step 3: send to GPT
  const context = relevantChunks.join('\n');
  const answer = await embeddingService.generateAnswer(question, context);
  // Step 4: return answer
  return { answer, chunks: relevantChunks };
}

module.exports = { indexDocument, answerQuestion };