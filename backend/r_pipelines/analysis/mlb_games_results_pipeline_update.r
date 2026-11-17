
mlb_games_results_pipeline <- function() {
  
  mlb_historical_results_df <- get_data_from_database('mlb_games_results')
  
  season_dates <- seq(as.Date("2026-03-25"), as.Date("2026-11-02"), by = "day")
  
  game_results_list <- c()
  
  for (d in season_dates) {
    # 1. Re-construct a completely unambiguous Date object from the loop index
    loop_date_obj <- as.Date(d, origin = "1970-01-01")
    
    print(paste0('Processing game date ', loop_date_obj))
    
    games_table <- get_mlb_games(loop_date_obj)
    
    if (is.null(games_table) || nrow(games_table) == 0) {
      message("No MLB games for this date. Pipeline exiting.")
      next
    }
    
    matchup_df <- create_matchup_df(games_table)
    
    results_df <- create_results_df(matchup_df)
    
    if (nrow(results_df) == 0) {
      message("No new valid MLB results to insert.")
      next
    }
    
    game_results_list[[length(game_results_list) + 1]] <- results_df
  }
  
  all_results_df <- bind_rows(game_results_list)
  
  
  cleaned_final_results_df <- all_results_df %>%
    drop_na(Home_Team_Score, Away_Team_Score)
  
  historical_game_ids <- mlb_historical_results_df$Game_ID
  
  final_results_df <- cleaned_final_results_df %>%
    filter(!(Game_ID %in% historical_game_ids))
  
  if (nrow(final_results_df) == 0) {
    message("No new valid MLB results to insert.")
    return(invisible(NULL))
  }
  
  write_df_to_sql_append('mlb_games_results', cleaned_final_results_df)
  
}



