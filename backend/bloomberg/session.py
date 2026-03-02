"""
bloomberg/session.py
Manages the blpapi session lifecycle, connecting to the
local Bloomberg Terminal via the Desktop API.
"""

import logging
import blpapi

log = logging.getLogger("market_monitor.bloomberg")

SESSION_HOST = "localhost"
SESSION_PORT = 8194  # Bloomberg Desktop API default port


class BloombergSession:
    """
    Wraps a blpapi.Session connected to the local Bloomberg Terminal.
    No additional licence or API key needed beyond the Terminal itself.
    """

    def __init__(self):
        self._session = None
        self._refdata_service = None

    def start(self):
        """Open a session with the local Bloomberg Terminal."""
        options = blpapi.SessionOptions()
        options.setServerHost(SESSION_HOST)
        options.setServerPort(SESSION_PORT)

        self._session = blpapi.Session(options)

        if not self._session.start():
            raise ConnectionError(
                "Could not connect to Bloomberg Terminal. "
                "Ensure Terminal is open and you are logged in."
            )

        if not self._session.openService("//blp/refdata"):
            raise ConnectionError(
                "Failed to open Bloomberg reference data service."
            )

        self._refdata_service = self._session.getService("//blp/refdata")
        log.info("Bloomberg Desktop API session started successfully.")

    def stop(self):
        if self._session:
            self._session.stop()
            self._session = None
        log.info("Bloomberg session stopped.")

    def is_connected(self):
        return self._session is not None

    @property
    def session(self):
        if not self._session:
            raise RuntimeError("Bloomberg session not started.")
        return self._session

    @property
    def refdata_service(self):
        if not self._refdata_service:
            raise RuntimeError("Bloomberg reference data service not open.")
        return self._refdata_service
