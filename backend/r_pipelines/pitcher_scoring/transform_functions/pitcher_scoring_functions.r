
############### CALCULATE PITCHER SCORES ##########################

calculate_pitcher_scores <- function(pitcher_statcast_df, game_date = NULL) {

  # 1. Define blocks
  block_control   <- c('BB%', 'K%', 'K/9', 'BB/9', 'K-BB%', 'Chase%', 'Whiff%',
                       'Zone%', 'F-Strike%', 'CStr%', 'SwStr%', 'C+SwStr%')
  
  block_contact   <- c('GB%', 'FB%', 'LD%', 'PU%', 'GB/FB', 'HR/FB', 'IFFB%',
                       'Barrel%', 'HardHit%', 'Z-Contact%', 'O-Contact%',
                       'Contact%', 'EV', 'LA')
  
  block_prevention <- c('ERA', 'FIP', 'WHIP', 'H/9', 'HR/9', 'LOB%')
  
  block_results <- c('AVG', 'OBP', 'SLG', 'OPS', 'BABIP')
  
  block_expected  <- c('xBA', 'xwOBA', 'xSLG', 'xISO', 'xBABIP')
  
  all_stats_to_clean <- c(block_control, block_contact, block_prevention, block_results, block_expected)
  all_numeric_cols   <- c(all_stats_to_clean, 'SIERA')

  pitcher_df <- pitcher_statcast_df
  
  training_df <- pitcher_df %>%
    filter(!is.na(SIERA))
  
  training_df[all_numeric_cols] <- lapply(training_df[all_numeric_cols], function(x) as.numeric(as.character(x)))
  pitcher_df[all_stats_to_clean] <- lapply(pitcher_df[all_stats_to_clean], function(x) as.numeric(as.character(x)))
  
  for (col in all_stats_to_clean) {
    league_avg <- mean(training_df[[col]], na.rm = TRUE)
    if (is.na(league_avg)) league_avg <- 0 
    
    if (any(is.na(training_df[[col]]))) {
      training_df[[col]][is.na(training_df[[col]])] <- league_avg
    }
    if (any(is.na(pitcher_df[[col]]))) {
      pitcher_df[[col]][is.na(pitcher_df[[col]])] <- league_avg
    }
  }
  
  
  blocks_list <- list(
    Control   = block_control,
    Contact   = block_contact,
    Prevention = block_prevention,
    Results = block_results,
    Expected  = block_expected
  )
  
  
  negative_stats <- c(
    'BB%', 'BB/9', 'HardHit%', 'Barrel%', 'FB%', 'LD%', 'HR/FB', 'Contact%',
    'Z-Contact%', 'EV', 'LA', 'xBA', 'xwOBA', 'xSLG', 'xISO', 'xBABIP',
    'ERA', 'FIP', 'WHIP', 'H/9', 'HR/9', 'AVG', 'OBP', 'SLG', 'OPS', 'BABIP'
  )
  
  
  final_pitcher_scores_df <- pitcher_df %>% select(xMLBAMID)
  
  for (block_name in names(blocks_list)) {
    block_stats <- blocks_list[[block_name]]
    
    
    X_train_raw <- training_df %>% select(all_of(block_stats))
    X_train_mat <- data.matrix(X_train_raw)
    X_train_scaled <- scale(X_train_mat)
    X_train_scaled[is.na(X_train_scaled)] <- 0
    
    y_train_raw <- training_df$SIERA
    y_train_scaled <- as.vector(scale(y_train_raw))
    
    
    ridge_model <- cv.glmnet(X_train_scaled, y_train_scaled, alpha = 0)
    raw_coefficients <- as.vector(as.matrix(coef(ridge_model, s = "lambda.min")))[-1] 
    raw_coefficients[is.na(raw_coefficients)] <- 0
    
    sum_coefs <- sum(abs(raw_coefficients))
    if (sum_coefs == 0) sum_coefs <- 1
    normalized_weights <- abs(raw_coefficients) / sum_coefs
    
    
    pitcher_component_points <- matrix(0, nrow = nrow(pitcher_df), ncol = length(block_stats))
    
    for (i in 1:length(block_stats)) {
      stat_name <- block_stats[i]
      weight    <- normalized_weights[i]
      
      stat_values_all <- pitcher_df[[stat_name]]
      
      stat_mean_train <- mean(training_df[[stat_name]], na.rm = TRUE)
      stat_sd_train   <- sd(training_df[[stat_name]], na.rm = TRUE)
      
      if (is.na(stat_sd_train) || stat_sd_train == 0) {
        z_scores <- rep(0, length(stat_values_all))
      } else {
        z_scores <- (stat_values_all - stat_mean_train) / stat_sd_train
      }
      
      if (stat_name %in% negative_stats) {
        z_scores <- z_scores * -1
      }
      
      pitcher_component_points[, i] <- z_scores * weight
    }
    
    raw_composite_score <- rowSums(pitcher_component_points, na.rm = TRUE)
    
    avg_comp_train <- mean(raw_composite_score[pitcher_df$pitcher %in% training_df$pitcher], na.rm = TRUE)
    sd_comp_train  <- sd(raw_composite_score[pitcher_df$pitcher %in% training_df$pitcher], na.rm = TRUE)
    if (is.na(sd_comp_train) || sd_comp_train == 0) sd_comp_train <- 1
    
    index_score <- 100 + ((raw_composite_score - avg_comp_train) / sd_comp_train) * 15
    final_points_score <- round(index_score / 10, 2)
    
    column_output_name <- paste0("score_", tolower(block_name))
    final_pitcher_scores_df[[column_output_name]] <- final_points_score
  }
  
  if (is.null(game_date)) {
    game_date = Sys.Date()
  }
  
  final_pitcher_scores_df <- final_pitcher_scores_df %>%
    rename(xMLBAMID = pitcher) %>%
    mutate(
      game_date = game_date,
      update_date = Sys.time()
      )
  
  return(final_pitcher_scores_df)
}

process_pitcher_statcast_counts <- function(statcast_df) {
  
  # clean df - select only columns we need
  cleaned_statcast_df <- statcast_df %>%
    select(
      xMLBAMID = pitcher,
      season = game_year,
      p_throws,
      player_name,
      batter,
      game_date,
      events,
      description,
      zone,
      pitch_number,
      bb_type,
      launch_speed,
      launch_angle,
      estimated_ba_using_speedangle,
      estimated_woba_using_speedangle,
      iso_value,
      estimated_slg_using_speedangle,
      babip_value
    ) %>%
    mutate(
      xMLBAMID = as.character(xMLBAMID),
      batter = as.character(batter),
      launch_angle = as.numeric(launch_angle),
      iso_value = as.numeric(iso_value),
      babip_value = as.numeric(babip_value),
      
      
      launch_speed_bip = if_else(!is.na(bb_type), launch_speed, NA_real_),
      launch_angle_bip = if_else(!is.na(bb_type), launch_angle, NA_real_),
      ev = launch_speed_bip,
      la = launch_angle_bip,
      min_la = pmax(26 - (ev - 98), 8),
      max_la = pmin(30 + (ev - 98), 50),
      is_barrel_ball = (ev >= 98) & (la >= min_la) & (la <= max_la)
    )
  
  # set events lists and zone
  strike_zone <- seq(1:9)
  
  # Define a flag for pitches that actually finish a play
  
  swinging_strike_event_list = c('swinging_strike', 'swinging_strike_blocked')
  
  contact_event_list = c('foul', 'foul_tip', 'hit_into_play', 'foul_pitchout')
  
  strike_event_list = c('foul', 'foul_tip', 'hit_into_play', 'foul_pitchout',
                        'swinging_strike', 'swinging_strike_blocked', 'called_strike')
  
  swing_event_list = c(contact_event_list, swinging_strike_event_list)
  
  strikeout_event_list = c('strikeout', 'strikeout_double_play')
  
  walk_event_list = c('walk', 'intent_walk')
  
  error_event_list = c('catcher_interf', 'field_error')
  
  field_out_event_list = c('grounded_into_double_play', 'field_out', 'force_out', 'sac_bunt',
                           'fielders_choice', 'fielders_choice_out', 'double_play', 'triple_play',
                           'sac_fly', 'sac_fly_double_play')
  
  out_event_list = c(strikeout_event_list, field_out_event_list)
  
  base_hit_event_list = c('single', 'double', 'triple', 'home_run')
  
  non_ab_event_list = c('walk', 'intent_walk', 'hit_by_pitch', 'sac_bunt',
                        'sac_fly', 'sac_fly_double_play', 'catcher_interf')
  
  sacrifice_event_list = c('sac_bunt', 'sac_fly', 'sac_fly_double_play')
  
  fielders_choice_event_list = c('fielders_choice', 'fielders_choice_out')
  
  pitcher_statcast_df <- cleaned_statcast_df %>%
    group_by(xMLBAMID, season) %>%
    summarise(
      pitches = n(),
      # discipline block 'K%', 'BB%', 'BB/K', 'Z-Swing%', 'Chase%', 'Whiff%'
      plate_appearances = sum(!events == "", na.rm = TRUE),
      outs = sum(events %in% out_event_list, na.rm = TRUE),
      innings_pitched = (if_else(outs == 0, 0, outs / 3.0)),
      strikeouts = sum(events %in% strikeout_event_list, na.rm = TRUE),
      walks = sum(events %in% walk_event_list, na.rm = TRUE),
      pitches_outside_zone = sum(!(zone %in% strike_zone), na.rm = TRUE),
      swings_outside_zone = sum(description %in% swing_event_list & (!(zone %in% strike_zone)), na.rm = TRUE),
      pitches_inside_zone = sum(zone %in% strike_zone, na.rm = TRUE),
      swings_inside_zone = sum(description %in% swing_event_list & zone %in% strike_zone, na.rm = TRUE),
      whiffs = sum(description %in% swinging_strike_event_list, na.rm = TRUE),
      swings = sum(description %in% swing_event_list, na.rm = TRUE),
      first_pitch_strikes = sum(pitch_number == 1 & description %in% strike_event_list, na.rm = TRUE),
      called_strikes = sum(description == 'called_strike', na.rm = TRUE),
      
      # 'GB%', 'FB%', 'LD%', 'GB/FB', 'HR/FB', 'IFFB%', 'Barrel%', 'HardHit%','Z-Contact%', 'O-Contact%', 'Contact%', 'EV', 'LA'
      batted_balls = sum(bb_type != '', na.rm = TRUE),
      fly_balls = sum(bb_type == 'fly_ball', na.rm = TRUE),
      ground_balls = sum(bb_type == 'ground_ball', na.rm = TRUE),
      line_drives = sum(bb_type == 'line_drive', na.rm = TRUE),
      home_runs = sum(events == 'home_run', na.rm = TRUE),
      pop_ups = sum(bb_type == 'popup', na.rm = TRUE),
      barreled_balls = sum(is_barrel_ball, na.rm = TRUE),
      hard_hits_balls = sum(ev >= 95.0, na.rm = TRUE),
      contacted_balls = sum(description %in% contact_event_list, na.rm = TRUE),
      contacted_balls_inside_zone = sum(description %in% contact_event_list & zone %in% strike_zone, na.rm = TRUE),
      contacted_balls_outside_zone = sum(description %in% contact_event_list & (!(zone %in% strike_zone)), na.rm = TRUE),
      ev_sum = sum(ev, na.rm = TRUE),
      la_sum = sum(la, na.rm = TRUE),
      estimated_ba_using_speedangle_bip = sum(estimated_ba_using_speedangle, na.rm = TRUE),
      estimated_woba_using_speedangle_bip = sum(estimated_woba_using_speedangle, na.rm = TRUE),
      iso_value_bip = sum(iso_value, na.rm = TRUE),
      estimated_slg_using_speedangle_bip = sum(estimated_slg_using_speedangle, na.rm = TRUE),
      babip_value_bip = sum(babip_value, na.rm = TRUE),
      .groups = 'drop'
    )
  
  return(pitcher_statcast_df)
}

process_pitcher_statcast_small_sample_size_pitchers <- function(statcast_df = NULL) {
  
  numeric_cols <- names(statcast_df %>% select(where(function(x) is.numeric(x))))
  
  league_averages_df <- statcast_df %>%
    summarise(across(all_of(numeric_cols), ~mean(.x, na.rm = TRUE)))
  
  curated_statcast_df <- statcast_df %>%
    mutate(
      across(
        all_of(numeric_cols),
        ~ if_else(plate_appearances < 50, league_averages_df[[cur_column()]], .x)
      )
    )
  
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
    )
  
  return(processed_pitcher_statcast_df)
}

create_pitcher_identifier_df <- function(pitcher_df) {
  pitcher_identifier_df <- pitcher_df %>%
    select(
      xMLBAMID,
      player_name,
      gamesStarted,
      gamesPitched
    )
  return(pitcher_identifier_df)
}

prepare_pitcher_stats_counts_df <- function(statsapi_df, statcast_df) {
  
  # join statsapi and statcast
  combined_pitcher_data <- statsapi_df %>%
    inner_join(
      statcast_df,
      by = c('xMLBAMID' = 'pitcher'),
      relationship = 'one-to-one'
    )
  
  cleaned_pitcher_data <- combined_pitcher_data %>%
    select(xMLBAMID,
           runs,
           earnedRuns,
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
  
  return(cleaned_pitcher_data)
}

produce_overall_pitcher_stats <- function(current_year = as.numeric(format(Sys.Date(), '%Y'))) {
  
  year_range <- seq(from = current_year, to = (current_year - 2))
  
  pitcher_stats_counts_df_list <- c()
  
  for (year in year_range) {
    
    statsapi_table <- paste0('pitcher_statsapi_counts_', year)
    statcast_table <- paste0('pitcher_statcast_counts_', year)
    
    pitcher_statsapi_df <- get_data_from_database(statsapi_table)
    pitcher_statcast_df <- get_data_from_database(statcast_table)
    
    pitcher_identifier_df <- create_pitcher_identifier_df(pitcher_statsapi_df)
    
    prepared_pitcher_stat_counts_df <- prepare_pitcher_stats_counts_df(pitcher_statsapi_df, pitcher_statcast_df)
    
    prepared_pitcher_stat_counts_df <- process_pitcher_statcast_small_sample_size_pitchers(prepared_pitcher_stat_counts_df)
    
    max_year <- current_year
    multiplier <- 5
    
    if (max_year - year == 2) {
      multiplier <- 2
    } else if (max_year - year == 1) {
      multiplier <- 3
    } else {
      multiplier <- 5
    }
    
    prepared_pitcher_stat_counts_df <- process_pitcher_statcast_decay(prepared_pitcher_stat_counts_df, multiplier = multiplier)
    
    final_pitcher_stat_counts_df <- pitcher_identifier_df %>%
      inner_join(
        prepared_pitcher_stat_counts_df,
        by = ('xMLBAMID')
      )
    
    pitcher_stats_counts_df_list[[length(pitcher_stats_counts_df_list) + 1]] <- final_pitcher_stat_counts_df    
    
  }
  
  pitcher_stat_counts_df <- bind_rows(pitcher_stats_counts_df_list)    
  
  complete_pitcher_stats_df <- process_pitcher_statcast_stats(pitcher_stat_counts_df)
  
  return(complete_pitcher_stats_df)
}

assing_pitcher_role <- function(pitcher_stats_df) {
  pitcher_stats_df <- pitcher_stats_df %>%
    mutate(
      gs_rate = if_else(total_games_pitched == 0, 0, total_games_started / total_games_pitched),
      pitcher_role = case_when(
        total_games_started >= 15 & gs_rate >= 0.60 ~ 'starter',
        total_games_started <= 2 ~ 'reliever',
        TRUE ~ 'hybrid'
      )
    )
  return(pitcher_stats_df)
}
