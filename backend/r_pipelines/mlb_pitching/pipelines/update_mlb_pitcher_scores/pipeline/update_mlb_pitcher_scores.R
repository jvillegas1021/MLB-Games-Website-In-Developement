mlb_pitcher_scores_pipeline <- function(current_year = as.numeric(format(Sys.Date(), '%Y'))) {
  
  # extract data and merge
  current_stats_table_name <- paste0('pitcher_overall_stats_', current_year)
  
  pitcher_database_df <- get_data_from_database(current_stats_table_name)
  
  pitcher_fg_df <- fg_pitcher_leaders(startseason = current_year, endseason = current_year)
  
  pitcher_fg_df <- pitcher_fg_df %>%
    select(xMLBAMID, SIERA) %>%
    mutate(xMLBAMID = as.character(xMLBAMID))
  
  complete_pitcher_stats <- pitcher_database_df %>%
    left_join(
      pitcher_fg_df,
      by=('xMLBAMID'))
  
  complete_pitcher_stats <- assign_pitcher_role(complete_pitcher_stats)
  # transform data
  starting_pitcher_df <- complete_pitcher_stats %>% filter(pitcher_role == 'starter')
  reliever_pitcher_df <- complete_pitcher_stats %>% filter(pitcher_role == 'reliever')
  hybrid_pitcher_df <- complete_pitcher_stats %>% filter(pitcher_role == 'hybrid')
    
  
  final_starter_scores_df = calculate_pitcher_scores(starting_pitcher_df)
  final_reliever_scores_df = calculate_pitcher_scores(reliever_pitcher_df)
  final_hyrbid_scores_df = calculate_pitcher_scores(hybrid_pitcher_df)
    
  
  final_pitcher_scores_df = bind_rows(final_starter_scores_df,
                                      final_reliever_scores_df,
                                      final_hyrbid_scores_df)
  
  
  pitcher_scores_table_name <- paste0("mlb_pitcher_scores_", current_year)
  write_df_to_sql_append(final_pitcher_scores_df, pitcher_scores_table_name)
  
} 

