from fastapi import APIRouter, Header, HTTPException
import os
from database import get_connection

router = APIRouter()

from fastapi import APIRouter, Header, HTTPException, Query
from datetime import datetime, timezone
import os
from database import get_connection

router = APIRouter()

@router.get("/mlb_matchup_card")
def get_matchup_card(
    game_date: str = Query(None, description="Optional date filter: YYYY-MM-DD. Defaults to today."),
    x_api_key: str = Header(None)
):
    if x_api_key != os.getenv("API_KEY"):
        raise HTTPException(status_code=401, detail="Invalid API Key")

    # If no date parameter is supplied from React, default to today's date string
    if not game_date:
        # Generates a string like "2026-10-02" matching your database text format
        game_date = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    connection = get_connection()
    cursor = connection.cursor()

    # Updated to match your exact column name: Game_Date
    query = 'SELECT * FROM historical_matchup_df WHERE "Game_Date" = %s'
    
    # Note: If your database uses case-insensitive columns you can drop the double quotes,
    # but if it was created specifically as CamelCase, wrapping it in quotes ensures it connects.
    cursor.execute(query, (game_date,))
    
    rows = cursor.fetchall()
    colnames = [desc[0] for desc in cursor.description]

    cursor.close()
    connection.close()

    return {"date_requested": game_date, "matchups": [dict(zip(colnames, row)) for row in rows]}


@router.get("/pitcher_stats")
def get_pitcher_stats(x_api_key: str = Header(None)):
    if x_api_key != os.getenv("API_KEY"):
        raise HTTPException(status_code=401, detail="Invalid API Key")

    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute("SELECT * FROM matchup_starting_pitcher_stats")
    rows = cursor.fetchall()
    colnames = [desc[0] for desc in cursor.description]

    cursor.close()
    connection.close()

    return {"pitcher_stats": [dict(zip(colnames, row)) for row in rows]}


@router.get("/pitcher_stats_current_year")
def get_pitcher_stats_current_year(x_api_key: str = Header(None)):
    if x_api_key != os.getenv("API_KEY"):
        raise HTTPException(status_code=401, detail="Invalid API Key")

    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute("SELECT * FROM matchup_starting_pitcher_stats_current_year")
    rows = cursor.fetchall()
    colnames = [desc[0] for desc in cursor.description]

    cursor.close()
    connection.close()

    return {"pitcher_stats_current_year": [dict(zip(colnames, row)) for row in rows]}


@router.get("/team_batting_stats")
def get_team_batting_stats(x_api_key: str = Header(None)):
    if x_api_key != os.getenv("API_KEY"):
        raise HTTPException(status_code=401, detail="Invalid API Key")

    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute("SELECT * FROM matchup_team_batting_stats")
    rows = cursor.fetchall()
    colnames = [desc[0] for desc in cursor.description]

    cursor.close()
    connection.close()

    return {"team_battings_stats": [dict(zip(colnames, row)) for row in rows]}


@router.get("/team_pitching_stats")
def get_team_pitching_stats(x_api_key: str = Header(None)):
    if x_api_key != os.getenv("API_KEY"):
        raise HTTPException(status_code=401, detail="Invalid API Key")

    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute("SELECT * FROM matchup_team_pitching_stats")
    rows = cursor.fetchall()
    colnames = [desc[0] for desc in cursor.description]

    cursor.close()
    connection.close()

    return {"team_pitching_stats": [dict(zip(colnames, row)) for row in rows]}

@router.get("/pitcher_league_averages")
def get_team_pitching_stats(x_api_key: str = Header(None)):
    if x_api_key != os.getenv("API_KEY"):
        raise HTTPException(status_code=401, detail="Invalid API Key")

    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute("SELECT * FROM mlb_pitcher_league_averages")
    rows = cursor.fetchall()
    colnames = [desc[0] for desc in cursor.description]

    cursor.close()
    connection.close()

    return {"pitcher_league_averages": [dict(zip(colnames, row)) for row in rows]}

@router.get("/diamonds_edge_results")
def get_diamonds_edge_results(x_api_key: str = Header(None)):
    if x_api_key != os.getenv("API_KEY"):
        raise HTTPException(status_code=401, detail="Invalid API Key")

    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute("SELECT * FROM mlb_games_prediction_results")
    rows = cursor.fetchall()
    colnames = [desc[0] for desc in cursor.description]

    cursor.close()
    connection.close()

    return {"mlb_games_prediction_results": [dict(zip(colnames, row)) for row in rows]}
