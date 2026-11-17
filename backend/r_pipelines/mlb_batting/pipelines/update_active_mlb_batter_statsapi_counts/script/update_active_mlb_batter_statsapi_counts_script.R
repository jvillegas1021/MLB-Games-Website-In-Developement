library(baseballr)
library(tidyverse)
library(httr)
library(jsonlite)
library(DBI)
library(RPostgres)


source("backend/r_pipelines/mlb_batting/pipelines/update_active_mlb_batter_statsapi_counts/extract_functions/extract_mlb_batter_stats.R")
source("backend/r_pipelines/mlb_batting/pipelines/update_active_mlb_batter_statsapi_counts/extract_functions/extract_data_from_database.R")
source("backend/r_pipelines/mlb_batting/pipelines/update_active_mlb_batter_statsapi_counts/load_functions/load_data_to_database.r")
source("backend/r_pipelines/mlb_batting/pipelines/update_active_mlb_batter_statsapi_counts/pipeline/update_active_mlb_batter_statsapi_counts_pipeline.R")

update_active_mlb_batter_statsapi_counts()
print("Updated Active MLB batters STATSAPI counts.")




