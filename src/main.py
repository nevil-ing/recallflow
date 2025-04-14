from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from typing import Dict
from src.auth import get_current_user

app = FastAPI(title="RecallFlow")

origins = [
    "http://localhost",         
    "http://localhost:3000",    
    "http://localhost:5173", 
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,       # List of origins allowed to make requests
    allow_credentials=True,    # Allow cookies/authorization headers
    allow_methods=["*"],       # Allow all HTTP methods (GET, POST, etc.)
    allow_headers=["*"],       # Allow all headers (including Authorization)
)

# --- Public Endpoint ---
@app.get("/")
async def root():
    """ Publicly accessible root endpoint. """
    return {"message": "Hello from FastAPI with Supabase Auth (Poetry & Docker!)"}

# --- Protected Endpoint ---
# Why Depends(get_current_user)? This injects the dependency. FastAPI runs
# get_current_user first. If it succeeds (token valid), it returns the payload,
# which FastAPI injects into the `user_payload` parameter. If it fails (token invalid),
# it raises an HTTPException, and FastAPI sends the error response immediately.
@app.get("/users/me", response_model=Dict) # Using Dict for simplicity, define Pydantic models for better validation
async def read_users_me(user_payload: dict = Depends(get_current_user)):
    """ Protected endpoint. Returns user info from the verified JWT payload. """
    user_id = user_payload.get("sub") # 'sub' claim is the standard User ID in JWT
    user_email = user_payload.get("email") # Email claim (if present)
    # You can access other claims as needed, e.g., user_payload.get('user_metadata')

    return {
        "message": "Access granted to protected endpoint!",
        "user_id": user_id,
        "email": user_email,
        "all_claims": user_payload # Return all claims for inspection/debugging
    }
