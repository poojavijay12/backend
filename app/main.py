from fastapi import FastAPI

app = FastAPI()

@app.get("/health")
def health():
    return {"status": "UP"}

@app.get("/hello")
def hello():
    return {"message": "Hello from GKE 🚀"}
