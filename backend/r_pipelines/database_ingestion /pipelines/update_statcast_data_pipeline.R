
update_statcast_data <- function(current_date = Sys.Date()) {
  
  # 1. Ensure current_date is always a Date object (fixes string input error)
  current_date <- as.Date(current_date)
  current_year <- format(current_date, '%Y')
  table_name <- paste0('statcast_', current_year)
  
  start_date <- current_date - 2
  end_date <- current_date
  date_range_list <- seq.Date(from = start_date, by = 1, to = end_date)
  
  # 2. Pull data first
  statcast_df <- statcast_search_pitchers(start_date = start_date, end_date = end_date)
  
  # 3. Guard against empty pulls before touching the database
  if (is.null(statcast_df) || nrow(statcast_df) == 0) {
    message(sprintf("No Statcast data returned for %s to %s. Skipping update.", start_date, end_date))
    return(invisible(FALSE))
  }
  
  cleaned_statcast_df <- process_statcast_df(statcast_df)
  
  # 4. Delete overlapping window and append fresh rows using the same table_name
  delete_statcast_rows_from_df(table_name, date_range_list)
  write_df_to_sql_append(cleaned_statcast_df, table_name)
  
  return(invisible(TRUE))
}

