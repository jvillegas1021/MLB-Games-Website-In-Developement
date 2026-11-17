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
