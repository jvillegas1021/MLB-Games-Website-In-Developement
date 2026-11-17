update_active_mlb_batter_statsapi_counts <- function(current_year = format(Sys.Date(), "%Y")) {
  
  table_year <- current_year
  historical_table_name <- paste0('batter_statsapi_counts_', table_year)
  active_batter_table_name <- paste0('active_mlb_batters_', table_year)
  #extract data 
  active_mlb_batters_df <- tryCatch(
    get_data_from_database(active_batter_table_name),
    error = function(e) {
      message("Table not found: ", active_batter_table_name)
      NULL
    }
  )
  
  if (is.null(active_mlb_batters_df)) {
    print("Active MLB batters table is empty, exiting.")
    return(invisible())
  }

  historical_mlb_batter_statsapi_counts_df <- tryCatch(
    get_data_from_database(historical_table_name),
    error = function(e) {
      message("Table not found: ", historical_table_name)
      NULL
    }
  )
  # update batter statsapi counts
  
  active_batter_list <- active_mlb_batters_df$xMLBAMID
  
  active_batter_statsapi_counts_df_list <- list()
  
  for (batter in active_batter_list) {
    batter_statsapi_counts_df <- get_batter_season_stats(batter, current_year)
    batter_statsapi_counts_df <- batter_statsapi_counts_df %>%
      mutate(update_date = Sys.Date())
    active_batter_statsapi_counts_df_list[[length(active_batter_statsapi_counts_df_list) + 1]] <- batter_statsapi_counts_df
  }
  
  final_batter_statsapi_counts_df <- bind_rows(active_batter_statsapi_counts_df_list)
  
  if (!is.null(historical_mlb_batter_statsapi_counts_df)) {
    batters_to_update <- final_batter_statsapi_counts_df$xMLBAMID
    delete_batter_stats_from_df(historical_table_name, batters_to_update)
  }
  
  write_df_to_sql_append(final_batter_statsapi_counts_df, historical_table_name)
  
}

