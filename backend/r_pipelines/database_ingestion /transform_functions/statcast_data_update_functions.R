process_statcast_df <- function(statcast_df) {
    
  cleaned_statcast_df <- statcast_df %>%
    select(
      pitcher,
      batter,
      game_year,
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
      pitcher = as.character(pitcher),
      batter = as.character(batter),
      game_date = as.Date(game_date),
      launch_angle = as.numeric(launch_angle),
      iso_value = as.numeric(iso_value),
      babip_value = as.numeric(babip_value),
      
      launch_speed_bip = if_else(!is.na(bb_type), launch_speed, NA_real_),
      launch_angle_bip = if_else(!is.na(bb_type), launch_angle, NA_real_),
      ev = launch_speed_bip,
      la = launch_angle_bip,
      min_la = pmax(26 - (ev - 98), 8),
      max_la = pmin(30 + (ev - 98), 50),
      is_barrel_ball = (ev >= 98) & (la >= min_la) & (la <= max_la),
      
      update_date = Sys.Date()
    ) %>%
    as.data.frame() # Strips "baseballr_data" S3 class for RPostgres
  
  return(cleaned_statcast_df)
  
}