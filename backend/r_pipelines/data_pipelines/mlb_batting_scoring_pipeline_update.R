mlb_team_batting_scores_pipeline <- function() {
  

  # extract data and merge
  
  team_batting_database_df = get_data_from_database('mlb_team_batting_stats')
  team_batting_database_df <- add_team_abbv_using_team_name(team_batting_database_df)
  
  team_batting_fg_df = fg_team_batter(startseason = 2026, endseason = 2026)
  team_batting_fg_df <- team_batting_fg_df %>%
    select(
    team_name_abb,
    R
  )
  
  all_team_batting_df <- team_batting_database_df %>%
    left_join(
      team_batting_fg_df,
      by=c('team_abbv' = 'team_name_abb')
    )
  # transform data
  final_team_scores_df = calculate_roster_batting_scores(all_team_batting_df)
  
  # load data
  write_df_to_sql_replace('mlb_team_batting_scores', final_team_scores_df)

} 













