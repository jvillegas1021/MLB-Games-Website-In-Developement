process_pitcher_statcast_counts <- function(statcast_df, active_pitcher_list) {
  
  # clean df - select only columns we need
  cleaned_statcast_df <- statcast_df %>%
    mutate(
      xMLBAMID = as.character(pitcher),
      game_year = season
    ) %>%
    filter(
      xMLBAMID %in% active_pitcher_list
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