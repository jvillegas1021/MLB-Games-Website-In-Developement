library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgres)
library(baseballr)

source("extract_functions/extract_data_from_database.r")
source("extract_functions/extract_mlb_player_info.r")
source("transform_functions/pitcher_scoring_functions.r")
source("load_functions/load_data_to_database.r")

names(complete_pitcher_stats_df)


pitcher_database_df <- get_data_from_database('overall_pitcher_stats_2025')

pitcher_fg_df <- fg_pitcher_leaders(startseason = 2025, endseason = 2025)

complete_pitcher_stats <- assing_pitcher_role(pitcher_database_df)
# transform data
starting_pitcher_df <- complete_pitcher_stats %>% filter(pitcher_role == 'starter')
reliever_pitcher_df <- complete_pitcher_stats %>% filter(pitcher_role == 'reliever')
hybrid_pitcher_df <- complete_pitcher_stats %>% filter(pitcher_role == 'hybrid')

pitcher_siera_df <- pitcher_fg_df %>%
  mutate(xMLBAMID = as.character(xMLBAMID)) %>%
  select(xMLBAMID, SIERA)

prepared_pitcher_stats <- complete_pitcher_stats %>%
  inner_join(
    pitcher_siera_df,
    by = 'xMLBAMID'
  )


final_starter_scores_df = calculate_pitcher_scores(prepared_pitcher_stats)
final_reliever_scores_df = calculate_pitcher_scores(prepared_pitcher_stats)
final_hyrbid_scores_df = calculate_pitcher_scores(prepared_pitcher_stats)


final_pitcher_scores_df = bind_rows(final_starter_scores_df,
                                    final_reliever_scores_df,
                                    final_hyrbid_scores_df)
