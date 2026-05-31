const { OpenAIEmbeddings } = require('@langchain/openai');
const { ChatOpenAI } = require('@langchain/openai');

const embeddings = new OpenAIEmbeddings({
  openAIApiKey: process.env.OPENAI_API_KEY,
  modelName: 'text-embedding-3-small',
});

const llm = new ChatOpenAI({
  openAIApiKey: process.env.OPENAI_API_KEY,
  modelName: 'gpt-4o-mini',
});

async function generateEmbeddings(texts) {
  // Batch embeddings
  return await embeddings.embedDocuments(texts);
}

async function generateEmbedding(text) {
  return await embeddings.embedQuery(text);
}

async function generateAnswer(question, context) {
  const prompt = `Context: ${context}\n\nQuestion: ${question}\n\nAnswer:`;
  const response = await llm.invoke(prompt);
  return response.content;
}

module.exports = { generateEmbeddings, generateEmbedding, generateAnswer };