library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgres)
library(ggplot2)
library(mlbplotR)

source("backend/r_pipelines/data_extract_functions/extract_data_from_database.r")
source("backend/r_pipelines/data_load_functions/load_data_to_database.r")
source("backend/r_pipelines/data_pipelines/mlb_team_pick_accuracy_pipeline_update.r")

mlb_team_pick_accuracy_pipeline()

