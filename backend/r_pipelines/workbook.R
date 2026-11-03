library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgres)
library(baseballr)

# test new function

pitcher_statcast_df <- get_data_from_database('pitcher_statcast_counts_2023')
pitcher_statsapi_df <- get_data_from_database('pitcher_statsapi_counts_2023')

# going to evaluate using statsapi

# join statsapi and statcast
combined_pitcher_data <- pitcher_statsapi_df %>%
  inner_join(
    pitcher_statcast_df,
    by = c('xMLBAMID' = 'pitcher'),
    relationship = 'one-to-one'
  )

pitcher_identifier_df <- cleaned_pitcher_data %>%
  select(
    xMLBAMID,
    player_name,
    season,
    gamesStarted
  )

cleaned_pitcher_data <- combined_pitcher_data %>%
  select(xMLBAMID,
         runs,
         strikeouts,
         baseOnBalls,
         intentionalWalks,
         hits,
         hitByPitch,
         groundIntoDoublePlay,
         totalBases,
         sacBunts,
         sacFlies,
         pitches,
         plate_appearances,
         innings_pitched,
         strikeouts,
         walks,
         pitches_outside_zone,
         swings_outside_zone,
         pitches_inside_zone,
         swings_inside_zone,
         whiffs,
         swings,
         first_pitch_strikes,
         called_strikes,
         batted_balls,
         fly_balls,
         ground_balls,
         line_drives,
         home_runs,
         pop_ups,
         barreled_balls,
         hard_hits_balls,
         contacted_balls,
         contacted_balls_inside_zone,
         contacted_balls_outside_zone,
         ev_sum,
         la_sum,
         estimated_ba_using_speedangle_bip,
         estimated_woba_using_speedangle_bip,
         iso_value_bip,
         estimated_slg_using_speedangle_bip,
         babip_value_bip
         )


