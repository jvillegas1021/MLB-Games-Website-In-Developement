process_statcast_df <- function(statcast_df) {
  
  cleaned_statcast_df <- statcast_df %>%
    select(
      pitcher,
      game_year,
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
      pitcher = as.character(pitcher),
      batter = as.character(batter),
      launch_angle = as.numeric(launch_angle),
      iso_value = as.numeric(iso_value),
      babip_value = as.numeric(babip_value),
      update_date = Sys.Date()
    )
  
  return(cleaned_statcast_df)
}