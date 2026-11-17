update_active_mlb_batters <- function(current_year = format(Sys.Date(), "%Y")) {
  
  table_name <- paste0('active_mlb_batters_', current_year)
  batter_df <- get_all_active_mlb_batters()
  write_df_to_sql_replace(batter_df, table_name)
  
}