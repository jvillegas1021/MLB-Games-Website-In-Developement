##################### create currated results df ########################
create_curated_results_df <- function(mlb_games_results_df, historical_matchup_df) {
  
  mlb_games_results_df <- mlb_games_results_df %>%
    select(
      Game_ID,
      Home_Team,
      Home_Team_Runs,
      Home_Team_Is_Winner,
      Away_Team,
      Away_Team_Runs,
      Away_Team_Is_Winner)
  
  curated_results_df <- historical_matchup_df %>%
    left_join(
      mlb_games_results_df,
      by=c('Game_ID', 'Home_Team', 'Away_Team'),
      relationship='many-to-many'
    ) %>%
    mutate(
      Winner = if_else(
        Home_Team_Is_Winner == TRUE, Home_Team, Away_Team
      ),
      Correct_Prediction = if_else(
        Predicted_Winner == Winner, TRUE, FALSE
      )
    ) %>%
    drop_na(Correct_Prediction)
  
  return(curated_results_df)
  
}

############## calcualte overall pick accuracy ###############
calculate_overall_pick_accuracy <- function(curated_results_df, final_results_df) {
  
  total_overall_picks <- nrow(curated_results_df)
  total_correct_picks <- sum(curated_results_df$Correct_Prediction)
  
  correct_pick_percentage <- round((total_correct_picks / total_overall_picks) * 100, 2)
  
  final_results_df$overall_picks <- total_overall_picks
  final_results_df$overall_correct_picks <- total_correct_picks
  final_results_df$overall_accuracy <- correct_pick_percentage
  
  return(final_results_df)
}

################ calculate betting accuracy picks ##############
calculate_overall_betting_accuracy <- function(curated_results_df, final_results_df) {
  betting_edge_df <- curated_results_df %>%
    filter(
      Place_Bet_Home_Current | Place_Bet_Away_Current
    ) %>%
    mutate(
      Correct_Bet = if_else(
        Bet_Team_Current == Winner, TRUE, FALSE
      )
    )
  
  total_bets_placed <- nrow(betting_edge_df)
  total_correct_bets_placed <- sum(betting_edge_df$Correct_Bet)
  
  correct_bet_percentage <- round((total_correct_bets_placed / total_bets_placed) * 100, 2)
  
  final_results_df$bets_placed <- total_bets_placed
  final_results_df$correct_bets_placed <- total_correct_bets_placed
  final_results_df$betting_accuracy <- correct_bet_percentage
  
  return(final_results_df)
}


################## calculate underdog accuracy picks ###############
calculate_underdog_accuracy <- function(curated_results_df, final_results_df) {
  underdog_df <- curated_results_df %>%
    drop_na(Underdog_Open) %>%  
    filter(Predicted_Winner == Underdog_Open)   
  
  total_underdog_predictions <- nrow(underdog_df)
  total_correct_underdog_predictions <- sum(underdog_df$Correct_Prediction)
  
  underdog_correct_prediction_percentage <- round(
    (total_correct_underdog_predictions / total_underdog_predictions) * 100,
    2
  )
  
  final_results_df$underdog_predictions <- total_underdog_predictions
  final_results_df$correct_underdog_predictions <- total_correct_underdog_predictions
  final_results_df$underdog_accuracy <- underdog_correct_prediction_percentage
  
  return(final_results_df)
}


################### calculate win prob accuracy ##################
calculate_win_probability_accuracy <- function(curated_results_df, final_results_df) {
  
  win_probability_df <- curated_results_df %>%
    mutate(
      WinProb_Bucket = case_when(
        Win_Probability < 50 ~ "Win_Prob_Under_50",
        Win_Probability >= 50 & Win_Probability < 55 ~ "Win_Prob_50_55",
        Win_Probability >= 55 & Win_Probability < 60 ~ "Win_Prob_55_60",
        Win_Probability >= 60 & Win_Probability < 65 ~ "Win_Prob_60_65",
        Win_Probability >= 65 ~ "Win_Prob_65+"
      )
    )
  
  win_probabilty_bucket_df <- win_probability_df %>%
    group_by(WinProb_Bucket) %>%
    summarise(
      total = n(),
      correct = sum(Correct_Prediction),
      accuracy = round(correct / total * 100, 2)
    ) %>%
    select(WinProb_Bucket, accuracy) %>% 
    pivot_wider(
      names_from = WinProb_Bucket,
      values_from = accuracy
    )
  
  final_results_df <- bind_cols(final_results_df, win_probabilty_bucket_df)
  
  return(final_results_df)
  
}
