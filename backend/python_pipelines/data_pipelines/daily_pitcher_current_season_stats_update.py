from backend.python_pipelines.data_extract_functions.extract_data_from_database import get_data_from_database
from backend.python_pipelines.data_transform_functions.data_process_functions import process_starting_pitcher_current_year_stats
from backend.python_pipelines.data_load_functions.load_data_to_database import push_pitcher_data_to_sql_upsert_player_id


def run_daily_pitcher_current_season_stats_update():
    #extract
    pitcher_statsapi = get_data_from_database('pitcher_seasonal_data_statsapi')
    pitcher_statcast = get_data_from_database('pitcher_seasonal_data_statcast_v2')
    #transform
    pitcher_current_year_stats_df = process_starting_pitcher_current_year_stats(pitcher_statsapi, pitcher_statcast)
    #load
    table_name = 'active_pitcher_stats_current_year_v2'
    push_pitcher_data_to_sql_upsert_player_id(table_name, pitcher_current_year_stats_df)

if __name__ == "__main__":
    run_daily_pitcher_current_season_stats_update()
