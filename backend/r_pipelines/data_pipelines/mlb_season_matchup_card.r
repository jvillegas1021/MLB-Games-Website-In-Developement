library(tidyverse)
library(DBI)
library(RPostgres)

source("backend/r_pipelines/data_extract_functions/extract_mlb_games_info.r")
source("backend/r_pipelines/data_extract_functions/extract_data_from_database.r")
source("backend/r_pipelines/data_extract_functions/extract_data_from_files.r")
source("backend/r_pipelines/data_transform_functions/mlb_matchup_pipeline_functions.r")
source("backend/r_pipelines/data_load_functions/load_data_to_database.r")
source("backend/r_pipelines/data_pipelines/mlb_matchup_card_pipeline.r")


season_dates <- seq(as.Date("2026-03-25"), as.Date("2026-10-28"), by = "day")

# pitcher_data
starting_pitcher_stats_df <- get_data_from_database('mlb_pitcher_scores')
# pitcher_data
starting_pitcher_stats_current_year_df <- get_data_from_database('active_pitcher_stats_current_year')
# team batting_data
team_batting_df <- get_data_from_database('mlb_team_batting_scores_gameday')
# probability model
prob_model <- load_rds("win_prob_model")
# mlb odds table
mlb_games_odds_df <- get_data_from_database('mlb_games_odds_df')

mlb_matchup_card_list <- c()

for (d in season_dates) {
  # 1. Re-construct a completely unambiguous Date object from the loop index
  loop_date_obj <- as.Date(d, origin = "1970-01-01")
  
  print(paste("Processing Matchup Card for:", as.character(loop_date_obj)))
  
  # 2. FORCE the pipeline function to accept this exact date object 
  # explicitly by name so it bypasses the default Sys.time() parameter trap
  mlb_matchup_card <- mlb_matchup_card_pipeline(game_date = loop_date_obj)
  
  mlb_matchup_card_list[[length(mlb_matchup_card_list) + 1]] <- mlb_matchup_card
}

final_matchup_df <- bind_rows(mlb_matchup_card_list)

#write_df_to_sql_replace('historical_matchup_df', final_matchup_df)
