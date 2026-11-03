library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgres)
library(baseballr)

source("backend/r_pipelines/data_extract_functions/extract_data_from_database.r")
source("backend/r_pipelines/data_transform_functions/pitcher_statcast_pipeline_functions.r")
# test new function

#current_year <- as.numeric(format(Sys.Date(), '%Y'))

current_year <- 2025
year_range <- seq(from = current_year, to = (current_year - 2))

pitcher_stats_counts_df_list <- c()

for (year in year_range) {
  
  statsapi_table <- paste0('pitcher_statsapi_counts_', year)
  statcast_table <- paste0('pitcher_statcast_counts_', year)
  
  pitcher_statsapi_df <- get_data_from_database(statsapi_table)
  pitcher_statcast_df <- get_data_from_database(statcast_table)
  
  pitcher_identifier_df <- create_pitcher_identifier_df(pitcher_statsapi_df)
  
  prepared_pitcher_stat_counts_df <- prepare_pitcher_stats_counts_df(pitcher_statsapi_df, pitcher_statcast_df)
  
  prepared_pitcher_stat_counts_df <- process_pitcher_statcast_small_sample_size_pitchers(prepared_pitcher_stat_counts_df)
  
  max_year <- current_year
  multiplier <- 5
  
  if (max_year - year == 2) {
    multiplier <- 2
  } else if (max_year - year == 1) {
    multiplier <- 3
  } else {
    multiplier <- 5
  }
  
  prepared_pitcher_stat_counts_df <- process_pitcher_statcast_decay(prepared_pitcher_stat_counts_df, multiplier = multiplier)
  
  final_pitcher_stat_counts_df <- pitcher_identifier_df %>%
    inner_join(
      prepared_pitcher_stat_counts_df,
      by = ('xMLBAMID')
    )
  
  pitcher_stats_counts_df_list[[length(pitcher_stats_counts_df_list) + 1]] <- final_pitcher_stat_counts_df    
  
}

pitcher_stat_counts_df <- bind_rows(pitcher_stats_counts_df_list)    
    
complete_pitcher_stats_df <- process_pitcher_statcast_stats(pitcher_stat_counts_df)
    
    
complete_pitcher_stats_df   
    
    
    
    
    
    
