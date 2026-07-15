library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgres)

source("backend/r_pipelines/data_extract_functions/extract_mlb_games_info.r")
source("backend/r_pipelines/data_transform_functions/mlb_games_process_functions.r")
source("backend/r_pipelines/data_load_functions/load_data_to_database.r")
source("backend/r_pipelines/data_pipelines/mlb_games_results_pipeline_update.r")

mlb_games_results_pipeline()
