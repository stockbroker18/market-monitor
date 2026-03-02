from fastapi import APIRouter

router = APIRouter()

@router.post("/register-tunnel")
async def register_tunnel():
    return {"status": "ok"}
