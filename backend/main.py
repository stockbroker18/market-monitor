"""
Market Monitor — FastAPI Backend
Connects to local Bloomberg Terminal via blpapi Desktop API.
"""

import os
import asyncio
import logging
from contextlib import asynccontextmanager
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import socketio

from bloomberg.session import BloombergSession
from bloomberg.requests import BloombergRequests
from bloomberg.subscriptions import SubscriptionManager
from api.market_data import router as market_data_router
from api.auth import router as auth_router

# ── Config ──────────────────────────────────────────────────────────────────
load_dotenv(dotenv_path="../config.env")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%H:%M:%S"
)
log = logging.getLogger("market_monitor")

ALLOWED_ORIGINS = [
    "https://your-app.vercel.app",
    "http://localhost:5173",
    "http://localhost:5174",
    "http://localhost:3000",
    "http://127.0.0.1:5173",
    "http://127.0.0.1:5174",
]

# ── Bloomberg session ────────────────────────────────────────────────────────
bloomberg_session = BloombergSession()
bloomberg_requests = BloombergRequests(bloomberg_session)
subscription_manager = SubscriptionManager(bloomberg_session)

# ── Socket.IO ────────────────────────────────────────────────────────────────
sio = socketio.AsyncServer(
    async_mode="asgi",
    cors_allowed_origins=ALLOWED_ORIGINS,
    logger=False,
    engineio_logger=False,
)

# ── App lifecycle ────────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    log.info("Starting Market Monitor backend...")
    try:
        bloomberg_session.start()
        log.info("Bloomberg Terminal connection established.")
    except Exception as e:
        log.error(f"Could not connect to Bloomberg Terminal: {e}")
        log.error("Ensure Bloomberg Terminal is open and logged in.")
    yield
    log.info("Shutting down...")
    bloomberg_session.stop()

# ── FastAPI app ──────────────────────────────────────────────────────────────
app = FastAPI(
    title="Market Monitor API",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/api/auth")
app.include_router(market_data_router, prefix="/api/data")

app.state.bloomberg_requests = bloomberg_requests
app.state.subscription_manager = subscription_manager


@app.get("/health")
async def health():
    """Health check — used by START.bat to confirm backend is ready."""
    connected = bloomberg_session.is_connected()
    return {
        "status": "ok",
        "bloomberg_connected": connected,
        "message": "Bloomberg Terminal connected." if connected
                   else "Bloomberg Terminal not connected. Open Terminal and restart.",
    }


# ── Socket.IO events ─────────────────────────────────────────────────────────
@sio.event
async def connect(sid, environ, auth):
    token = auth.get("token") if auth else None
    if not token:
        return False
    log.info(f"Client connected: {sid}")


@sio.event
async def disconnect(sid):
    log.info(f"Client disconnected: {sid}")
    await subscription_manager.remove_client(sid)


@sio.event
async def subscribe(sid, data):
    """
    Subscribe to real-time Bloomberg data.
    data = { "ticker": "GT10 Govt", "fields": ["YLD_YTM_MID"] }
    """
    ticker = data.get("ticker")
    fields = data.get("fields", ["PX_LAST"])
    if not ticker:
        return

    async def on_update(tick_data):
        await sio.emit("price_update", tick_data, to=sid)

    await subscription_manager.subscribe(sid, ticker, fields, on_update)
    log.info(f"Subscribed {sid} to {ticker} {fields}")


@sio.event
async def unsubscribe(sid, data):
    ticker = data.get("ticker")
    if ticker:
        await subscription_manager.unsubscribe(sid, ticker)


# ── Combined ASGI app ────────────────────────────────────────────────────────
combined_app = socketio.ASGIApp(sio, app)
