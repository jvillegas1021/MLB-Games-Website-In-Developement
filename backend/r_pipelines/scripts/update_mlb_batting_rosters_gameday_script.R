library(baseballr)
library(tidyverse)

source("backend/r_pipelines/data_load_functions/load_data_to_database.r")
source("backend/r_pipelines/data_transform_functions/mlb_batting_rosters_pipeline_functions.R")
source("backend/r_pipelines/data_pipelines/mlb_batting_rosters_pipeline_update.r")

update_mlb_batting_rosters_gameday()
