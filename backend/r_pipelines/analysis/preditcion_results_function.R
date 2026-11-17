library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgres)

source("backend/r_pipelines/data_extract_functions/extract_data_from_database.r")
source("backend/r_pipelines/data_transform_functions/mlb_prediction_results_pipeline_functions.r")
source("backend/r_pipelines/data_load_functions/load_data_to_database.r")
source("backend/r_pipelines/data_pipelines/mlb_games_prediction_results_pipeline_update.r")
# pull in data
mlb_games_results_df <- get_data_from_database('mlb_games_results')
historical_matchup_df <- get_data_from_database('historical_matchup_df_v2')

# process data
curated_results_df <- create_curated_results_df(mlb_games_results_df, historical_matchup_df)

# create final_results_df 
final_results_df <- data.frame(update_date = Sys.time())

final_results_df <- calculate_overall_pick_accuracy(curated_results_df, final_results_df)

final_results_df <- calculate_overall_betting_accuracy(curated_results_df, final_results_df)

final_results_df <- calculate_underdog_accuracy(curated_results_df, final_results_df)

final_results_df <- calculate_win_probability_accuracy(curated_results_df, final_results_df)

# push data to database
curated_results_df

roi_df <- curated_results_df %>%
  mutate(
    Bet_Team_Home_Away = if_else(
      Bet_Team_Current == Home_Team, Home_Team, Away_Team
    ),
    Bet_Team_Odds = if_else(
      Bet_Team_Home_Away == Home_Team, as.numeric(home_open_odds), as.numeric(away_open_odds)
    ),
    Net_Profit = case_when(
      # 1. Catch the non-actions first
      Bet_Team_Current == 'No Bet' ~ 0,
      
      # 2. Catch the losses next
      Bet_Team_Current != Winner   ~ -100,
      
      # 3. Catch the wins cleanly using the raw numbers
      Bet_Team_Current == Winner   ~ if_else(
        Bet_Team_Odds > 0, 
        Bet_Team_Odds,                        # Shortcut: $100 bet on +130 wins exactly $130
        100 * (100 / abs(Bet_Team_Odds))      # Standard negative odds formula
      )
    )
  ) 

roi_summary_table <- roi_df %>%
  # Filter out the "No Bets" only when calculating final ROI
  filter(Bet_Team_Current != "No Bet") %>%
  summarise(
    Total_Bets_Placed = n(),
    Total_Capital_Risked = Total_Bets_Placed * 100,
    Total_Net_Profit = sum(Net_Profit),
    Final_ROI_Percentage = round((Total_Net_Profit / Total_Capital_Risked) * 100, 2)
  )

roi_df
roi_summary_table
roi_df %>% arrange(desc(Game_Date))

roi_df$Net_Profit
