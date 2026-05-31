const { ChromaClient } = require('chromadb');

const client = new ChromaClient({ path: 'http://localhost:8000' });

let collection;

async function initCollection() {
  if (!collection) {
    collection = await client.getOrCreateCollection({ name: 'rag_docs' });
  }
}

async function storeChunks(chunks, embeddings) {
  await initCollection();
  const ids = chunks.map((_, i) => `chunk_${i}`);
  await collection.add({
    ids,
    embeddings,
    documents: chunks,
  });
}

async function queryChunks(queryEmbedding, topK) {
  await initCollection();
  const results = await collection.query({
    queryEmbeddings: [queryEmbedding],
    nResults: topK,
  });
  return results.documents[0]; // array of chunks
}

module.exports = { storeChunks, queryChunks };