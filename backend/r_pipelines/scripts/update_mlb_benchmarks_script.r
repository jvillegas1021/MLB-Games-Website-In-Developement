library(tidyverse)
library(DBI)
library(RPostgres)

source("data_extract_functions/extract_data_from_database.r")
source("data_transform_functions/benchmark_functions.r")
source("data_load_functions/load_data_to_database.r")
source("pipelines/mlb_benchmarks_update_pipeline.r")

run_mlb_benchmarks_update_pipeline()
