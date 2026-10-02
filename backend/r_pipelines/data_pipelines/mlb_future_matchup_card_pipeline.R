
mlb_future_matchup_card_pipeline <- function(game_date = as.Date(format(Sys.time(), tz = "America/New_York"))) {
  
  historical_matchup_df <- get_data_from_database('historical_matchup_df')
  
  today_date <- Sys.Date()
  three_day_future_date <- today_date + 3
  
  mlb_dates_list <- seq(as.Date(today_date ), as.Date(three_day_future_date), by = "day")
  
  mlb_matchup_card_list <- c()
  
  for (date in mlb_dates_list){
    loop_date_obj <- as.Date(date, origin = "1970-01-01")
    mlb_matchup_card <- mlb_matchup_card_pipeline(loop_date_obj)
    mlb_matchup_card_list[[length(mlb_matchup_card_list) + 1]] <- mlb_matchup_card
  }
  
  combined_mlb_matchup_card <- bind_rows(mlb_matchup_card_list)
  
  pre_game_status_list <- c('Scheduled', 'Pre-Game', 'Warmup')
  
  mlb_matchup_card_not_started <- combined_mlb_matchup_card %>%
    filter(
      (Game_Status %in% pre_game_status_list)
    )
  
  games_to_update_id_list <- mlb_matchup_card_not_started$Game_ID
  
  if (length(games_to_update_id_list) > 0) {
    delete_games_from_historical_matchup_df('historical_matchup_df', games_to_update_id_list)
    write_df_to_sql_append('historical_matchup_df', mlb_matchup_card_not_started)
  }
  
  write_df_to_sql_replace('mlb_matchup_card', mlb_matchup_card_not_started)
  
  return(invisible())
}