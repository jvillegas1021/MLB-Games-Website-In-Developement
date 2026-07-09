run_mlb_benchmarks_update_pipeline <- function() {
    # extract data
    pitcher_df <- get_data_from_database('active_pitcher_stats_v2')
    team_batting_df <- get_data_from_database('active_team_batting_stats_v2')
    team_pitching_df <- get_data_from_database('active_team_pitching_stats_v2')
    mlb_team_record_df <- get_data_from_database('mlb_team_record_info')

    #transform
    pitcher_benchmark_df <- pitcher_benchmark(pitcher_df)
    team_batting_benchmark_df <- team_batting_benchmark(team_batting_df)
    team_pitching_benchmark_df <- team_pitching_benchmark(team_pitching_df)
    mlb_team_record_benchmark_df <- mlb_team_record_benchmark(mlb_team_record_df)
    mlb_pitcher_league_averages_df <- mlb_pitcher_league_averages(pitcher_df)
    mlb_team_league_batting_averages_df <- mlb_team_league_batting_averages(team_batting_df)
    mlb_team_league_batting_splits_df <- mlb_team_league_batting_splits(team_batting_df)
    
    # load
    write_df_to_sql_replace('pitcher_benchmark_v2', pitcher_benchmark_df)
    write_df_to_sql_replace('team_batting_benchmark_v2', team_batting_benchmark_df)
    write_df_to_sql_replace('team_pitching_benchmark_v2', team_pitching_benchmark_df)
    write_df_to_sql_replace('mlb_team_record_benchmark', mlb_team_record_benchmark_df)
    write_df_to_sql_replace('mlb_pitcher_league_averages', mlb_pitcher_league_averages_df)
    write_df_to_sql_replace('mlb_team_league_batting_averages', mlb_team_league_batting_averages_df)
    write_df_to_sql_replace('mlb_team_league_batting_splits', mlb_team_league_batting_splits_df)
    }
