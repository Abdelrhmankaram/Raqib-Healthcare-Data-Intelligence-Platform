import  fs  from "fs/promises"
import {RecursiveCharacterTextSplitter} from '@langchain/textsplitters'
import 'dotenv/config'
import {ChromaClient} from 'chromadb'
// ===================== Step 1 : Read file content =======================

const filePath = './document.txt';
const text = await fs.readFile(filePath , "utf-8");


// =================== Step 2  : Split text into chunks ====================

const splitter = new RecursiveCharacterTextSplitter({
    chunkSize: 300,
    chunkOverlap: 50
})

const chunks =  await splitter.splitText(text);


// // ==================  Step 3 : Convert each chunk to embeddings ===============

async function getEmbedding(chunk){
   const res = await fetch("https://api.openai.com/v1/embeddings" , {
    method: "POST",
    headers: {
        "content-type" : "application/json",
        Authorization : `Bearer ${process.env.OPENAI_API_KEY}`
    },

    body: JSON.stringify({
        model: "text-embedding-3-small",
        input : chunk
    })
    })

    const data =  await res.json();
    
    // console.log(data.data[0].embedding);
    
    return data.data[0].embedding
    

}

// await getEmbedding(chunks[0])

// console.log(await getEmbedding(chunks[0]));

let vectors = [];

// // [{id: "chunk-0" , embedding:[16466,388559,...] , metadata:{text: js....} , {}, {}]
// // vectors.map(v => v.id) ==> ["chunk-0", ....]
for(let i=0 ; i < chunks.length ; i++){

   const vector =  await getEmbedding(chunks[i])
   vectors.push({
        id : `chunk-${i}`,
        embedding: vector,
        metadata : {text: chunks[i]}
   })
}




// // =================== Step 4 : Initalize chroma client and collection ===========


const client = new ChromaClient({
    host: "localhost",
    port : "8000",
    ssl: false
})
const collection = await  client.getOrCreateCollection({name: "dotNet_ragSystem", embeddingFunction: null});

collection.add({
   ids :  vectors.map(v => v.id),//["chunk-0", ..]
   embeddings : vectors.map(v => v.embedding),
   metadatas : vectors.map(v=> v.metadata)
})

// console.log("✅ Stored in chroma db");

// // docker run -p 8000:8000 chromadb/chroma

// // ================================ Step 5 : Querying ====================

// const query = "Who made this file?"
// const  queryEmbeddings = await  getEmbedding(query)

// console.log(queryEmbeddings);


// // ===================== Step 6 : Search chroma for similar chunks ========


async function searchReleventChunks(query , topK = 3  ){

    const  queryEmbeddings = await  getEmbedding(query)
    const results = await collection.query({
        queryEmbeddings : [queryEmbeddings],
        nResults: topK,
        include : ["metadatas", "distances"]
    })

    // console.log(results.metadatas[0].map(m => m.text));
    
    return results.metadatas[0].map(m => m.text); // [ ".." , "..." , "...."]
}

const query = "What is Machine learning?" 
 const relevantChunks = await searchReleventChunks(query);


// //  ===================== Step 7: Generate answer using openAi chat completion ========


async function getAnswerFromOpenAI(question , relevantChunks){

    const contextText =  relevantChunks.join("\n\n");

    // console.log(contextText);
    

    const prompt = `Use the following context to answer the question :${contextText}, Question: ${question}`;


    const res = await fetch("https://api.openai.com/v1/chat/completions" , {
    method: "POST",
    headers: {
        "content-type" : "application/json",
        Authorization : `Bearer ${process.env.OPENAI_API_KEY}`
    },

    body: JSON.stringify({
        model: "gpt-4o-mini",
        messages : [
            {role : "user", content : prompt},
            {role  : "developer" , content : "You are a helpful assistant that answers based only on provided context"}
        ]
    })
    })
    const data = await res.json();

    // console.log(data.choices[0].message.content);
    
    return data.choices[0].message.content
}
const answer = await getAnswerFromOpenAI(query , relevantChunks )
console.log(`✅ Answer: ${answer}`);
  
