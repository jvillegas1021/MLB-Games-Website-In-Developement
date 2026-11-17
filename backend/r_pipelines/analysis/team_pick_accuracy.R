library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgres)
library(ggplot2)

source("backend/r_pipelines/data_extract_functions/extract_data_from_database.r")
source("backend/r_pipelines/data_transform_functions/mlb_prediction_results_pipeline_functions.r")
source("backend/r_pipelines/data_load_functions/load_data_to_database.r")
source("backend/r_pipelines/data_pipelines/mlb_games_prediction_results_pipeline_update.r")

mlb_games_results_df <- get_data_from_database('mlb_games_results')
historical_matchup_df <- get_data_from_database('historical_matchup_df')

# process data
curated_results_df <- create_curated_results_df(mlb_games_results_df, historical_matchup_df)

# 1. Home Perspective (Your code with two small additions)
home_team_df <- curated_results_df %>%
  select(
    Game_ID,
    Team = Home_Team,               # <-- Renamed to 'Team'
    Predicted_Winner,
    Actual_Winner = Home_Team_Is_Winner
  ) %>%
  mutate(
    Predicted_To_Win = if_else(Predicted_Winner == Team, TRUE, FALSE),
    Actual_Win = if_else(Actual_Winner == 1, TRUE, FALSE), # Converts 1/0 to TRUE/FALSE
    Location = "Home"               # <-- Added visual label
  )

# 2. Away Perspective (The matching twin dataset)
away_team_df <- curated_results_df %>%
  select(
    Game_ID,
    Team = Away_Team,               # <-- Renamed to 'Team'
    Predicted_Winner,
    # If Home Team didn't win, the Away Team did (assuming no ties in baseball)
    Actual_Winner = Home_Team_Is_Winner 
  ) %>%
  mutate(
    Predicted_To_Win = if_else(Predicted_Winner == Team, TRUE, FALSE),
    Actual_Win = if_else(Actual_Winner == 0, TRUE, FALSE), # If Home lost, Away won
    Location = "Away"               # <-- Added visual label
  )


evaluation_df <- bind_rows(home_team_df, away_team_df)

results_df <- evaluation_df %>%
  group_by(Team) %>%
  summarise(
    Total_Games = n(),
    
    # 1. Track how often you pick them to win vs. lose
    Predicted_Wins = sum(Predicted_To_Win == TRUE),
    Predicted_Losses = sum(Predicted_To_Win == FALSE),
    
    # 2. Track your exact wins and losses (Confusion Matrix elements)
    True_Positives  = sum(Predicted_To_Win == TRUE  & Actual_Win == TRUE),  # Picked to win, they won
    False_Positives = sum(Predicted_To_Win == TRUE  & Actual_Win == FALSE), # Picked to win, they lost
    True_Negatives  = sum(Predicted_To_Win == FALSE & Actual_Win == FALSE), # Picked to lose, they lost
    False_Negatives = sum(Predicted_To_Win == FALSE & Actual_Win == TRUE),  # Picked to lose, they won
    
    # 3. Calculate your specialized accuracy rates
    Overall_Accuracy = round((True_Positives + True_Negatives) / Total_Games * 100, 2),
    Win_Pick_Accuracy = round(True_Positives / (True_Positives + False_Positives) * 100, 2),
    Loss_Pick_Accuracy = round(True_Negatives / (True_Negatives + False_Negatives) * 100, 2)
  ) %>%
  arrange(desc(Overall_Accuracy)) # Ranks your best predicted teams at the top

# View the final dataset

# Fix syntax and reorder teams from highest to lowest accuracy
team_plot <- ggplot(
  results_df, 
  aes(x = reorder(Team, Overall_Accuracy), y = Overall_Accuracy)
) + 
  geom_point(color = "#002D62", size = 4) + # Creates the dots
  coord_flip() + # Flips the chart horizontally so team names don't overlap
  labs(
    title = "MLB Prediction Model: Overall Accuracy by Team",
    x = "Team",
    y = "Overall Accuracy (%)"
  ) +
  theme_minimal()

# Display the plot
print(team_plot)