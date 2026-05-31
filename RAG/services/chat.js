import 'dotenv/config';

const USE_LOCAL_CHAT = process.env.USE_LOCAL_CHAT === 'true';

export async function getAnswerFromOpenAI(question, relevantChunks) {
    if (USE_LOCAL_CHAT) {
        return generateLocalAnswer(question, relevantChunks);
    }

    const contextText = relevantChunks.join("\n\n");
    const prompt = `Use the following context to answer the question: ${contextText}\n\nQuestion: ${question}`;

    const res = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
            "content-type": "application/json",
            "Authorization": `Bearer ${process.env.OPENAI_API_KEY}`
        },
        body: JSON.stringify({
            model: "gpt-4o-mini",
            messages: [
                { role: "user", content: prompt },
                { role: "developer", content: "You are a helpful assistant that answers based only on the provided context." }
            ]
        })
    });

    if (!res.ok) {
        throw new Error(`OpenAI API error: ${res.status} ${res.statusText}`);
    }

    const data = await res.json();
    return data.choices[0].message.content;
}

function generateLocalAnswer(question, relevantChunks) {
    if (!relevantChunks || relevantChunks.length === 0) {
        return 'No relevant information found in the uploaded document.';
    }

    const joinedText = relevantChunks.slice(0, 3).join(' ');
    const summary = summarizeText(joinedText);
    const topics = extractTopics(joinedText, 5);

    if (/what is this document about|what is this about|summary|describe this document/i.test(question)) {
        return `This document is about ${topics.join(', ')}. ${summary}`;
    }

    return `Based on the retrieved context, the document is about ${topics.join(', ')}. ${summary}`;
}

function summarizeText(text) {
    const sentences = text.match(/[^.!?]+[.!?]+/g) || [text];
    const trimmed = sentences.map((sentence) => sentence.trim()).filter(Boolean);
    const firstThree = trimmed.slice(0, 3).join(' ');

    return firstThree || 'The document discusses the retrieved topics.';
}

function extractTopics(text, count = 5) {
    const stopWords = new Set([
        'the','and','for','with','that','this','from','are','was','were','has','have','also','can','using','about','into','use','used','will','its','not','but','all','your','you','they','their','them','such','these','those','any','some','more','most','many','than','other','where','what','when','which','who','how','why','each','may'
    ]);

    const words = (text || '')
        .toLowerCase()
        .match(/\b[a-z]{3,}\b/g) || [];

    const counts = words.reduce((acc, word) => {
        if (stopWords.has(word)) return acc;
        acc[word] = (acc[word] || 0) + 1;
        return acc;
    }, {});

    return Object.entries(counts)
        .sort((a, b) => b[1] - a[1])
        .slice(0, count)
        .map(([word]) => word);
}
