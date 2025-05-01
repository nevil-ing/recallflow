from fastapi import FastAPI
from src.router import auth, ai_route
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="RecallFlow",
              description="API for the AI-Powered Active Recall / Feynman Technique Tool",
              version="0.1.0")

app.include_router(auth.router, prefix="api/auth")
app.include_router(ai_route.router, prefix="api/ai")


