update_active_mlb_pitcher_statsapi_counts <- function(current_year = format(Sys.Date(), "%Y")) {
  
  table_year <- current_year
  historical_table_name <- paste0('pitcher_statsapi_counts_', table_year)
  active_pitcher_table_name <- paste0('mlb_pitchers_', table_year)
  #extract data 
  active_mlb_pitchers_df <- get_data_from_database(active_pitcher_table_name)
  historical_mlb_pitcher_statsapi_counts_df <- (historical_table_name)
  
  # update pitcher statsapi counts
  
  active_pitcher_list <- active_mlb_pitchers_df$xMLBAMID
  
  active_pitcher_statsapi_counts_df_list <- list()
  
  for (pitcher in active_pitcher_list) {
    pitcher_statsapi_counts_df <- get_pitcher_season_stats(pitcher, current_year)
    pitcher_statsapi_counts_df <- pitcher_statsapi_counts_df %>%
      mutate(update_date = Sys.Date())
    active_pitcher_statsapi_counts_df_list[[length(active_pitcher_statsapi_counts_df_list) + 1]] <- pitcher_statsapi_counts_df
  }
  
  final_pitcher_statsapi_counts_df <- bind_rows(active_pitcher_statsapi_counts_df_list)
  
  pitchers_to_update <- final_pitcher_statsapi_counts_df$xMLBAMID
  
  delete_pitcher_stats_from_df(historical_table_name, pitchers_to_update)
  
  write_df_to_sql_append(final_pitcher_statsapi_counts_df, historical_table_name)
  
}

