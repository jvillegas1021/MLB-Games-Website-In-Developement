library(baseballr)
library(tidyverse)
library(httr)
library(jsonlite)
library(DBI)
library(RPostgres)

source("backend/r_pipelines/statcast_data/pipelines/update_statcast_data/load_functions/load_data_to_database.r")
source("backend/r_pipelines/statcast_data/pipelines/update_statcast_data/pipeline/update_statcast_data_pipeline.R")
source("backend/r_pipelines/statcast_data/pipelines/update_statcast_data/transform_functions/update_statcast_data_functions.R")

update_statcast_data()
print(paste0("Updated statcast data for ", Sys.Date()))
