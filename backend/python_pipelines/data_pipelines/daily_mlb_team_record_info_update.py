from backend.python_pipelines.data_extract_functions.extract_mlb_games_info import get_mlb_team_record_info
from backend.python_pipelines.data_transform_functions.data_process_functions import process_mlb_team_record_info
from backend.python_pipelines.data_load_functions.load_data_to_database import push_mlb_team_record_info
from datetime import datetime
import pandas as pd
import pytz

def run_daily_mlb_team_record_info_update():
    
    mlb_teams_df_list = []
    league_ids = [103, 104]

    current_year = datetime.now().year
    
    for league in league_ids:
        league_df = get_mlb_team_record_info(league, current_year)
        team_df = process_mlb_team_record_info(league, league_df)
        mlb_teams_df_list.append(team_df)
    mlb_records_df = pd.concat(mlb_teams_df_list)

    mlb_records_df['update date'] = datetime.now(pytz.timezone("America/New_York"))
    
    table_name = 'mlb_team_record_info'
    
    push_mlb_team_record_info(table_name, mlb_records_df)

if __name__ == "__main__":
    run_daily_mlb_team_record_info_update()
