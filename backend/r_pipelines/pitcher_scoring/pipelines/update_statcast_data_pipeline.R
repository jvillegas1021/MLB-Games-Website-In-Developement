
update_statcast_data <- function(current_date = Sys.Date()) {
  
  # 1. Ensure current_date is always a Date object (fixes string input error)
  current_date <- as.Date(current_date)
  current_year <- format(current_date, '%Y')
  table_name <- paste0('statcast_', current_year)
  
  start_date <- current_date - 2
  end_date <- current_date
  date_range_list <- seq.Date(from = start_date, by = 1, to = end_date)
  
  # 2. Pull data first
  statcast_df <- statcast_search_pitchers(start_date = start_date, end_date = end_date)
  
  # 3. Guard against empty pulls before touching the database
  if (is.null(statcast_df) || nrow(statcast_df) == 0) {
    message(sprintf("No Statcast data returned for %s to %s. Skipping update.", start_date, end_date))
    return(invisible(FALSE))
  }
  
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
  
  # 4. Delete overlapping window and append fresh rows using the same table_name
  delete_statcast_rows_from_df(table_name, date_range_list)
  write_df_to_sql_append(cleaned_statcast_df, table_name)
  
  return(invisible(TRUE))
}

