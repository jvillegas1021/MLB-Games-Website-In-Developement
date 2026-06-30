library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgres)

source("data_extract_functions/extract_mlb_games_info.r")
source("data_transform_functions/mlb_games_process_functions.r")
source("data_load_functions/load_data_to_database.r")
source("pipelines/mlb_games_pipeline_update.r")

mlb_games_pipeline()


