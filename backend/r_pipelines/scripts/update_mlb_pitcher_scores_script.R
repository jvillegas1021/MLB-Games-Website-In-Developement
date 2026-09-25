library(tidyverse)
library(DBI)
library(RPostgres)
library(glmnet)
library(caret)


source("backend/r_pipelines/data_extract_functions/extract_data_from_database.r")
source("backend/r_pipelines/data_transform_functions/mlb_games_process_functions.r")
source("backend/r_pipelines/data_load_functions/load_data_to_database.r")
source("backend/r_pipelines/data_pipelines/mlb_pitcher_scoring_pipeline_update.r")

mlb_pitcher_scores_pipeline()
