from fastapi import FastAPI
from src.router import auth, ai_route
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="RecallFlow")

app.include_router(auth.router, prefix="api/auth")
app.include_router(ai_route.router, prefix="api/ai")


