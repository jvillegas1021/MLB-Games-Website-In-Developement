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
    select(xMLBAMID, player_name, season, everything())
  
  return(batter_df)
  
}