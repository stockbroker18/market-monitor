"""
bloomberg/subscriptions.py
Manages real-time Bloomberg subscriptions per connected client.
"""

import asyncio
import logging
import threading
from collections import defaultdict
from typing import Callable, Awaitable
import blpapi
from .session import BloombergSession

log = logging.getLogger("market_monitor.bloomberg")


class SubscriptionManager:
    """
    Manages Bloomberg real-time subscriptions for all connected WebSocket clients.
    When Bloomberg pushes an update, relevant clients receive it via their callback.
    """

    def __init__(self, session: BloombergSession):
        self._session = session
        # { ticker: { sid: callback } }
        self._subscribers = defaultdict(dict)
        # { ticker: blpapi.Subscription }
        self._active_subs = {}
        self._lock = threading.Lock()
        self._loop = None
        self._listener_thread = None
        self._running = False

    def start_listener(self):
        """Start background thread listening for Bloomberg subscription events."""
        self._loop = asyncio.get_event_loop()
        self._running = True
        self._listener_thread = threading.Thread(
            target=self._listen_loop, daemon=True, name="bbg-sub-listener"
        )
        self._listener_thread.start()
        log.info("Bloomberg subscription listener started.")

    def _listen_loop(self):
        while self._running:
            try:
                event = self._session.session.nextEvent(200)
                if event.eventType() == blpapi.Event.SUBSCRIPTION_DATA:
                    for msg in event:
                        self._handle_subscription_data(msg)
            except Exception as e:
                log.error(f"Subscription listener error: {e}")

    def _handle_subscription_data(self, msg):
        """Process incoming real-time data and dispatch to subscribed clients."""
        ticker = str(msg.correlationId().value())
        update = {"ticker": ticker}

        for i in range(msg.numElements()):
            el = msg.getElement(i)
            try:
                update[str(el.name())] = el.getValue()
            except Exception:
                update[str(el.name())] = None

        if ticker not in self._subscribers:
            return

        for sid, callback in list(self._subscribers[ticker].items()):
            if self._loop:
                asyncio.run_coroutine_threadsafe(callback(update), self._loop)

    async def subscribe(
        self,
        sid: str,
        ticker: str,
        fields: list,
        callback: Callable,
    ):
        with self._lock:
            self._subscribers[ticker][sid] = callback

            if ticker not in self._active_subs:
                sub_list = blpapi.SubscriptionList()
                corr_id = blpapi.CorrelationId(ticker)
                sub_list.add(ticker, fields, [], corr_id)
                self._session.session.subscribe(sub_list)
                self._active_subs[ticker] = sub_list
                log.info(f"New Bloomberg subscription: {ticker} {fields}")

    async def unsubscribe(self, sid: str, ticker: str):
        with self._lock:
            if ticker in self._subscribers:
                self._subscribers[ticker].pop(sid, None)

                if not self._subscribers[ticker]:
                    if ticker in self._active_subs:
                        self._session.session.unsubscribe(
                            self._active_subs.pop(ticker)
                        )
                    del self._subscribers[ticker]
                    log.info(f"Cancelled Bloomberg subscription: {ticker}")

    async def remove_client(self, sid: str):
        """Remove all subscriptions for a disconnected client."""
        with self._lock:
            tickers_to_clean = [
                t for t, subs in self._subscribers.items() if sid in subs
            ]
        for ticker in tickers_to_clean:
            await self.unsubscribe(sid, ticker)

    def stop(self):
        self._running = False
