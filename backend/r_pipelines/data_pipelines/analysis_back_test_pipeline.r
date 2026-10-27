library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgres)
library(glmnet)

source("backend/r_pipelines/data_extract_functions/extract_mlb_games_info.r")
source("backend/r_pipelines/data_extract_functions/extract_data_from_database.r")
source("backend/r_pipelines/data_extract_functions/extract_data_from_files.r")
source("backend/r_pipelines/data_transform_functions/mlb_matchup_pipeline_functions.r")
source("backend/r_pipelines/data_load_functions/load_data_to_database.r")
source("backend/r_pipelines/data_pipelines/mlb_matchup_card_pipeline.r")


season_dates <- seq(as.Date("2026-03-25"), as.Date("2026-11-02"), by = "day")

# pitcher_data
starting_pitcher_stats_df <- get_data_from_database('mlb_pitcher_scores')
# pitcher_data
starting_pitcher_stats_current_year_df <- get_data_from_database('active_pitcher_stats_current_year')
# team batting_data
team_batting_df <- get_data_from_database('mlb_team_batting_scores')
# probability model
prob_model <- load_rds("win_prob_model")
# mlb odds table
mlb_games_odds_df <- get_data_from_database('mlb_games_odds_df')

mlb_matchup_card_list <- c()

for (d in season_dates) {
  # 1. Re-construct a completely unambiguous Date object from the loop index
  loop_date_obj <- as.Date(d, origin = "1970-01-01")
  
  print(paste("Processing Matchup Card for:", as.character(loop_date_obj)))
  
  # 2. FORCE the pipeline function to accept this exact date object 
  # explicitly by name so it bypasses the default Sys.time() parameter trap
  mlb_matchup_card <- mlb_matchup_card_pipeline(game_date = loop_date_obj,
                                                starting_pitcher_stats_df,
                                                starting_pitcher_stats_current_year_df,
                                                team_batting_df,
                                                prob_model,
                                                mlb_games_odds_df)
  
  mlb_matchup_card_list[[length(mlb_matchup_card_list) + 1]] <- mlb_matchup_card
}

final_matchup_df <- bind_rows(mlb_matchup_card_list)

drop_na_scores_df <- final_matchup_df %>% drop_na(Home_Team_Score, 
                                                  Away_Team_Score,
                                                  Net_Discipline_Margin,
                                                  Net_Power_Margin,
                                                  Net_Result_Margin)

mlb_testing_df <- drop_na_scores_df %>%
  mutate(
    Run_Differential = Home_Team_Score - Away_Team_Score,
    Home_Win         = ifelse(Home_Team_Score > Away_Team_Score, 1, 0)
  )

margin_features <- c("Net_Discipline_Margin", "Net_Power_Margin", "Net_Result_Margin", "Net_Expected_Margin")

margin_matrix <- cor(
  mlb_testing_df[, c(margin_features, "Run_Differential", "Home_Win")], 
  use = "complete.obs"
)

margin_rankings <- data.frame(
  Margin_Feature = margin_features,
  Run_Diff_Correlation = margin_matrix[margin_features, "Run_Differential"],
  Win_Correlation      = margin_matrix[margin_features, "Home_Win"]
)

print(margin_rankings, row.names = FALSE)

# 1. Define the margin features we want to combine into our master score
model_features_test_res <- c("Net_Discipline_Margin", "Net_Power_Margin", "Net_Result_Margin")
model_features_test_exp <- c("Net_Discipline_Margin", "Net_Power_Margin", "Net_Expected_Margin")
model_features_test_all <- c("Net_Discipline_Margin", "Net_Power_Margin", "Net_Result_Margin", "Net_Expected_Margin")
# 2. Prepare the data matrices for glmnet (dropping any rows missing data)
test_blocks <- list(
  res_block = model_features_test_res,
  exp_block = model_features_test_exp,
  all_block = model_features_test_all
)

weight_table_list <- c()

for (test_group in test_blocks) {
  clean_model_df <- mlb_testing_df %>% 
    filter(complete.cases(.[, c(test_group, "Run_Differential")]))
  
  X <- as.matrix(clean_model_df[, test_group])
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
  weight_table_list[[length(weight_table_list) + 1]] <- weights_table
}


for (test in seq(1:length(weight_table_list))) {
  if (is.na(weight_table_list[[test]][3, 2])) {
    result_margin_weight <- 0
  } else {
    result_margin_weight <- weight_table_list[[test]][3, 2]
  }
  
  if (is.na(weight_table_list[[test]][4, 2])) {
    expected_margin_weight <- 0
  } else {
    expected_margin_weight <- weight_table_list[[test]][4, 2]
  }
  
  # 1. Apply the regression weights to create a single Master Matchup Score
  mlb_backtest_results <- mlb_testing_df %>%
    mutate(
      Master_Matchup_Score = (Net_Discipline_Margin * weight_table_list[[test]][1, 2]) + 
        (Net_Power_Margin      * weight_table_list[[test]][2, 2]) + 
        (Net_Result_Margin   * result_margin_weight) +
        (Net_Expected_Margin   * expected_margin_weight)
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
  print(weight_table_list[[test]])
  cat("Total Games Picked: ", total_games, "\n")
  cat("Correct Picks:      ", correct_picks, " - Incorrect: ", total_games - correct_picks, "\n")
  cat("Overall Win %:      ", round(win_percentage, 2), "%\n\n")
  cat("Home Pick Win %:    ", round(mean(home_picks$Is_Correct, na.rm = TRUE) * 100, 2), "%\n")
  cat("Away Pick Win %:    ", round(mean(away_picks$Is_Correct, na.rm = TRUE) * 100, 2), "%\n")
}

# choosing expected
mlb_backtest_results <- mlb_testing_df %>%
  mutate(
    Master_Matchup_Score = (Net_Discipline_Margin * weight_table_list[[2]][1, 2]) + 
      (Net_Power_Margin      * weight_table_list[[2]][2, 2]) + 
      (Net_Result_Margin   * 0) +
      (Net_Expected_Margin   * weight_table_list[[2]][3, 2])
  )

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



final_matchup_df
