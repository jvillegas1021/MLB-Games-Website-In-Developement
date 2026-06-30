from fastapi import FastAPI
from mlb_api.api_endpoints.matchup_endpoints import router as matchups_router


api = FastAPI()

@api.get("/")
def get_matchups_today():
    return {"message": ""}


api.include_router(matchups_router)
