library(baseballr)
library(tidyverse)
library(httr)
library(jsonlite)
library(DBI)
library(RPostgres)

source("backend/r_pipelines/mlb_pitching/pipelines/update_active_mlb_pitcher_statcast_counts/extract_functions/extract_data_from_database.r")
source("backend/r_pipelines/mlb_pitching/pipelines/update_active_mlb_pitcher_statcast_counts/load_functions/load_data_to_database.r")
source("backend/r_pipelines/mlb_pitching/pipelines/update_active_mlb_pitcher_statcast_counts/transform_functions/statcast_count_functions.r")
source("backend/r_pipelines/mlb_pitching/pipelines/update_active_mlb_pitcher_statcast_counts/pipeline/update_active_mlb_pitcher_statcast_counts.R")

update_active_mlb_pitcher_statcast_counts()
print("Updated Active MLB pitchers STATCAST counts.")