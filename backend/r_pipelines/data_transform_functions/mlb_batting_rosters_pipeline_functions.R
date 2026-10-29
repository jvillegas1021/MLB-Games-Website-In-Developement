create_mlb_batting_rosters_gameday <- function(mlb_team_df, current_season, game_date, roster_type_pulled) {
  
  if (nrow(mlb_team_df) == 0 || length(mlb_team_df) == 0) {
    return(tibble()) 
  }
  
  mlb_batting_rosters_list <- c()
  
  for (row in 1:nrow(mlb_team_df)) {
    team_id <- as.character(mlb_teams[row, 2])
    team_name <- mlb_teams[row, 3]
    team_abbv <- mlb_teams[row, 8]
    season <- as.character(mlb_teams[row, 5])
    
    mlb_team <- mlb_rosters(team_id = team_id, season = current_season, date = game_date, roster_type = roster_type_pulled)
    
    batting_lineup_xmlbamid_ids <- mlb_team %>%
      filter(position_code != 1) %>%
      pull(person_id) %>% 
      as.character()
    
    lineup_str <- paste(batting_lineup_xmlbamid_ids, collapse = ",")
    
    mlb_batting_roster <- data.frame(team_id = team_id,
                                     team_name = team_name,
                                     team_abbv = team_abbv,
                                     season = season,
                                     roster_date = game_date,
                                     roster_type = roster_type_pulled,
                                     roster_lineup_ids = lineup_str,
                                     update_date = Sys.Date())
    
    mlb_batting_rosters_list[[length(mlb_batting_rosters_list) + 1]] <- mlb_batting_roster
  }
  
 
  mlb_batting_roster_final <- bind_rows(mlb_batting_rosters_list)
  
  return(mlb_batting_roster_final)
}