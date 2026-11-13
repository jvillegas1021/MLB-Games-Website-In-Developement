get_all_active_mlb_pitchers <- function() {
  
  url = "https://statsapi.mlb.com/api/v1/sports/1/players"
  players_df <- GET(url)
  parsed <- jsonlite::fromJSON(content(players_df, "text"), flatten = TRUE)
  players_df <- parsed$people
  
  pitcher_df <- players_df %>%
    filter((primaryPosition.type == 'Pitcher' |
             primaryPosition.type == 'Two-Way Player'),
           active == TRUE)
  
  cleaned_pitcher_df <- pitcher_df %>%
    mutate(id = as.character(id)) %>%
    select(id,
           fullName,
           primaryPosition.type,
           primaryPosition.name,
           primaryPosition.code,
           primaryPosition.abbreviation,
           active,
           isPlayer) %>%
    rename(
      xMLBAMID = id,
      pitcher_name = fullName,
      position_type = primaryPosition.type,
      position_name = primaryPosition.name,
      position_code = primaryPosition.code,
      position_abbv = primaryPosition.abbreviation,
      is_active = active,
      is_player = isPlayer
    )
  
  return(cleaned_pitcher_df)
}

get_pitcher_season_stats <- function(pitcher_id, season) {
  
  
  url <- paste0("https://statsapi.mlb.com/api/v1/people/", pitcher_id, "/stats")
  params <- list(
    stats = "season",
    group = "pitching",
    season = season
  )
  
  response <- GET(url, query = params)
  
  stop_for_status(response)
  
  data <- content(response, as = "parsed", type = "application/json")
  
  if (length(data$stats) == 0 || length(data$stats[[1]]$splits) == 0) {
    warning(paste("No stats found for pitcher ID:", pitcher_id, "in season:", season))
    return(tibble())
  }
  
  stat_metrics <- as_tibble(data$stats[[1]]$splits[[1]]$stat)
  player_meta  <- data$stats[[1]]$splits[[1]]$player
  
  pitcher_df <- stat_metrics %>%
    mutate(
      xMLBAMID   = as.character(player_meta$id),
      player_name = player_meta$fullName,
      season      = as.integer(season)
    ) %>%
    
    mutate(across(c(era, whip, avg, obp, slg, ops, 
                    inningsPitched, strikeoutsPer9Inn, 
                    walksPer9Inn, hitsPer9Inn, strikePercentage), as.numeric)) %>%
    
    select(xMLBAMID, player_name, season, everything())
  
  return(pitcher_df)
  
}