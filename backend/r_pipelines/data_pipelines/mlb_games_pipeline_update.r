mlb_games_pipeline <- function(game_date = as.Date(format(Sys.time(), tz = "America/New_York"))) {
  
  games_table <- get_mlb_games(game_date)
  
  if (is.null(games_table) || nrow(games_table) == 0) {
    message("No MLB games today. Pipeline exiting.")
    return(invisible(NULL))
  }
  
  ###### PULL ALL DATA ################
  # pitcher_data
  starting_pitcher_stats_df <- get_data_from_database('active_pitcher_stats_v2')
  # pitcher_data
  starting_pitcher_stats_current_year_df <- get_data_from_database('active_pitcher_stats_current_year_v2')
  # starting pitchers recent form
  starting_pitcher_recent_form_df <- get_data_from_database('starting_pitchers_recent_form')
  # team batting_data + historical
  team_batting_df <- get_data_from_database('active_team_batting_stats_v2')
  hist_team_batting_df <- get_data_from_database('historical_team_batting_stats_v2')
  # team pitching + historical
  team_pitching_df <- get_data_from_database('active_team_pitching_stats_v2')
  hist_team_pitching_df <- get_data_from_database('historical_team_pitching_stats_v2')
  # mlb_team_record_info
  mlb_team_record_df <-  get_data_from_database('mlb_team_record_info')
  # mlb_team_league_batting_averages
  mlb_team_league_batting_averages_df <- get_data_from_database('mlb_team_league_batting_averages')
  # mlb_team_batting_splits
  mlb_team_league_batting_splits_df <- get_data_from_database('mlb_team_league_batting_splits')
  # ball_park_factor
  ball_park_factor_df <- load_csv('ball_park_factor')
  # pitcher benchmarks
  pitcher_season_benchmark_df <- get_data_from_database('pitcher_benchmark_v2')
  pitcher_recent_form_benchmark_df <- get_data_from_database('pitcher_recent_form_benchmark')
  # team batting benchmark
  team_batting_benchmark_df <- get_data_from_database('team_batting_benchmark_v2')
  # team pitching benchmark
  team_pitching_benchmark_df <- get_data_from_database('team_pitching_benchmark_v2')
  # mlb_team_record_benchmark
  mlb_team_record_benchmark <- get_data_from_database('mlb_team_record_benchmark')
  # odds table
  espn_mlb_odds_table_df <- get_espn_mlb_odds(game_date)
  # probability model
  prob_model <- load_rds("win_prob_model")
  # historical matchup df table
  historical_matchup_df <- get_data_from_database('historical_matchup_df')
  
  ###### create matchup df #############
  
  matchup_df <- create_matchup_df(games_table)
  
  #########add odds table ################
  
  matchup_df <- assign_odds_to_teams(matchup_df, espn_mlb_odds_table_df)
  
  ######### add mlb divisions and leagues ###################
  
  matchup_df <- assign_league_and_division_ids(matchup_df, mlb_team_record_df)
  
  ####### filter pitchers data #############
  
  starting_pitcher_filtered_df <- filter_pitchers_for_matchup(matchup_df, starting_pitcher_stats_df)
  starting_pitcher_current_year_filtered_df <- filter_pitchers_for_matchup(matchup_df, starting_pitcher_stats_current_year_df)
  starting_pitcher_recent_form_filtered_df <- filter_pitchers_for_matchup(matchup_df, starting_pitcher_recent_form_df)
  
  ############################ Guard for NA starting Pitchers  ##############################
  
  matchup_df <- no_starting_pitchers_guard(matchup_df)
  
  ########################## ADD PITCHER THROWING HANDS / WINS / LOSES / ERA###################################
  
  matchup_df <- assign_starting_pitcher_throwing_hands_wins_loses_era(matchup_df, starting_pitcher_filtered_df, starting_pitcher_current_year_filtered_df)
  
  #################### CHANGE PITCHER ID TO CHARACTERS ####################################
  starting_pitcher_filtered_df <- starting_pitcher_filtered_df %>%
    mutate(xMLBAMID = as.character(xMLBAMID))
  
  starting_pitcher_current_year_filtered_df <- starting_pitcher_current_year_filtered_df %>%
    mutate(xMLBAMID = as.character(xMLBAMID))
  ################### ADD BATTING LINEUPS LIST PLUS HYDRATION STATUS ###################################
  
  matchup_df <- assign_batting_lineups_with_hydration_status(matchup_df, team_batting_df, hist_team_batting_df)
  
  ################## JOIN BALL PARK FACTOR #########################
  
  matchup_df <- join_ball_park_df(matchup_df, ball_park_factor_df)
  
  ######### PROABABLE PITCHER & PITCHER STATS & LINE UP HYDRATION FLAGS##################################
  
  matchup_df <- probable_pitcher_and_lineup_hydration_flags(matchup_df, starting_pitcher_filtered_df)
  
  ############################################## calculate pitcher score #######################################################
  
  matchup_df <- calculate_starting_pitcher_scores(matchup_df,
                                                  starting_pitcher_filtered_df,
                                                  starting_pitcher_recent_form_filtered_df,
                                                  pitcher_season_benchmark_df,
                                                  pitcher_recent_form_benchmark_df)
  
  ###############################calculate team batting score#######################################################
  
  matchup_df <- calculate_team_batting_scores(matchup_df,
                                              team_batting_df,
                                              hist_team_batting_df,
                                              team_batting_benchmark_df)
  
  ###############################################calculate team pitching score########################################
  
  matchup_df <- calculate_team_pitching_scores(matchup_df,
                                               team_pitching_df,
                                               hist_team_pitching_df,
                                               team_pitching_benchmark_df)
  
  ################################# calculate team record score ############################
  matchup_df <- calculate_team_record_scores(matchup_df,
                                             mlb_team_record_df,
                                             mlb_team_record_benchmark)
  
  ###############################calculate context Score#####################################################
  
  matchup_df <- calculate_team_context_scores(matchup_df)
  
  ############################# calculate pitcher vs team batting score ##################
  
  matchup_df <- calculate_pitcher_vs_team_batting_score(matchup_df,
                                                        starting_pitcher_filtered_df,
                                                        team_batting_df)
  
  ############################### calculate split score ####################################
  matchup_df <- calculate_team_split_score(matchup_df,
                                           starting_pitcher_filtered_df,
                                           team_batting_df,
                                           mlb_team_league_batting_splits_df)
  
  ############################## calculate power boost score / suppression #################
  
  matchup_df <- calculate_power_boost_score(matchup_df,
                                            starting_pitcher_filtered_df,
                                            team_batting_df,
                                            mlb_team_league_batting_averages_df)
  
  
  ###############################################calculate total score##########################################
  
  matchup_df <- calculate_total_scores(matchup_df)
  
  ################################### Calculate win prob ####################################
  
  matchup_df <- calculate_win_prob_prediction(matchup_df, prob_model)
  
  ################################# Calculate model odds and edge #################################
  
  matchup_df <- calculate_model_odds_and_edge(matchup_df)
  
  ############################## round display columns for matchup and pitcher#####################################
  
  matchup_df <- round_display_columns_for_matchup_df(matchup_df)
  
  starting_pitcher_stats_df <- round_display_columns_for_pitcher_df(starting_pitcher_stats_df)
  
  ############################### final table display (select) ############################
  
  matchup_display_df <- create_final_display_matchup_df(matchup_df)
  ############################# PUSH DATA TO SQL ##################################
  
  
  write_df_to_sql('matchup_df', matchup_display_df)
  write_df_to_sql('matchup_starting_pitcher_stats', starting_pitcher_filtered_df)
  write_df_to_sql('matchup_starting_pitcher_stats_current_year_', starting_pitcher_current_year_filtered_df)
  write_df_to_sql('matchup_team_batting_stats', team_batting_df)
  write_df_to_sql('matchup_team_pitching_stats', team_pitching_df)
  
  return(invisible((TRUE)))
}
