mlb_pitcher_scores_pipeline <- function() {
  
  
  # extract data and merge
  
  pitcher_df <- get_data_from_database('active_pitcher_stats_v2')
  
  # transform data
  starting_pitcher_df <- filter_starting_pitcher(pitcher_df)
  final_starting_pitcher_scores_df = calculate_pitcher_scores(starting_pitcher_df)
    
  hybrid_pitcher_df <- filter_hybrid_pitcher(pitcher_df)
  final_hybrid_scores_df = calculate_pitcher_scores(hybrid_pitcher_df)
    
  relief_pitcher_df <- filter_relief_pitcher(pitcher_df)
  final_relief_scores_df = calculate_pitcher_scores(relief_pitcher_df)
    
  
  final_pitcher_scores_df = rbind(final_starting_pitcher_scores_df,
                                  final_hybrid_scores_df,
                                  final_relief_scores_df)
  
  # load data
  write_df_to_sql_replace('mlb_pitcher_scores', final_pitcher_scores_df)
  
} 













