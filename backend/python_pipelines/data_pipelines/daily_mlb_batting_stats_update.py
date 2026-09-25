from backend.python_pipelines.data_extract_functions.extract_mlb_games_info import extract_active_mlb_rosters
from backend.python_pipelines.data_extract_functions.extract_data_from_database import get_data_from_database

from backend.python_pipelines.data_transform_functions.data_process_functions import process_full_roster_batting_stats_df

from backend.python_pipelines.data_load_functions.load_data_to_database import push_active_team_data_to_sql

def run_mlb_batting_stats_update():
    # Extract
    batting_df_statcast = get_data_from_database('batter_seasonal_data_statcast_v2')
    mlb_batting_rosters = extract_active_mlb_rosters()

    # Transform
    mlb_team_batting_df = process_full_roster_batting_stats_df(batting_df_statcast, mlb_batting_rosters)
    
    # Load
    push_active_team_data_to_sql('mlb_team_batting_stats', mlb_team_batting_df)

if __name__ == "__main__":
    run_mlb_batting_stats_update()