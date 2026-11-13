library(baseballr)
library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgres)

source("pipelines/update_statcast_data_pipeline.R")
source("pipelines/update_active_mlb_pitcher_statcast_counts.R")
source("transform_functions/update_active_mlb_pitcher_counts_functions.R")
source("load_functions/load_data_to_database.r")

update_active_mlb_pitchers()
print("Updated Active MLB pitchers.")

update_active_mlb_pitcher_statsapi_counts()
print("Updated Active MLB pitchers STATSAPI counts.")
#########
update_active_mlb_pitcher_statcast_counts()
print("Updated Active MLB pitchers STATCAST counts.")



