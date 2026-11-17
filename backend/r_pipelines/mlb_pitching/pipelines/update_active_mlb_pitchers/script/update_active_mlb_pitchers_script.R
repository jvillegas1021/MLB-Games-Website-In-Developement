
library(baseballr)
library(tidyverse)
library(httr)
library(jsonlite)
library(DBI)
library(RPostgres)



source("backend/r_pipelines/mlb_pitching/pipelines/update_active_mlb_pitchers/extract_functions/extract_active_mlb_pitchers.R")
source("backend/r_pipelines/mlb_pitching/pipelines/update_active_mlb_pitchers/load_functions/load_data_to_database.r")
source("backend/r_pipelines/mlb_pitching/pipelines/update_active_mlb_pitchers/pipeline/update_active_mlb_pitchers.R")

update_active_mlb_pitchers()
print("Updated Active MLB pitchers.")
