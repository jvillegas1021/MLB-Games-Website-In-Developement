mlb_games_results_pipeline <- function(game_date = as.Date(format(Sys.time(), tz = "America/New_York"))) {
  
  previous_date <- game_date - 1
  games_table <- get_mlb_games(previous_date)
  
  if (is.null(games_table) || nrow(games_table) == 0) {
    message("No MLB games for this date. Pipeline exiting.")
    return(invisible(NULL))
  }
  

  results_df <- create_results_df(games_table)
  write_df_to_sql_append('mlb_games_results', results_df)
  
}

