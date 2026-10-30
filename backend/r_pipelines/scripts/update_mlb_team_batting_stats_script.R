library(tidyverse)
library(DBI)
library(RPostgres)
library(glmnet)
library(caret)
library(baseballr)


source("backend/r_pipelines/data_extract_functions/extract_data_from_database.r")
source("backend/r_pipelines/data_transform_functions/mlb_battin_stats_pipeline_functions.r")
source("backend/r_pipelines/data_load_functions/load_data_to_database.r")
source("backend/r_pipelines/data_pipelines/mlb_batting_stats_gameday_pipeline_update.r")

update_mlb_team_batting_stats_gameday()



