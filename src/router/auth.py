from fastapi import  Depends, APIRouter
from fastapi.middleware.cors import CORSMiddleware
from typing import Dict
from src.router.auth import get_current_user

router = APIRouter()

@router.get("/users/me", response_model=Dict) # Using Dict for simplicity, define Pydantic models for better validation
async def read_users_me(user_payload: dict = Depends(get_current_user)):
    """ Protected endpoint. Returns user info from the verified JWT payload. """
    user_id = user_payload.get("sub") # 'sub' claim is the standard User ID in JWT
    user_email = user_payload.get("email") # Email claim (if present)
    

    return {
        "message": "Access granted to protected endpoint!",
        "user_id": user_id,
        "email": user_email,
        "all_claims": user_payload 
    }