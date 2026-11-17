update_active_mlb_batter_statcast_counts <- function(current_year = format(Sys.Date(), "%Y")) {
  
  table_year <- current_year
  # extract data 
  
  historical_table_name <- paste0('batter_statcast_counts_', table_year)
  current_year_statcast_table_name <- paste0('statcast_', table_year)
  
  current_statcast_year_df <- tryCatch(
    get_data_from_database(current_year_statcast_table_name),
    error = function(e) {
      message("Table not found: ", current_year_statcast_table_name)
      NULL
    }
  )
  
  if (is.null(current_statcast_year_df)) {
    print("Statcast data not available.")
    return(invisible())
  }
  
  historical_statcast_counts_df <- tryCatch(
    get_data_from_database(historical_table_name),
    error = function(e) {
      message("Table not found: ", historical_table_name)
      NULL
    }
  )
  
  batter_statcast_counts_df <- process_batter_statcast_counts(current_statcast_year_df)
  
  if (!is.null(historical_statcast_counts_df)) {
    batter_to_update <- batter_statcast_counts_df$xMLBAMID
    
    delete_batter_stats_from_df(historical_table_name, batter_to_update)
  }
  
  write_df_to_sql_append(batter_statcast_counts_df, historical_table_name)
  
}