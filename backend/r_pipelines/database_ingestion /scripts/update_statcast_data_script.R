library(baseballr)
library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgres)

source("pipelines/update_statcast_data_pipeline.R")
source("transform_functions/statcast_data_update_functions.R")
source("load_functions/load_data_to_database.r")

update_statcast_data()
