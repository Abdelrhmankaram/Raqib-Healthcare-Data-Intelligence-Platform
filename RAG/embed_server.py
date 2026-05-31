from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer

app = FastAPI()

class TextsPayload(BaseModel):
    texts: list[str]

model = None


def get_model():
    global model
    if model is None:
        model = SentenceTransformer("all-MiniLM-L6-v2")
    return model


@app.post("/embed")
async def embed(payload: TextsPayload):
    try:
        m = get_model()
        embs = m.encode(payload.texts)
        return {"embeddings": [e.tolist() for e in embs]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == '__main__':
    import uvicorn

    uvicorn.run(app, host='127.0.0.1', port=8001)
