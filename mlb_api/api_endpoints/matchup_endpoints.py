from fastapi import APIRouter
from mlb_api.database import get_connection

router = APIRouter()

@router.get("/matchups")
def get_matchups_today():
    if x_api_key != os.getenv("API_KEY"):
        raise HTTPException(status_code=401, detail="Invalid API Key")
        
    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute("SELECT * FROM matchup_df")
    rows = cursor.fetchall()

    # Get column names
    colnames = [desc[0] for desc in cursor.description]

    cursor.close()
    connection.close()

    # Convert rows → list of dicts
    matchups = [dict(zip(colnames, row)) for row in rows]

    return {"matchups": matchups}

@router.get("/pitcher_stats")
def get_pitcher_stats():
    if x_api_key != os.getenv("API_KEY"):
        raise HTTPException(status_code=401, detail="Invalid API Key")

    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute("SELECT * FROM matchup_starting_pitcher_stats")
    rows = cursor.fetchall()

    # Get column names
    colnames = [desc[0] for desc in cursor.description]

    cursor.close()
    connection.close()

    # Convert rows → list of dicts
    pitcher_stats = [dict(zip(colnames, row)) for row in rows]

    return {"matchups": pitcher_stats}

@router.get("/pitcher_stats_current_year")
def get_pitcher_stats_current_year():
    if x_api_key != os.getenv("API_KEY"):
        raise HTTPException(status_code=401, detail="Invalid API Key")

    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute("SELECT * FROM matchup_starting_pitcher_stats_current_year_")
    rows = cursor.fetchall()

    # Get column names
    colnames = [desc[0] for desc in cursor.description]

    cursor.close()
    connection.close()

    # Convert rows → list of dicts
    pitcher_stats = [dict(zip(colnames, row)) for row in rows]

    return {"matchups": pitcher_stats}

@router.get("/team_batting_stats")
def get_team_batting_stats():
    if x_api_key != os.getenv("API_KEY"):
        raise HTTPException(status_code=401, detail="Invalid API Key")

    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute("SELECT * FROM matchup_team_batting_stats")
    rows = cursor.fetchall()

    # Get column names
    colnames = [desc[0] for desc in cursor.description]

    cursor.close()
    connection.close()

    # Convert rows → list of dicts
    team_batting_stats = [dict(zip(colnames, row)) for row in rows]

    return {"matchups": team_batting_stats}

@router.get("/team_pitching_stats")
def get_team_batting_stats():
    if x_api_key != os.getenv("API_KEY"):
        raise HTTPException(status_code=401, detail="Invalid API Key")

    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute("SELECT * FROM matchup_team_pitching_stats")
    rows = cursor.fetchall()

    # Get column names
    colnames = [desc[0] for desc in cursor.description]

    cursor.close()
    connection.close()

    # Convert rows → list of dicts
    team_pitching_stats = [dict(zip(colnames, row)) for row in rows]

    return {"matchups": team_pitching_stats}
