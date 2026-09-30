library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgres)

source("backend/r_pipelines/data_extract_functions/extract_data_from_database.r")

mlb_game_results_df <- get_data_from_database('mlb_games_results')
mlb_game_results_df_cleaned <- mlb_game_results_df %>%
  select(
    Game_ID,
    Home_Team,
    Home_Team_Runs,
    Away_Team,
    Away_Team_Runs
  )

mlb_prediction_df <- get_data_from_database('historical_matchup_df_v2')

mlb_complete_df <- mlb_prediction_df %>%
  left_join(
    mlb_game_results_df,
    by = c('Game_ID', 'Home_Team', 'Away_Team')
  )

mlb_testing_df <- mlb_complete_df %>%
  # 1. Create clear game outcome metrics
  mutate(
    Run_Differential = Home_Team_Runs - Away_Team_Runs,
    Home_Win         = ifelse(Home_Team_Runs > Away_Team_Runs, 1, 0)
  )

# 5. Isolate our new net game margins to test them
margin_features <- c("Net_Discipline_Margin", "Net_Power_Margin", "Net_Expected_Margin")

# 6. Calculate the correlation against Run Differential and Wins
margin_matrix <- cor(
  mlb_testing_df[, c(margin_features, "Run_Differential", "Home_Win")], 
  use = "complete.obs"
)


margin_matrix
# 7. Format and print the clean results
margin_rankings <- data.frame(
  Margin_Feature = margin_features,
  Run_Diff_Correlation = margin_matrix[margin_features, "Run_Differential"],
  Win_Correlation      = margin_matrix[margin_features, "Home_Win"]
)

print(margin_rankings, row.names = FALSE)

library(glmnet)

# 1. Define the margin features we want to combine into our master score
model_features <- c("Net_Discipline_Margin", "Net_Power_Margin", "Net_Expected_Margin")

# 2. Prepare the data matrices for glmnet (dropping any rows missing data)
clean_model_df <- mlb_testing_df %>% 
  filter(complete.cases(.[, c(model_features, "Run_Differential")]))

X <- as.matrix(clean_model_df[, model_features])
Y <- clean_model_df$Run_Differential

# 3. Run Cross-Validation Ridge Regression (alpha = 0)
cv_ridge <- cv.glmnet(X, Y, alpha = 0, standardize = TRUE)

# 4. Extract the optimized coefficients at the best lambda value
best_lambda <- cv_ridge$lambda.min
model_coefs <- coef(cv_ridge, s = best_lambda)

# 5. Clean up the output to see the true weights
weights_table <- data.frame(
  Feature = rownames(model_coefs)[-1],
  Weight = as.vector(model_coefs)[-1]
)

print(weights_table, row.names = FALSE)

# 1. Apply the regression weights to create a single Master Matchup Score
mlb_backtest_results <- mlb_testing_df %>%
  mutate(
    Master_Matchup_Score = (Net_Discipline_Margin * 0.19793663) + 
      (Net_Power_Margin      * 0.09048099) + 
      (Net_Expected_Margin   * 0.11854899)
  )

# 2. Check the final unified correlation against wins and run differential
final_eval <- cor(
  mlb_backtest_results[, c("Master_Matchup_Score", "Run_Differential", "Home_Win")], 
  use = "complete.obs"
)

# 3. Print the performance summary
cat("=== FINAL MODEL BACKTEST PERFORMANCE ===\n")
cat("Correlation vs Run Differential: ", final_eval["Master_Matchup_Score", "Run_Differential"], "\n")
cat("Correlation vs Pure Game Wins:   ", final_eval["Master_Matchup_Score", "Home_Win"], "\n")


# 1. Determine which team your model would have picked for every game
mlb_backtest_results <- mlb_backtest_results %>%
  mutate(
    # If score is positive, pick Home (1). If negative, pick Away (0).
    Model_Pick = ifelse(Master_Matchup_Score > 0, 1, 0),
    
    # Check if the pick matched the actual outcome (Home_Win is 1 or 0)
    Is_Correct = ifelse(Model_Pick == Home_Win, 1, 0)
  )

# 2. Calculate total record and percentage
total_games   <- nrow(mlb_backtest_results)
correct_picks <- sum(mlb_backtest_results$Is_Correct, na.rm = TRUE)
win_percentage <- (correct_picks / total_games) * 100

# 3. Calculate Home vs Away accuracy breakdown
home_picks <- mlb_backtest_results %>% filter(Model_Pick == 1)
away_picks <- mlb_backtest_results %>% filter(Model_Pick == 0)

# 4. Print your true historical record
cat("=== YOUR HISTORICAL MODEL ACCURACY ===\n")
cat("Total Games Picked: ", total_games, "\n")
cat("Correct Picks:      ", correct_picks, " - Incorrect: ", total_games - correct_picks, "\n")
cat("Overall Win %:      ", round(win_percentage, 2), "%\n\n")
cat("Home Pick Win %:    ", round(mean(home_picks$Is_Correct, na.rm = TRUE) * 100, 2), "%\n")
cat("Away Pick Win %:    ", round(mean(away_picks$Is_Correct, na.rm = TRUE) * 100, 2), "%\n")


# 1. Train a logistic regression model using your Master Matchup Score
prob_model <- glm(Home_Win ~ Master_Matchup_Score, data = mlb_backtest_results, family = binomial)

# 2. Extract the model's calibration formulas (Intercept and Slope)
intercept <- coef(prob_model)[1]
slope     <- coef(prob_model)[2]

# 3. Predict the exact Home Win Probability for every game
mlb_backtest_results <- mlb_backtest_results %>%
  mutate(
    Home_Win_Probability = predict(prob_model, newdata = ., type = "response"),
    # Away probability is just the remaining percentage
    Away_Win_Probability = 1 - Home_Win_Probability
  )

# 4. View a quick snippet of how scores map to percentages
print(mlb_backtest_results %>% 
        select(Master_Matchup_Score, Home_Win_Probability, Away_Win_Probability) %>% 
        distinct() %>% 
        head(10), 
      row.names = FALSE)

saveRDS(prob_model, 'backend/r_pipelines/data/win_prob_model.rds')
