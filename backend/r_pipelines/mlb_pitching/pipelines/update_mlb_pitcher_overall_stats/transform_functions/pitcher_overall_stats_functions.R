convert_ip_to_decimal <- function(ip) {
  ip_num <- as.numeric(ip)
  whole_innings <- floor(ip_num)
  outs <- round((ip_num - whole_innings) * 10)
  return(whole_innings + (outs / 3))
}

create_pitcher_identifier_df <- function(statsapi_df, statcast_df) {
  
  pitcher_statsapi_identifier_df <- statsapi_df %>%
    select(
      xMLBAMID,
      player_name,
      gamesStarted,
      gamesPitched
    )
  
  pitcher_statcast_identifier_df <- statcast_df %>%
    select(
      xMLBAMID,
      raw_plate_appearances = plate_appearances
    )
  
  pitcher_identifier_df <- pitcher_statsapi_identifier_df %>%
    inner_join(
      pitcher_statcast_identifier_df,
      by = c('xMLBAMID' = 'xMLBAMID'),
      relationship = 'one-to-one'
    )
  
  return(pitcher_identifier_df)
}

prepare_pitcher_stats_counts_df <- function(statsapi_df, statcast_df) {
  
  # join statsapi and statcast
  combined_pitcher_data <- statsapi_df %>%
    inner_join(
      statcast_df,
      by = c('xMLBAMID' = 'xMLBAMID'),
      relationship = 'one-to-one'
    )
  
  cleaned_pitcher_data <- combined_pitcher_data %>%
    select(xMLBAMID,
           runs,
           earnedRuns,
           plate_appearances,
           atBats,
           homeRuns,
           strikeouts,
           baseOnBalls,
           intentionalWalks,
           hits,
           hitByPitch,
           inningsPitched,
           groundIntoDoublePlay,
           totalBases,
           sacBunts,
           sacFlies,
           pitches,
           innings_pitched,
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
    ) %>%
    mutate(
        inningsPitched = convert_ip_to_decimal(inningsPitched)
    )
  
  return(cleaned_pitcher_data)
}

process_pitcher_statcast_small_sample_size_pitchers <- function(statcast_df = NULL, threshold = 150) {
  
  static_cols <- c('xMLBAMID', 'player_name', 'season_count', 'total_games_started', 
                   'total_games_pitched', 'total_plate_appearances', 'update_date')
  
  average_cols <- setdiff(names(statcast_df), static_cols)
  
  league_averages_df <- statcast_df %>%
    filter(total_plate_appearances >= threshold) %>%
    summarise(across(all_of(average_cols), ~mean(.x, na.rm = TRUE)))
  
  curated_statcast_df <- statcast_df %>%
    mutate(
      sample_weight = pmin(total_plate_appearances / threshold, 1),
      across(
        all_of(average_cols),
        ~ (sample_weight * .x) + ((1 - sample_weight) * league_averages_df[[cur_column()]])
      )
    ) %>%
    select(-sample_weight)
  
  return(curated_statcast_df)
}

process_pitcher_statcast_decay <- function(statcast_df = NULL, multiplier = 5) {
  
  numeric_cols <- names(statcast_df %>% select(where(function(x) is.numeric(x))))
  
  decayed_statcast_df <- statcast_df %>%
    mutate(
      across(
        all_of(numeric_cols),
        ~.x * multiplier)
    )
}

process_pitcher_statcast_stats <- function(statcast_df = NULL) {
  processed_pitcher_statcast_df <- statcast_df %>%
    group_by(xMLBAMID, player_name) %>%
    mutate(
      babip_denom_row = atBats - strikeouts - homeRuns + sacFlies,
      babip_num_row   = hits - homeRuns,
      lob_denom_row   = hits + baseOnBalls + hitByPitch - (1.4 * homeRuns),
      lob_num_row     = hits + baseOnBalls + hitByPitch - runs,
      fip_num_row     = (13 * homeRuns) + (3 * (baseOnBalls + hitByPitch)) - (2 * strikeouts),
      obp_denom_row   = atBats + baseOnBalls + hitByPitch + sacFlies,
      obp_num_row     = hits + baseOnBalls + hitByPitch
    ) %>%
    summarise(
      season_count = n(),
      total_games_started = sum(gamesStarted),
      total_games_pitched = sum(gamesPitched),
      total_plate_appearances = sum(raw_plate_appearances),
      # Control block
      `BB%`       = if_else(sum(plate_appearances) == 0, 0, sum(walks) / sum(plate_appearances)),
      `K%`        = if_else(sum(plate_appearances) == 0, 0, sum(strikeouts) / sum(plate_appearances)),
      `K/9`       = if_else(sum(innings_pitched) == 0, 0, sum(strikeouts) * 9 / sum(innings_pitched)),
      `BB/9`      = if_else(sum(innings_pitched) == 0, 0, sum(walks) * 9 / sum(innings_pitched)),
      `K-BB%`     = `K%` - `BB%`,
      `Chase%`    = if_else(sum(pitches_outside_zone) == 0, 0, sum(swings_outside_zone) / sum(pitches_outside_zone)),
      `Whiff%`    = if_else(sum(swings) == 0, 0, sum(whiffs) / sum(swings)),
      `Zone%`     = if_else(sum(pitches) == 0, 0, sum(pitches_inside_zone) / sum(pitches)),
      `F-Strike%` = if_else(sum(plate_appearances) == 0, 0, sum(first_pitch_strikes) / sum(plate_appearances)),
      `CStr%`     = if_else(sum(pitches) == 0, 0, sum(called_strikes) / sum(pitches)),
      `SwStr%`    = if_else(sum(pitches) == 0, 0, sum(whiffs) / sum(pitches)),
      `C+SwStr%`  = if_else(sum(pitches) == 0, 0, (sum(called_strikes) + sum(whiffs)) / sum(pitches)),
      
      # Contact block
      `GB%`        = if_else(sum(batted_balls) == 0, 0, sum(ground_balls) / sum(batted_balls)),
      `FB%`        = if_else(sum(batted_balls) == 0, 0, sum(fly_balls) / sum(batted_balls)),
      `LD%`        = if_else(sum(batted_balls) == 0, 0, sum(line_drives) / sum(batted_balls)),
      `PU%`        = if_else(sum(batted_balls) == 0, 0, sum(pop_ups) / sum(batted_balls)),
      `GB/FB`      = if_else(sum(fly_balls) == 0, 0, sum(ground_balls) / sum(fly_balls)),
      `HR/FB`      = if_else(sum(fly_balls) == 0, 0, sum(home_runs) / sum(fly_balls)),
      `IFFB%`      = if_else(sum(fly_balls) == 0, 0, sum(pop_ups) / sum(fly_balls)),
      `Barrel%`    = if_else(sum(batted_balls) == 0, 0, sum(barreled_balls) / sum(batted_balls)),
      `HardHit%`   = if_else(sum(batted_balls) == 0, 0, sum(hard_hits_balls) / sum(batted_balls)), 
      `Z-Contact%` = if_else(sum(swings_inside_zone) == 0, 0, sum(contacted_balls_inside_zone) / sum(swings_inside_zone)),
      `O-Contact%` = if_else(sum(swings_outside_zone) == 0, 0, sum(contacted_balls_outside_zone) / sum(swings_outside_zone)),
      `Contact%`   = if_else(sum(swings) == 0, 0, sum(contacted_balls) / sum(swings)),
      `EV`         = if_else(sum(batted_balls) == 0, 0, sum(ev_sum) / sum(batted_balls)),
      `LA`         = if_else(sum(batted_balls) == 0, 0, sum(la_sum) / sum(batted_balls)),
      
      # Results block
      `H/9`   = if_else(sum(inningsPitched) == 0, 0, (sum(hits) * 9) / sum(inningsPitched)),
      `HR/9`  = if_else(sum(inningsPitched) == 0, 0, (sum(homeRuns) * 9) / sum(inningsPitched)),
      `ERA`   = if_else(sum(inningsPitched) == 0, 0, (sum(earnedRuns) * 9) / sum(inningsPitched)),
      `AVG`   = if_else(sum(atBats) == 0, 0, sum(hits) / sum(atBats)),
      `WHIP`  = if_else(sum(inningsPitched) == 0, 0, (sum(hits) + sum(baseOnBalls)) / sum(inningsPitched)),
      `BABIP` = if_else(sum(babip_denom_row) == 0, 0, sum(babip_num_row) / sum(babip_denom_row)),
      `LOB%`  = if_else(sum(lob_denom_row) == 0, 0, sum(lob_num_row) / sum(lob_denom_row)),
      `FIP`   = if_else(sum(inningsPitched) == 0, 0, sum(fip_num_row) / sum(inningsPitched) + 4.00),
      `OBP`   = if_else(sum(obp_denom_row) == 0, 0, sum(obp_num_row) / sum(obp_denom_row)),
      `SLG`   = if_else(sum(atBats) == 0, 0, sum(totalBases) / sum(atBats)),  
      `OPS`   = `OBP` + `SLG`,
      
      # Expected block
      `xBA`    = if_else(sum(batted_balls) == 0, 0, sum(estimated_ba_using_speedangle_bip) / sum(batted_balls)),
      `xwOBA`  = if_else(sum(batted_balls) == 0, 0, sum(estimated_woba_using_speedangle_bip) / sum(batted_balls)),
      `xSLG`   = if_else(sum(batted_balls) == 0, 0, sum(estimated_slg_using_speedangle_bip) / sum(batted_balls)),
      `xISO`   = if_else(sum(batted_balls) == 0, 0, sum(iso_value_bip) / sum(batted_balls)),
      `xBABIP` = if_else(sum(batted_balls) == 0, 0, sum(babip_value_bip) / sum(batted_balls)),
      
      .groups = "drop"
    ) %>%
    mutate(
      update_date = Sys.Date()
    )
  
  return(processed_pitcher_statcast_df)
}


