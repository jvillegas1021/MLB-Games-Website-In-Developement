################# mlb games ################################
get_mlb_games <- function(game_date = as.Date(format(Sys.time(), tz = "America/New_York"))) {

    url <- paste0(
        "https://statsapi.mlb.com/api/v1/schedule?sportId=1&date=",
        game_date,
        "&hydrate=probablePitcher(note)"
    )

    games_df <- GET(url)
    parsed <- jsonlite::fromJSON(content(games_df, "text"), flatten = TRUE)

    # If no games exist for this date, return NULL early
    if (length(parsed$dates) == 0 || length(parsed$dates$games[[1]]) == 0) {
        message("No MLB games for this date.")
        return(NULL)
    }

    games_table <- parsed$dates$games[[1]]

    # Filter out All-Star and Exhibition
    games_table <- games_table %>%
        filter(!gameType %in% c('A', 'E'))

    return(games_table)
}


#################### CREATE ODDS TABLE ####################################
get_espn_mlb_odds <- function(game_date = as.Date(format(Sys.time(), tz = "America/New_York"))) {

    odds_game_date <- format(game_date, "%Y%m%d")
    
    odds_url <- paste0("https://site.api.espn.com/apis/site/v2/sports/baseball/mlb/scoreboard?dates=", odds_game_date)
    odds_data <- GET(odds_url)
    odds_df <- jsonlite::fromJSON(content(odds_data, "text"), flatten = TRUE)

    home_team_names <- character()
    away_team_names <- character()
    home_team_odds <- character()
    away_team_odds <- character()
    game_timestamp <- character()
    
    for (game in seq_len(length(odds_df$events$competitions))) {
        matchups <- odds_df$events$competitions[[game]]

        
        if (!is.null(matchups$odds) && length(matchups$odds) > 0) {
            home_team_names[game] <- matchups$odds[[1]]$homeTeamOdds.team.displayName
            home_team_odds[game] <- matchups$odds[[1]]$moneyline.home.close.odds
            away_team_names[game] <- matchups$odds[[1]]$awayTeamOdds.team.displayName
            away_team_odds[game] <- matchups$odds[[1]]$moneyline.away.close.odds
            game_timestamp[game] <- matchups$date
            }
        else {
            home_team_names[game] <- matchups$competitors[[1]]$team.displayName[1]
            home_team_odds[game] <- "Game Started"
            away_team_names[game] <- matchups$competitors[[1]]$team.displayName[2]
            away_team_odds[game] <- "Game Started"
            game_timestamp[game] <- matchups$date
            }
        }
    odds_table <- data.frame(
        Home_Team = home_team_names,
        Home_Team_ESPN_Odds = home_team_odds,
        Away_Team = away_team_names,
        Away_Team_ESPN_Odds = away_team_odds,
        Game_Timestamp = game_timestamp
        )

    odds_table$Game_Timestamp <- ymd_hm(odds_table$Game_Timestamp, quiet = TRUE)



    return(odds_table)
    }
