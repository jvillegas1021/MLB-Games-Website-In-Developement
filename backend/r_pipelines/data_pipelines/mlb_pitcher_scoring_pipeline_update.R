mlb_pitcher_scores_pipeline <- function() {
  
  
  # extract data and merge
  
  pitcher_database_df <- get_data_from_database('active_pitcher_stats')
  
  pitcher_fg_df <- fg_pitcher_leaders(startseason = 2026, endseason = 2026)
  
  pitcher_fg_df <- pitcher_fg_df %>%
    select(xMLBAMID, SIERA) %>%
    mutate(xMLBAMID = as.character(xMLBAMID))
  
  complete_pitcher_stats <- pitcher_database_df %>%
    left_join(
      pitcher_fg_df,
      by=('xMLBAMID'))
  
  # transform data
  starting_pitcher_df <- filter_starting_pitcher(complete_pitcher_stats)
  final_starting_pitcher_scores_df = calculate_pitcher_scores(starting_pitcher_df)
    
  hybrid_pitcher_df <- filter_hybrid_pitcher(complete_pitcher_stats)
  final_hybrid_scores_df = calculate_pitcher_scores(hybrid_pitcher_df)
    
  relief_pitcher_df <- filter_relief_pitcher(complete_pitcher_stats)
  final_relief_scores_df = calculate_pitcher_scores(relief_pitcher_df)
    
  
  final_pitcher_scores_df = bind_rows(final_starting_pitcher_scores_df,
                                  final_hybrid_scores_df,
                                  final_relief_scores_df)
  
  # load data
  write_df_to_sql_replace('mlb_pitcher_scores', final_pitcher_scores_df)
  
} 

