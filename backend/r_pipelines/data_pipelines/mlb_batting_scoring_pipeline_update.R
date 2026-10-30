mlb_team_batting_scores_pipeline <- function(game_date = as.Date(format(Sys.time(), tz = "America/New_York")),
                                             current_season = as.numeric(format(Sys.Date(), "%Y"))) {
  
  current_gameday = game_date
  # extract data and merge
  
  team_batting_database_df = get_data_from_database('mlb_team_batting_stats_gameday')
  
  team_batting_fg_df = fg_team_batter(startseason = current_season, endseason = current_season)
  team_batting_fg_df <- team_batting_fg_df %>%
    select(
    team_name_abb,
    R
  )
  
  all_team_batting_df <- team_batting_database_df %>%
    left_join(
      team_batting_fg_df,
      by=c('team_abbreviation' = 'team_name_abb')
    ) %>%
    filter(game_date == current_gameday)
  
  # transform data
  final_team_scores_df = calculate_roster_batting_scores(all_team_batting_df)
  
  # load data
  write_df_to_sql_append('mlb_team_batting_scores_gameday', final_team_scores_df)

} 













