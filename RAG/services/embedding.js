import 'dotenv/config';

const USE_LOCAL = process.env.USE_LOCAL_EMBEDDINGS === 'true';
const LOCAL_EMBED_URL = process.env.LOCAL_EMBED_URL || 'http://127.0.0.1:8001/embed';

export async function getEmbedding(text) {
    if (USE_LOCAL) {
        const res = await fetch(LOCAL_EMBED_URL, {
            method: 'POST',
            headers: { 'content-type': 'application/json' },
            body: JSON.stringify({ texts: [text] })
        });

        if (!res.ok) {
            throw new Error(`Local embedding service error: ${res.status} ${res.statusText}`);
        }

        const data = await res.json();
        return data.embeddings[0];
    }

    const res = await fetch("https://api.openai.com/v1/embeddings", {
        method: "POST",
        headers: {
            "content-type": "application/json",
            "Authorization": `Bearer ${process.env.OPENAI_API_KEY}`
        },
        body: JSON.stringify({
            model: "text-embedding-3-small",
            input: text
        })
    });

    if (!res.ok) {
        throw new Error(`OpenAI API error: ${res.status} ${res.statusText}`);
    }

    const data = await res.json();
    return data.data[0].embedding;
}