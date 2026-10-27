library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgres)

source("backend/r_pipelines/data_extract_functions/extract_data_from_database.r")
source("backend/r_pipelines/data_transform_functions/mlb_prediction_results_pipeline_functions.r")
source("backend/r_pipelines/data_load_functions/load_data_to_database.r")
source("backend/r_pipelines/data_pipelines/mlb_games_prediction_results_pipeline_update.r")


mlb_games_results_df <- get_data_from_database('mlb_games_results')
historical_matchup_df <- get_data_from_database('historical_matchup_df')

# process data
curated_results_df <- create_curated_results_df(mlb_games_results_df, historical_matchup_df)
# create final_results_df 
final_results_df <- data.frame(update_date = Sys.time())

final_results_df <- calculate_overall_pick_accuracy(curated_results_df, final_results_df)

final_results_df <- calculate_win_probability_accuracy(curated_results_df, final_results_df)

# push data to database

#write_df_to_sql_replace('mlb_games_prediction_results', final_results_df)
  

curated_results_df$away_open_odds


opening_betting_df <- curated_results_df %>%
  drop_na(away_open_odds, home_open_odds) %>%
  filter(Bet_Team_Open != 'No Bet') %>%
  mutate(
    Correct_Bet = if_else(Bet_Team_Open == Winner, TRUE, FALSE),
    Open_Bet_Odds = if_else(Bet_Team_Open == Home_Team, home_open_odds, away_open_odds),
    Bet_Profit = if_else(as.numeric(Open_Bet_Odds) < 0,
                         round(100 * (100 / abs(as.numeric(Open_Bet_Odds))), 2),
                         round(as.numeric(Open_Bet_Odds), 2)),
    Actual_Profit = if_else(Correct_Bet, Bet_Profit, -100.00)
  )
  
closing_betting_df <- curated_results_df %>%
  drop_na(away_close_odds, home_close_odds) %>%
  filter(Bet_Team_Current != 'No Bet') %>%
  mutate(
    Correct_Bet = if_else(Bet_Team_Current == Winner, TRUE, FALSE),
    Close_Bet_Odds = if_else(Bet_Team_Current == Home_Team, home_close_odds, away_close_odds),
    Bet_Profit = if_else(as.numeric(Close_Bet_Odds) < 0,
                         round(100 * (100 / abs(as.numeric(Close_Bet_Odds))), 2),
                         round(as.numeric(Close_Bet_Odds), 2)),
    Actual_Profit = if_else(Correct_Bet, Bet_Profit, -100.00)
  )

opening_bet_winnings <- sum(opening_betting_df$Actual_Profit)
closing_bet_winnings <- sum(closing_betting_df$Actual_Profit)
opening_bet_winnings
closing_bet_winnings
nrow(closing_betting_df)
