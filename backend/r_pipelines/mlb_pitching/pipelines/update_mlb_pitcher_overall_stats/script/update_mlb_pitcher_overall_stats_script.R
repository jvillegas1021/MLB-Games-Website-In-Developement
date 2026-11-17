library(baseballr)
library(tidyverse)
library(httr)
library(jsonlite)
library(DBI)
library(RPostgres)

source("backend/r_pipelines/mlb_pitching/pipelines/update_mlb_pitcher_overall_stats/extract_functions/extract_data_from_database.r")
source("backend/r_pipelines/mlb_pitching/pipelines/update_mlb_pitcher_overall_stats/load_functions/load_data_to_database.r")
source("backend/r_pipelines/mlb_pitching/pipelines/update_mlb_pitcher_overall_stats/pipeline/update_mlb_pitcher_overall_stats.R")
source("backend/r_pipelines/mlb_pitching/pipelines/update_mlb_pitcher_overall_stats/transform_functions/pitcher_overall_stats_functions.R")

update_pitcher_overall_stats()
print("Updated MLB pitchers overall stats.")