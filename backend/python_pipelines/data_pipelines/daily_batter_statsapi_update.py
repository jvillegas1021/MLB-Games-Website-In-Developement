from backend.python_pipelines.data_extract_functions.extract_mlb_games_info import get_all_active_batter_ids, get_batter_info_and_stats_season
from backend.python_pipelines.data_transform_functions.utility_functions import convert_batter_df_types_statsapi, add_update_date
from backend.python_pipelines.data_load_functions.load_data_to_database import push_batter_data_to_sql_upsert
import pandas as pd
from datetime import datetime

def run_daily_batter_statsapi_update():

    current_year = datetime.now().year

    current_batter_ids = get_all_active_batter_ids()

    all_current_batters_df_list = []

    for batter in current_batter_ids:
        current_batter_df = get_batter_info_and_stats_season(batter, season=current_year)
        if current_batter_df is None or current_batter_df.empty:
            continue
        all_current_batters_df_list.append(current_batter_df)

    final_batter_df = pd.concat(all_current_batters_df_list)

    clean_types_batter_df = convert_batter_df_types_statsapi(final_batter_df)
    
    update_date_batter_df = add_update_date(clean_types_batter_df)

    data_table_name = 'batter_seasonal_data_statsapi'

    push_batter_data_to_sql_upsert(data_table_name, update_date_batter_df)

if __name__ == "__main__":
    run_daily_batter_statsapi_update()
