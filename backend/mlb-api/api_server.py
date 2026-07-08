from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from mlb_api.api_endpoints.matchup_endpoints import router as matchups_router

app = FastAPI()

# CORS so React / Shiny / Render can call your API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"status": "mlb_api running"}

# include your matchups endpoint
app.include_router(matchups_router)
