update_mlb_pitchers <- function(current_year = format(Sys.Date(), "%Y")) {
  
  table_name <- paste0('mlb_pitchers_', current_year)
  pitcher_df <- get_all_pitchers()
  write_df_to_sql_replace(pitcher_df, table_name)
  
}