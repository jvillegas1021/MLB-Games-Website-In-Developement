mlb_team_pick_accuracy_pipeline <- function() {
  
  mlb_games_results_df <- get_data_from_database('mlb_games_results')
  historical_matchup_df <- get_data_from_database('historical_matchup_df')
  
  mlb_teams <- mlbplotR::load_mlb_teams()
  
  mlb_teams_cleaned <- mlb_teams %>%
    mutate(
      team_id_num = as.character(team_id_num)
    ) %>%
    select(
      team_abbr,
      team_name,
      team_id_num
    )

  curated_results_df <- create_curated_results_df(mlb_games_results_df, historical_matchup_df)
  
  home_team_df <- curated_results_df %>%
    mutate(
      Home_Team_ID = as.character(Home_Team_ID)
    ) %>%
    select(Team_ID = Home_Team_ID, Team = Home_Team, Predicted_Winner, Actual_Winner = Home_Team_Is_Winner) %>%
    mutate(
      Predicted_To_Win = if_else(Predicted_Winner == Team, TRUE, FALSE),
      Actual_Win = if_else(Actual_Winner == 1, TRUE, FALSE),
      Location = "Home"
    )
  
  away_team_df <- curated_results_df %>%
    mutate(
      Away_Team_ID = as.character(Away_Team_ID)
    ) %>%
    select(Team_ID = Away_Team_ID, Team = Away_Team, Predicted_Winner, Actual_Winner = Home_Team_Is_Winner) %>%
    mutate(
      Predicted_To_Win = if_else(Predicted_Winner == Team, TRUE, FALSE),
      Actual_Win = if_else(Actual_Winner == 0, TRUE, FALSE),
      Location = "Away"
    )
  
  evaluation_df <- bind_rows(home_team_df, away_team_df)
  
  # 1. Calculate the Location Splits (Home vs Away)
  location_splits_wide <- evaluation_df %>%
    group_by(Team, Team_ID, Location) %>%
    summarise(
      Total_Games     = n(),
      True_Positives  = sum(Predicted_To_Win == TRUE  & Actual_Win == TRUE),
      False_Positives = sum(Predicted_To_Win == TRUE  & Actual_Win == FALSE),
      True_Negatives  = sum(Predicted_To_Win == FALSE & Actual_Win == FALSE),
      False_Negatives = sum(Predicted_To_Win == FALSE & Actual_Win == TRUE),
      Accuracy        = round((True_Positives + True_Negatives) / Total_Games * 100, 2),
      Win_Accuracy    = round(True_Positives / max(True_Positives + False_Positives, 1) * 100, 2),
      Loss_Accuracy   = round(True_Negatives / max(True_Negatives + False_Negatives, 1) * 100, 2),
      .groups = "drop"
    ) %>%
    pivot_wider(
      names_from = Location, 
      values_from = c(Total_Games, True_Positives, False_Positives, True_Negatives, False_Negatives, Accuracy, Win_Accuracy, Loss_Accuracy),
      names_glue = "{Location}_{.value}" 
    )
  
  master_summary_df <- evaluation_df %>%
    group_by(Team, Team_ID) %>%
    summarise(
      Total_Games       = n(),
      Predicted_Wins    = sum(Predicted_To_Win == TRUE),
      Predicted_Losses  = sum(Predicted_To_Win == FALSE),
      True_Positives    = sum(Predicted_To_Win == TRUE  & Actual_Win == TRUE),
      False_Positives   = sum(Predicted_To_Win == TRUE  & Actual_Win == FALSE),
      True_Negatives    = sum(Predicted_To_Win == FALSE & Actual_Win == FALSE),
      False_Negatives   = sum(Predicted_To_Win == FALSE & Actual_Win == TRUE),
      Overall_Accuracy  = round((True_Positives + True_Negatives) / Total_Games * 100, 2),
      Win_Pick_Accuracy = round(True_Positives / max(True_Positives + False_Positives, 1) * 100, 2),
      Loss_Pick_Accuracy = round(True_Negatives / max(True_Negatives + False_Negatives, 1) * 100, 2)
    ) %>%
    left_join(location_splits_wide, by = "Team_ID") %>%
    left_join(mlb_teams_cleaned, by = c("Team_ID" = "team_id_num")) %>%
    filter(!team_abbr %in% c("AL", "NL", "MLB")) %>%
    arrange(desc(Overall_Accuracy))
  
  
  write_df_to_sql_replace('mlb_team_pick_accuracy', master_summary_df)
  
  return(invisible())
}

