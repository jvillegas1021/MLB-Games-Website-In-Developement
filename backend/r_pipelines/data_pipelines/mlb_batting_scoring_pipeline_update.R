mlb_team_batting_scores_pipeline <- function() {
  

  # extract data and merge
  
  team_batting_df = get_data_from_database('mlb_team_batting_stats')
  
  # transform data
  final_team_scores_df = calculate_roster_batting_scores(team_batting_df)
  
  # load data
  write_df_to_sql_replace('mlb_team_batting_scores', final_team_scores_df)

} 













