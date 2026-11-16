library(baseballr)
library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgres)

source("pipelines/update_statcast_data/load_functions/load_data_to_database.r")
source("pipelines/update_statcast_data/pipeline_script/update_statcast_data_pipeline.R")

update_statcast_data()
