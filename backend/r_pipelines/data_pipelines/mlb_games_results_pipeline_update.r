mlb_games_results_pipeline <- function(game_date = as.Date(format(Sys.time(), tz = "America/New_York"))) {
  ######## Previous day mlb game results ##############
  previous_date <- game_date - 1
  games_table <- get_mlb_games(previous_date)
  
  if (is.null(games_table) || nrow(games_table) == 0) {
    message("No MLB games for this date. Pipeline exiting.")
    return(invisible(NULL))
  }
  
  ############ pull pushed results from  data base ##########
  historical_mlb_games_results <- get_data_from_database('mlb_games_results')
  ############# create results df ###########################
  results_df <- create_results_df(games_table)
  ############### check if valid / new results ##############
  results_final_df <- check_valid_results_df(results_df, historical_mlb_games_results)
  ################ empty df guard ######################
  if (nrow(results_final_df) == 0) {
    message("No new valid MLB results to insert.")
    return(invisible(NULL))
  }
  ############## push to data base #####################
  write_df_to_sql_append('mlb_games_results', results_final_df)
  
}

