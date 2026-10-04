library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgres)

source("backend/r_pipelines/data_extract_functions/extract_mlb_games_info.r")
source("backend/r_pipelines/data_extract_functions/extract_data_from_database.r")
source("backend/r_pipelines/data_extract_functions/extract_data_from_files.r")
source("backend/r_pipelines/data_transform_functions/mlb_games_process_functions.r")
source("backend/r_pipelines/data_load_functions/load_data_to_database.r")



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
mlb_games_odds_df <- get_data_from_database('mlb_games_odds_df')
# probability model
prob_model <- load_rds("win_prob_model")



game_dates <- seq(
  from = as.Date("2026-03-10"),
  to   = as.Date("2026-08-20"),
  by   = "day"
)
source("backend/r_pipelines/data_transform_functions/mlb_games_process_functions.r")
matchup_df_list <- list()

for (game_date in game_dates) {
  game_date <- as.Date(game_date)
  games_table <- get_mlb_games(game_date)
  
  if (is.null(games_table) || nrow(games_table) == 0) {
    message("No MLB games today. Pipeline exiting.")
    next
  }
  
  ###### create matchup df #############
  
  matchup_df <- create_matchup_df_scoring_analysis(games_table)
  
  #########add odds table ################
  
  matchup_df <- assign_odds_and_win_probability_to_teams(matchup_df, mlb_games_odds_df)
  
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
  
  matchup_pitcher_score_list <- calculate_starting_pitcher_scores(matchup_df,
                                                                  starting_pitcher_filtered_df,
                                                                  starting_pitcher_recent_form_filtered_df,
                                                                  pitcher_season_benchmark_df,
                                                                  pitcher_recent_form_benchmark_df)
  
  matchup_df <- matchup_pitcher_score_list[[1]]
  
  pitcher_season_scores <- matchup_pitcher_score_list[[2]]
  pitcher_recent_scores <- matchup_pitcher_score_list[[3]]
  
  
  ###############################calculate team batting score#######################################################
  
  matchup_batting_score_list <- calculate_team_batting_scores(matchup_df,
                                                              team_batting_df,
                                                              hist_team_batting_df,
                                                              team_batting_benchmark_df)
  
  matchup_df <- matchup_batting_score_list[[1]]
  
  batting_scores <- matchup_batting_score_list[[2]]
  
  ###############################################calculate team pitching score########################################
  
  matchup_pitching_score_list  <- calculate_team_pitching_scores(matchup_df,
                                                                 team_pitching_df,
                                                                 hist_team_pitching_df,
                                                                 team_pitching_benchmark_df)
  
  matchup_df <- matchup_pitching_score_list[[1]]
  
  pitching_scores <- matchup_pitching_score_list[[2]]
  
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
  
  
  ###############################################calculate total score##########################################
  
  matchup_df <- calculate_total_scores_testing(matchup_df)
  
  ################################### Calculate win prob ####################################
  
  matchup_df <- calculate_win_prob_prediction(matchup_df, prob_model)
  
  ################################# Calculate model odds and edge #################################
  
  matchup_df <- calculate_model_odds_and_edge(matchup_df)
  
  ############################## round display columns for matchup and pitcher#####################################
  
  matchup_df <- round_display_columns_for_matchup_df(matchup_df)
  
  ############################### add betting logic / columns ####################
  matchup_df <- calculate_betting_logic(matchup_df)
  
  ###############################  display (select) ############################
  
  matchup_df_list[[length(matchup_df_list) + 1]] <- matchup_df
}

final_matchup_df <- do.call(rbind, matchup_df_list)

cleaned_final_matchup_df <- final_matchup_df %>%
  filter(
    Prediction_Status == 'Full Prediction',
    teams.home.score != teams.away.score
  ) %>%
  mutate(
    home_team_is_winner = if_else(
      teams.home.score > teams.away.score,
      1,
      0),
    winner = if_else(
      teams.home.score > teams.away.score, Home_Team, Away_Team
    )
  )
cleaned_final_matchup_df

home_scoring_columns <- str_subset(names(cleaned_final_matchup_df), '^Home_.*_Score$')
away_scoring_columns <- str_subset(names(cleaned_final_matchup_df), '^Away_.*_Score$')

scoring_columns <- c(home_scoring_columns, away_scoring_columns, "home_team_is_winner")

prepared_cor_df <- cleaned_final_matchup_df %>%
  select(
    all_of(scoring_columns),
    -Home_Context_Score,
    -Away_Context_Score
  )


model <- glm(
  home_team_is_winner ~ Score_Difference,
  data = cleaned_final_matchup_df,
  family = binomial()
)
summary(model)























