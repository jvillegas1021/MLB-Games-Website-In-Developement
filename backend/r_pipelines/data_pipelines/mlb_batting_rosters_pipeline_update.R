

update_mlb_batting_rosters_gameday <- function(game_date = as.Date(format(Sys.time(), tz = "America/New_York"))) {
  #set parameters
  current_season <- substr(game_date, start = 1, stop = 4)
  baseball_sport_id <- 1
  roster_type_pulled <- 'gameday'
  
  
  #extract mlb teams
  mlb_teams <- mlb_teams(season = current_season, sport_ids = baseball_sport_id)
  
  #create mlb_team_batting_rosters
  mlb_batting_roster_final <- create_mlb_batting_rosters_gameday(mlb_teams, current_season, game_date, roster_type_pulled)
  
  if (nrow(mlb_batting_roster_final) == 0 || length(mlb_batting_roster_final) == 0) {
    return(invisible())
  }
  
  #load to database
  write_df_to_sql_append('mlb_batting_rosters_gameday', mlb_batting_roster_final)
}


