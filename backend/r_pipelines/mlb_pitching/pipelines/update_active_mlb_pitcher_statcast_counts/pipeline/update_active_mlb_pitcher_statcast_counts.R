update_active_mlb_pitcher_statcast_counts <- function(current_year = format(Sys.Date(), "%Y")) {
  
  table_year <- current_year
  # extract data 
  
  historical_table_name <- paste0('pitcher_statcast_counts_', table_year)
  current_year_statcast_table_name <- paste0('statcast_', table_year)
  
  current_statcast_year_df <- get_data_from_database(current_year_statcast_table_name)
  
  # update pitcher statcast counts
  
  pitcher_statcast_counts_df <- process_pitcher_statcast_counts(current_statcast_year_df)
  
  pitchers_to_update <- pitcher_statcast_counts_df$xMLBAMID
  
  delete_pitcher_stats_from_df(historical_table_name, pitchers_to_update)
  
  write_df_to_sql_append(pitcher_statcast_counts_df, historical_table_name)
  
}