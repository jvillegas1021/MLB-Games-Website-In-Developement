update_mlb_teams_batting_stats_gameday <- function(game_date = as.Date(format(Sys.time(), tz = "America/New_York")),
                                                   current_season = as.numeric(format(Sys.Date(), "%Y")),
                                                   sports_id = 1,
                                                   mlb_batting_roster_gameday_df,
                                                   batter_stats_statcast_df,
                                                   mlb_teams) {
  
  
  print(paste0("Processing ", game_date, ", ", current_season))
  # extract batting_rosters_gameday
  if (is.null(mlb_batting_roster_gameday_df) || nrow(mlb_batting_roster_gameday_df) == 0) {
    mlb_batting_roster_gameday_df <- get_data_from_database('mlb_batting_rosters_gameday')
  } else {
    mlb_batting_roster_gameday_df <- mlb_batting_roster_gameday_df
  }
  # extract statcast data
  if (is.null(batter_stats_statcast_df) || nrow(batter_stats_statcast_df) == 0) {
    batter_stats_statcast_df <- get_data_from_database('batter_seasonal_data_statcast')
  } else {
    batter_stats_statcast_df <- batter_stats_statcast_df
  }
  # extract teams
  if (is.null(mlb_teams) || nrow(mlb_teams) == 0) {
    mlb_teams <- mlb_teams(season = current_season, sport_ids = sports_id)
  } else {
    mlb_teams <- mlb_teams
  }
  #process data
  mlb_teams_batting_df <- create_mlb_teams_batting_df(game_date,
                                                      mlb_batting_roster_gameday_df,
                                                      batter_stats_statcast_df,
                                                      mlb_teams)
  # load data
  write_df_to_sql_append('mlb_team_batting_stats_gameday', mlb_teams_batting_df)
  
  print(paste0("Completed ", game_date, ", ", current_season))
}
