update_active_mlb_pitcher_statcast_counts <- function(current_year = format(Sys.Date(), "%Y")) {
  
  table_year <- current_year
  # extract data 
  
  historical_table_name <- paste0('pitcher_statcast_counts_', table_year)
  active_pitcher_table_name <- paste0('active_mlb_pitchers_', table_year)
  current_year_statcast_table_name <- paste0('statcast_', table_year)

  active_mlb_pitchers_df <- get_data_from_database(active_pitcher_table_name)
  current_statcast_year_df <- get_data_from_database(current_year_statcast_table_name)
  
  # update pitcher statcast counts
  
  active_pitcher_list <- active_mlb_pitchers_df$xMLBAMID
  
  pitcher_statcast_counts_df <- process_pitcher_statcast_counts(current_statcast_year_df, active_pitcher_list)
  
  pitchers_to_update <- pitcher_statcast_counts_df$xMLBAMID
  
  delete_pitcher_stats_from_df(historical_table_name, pitchers_to_update)
  
  write_df_to_sql_append(pitcher_statcast_counts_df, historical_table_name)
  
}