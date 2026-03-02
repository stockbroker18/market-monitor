from fastapi import APIRouter, Request

router = APIRouter()

@router.get("/reference")
async def get_reference(request: Request, ticker: str, field: str):
    try:
        bbg = request.app.state.bloomberg_requests
        result = await bbg.bdp([ticker], [field])
        return {"ticker": ticker, "field": field, "value": result.get(ticker, {}).get(field)}
    except Exception as e:
        return {"error": str(e)}

@router.get("/history")
async def get_history(request: Request, ticker: str, field: str, start: str):
    try:
        from datetime import date
        bbg = request.app.state.bloomberg_requests
        start_date = date.fromisoformat(start)
        result = await bbg.bdh(ticker, [field], start_date)
        return {"ticker": ticker, "field": field, "data": result}
    except Exception as e:
        return {"error": str(e)}
