get_all_active_mlb_batters <- function() {
  
  url = "https://statsapi.mlb.com/api/v1/sports/1/players"
  players_df <- GET(url)
  parsed <- jsonlite::fromJSON(content(players_df, "text"), flatten = TRUE)
  players_df <- parsed$people
  
  batter_df <- players_df %>%
    filter((primaryPosition.type != 'Pitcher' |
              primaryPosition.type == 'Two-Way Player'),
           active == TRUE)
  
  cleaned_batter_df <- batter_df %>%
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
      batter_name = fullName,
      position_type = primaryPosition.type,
      position_name = primaryPosition.name,
      position_code = primaryPosition.code,
      position_abbv = primaryPosition.abbreviation,
      is_active = active,
      is_player = isPlayer
    )
  
  return(cleaned_batter_df)
}

get_batter_season_stats <- function(batter_id, season) {
  
  
  url <- paste0("https://statsapi.mlb.com/api/v1/people/", batter_id, "/stats")
  params <- list(
    stats = "season",
    group = "batting",
    season = season
  )
  
  response <- GET(url, query = params)
  
  stop_for_status(response)
  
  data <- content(response, as = "parsed", type = "application/json")
  
  if (length(data$stats) == 0 || length(data$stats[[1]]$splits) == 0) {
    warning(paste("No stats found for batter ID:", batter_id, "in season:", season))
    return(tibble())
  }
  
  stat_metrics <- as_tibble(data$stats[[1]]$splits[[1]]$stat)
  player_meta  <- data$stats[[1]]$splits[[1]]$player
  
  batter_df <- stat_metrics %>%
    mutate(
      xMLBAMID   = as.character(player_meta$id),
      player_name = player_meta$fullName,
      season      = as.integer(season)
    ) %>%
    
    mutate(across(c(era, whip, avg, obp, slg, ops, 
                    inningsPitched, strikeoutsPer9Inn, 
                    walksPer9Inn, hitsPer9Inn, strikePercentage), as.numeric)) %>%
    
    select(xMLBAMID, player_name, season, everything())
  
  return(batter_df)
  
}