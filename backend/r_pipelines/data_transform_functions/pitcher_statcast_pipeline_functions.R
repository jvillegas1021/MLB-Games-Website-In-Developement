process_pitcher_statcast_counts <- function(statcast_df = NULL) {
  # clean df - select only columns we need
  cleaned_statcast_df <- statcast_2024_df %>%
    select(
      pitcher,
      p_throws,
      player_name,
      batter,
      game_date,
      game_year,
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
      pitcher = as.character(pitcher),
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
    group_by(pitcher) %>%
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
      babip_value_bip = sum(babip_value, na.rm = TRUE)
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
  processed_pitcher_statcast_df <- pitcher_statcast_df %>%
    group_by(pitcher) %>%
    summarise(
      # control block
      `BB%` = if_else(plate_appearances == 0, 0, walks / plate_appearances),
      `K%` = if_else(plate_appearances == 0, 0, strikeouts / plate_appearances),
      `K/9` = if_else(innings_pitched == 0, 0, strikeouts * 9 / innings_pitched),
      `BB/9` = if_else(innings_pitched == 0, 0, walks * 9 / innings_pitched),
      `K-BB%` = `K%` - `BB%`,
      `Chase%` = if_else(pitches_outside_zone == 0, 0, swings_outside_zone / pitches_outside_zone),
      `Whiff%` = if_else(swings == 0, 0, whiffs / swings),
      `Zone%` = pitches_inside_zone / pitches,
      `F-Strike%` = if_else(plate_appearances == 0, 0, first_pitch_strikes / plate_appearances),
      `CStr%` = called_strikes / pitches,
      `SwStr%` = whiffs / pitches,
      `C+SwStr%` = (called_strikes + whiffs) / pitches,
      # contact
      `GB%` = if_else(batted_balls == 0, 0, ground_balls / batted_balls),
      `FB%` = if_else(batted_balls == 0, 0, fly_balls / batted_balls),
      `LD%` = if_else(batted_balls == 0, 0, line_drives / batted_balls),
      `PU%` = if_else(batted_balls == 0, 0, pop_ups / batted_balls),
      `GB/FB` = if_else(fly_balls == 0, 0, ground_balls / fly_balls),
      `HR/FB` = if_else(fly_balls == 0, 0, home_runs / fly_balls),
      `IFFB%` = if_else(fly_balls == 0, 0, pop_ups / fly_balls),
      `Barrel%` = if_else(batted_balls == 0, 0, barreled_balls / batted_balls),
      `HardHit%` = if_else(batted_balls == 0, 0, hard_hits_balls / batted_balls),
      `Z-Contact%` = if_else(swings_inside_zone == 0, 0, contacted_balls_inside_zone / swings_inside_zone),
      `O-Contact%` = if_else(swings_outside_zone == 0, 0, contacted_balls_outside_zone / swings_outside_zone),
      `Contact%` = if_else(swings == 0, 0, contacted_balls / swings),
      `EV` = if_else(batted_balls == 0, 0, ev_sum / batted_balls),
      `LA` = if_else(batted_balls == 0, 0, la_sum / batted_balls),
      # expected
      `xBA` = if_else(batted_balls == 0, 0, estimated_ba_using_speedangle_bip / batted_balls),
      `xwOBA` = if_else(batted_balls == 0, 0, estimated_woba_using_speedangle_bip / batted_balls),
      `xSLG` = if_else(batted_balls == 0, 0, estimated_slg_using_speedangle_bip / batted_balls),
      `xISO` = if_else(batted_balls == 0, 0, iso_value_bip / batted_balls),
      `xBABIP` = if_else(batted_balls == 0, 0, babip_value_bip / batted_balls)
    )
  
  return(processed_pitcher_statcast_df)
}