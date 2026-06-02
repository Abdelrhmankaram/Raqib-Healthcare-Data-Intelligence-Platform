"""RAG (Retrieval-Augmented Generation) logic for document querying."""
from helpers import cosine_sim
from ollama import embed, chat


def retrieve(query_vec: list[float], store: list[dict], top_k: int = 4) -> list[dict]:
    """Retrieve top-k most similar chunks from vector store."""
    scored = sorted(store, key=lambda c: cosine_sim(query_vec, c["vec"]), reverse=True)
    return scored[:top_k]


def generate_answer(
    question: str,
    chunks: list[dict],
    chat_model: str,
    base_url: str,
) -> str:
    """Generate answer using retrieved chunks and LLM."""
    context = "\n\n---\n\n".join(c["text"] for c in chunks)
    
    system_prompt = (
        "You are a helpful assistant that answers questions strictly based on "
        "the provided document context. If the answer is not in the context, "
        "say so clearly. Be concise and precise.\n\n"
        f"DOCUMENT CONTEXT:\n{context}"
    )
    
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": question},
    ]
    
    return chat(messages, chat_model, base_url)
