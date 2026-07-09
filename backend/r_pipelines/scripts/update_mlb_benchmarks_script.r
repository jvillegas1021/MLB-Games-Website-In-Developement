library(tidyverse)
library(DBI)
library(RPostgres)

source("backend/r_pipelines/data_extract_functions/extract_data_from_database.r")
source("backend/r_pipelines/data_transform_functions/benchmark_functions.r")
source("backend/r_pipelines/data_load_functions/load_data_to_database.r")
source("backend/r_pipelines/data_pipelines/mlb_benchmarks_update_pipeline.r")

run_mlb_benchmarks_update_pipeline()
