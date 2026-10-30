library(tidymodels)
library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgres)
install.packages("tidymodels")
source("backend/r_pipelines/data_extract_functions/extract_data_from_database.r")
source("backend/r_pipelines/data_transform_functions/mlb_prediction_results_pipeline_functions.r")
source("backend/r_pipelines/data_load_functions/load_data_to_database.r")
source("backend/r_pipelines/data_pipelines/mlb_games_prediction_results_pipeline_update.r")

# pull in data
mlb_games_results_df <- get_data_from_database('mlb_games_results')
historical_matchup_df <- get_data_from_database('historical_matchup_df')
curated_results_df <- create_curated_results_df(mlb_games_results_df, historical_matchup_df)
# 1. Prepare your machine learning dataset
ml_data <- curated_results_df %>%
  # Select your numerical predictors and your target variable
  select(
    Home_Team_Is_Winner, # Your target (TRUE/FALSE or 1/0)
    Home_pitcher_expected, Away_pitcher_expected,
    Home_batting_contact, Away_batting_contact,
    Net_Result_Margin, Master_Matchup_Score,
    home_open_odds, away_open_odds
  ) %>%
  # Convert target to a factor for classification modeling
  mutate(Home_Team_Is_Winner = as.factor(Home_Team_Is_Winner)) %>%
  na.omit()

# 2. Split your historical data into Training (80%) and Testing (20%) sets
set.seed(123)
data_split <- initial_split(ml_data, prop = 0.80)
train_data <- training(data_split)
test_data  <- testing(data_split)

# 3. Define a Random Forest Model
rf_spec <- rand_forest(trees = 500, min_n = 10) %>%
  set_engine("ranger", importance = "impurity") %>%
  set_mode("classification")

# 4. Train (Fit) the model using your columns
rf_fit <- rf_spec %>%
  fit(Home_Team_Is_Winner ~ ., data = train_data)

# 5. Predict on your test data to see how it performs
predictions <- predict(rf_fit, test_data, type = "prob") %>%
  bind_cols(test_data)

print(predictions)