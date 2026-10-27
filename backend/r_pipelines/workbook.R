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
  

master_analysis_df <- curated_results_df %>%
  # 1. Drop rows missing odds data entirely
  drop_na(away_open_odds, home_open_odds, away_close_odds, home_close_odds) %>%
  
  # 2. Process ALL opening and closing metrics simultaneously
  mutate(
    # --- OPENING LINE ANALYSIS ---
    Correct_Open_Bet  = if_else(Bet_Team_Open == Winner, TRUE, FALSE),
    Open_Bet_Odds     = if_else(Bet_Team_Open == Home_Team, as.numeric(home_open_odds), as.numeric(away_open_odds)),
    Open_Bet_Profit   = if_else(Open_Bet_Odds < 0, round(100 * (100 / abs(Open_Bet_Odds)), 2), round(Open_Bet_Odds, 2)),
    Actual_Open_Profit = if_else(Correct_Open_Bet, Open_Bet_Profit, -100.00),
    
    # --- CLOSING LINE ANALYSIS ---
    Correct_Close_Bet  = if_else(Bet_Team_Current == Winner, TRUE, FALSE),
    Close_Bet_Odds     = if_else(Bet_Team_Current == Home_Team, as.numeric(home_close_odds), as.numeric(away_close_odds)),
    Close_Bet_Profit   = if_else(Close_Bet_Odds < 0, round(100 * (100 / abs(Close_Bet_Odds)), 2), round(Close_Bet_Odds, 2)),
    Actual_Close_Profit = if_else(Correct_Close_Bet, Close_Bet_Profit, -100.00)
  )

prob_ranges <- seq(from = 50, to = 65)

for (prob in prob_ranges) {
# 3. Generate a single, comprehensive summary grid for the 58%+ Elite Threshold
  master_performance_summary <- master_analysis_df %>%
    summarise(
      # --- Opening Line 58%+ Metrics ---
      Open_Elite_Bets    = sum(Bet_Team_Open != "No Bet" & Win_Probability >= prob),
      Open_Elite_Win_Pct = mean(Correct_Open_Bet[Bet_Team_Open != "No Bet" & Win_Probability >= prob]) * 100,
      Open_Elite_Profit  = sum(Actual_Open_Profit[Bet_Team_Open != "No Bet" & Win_Probability >= prob]),
      
      # --- Closing Line 58%+ Metrics ---
      Close_Elite_Bets    = sum(Bet_Team_Current != "No Bet" & Win_Probability >= prob),
      Close_Elite_Win_Pct = mean(Correct_Close_Bet[Bet_Team_Current != "No Bet" & Win_Probability >= prob]) * 100,
      Close_Elite_Profit  = sum(Actual_Close_Profit[Bet_Team_Current != "No Bet" & Win_Probability >= prob])
    )
  
  # --- Print the Side-by-Side Performance Matrix ---
  cat(paste0("=== UNIFIED STRATEGY ANALYSIS (", prob, "%+ THRESHOLD) ===\n"))
  print(
    data.frame(
      Strategy_Metric = c("Total Bets Triggered", "Win Percentage", "Net Profit ($)"),
      Opening_Line_Market = c(master_performance_summary$Open_Elite_Bets, round(master_performance_summary$Open_Elite_Win_Pct, 2), round(master_performance_summary$Open_Elite_Profit, 2)),
      Closing_Line_Market = c(master_performance_summary$Close_Elite_Bets, round(master_performance_summary$Close_Elite_Win_Pct, 2), round(master_performance_summary$Close_Elite_Profit, 2))
    ),
    row.names = FALSE
  )
}

