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

month_df <- curated_results_df %>%
  select(
    Game_Date,
    Correct_Prediction
  ) %>%
  mutate(
    Month = case_when(
      str_sub(Game_Date, start = 7L, end = 7L) == 3 ~ 'March',
      str_sub(Game_Date, start = 7L, end = 7L) == 4 ~ 'April',
      str_sub(Game_Date, start = 7L, end = 7L) == 5 ~ 'May',
      str_sub(Game_Date, start = 7L, end = 7L) == 6 ~ 'June',
      str_sub(Game_Date, start = 7L, end = 7L) == 7 ~ 'July',
      str_sub(Game_Date, start = 7L, end = 7L) == 8 ~ 'August',
      str_sub(Game_Date, start = 7L, end = 7L) == 9 ~ 'September',
      str_sub(Game_Date, start = 6L, end = 7L) == 10 ~ 'October',
      str_sub(Game_Date, start = 6L, end = 7L) == 11 ~ 'November'
    ),
    Month_Number = str_sub(Game_Date, start = 6L, end = 7L)
  ) 
month_df

month_results_df <- month_df %>%
  group_by(
    Month_Number
  ) %>%
  summarise(
    Total_Picks = n(),
    Total_Correct_Picks = sum(Correct_Prediction),
    Correct_Accuracy = round((Total_Correct_Picks / Total_Picks) * 100, 2)
  )


month_plot <- ggplot(
  month_results_df,
  aes(x = Month_Number, y = Correct_Accuracy, group = 1)
) + 
  geom_point() +
  geom_line() +
  geom_hline(yintercept = 50, linetype = "dashed", color = "red") +
  labs(
    title = "MLB Prediction Model: Overall Accuracy by Month",
    x = "Month",
    y = "Overall Accuracy (%)"
  ) +
  theme_minimal()

month_plot
