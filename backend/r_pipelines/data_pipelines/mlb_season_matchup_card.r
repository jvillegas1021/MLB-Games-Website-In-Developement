library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgres)

source("backend/r_pipelines/data_extract_functions/extract_mlb_games_info.r")
source("backend/r_pipelines/data_extract_functions/extract_data_from_database.r")
source("backend/r_pipelines/data_extract_functions/extract_data_from_files.r")
source("backend/r_pipelines/data_transform_functions/mlb_matchup_pipeline_functions.r")
source("backend/r_pipelines/data_load_functions/load_data_to_database.r")
source("backend/r_pipelines/data_pipelines/mlb_matchup_card_pipeline.r")


season_dates <- seq(as.Date("2026-03-25"), as.Date("2026-09-27"), by = "day")

for (d in season_dates) {
  # 1. Re-construct a completely unambiguous Date object from the loop index
  loop_date_obj <- as.Date(d, origin = "1970-01-01")
  
  print(paste("Processing Matchup Card for:", as.character(loop_date_obj)))
  
  # 2. FORCE the pipeline function to accept this exact date object 
  # explicitly by name so it bypasses the default Sys.time() parameter trap
  mlb_matchup_card_pipeline(game_date = loop_date_obj)
}


