// Test script to verify the setup
import 'dotenv/config';

console.log('Testing RAG Chatbot Setup...\n');

// Test 1: Check environment variables
console.log('1. Checking environment variables...');
if (process.env.OPENAI_API_KEY) {
    console.log('✅ OPENAI_API_KEY is set');
} else {
    console.log('❌ OPENAI_API_KEY is not set');
}

// Test 2: Check if we can import modules
console.log('\n2. Checking module imports...');
try {
    const express = await import('express');
    console.log('✅ Express imported successfully');
} catch (error) {
    console.log('❌ Express import failed:', error.message);
}

try {
    const { ChromaClient } = await import('chromadb');
    console.log('✅ ChromaDB imported successfully');
} catch (error) {
    console.log('❌ ChromaDB import failed:', error.message);
}

try {
    const { RecursiveCharacterTextSplitter } = await import('@langchain/textsplitters');
    console.log('✅ LangChain imported successfully');
} catch (error) {
    console.log('❌ LangChain import failed:', error.message);
}

console.log('\n3. Next steps:');
console.log('- Start ChromaDB: docker run -p 8000:8000 chromadb/chroma');
console.log('- Start server: npm start');
console.log('- Open browser: http://localhost:3000');