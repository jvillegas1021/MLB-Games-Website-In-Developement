library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgres)

source("backend/r_pipelines/data_extract_functions/extract_mlb_player_info.r")
source("backend/r_pipelines/data_load_functions/load_data_to_database.r")

update_mlb_pitchers()