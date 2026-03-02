"""
bloomberg/requests.py
Clean async wrappers around Bloomberg BDP, BDH, and BDS requests.
"""

import asyncio
import logging
from datetime import date
from typing import Any
import blpapi
from .session import BloombergSession

log = logging.getLogger("market_monitor.bloomberg")


class BloombergRequests:

    def __init__(self, session: BloombergSession):
        self._session = session

    # ── BDP — single field value(s) ─────────────────────────────────────────
    async def bdp(
        self,
        tickers: list,
        fields: list,
        overrides: dict = None,
    ) -> dict:
        """
        Fetch one or more fields for one or more tickers.
        Returns: { ticker: { field: value } }

        Example:
            await bdp(["GT10 Govt", "GT2 Govt"], ["YLD_YTM_MID", "PX_LAST"])
        """
        return await asyncio.get_event_loop().run_in_executor(
            None, self._bdp_sync, tickers, fields, overrides
        )

    def _bdp_sync(self, tickers, fields, overrides):
        svc = self._session.refdata_service
        req = svc.createRequest("ReferenceDataRequest")

        for t in tickers:
            req.getElement("securities").appendValue(t)
        for f in fields:
            req.getElement("fields").appendValue(f)

        if overrides:
            ovr_elem = req.getElement("overrides")
            for k, v in overrides.items():
                o = ovr_elem.appendElement()
                o.setElement("fieldId", k)
                o.setElement("value", str(v))

        self._session.session.sendRequest(req)

        result = {}
        while True:
            event = self._session.session.nextEvent(500)
            for msg in event:
                if msg.messageType() == blpapi.Name("ReferenceDataResponse"):
                    security_data = msg.getElement("securityData")
                    for i in range(security_data.numValues()):
                        sd = security_data.getValue(i)
                        ticker = sd.getElementAsString("security")
                        field_data = sd.getElement("fieldData")
                        result[ticker] = {}
                        for field in fields:
                            try:
                                result[ticker][field] = field_data.getElementValue(field)
                            except Exception:
                                result[ticker][field] = None
            if event.eventType() == blpapi.Event.RESPONSE:
                break
        return result

    # ── BDH — historical time series ────────────────────────────────────────
    async def bdh(
        self,
        ticker: str,
        fields: list,
        start_date: date,
        end_date: date = None,
        periodicity: str = "DAILY",
    ) -> list:
        """
        Fetch historical time series data.
        Returns: [{ "date": "2024-01-15", "PX_LAST": 4.312 }, ...]

        Example:
            await bdh("GT10 Govt", ["YLD_YTM_MID"], date(2024, 1, 1))
        """
        return await asyncio.get_event_loop().run_in_executor(
            None, self._bdh_sync, ticker, fields, start_date, end_date, periodicity
        )

    def _bdh_sync(self, ticker, fields, start_date, end_date, periodicity):
        if end_date is None:
            end_date = date.today()

        svc = self._session.refdata_service
        req = svc.createRequest("HistoricalDataRequest")
        req.getElement("securities").appendValue(ticker)
        for f in fields:
            req.getElement("fields").appendValue(f)
        req.set("startDate", start_date.strftime("%Y%m%d"))
        req.set("endDate", end_date.strftime("%Y%m%d"))
        req.set("periodicitySelection", periodicity)

        self._session.session.sendRequest(req)

        rows = []
        while True:
            event = self._session.session.nextEvent(500)
            for msg in event:
                if msg.messageType() == blpapi.Name("HistoricalDataResponse"):
                    security_data = msg.getElement("securityData")
                    field_data = security_data.getElement("fieldData")
                    for i in range(field_data.numValues()):
                        point = field_data.getValue(i)
                        row = {"date": str(point.getElementAsDatetime("date").date())}
                        for f in fields:
                            try:
                                row[f] = point.getElementValue(f)
                            except Exception:
                                row[f] = None
                        rows.append(row)
            if event.eventType() == blpapi.Event.RESPONSE:
                break
        return rows

    # ── BDS — structured dataset ─────────────────────────────────────────────
    async def bds(
        self,
        ticker: str,
        field: str,
        overrides: dict = None,
    ) -> list:
        """
        Fetch a structured dataset (e.g. curve constituents, index members).
        Returns: list of dicts representing the dataset rows.

        Example:
            await bds("YCSW0023 Index", "CURVE_TENOR_RATES")
        """
        return await asyncio.get_event_loop().run_in_executor(
            None, self._bds_sync, ticker, field, overrides
        )

    def _bds_sync(self, ticker, field, overrides):
        svc = self._session.refdata_service
        req = svc.createRequest("ReferenceDataRequest")
        req.getElement("securities").appendValue(ticker)
        req.getElement("fields").appendValue(field)

        if overrides:
            ovr_elem = req.getElement("overrides")
            for k, v in overrides.items():
                o = ovr_elem.appendElement()
                o.setElement("fieldId", k)
                o.setElement("value", str(v))

        self._session.session.sendRequest(req)

        rows = []
        while True:
            event = self._session.session.nextEvent(500)
            for msg in event:
                if msg.messageType() == blpapi.Name("ReferenceDataResponse"):
                    sec_data = msg.getElement("securityData").getValue(0)
                    field_data = sec_data.getElement("fieldData")
                    bulk = field_data.getElement(field)
                    for i in range(bulk.numValues()):
                        item = bulk.getValue(i)
                        row = {}
                        for j in range(item.numElements()):
                            el = item.getElement(j)
                            row[str(el.name())] = el.getValue()
                        rows.append(row)
            if event.eventType() == blpapi.Event.RESPONSE:
                break
        return rows
