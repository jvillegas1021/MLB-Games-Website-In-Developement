library(tidymodels)
library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgres)
library(xgboost)

source("backend/r_pipelines/data_extract_functions/extract_data_from_database.r")
source("backend/r_pipelines/data_transform_functions/mlb_prediction_results_pipeline_functions.r")
source("backend/r_pipelines/data_load_functions/load_data_to_database.r")
source("backend/r_pipelines/data_pipelines/mlb_games_prediction_results_pipeline_update.r")

historical_matchup_df <- get_data_from_database('historical_matchup_df')



historical_matchup_df <- historical_matchup_df %>%
  mutate(Home_Team_Is_Winner = if_else(Home_Team_Is_Winner == TRUE, 1, 0)) %>%
  drop_na(Home_Team_Is_Winner)


min(historical_matchup_df$Game_Date)
max(historical_matchup_df $Game_Date)


training_df <- historical_matchup_df %>%
  filter(Game_Date <= '2026-08-31')

testing_df <- historical_matchup_df %>%
  filter(Game_Date > '2026-08-31')

feature_columns <- c(
  "Net_Discipline_Margin", "Net_Power_Margin", "Net_Expected_Margin", 
  "Master_Matchup_Score",
  "Home_Offense_Edge_Disc", "Away_Offense_Edge_Disc",
  "Home_Offense_Edge_Pow", "Away_Offense_Edge_Pow",
  "Home_Offense_Edge_Exp", "Away_Offense_Edge_Exp"
)

X_train <- as.matrix(training_df[, feature_columns])
X_test <- as.matrix(testing_df[, feature_columns])

y_train <- training_df$Home_Team_Is_Winner
y_test <- testing_df$Home_Team_Is_Winner

dtrain <- xgb.DMatrix(data = X_train, label = y_train)

params <- list(
  objective = "binary:logistic",
  max_depth = 3,
  learning_rate = 0.05)

xgb_model <- xgb.train(
  params = params,
  data = dtrain,
  nrounds = 100,
  verbose = 0)

test_predictions <- predict(xgb_model, X_test)

testing_df$XGB_Win_Probability <- test_predictions


testing_df <- testing_df %>%
  mutate(
    Original_Home_Win_Prob = if_else(
      # If your system picked the Home Team, keep the probability as-is
      # (Assuming Home_Team matches your exact column name for the home team's name!)
      Predicted_Winner == Home_Team, 
      Win_Probability / 100, 
      (100 - Win_Probability) / 100
    ),
    Winner = if_else(Home_Team_Is_Winner == 1, Home_Team, Away_Team),
    old_model_correct = if_else(Predicted_Winner == Winner, 1, 0),
    new_model_pick = if_else(XGB_Win_Probability >= 0.50, Home_Team, Away_Team),
    new_model_correct = if_else(new_model_pick == Winner, 1, 0)
  )

results_df <- testing_df %>%
  select(Game_Date,
         Home_Team,
         Away_Team,
         Predicted_Winner,
         Win_Probability,
         Original_Home_Win_Prob,
         XGB_Win_Probability,
         Winner,
         Home_Team_Is_Winner,
         old_model_correct,
         new_model_correct)


new_model_avg = mean(results_df$new_model_correct)
old_model_avg = mean(results_df$old_model_correct)

new_model_avg
old_model_avg


# 1. Calculate which features the model used the most
importance_matrix <- xgb.importance(
  feature_names = feature_columns, 
  model = xgb_model
)

# 2. Print out the raw text table to see the exact numbers
print(importance_matrix)

# 3. Create a clean bar chart to see them ranked visually
xgb.plot.importance(importance_matrix)



