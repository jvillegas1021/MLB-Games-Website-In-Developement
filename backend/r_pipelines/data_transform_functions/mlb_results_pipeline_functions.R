################### CREATE MLB RESULTS DF ########################
create_results_df <- function(games_table_df) {
  
  results_df <- games_table_df %>%
    select(
      gamePk,
      officialDate,
      status.detailedState,
      seriesGameNumber,
      venue.name,
      gameDate,
      dayNight,
      teams.home.team.name,
      teams.home.team.id,
      teams.home.score,
      teams.home.isWinner,
      teams.away.team.name,
      teams.away.team.id,
      teams.away.score,
      teams.away.isWinner
    ) %>%
    rename(
      Game_ID = gamePk,
      Game_Date = officialDate,
      Game_Status = status.detailedState,
      Game_In_Series = seriesGameNumber,
      Game_Venue = venue.name,
      Game_Time = gameDate,
      Day_Night = dayNight,
      Home_Team = teams.home.team.name,
      Home_Team_ID = teams.home.team.id,
      Home_Team_Runs = teams.home.score,
      Home_Team_Is_Winner = teams.home.isWinner,
      Away_Team = teams.away.team.name,
      Away_Team_ID = teams.away.team.id,
      Away_Team_Runs = teams.away.score,
      Away_Team_Is_Winner = teams.away.isWinner
    ) %>%
    mutate(
      Game_ID = as.character(Game_ID),
      update_date = Sys.time()
    )
  
  return(results_df)
  
}

################### CHECK VALID OR NEW GAME IDS FOR REULTS DF ################
check_valid_results_df <- function(results_df, historical_results_df) {
  
  historical_game_ids <- historical_results_df$Game_ID
  not_finished_games <- c('Postponed', 'Cancelled')
  
  results_final_df <- results_df %>%
    filter(
      (!(Game_ID %in% historical_game_ids)),
      (!(Game_Status %in% not_finished_games))
    )
  
  return(results_final_df)
  
}
