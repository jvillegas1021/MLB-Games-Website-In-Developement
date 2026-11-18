update_pitcher_overall_stats <- function(current_year = as.numeric(format(Sys.Date(), '%Y'))) {
  
  historical_table_name <- paste0('pitcher_overall_stats_', current_year)
  
  year_range <- seq(from = current_year, to = (current_year - 2))
  
  pitcher_stats_counts_df_list <- c()
  
  for (year in year_range) {
    
    statsapi_table <- paste0('pitcher_statsapi_counts_', year)
    statcast_table <- paste0('pitcher_statcast_counts_', year)
    
    pitcher_statsapi_df <- get_data_from_database(statsapi_table)
    pitcher_statcast_df <- get_data_from_database(statcast_table)
    
    pitcher_identifier_df <- create_pitcher_identifier_df(pitcher_statsapi_df, pitcher_statcast_df)
    
    prepared_pitcher_stat_counts_df <- prepare_pitcher_stats_counts_df(pitcher_statsapi_df, pitcher_statcast_df)
    
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
  
  processed_pitcher_stats_df <- process_pitcher_statcast_stats(pitcher_stat_counts_df)
  
  sample_sized_pitcher_stats_df <- process_pitcher_statcast_small_sample_size_pitchers(processed_pitcher_stats_df)
  
  pitchers_to_update <- sample_sized_pitcher_stats_df$xMLBAMID
  
  delete_pitcher_stats_from_df(historical_table_name, pitchers_to_update)
  
  write_df_to_sql_append(sample_sized_pitcher_stats_df, historical_table_name)

}