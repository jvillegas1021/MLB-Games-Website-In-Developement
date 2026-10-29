library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgres)
library(baseballr)

source("backend/r_pipelines/data_extract_functions/extract_data_from_database.r")
source("backend/r_pipelines/data_transform_functions/mlb_prediction_results_pipeline_functions.r")
source("backend/r_pipelines/data_load_functions/load_data_to_database.r")
source("backend/r_pipelines/data_pipelines/mlb_games_prediction_results_pipeline_update.r")

mlb_batting_rosters <- get_data_from_database('mlb_batting_rosters_gameday')
batter_stats <- get_data_from_database('batter_seasonal_data_statsapi')

######### grab roster stats scores for team and day

# extract batting_rosters_gameday
mlb_batting_rosters <- get_data_from_database('mlb_batting_rosters_gameday')
# extract statcast data
batter_stats_statcast <- get_data_from_database('batter_seasonal_data_statcast')
# extract teams
mlb_teams <- mlb_teams(season = current_season, sport_ids = 1)

# set parameters
game_date <- '2026-09-28'
mlb_team_id <- 133

# extract roster_linup_ids
lineup_ids <- mlb_batting_rosters %>%
  filter(roster_date == game_date,
         team_id == mlb_team_id) %>%
  pull(roster_lineup_ids)

split_up_linup_ids <- str_split(lineup_ids, ",") %>% unlist()

lineup_ids <- mlb_batting_rosters %>%
  filter(roster_date == '2026-09-28',
         team_id == 133) %>%
  pull(roster_lineup_ids)

split_up_linup_ids <- str_split(lineup_ids, ",") %>% unlist()

# filter statcast data
filtered_batter_statcast <- batter_stats_statcast %>%
  filter(xMLBAMID %in% split_up_linup_ids)

if (nrow(filtered_batter_statcast) == 0 || length(filtered_batter_statcast) == 0){
  return(tibble())
}

wBB <- 0.698
wHBP <- 0.729
w1B <- 0.890
w2B <- 1.261
w3B <- 1.596
wHR <- 2.049

league_woba <- 0.316
wOBAScale <- 1.238
R_PA_lg <- 0.118

column_list <- c('K%', 'BB%', 'GB%', 'FB%', 'LD%', 'GB/FB', 'ISO', 'OPS',
               'BABIP', 'AVG', 'OBP', 'SLG', 'BB/K', 'HR/FB', 'IFFB%', 'Barrel%', 'HardHit%',
               'O-Swing%', 'Z-Swing%', 'Z-Contact%', 'O-Contact%', 'Contact%', 'Chase%',
               'Whiff%', 'SwStr%', 'F-Strike%', 'EV', 'LA', 'wOBA', 'wRAA', 'wRC', 'wRC+',
               'xWOBA', 'xBA', 'xSLG', 'xISO', 'xBABIP')

batter_stats_summarized <- filtered_batter_statcast %>%
  summarise(
    `K%` = sum(strikeouts, na.rm = TRUE) / sum(plate_appearances, na.rm = TRUE),
    `BB%` = sum(walks, na.rm = TRUE) / sum(plate_appearances, na.rm = TRUE),
    `BB/K` = sum(walks, na.rm = TRUE) / sum(strikeouts, na.rm = TRUE),
    gb_fb_ld = sum(GB, na.rm = TRUE) + sum(FB, na.rm = TRUE) + sum(LD, na.rm = TRUE),
    `GB%` = sum(GB, na.rm = TRUE) / gb_fb_ld,
    `FB%` = sum(FB, na.rm = TRUE) / gb_fb_ld,
    `LD%` = sum(LD, na.rm = TRUE) / gb_fb_ld,
    `HR/FB` = sum(home_runs, na.rm = TRUE) / sum(FB, na.rm = TRUE),
    `GB/FB` = sum(GB, na.rm = TRUE) / sum(FB, na.rm = TRUE),
    `IFFB%` = sum(PU, na.rm = TRUE) / sum(FB, na.rm = TRUE),
    at_bats = sum(plate_appearances, na.rm = TRUE) - sum(non_at_bats, na.rm = TRUE),
    AVG = sum(hits, na.rm = TRUE) / at_bats,
    total_bases = sum(singles, na.rm = TRUE) * 1 + sum(doubles, na.rm = TRUE) * 2 + sum(triples, na.rm = TRUE) * 3 +
      sum(home_runs, na.rm = TRUE) * 4,
    SLG = total_bases / at_bats,
    ISO = SLG - AVG,
    babip_num = sum(hits, na.rm = TRUE) - sum(home_runs, na.rm = TRUE),
  )

batter_stats_summarized
