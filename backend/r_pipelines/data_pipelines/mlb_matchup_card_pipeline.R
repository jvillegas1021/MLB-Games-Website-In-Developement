mlb_matchup_card_pipeline <- function(game_date = as.Date(format(Sys.time(), tz = "America/New_York"))) {
  
  games_table <- get_mlb_games(game_date)
  
  if (is.null(games_table) || nrow(games_table) == 0) {
    message("No MLB games today. Pipeline exiting.")
    return(invisible(NULL))
  }

  # pitcher_data
  starting_pitcher_stats_df <- get_data_from_database('mlb_pitcher_scores')
  # pitcher_data
  starting_pitcher_stats_current_year_df <- get_data_from_database('active_pitcher_stats_current_year')
  # team batting_data
  team_batting_df <- get_data_from_database('mlb_team_batting_scores')
  # probability model
  prob_model <- load_rds("win_prob_model")
  # mlb odds table
  mlb_games_odds_df <- get_data_from_database('mlb_games_odds_df')
  ###### create matchup df #############
  matchup_df <- create_matchup_df(games_table)
  ######### assing odds #############
  matchup_df <- assign_odds_and_win_probability_to_teams(matchup_df, mlb_games_odds_df)
  ####### filter pitchers data #############
  starting_pitcher_filtered_df <- filter_pitchers_for_matchup(matchup_df, starting_pitcher_stats_df)
  starting_pitcher_current_year_filtered_df <- filter_pitchers_for_matchup(matchup_df, starting_pitcher_stats_current_year_df)
  ############################ Guard for NA starting Pitchers  ##############################
  matchup_df <- no_starting_pitchers_guard(matchup_df)
  ########################## ADD PITCHER THROWING HANDS / WINS / LOSES / ERA###################################
  matchup_df <- assign_starting_pitcher_throwing_hands_wins_loses_era(matchup_df, starting_pitcher_filtered_df, starting_pitcher_current_year_filtered_df)
  ##################### ADD PITCHER SCORES #########################################
  matchup_df <- assign_pitcher_scores(matchup_df, starting_pitcher_filtered_df)
  ################### ADD BATTING LINEUPS LIST PLUS HYDRATION STATUS ###################################
  matchup_df <- assign_team_batting_scores(matchup_df, team_batting_df)
  ######### PROABABLE PITCHER & PITCHER STATS & LINE UP HYDRATION FLAGS##################################
  matchup_df <- probable_pitcher_and_lineup_hydration_flags(matchup_df, starting_pitcher_filtered_df)
  ########### CALCULATE MATCHUP SCORE ########################################
  matchup_df <- calculate_matchup_score(matchup_df)
  ################################### Calculate win prob ####################################
  matchup_df <- calculate_win_prob_prediction(matchup_df, prob_model)
  ################################# Calculate model odds and edge #################################
  matchup_df <- calculate_model_odds_and_edge(matchup_df)
  ############################### add betting logic / columns ####################
  matchup_df <- calculate_betting_logic(matchup_df)
  ########################## add update date time #####################
  matchup_df <- add_update_date(matchup_df)
  ########################### push to sql ####################################
  write_df_to_sql_replace('mlb_matchup_card', matchup_df )
  
  return(invisible((TRUE)))
  
}
