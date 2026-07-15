
mlb_games_prediction_results_pipeline <- function() {
  # pull in data
  mlb_games_results_df <- get_data_from_database('mlb_games_results')
  historical_matchup_df <- get_data_from_database('historical_matchup_df')
  
  # process data
  curated_results_df <- create_curated_results_df(mlb_games_results_df, historical_matchup_df)
 
  # create final_results_df 
  final_results_df <- data.frame(update_date = Sys.time())
  
  final_results_df <- calculate_overall_pick_accuracy(curated_results_df, final_results_df)
  
  final_results_df <- calculate_overall_betting_accuracy(curated_results_df, final_results_df)
  
  final_results_df <- calculate_win_probability_accuracy(curated_results_df, final_results_df)
  
  # push data to database
  
  write_df_to_sql_replace('mlb_games_prediction_results', final_results_df)
  
}
