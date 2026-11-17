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