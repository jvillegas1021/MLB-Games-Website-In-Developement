from data_transform_functions.data_cleanup_functions import *
from data_transform_functions.data_flag_functions import *
from data_transform_functions.data_count_functions import compute_count_stats_batter, compute_count_stats_pitcher
from data_load_functions.load_data_to_database import push_batter_data_to_sql_upsert, push_pitcher_data_to_sql_upsert

from pybaseball import statcast, cache

def run_daily_statcast_stats_update():
    cache.enable()
    statcast_data = statcast('2026-03-01', '2026-11-30')

    statcast_data = remove_empty_pitch_types(statcast_data)
    statcast_data = remove_excess_columns(statcast_data)
    statcast_data = remove_two_pitcher_at_bats(statcast_data)
    statcast_data = change_pitch_names(statcast_data)
    statcast_data = create_count_flags(statcast_data)

    # pitcher branch
    pitcher_data = compute_count_stats_pitcher(statcast_data)
    pitcher_data_table_name = 'pitcher_seasonal_data_statcast_v2'
    push_pitcher_data_to_sql_upsert(pitcher_data_table_name, pitcher_data)

    # batter branch
    batter_data = compute_count_stats_batter(statcast_data)
    batter_data_table_name = 'batter_seasonal_data_statcast_v2'
    push_batter_data_to_sql_upsert(batter_data_table_name, batter_data)

if __name__ == "__main__":
    run_daily_statcast_stats_update()
