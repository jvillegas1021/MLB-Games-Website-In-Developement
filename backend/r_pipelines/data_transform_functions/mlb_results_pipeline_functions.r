################### CREATE MLB RESULTS DF ########################
create_matchup_df <- function(games_table) {
  
  check_col_list <- c("isTie", "teams.away.score", "teams.away.isWinner", "teams.away.probablePitcher.id",
                      "teams.away.probablePitcher.fullName", "teams.away.probablePitcher.link", "teams.home.score",
                      "teams.home.isWinner", "teams.home.probablePitcher.id", "teams.home.probablePitcher.fullName",
                      "teams.home.probablePitcher.link", "rescheduleDate", "rescheduleGameDate", "status.reason",
                      "rescheduledFrom", "rescheduledFromDate", "resumeDate", "resumeGameDate",
                      "resumedFrom", "resumedFromDate")
  
  missing_cols <- setdiff(check_col_list, colnames(games_table))
  
  if (length(missing_cols) > 0) {
    games_table[missing_cols] <- NA
  }
  
  matchup_df <- games_table %>%
    dplyr::mutate(
      gamePk = as.character(gamePk),
      isTie = ifelse(is.na(isTie), NA, as.logical(isTie)),
      teams.home.isWinner = ifelse(is.na(teams.home.isWinner), NA, as.logical(teams.home.isWinner)),
      teams.away.isWinner = ifelse(is.na(teams.away.isWinner), NA, as.logical(teams.away.isWinner)),
      teams.away.probablePitcher.link = ifelse(is.na(teams.away.probablePitcher.link), NA_character_, as.character(teams.away.probablePitcher.link)),
      teams.home.probablePitcher.link = ifelse(is.na(teams.home.probablePitcher.link), NA_character_, as.character(teams.home.probablePitcher.link)),
      teams.away.probablePitcher.id = ifelse(is.na(teams.away.probablePitcher.id), NA_character_, as.character(teams.away.probablePitcher.id)),
      teams.away.probablePitcher.id = ifelse(is.na(teams.away.probablePitcher.id), NA_character_, as.character(teams.away.probablePitcher.id)),
      teams.home.probablePitcher.fullName = ifelse(is.na(teams.home.probablePitcher.fullName), "TBD", as.character(teams.home.probablePitcher.fullName)),
      teams.away.probablePitcher.fullName = ifelse(is.na(teams.away.probablePitcher.fullName), "TBD", as.character(teams.away.probablePitcher.fullName)),
      teams.home.score = ifelse(is.na(teams.home.score), NA_real_, as.numeric(teams.home.score)),
      teams.away.score = ifelse(is.na(teams.away.score), NA_real_, as.numeric(teams.away.score)),
      rescheduleDate = ifelse(is.na(rescheduleDate), NA_character_, as.character(rescheduleDate)),
      rescheduleGameDate = ifelse(is.na(rescheduleGameDate), NA_character_, as.character(rescheduleGameDate)),
      status.reason = ifelse(is.na(status.reason), NA_character_, as.character(status.reason)),
      rescheduledFrom = ifelse(is.na(rescheduledFrom), NA_character_, as.character(rescheduledFrom)),
      rescheduledFromDate = ifelse(is.na(rescheduledFromDate), NA_character_, as.character(rescheduledFromDate)),
      resumeDate = ifelse(is.na(resumeDate), NA_character_, as.character(resumeDate)),
      resumeGameDate = ifelse(is.na(resumeGameDate), NA_character_, as.character(resumeGameDate)),
      resumedFrom = ifelse(is.na(resumedFrom), NA_character_, as.character(resumedFrom)),
      resumedFromDate = ifelse(is.na(resumedFromDate), NA_character_, as.character(resumedFromDate))
    ) %>%
    dplyr::rename(
      Game_ID = gamePk,
      Game_Date = officialDate,
      Game_Status = status.detailedState,
      Game_Status_Code = status.abstractGameCode,
      Game_In_Series = seriesGameNumber,
      Game_Venue = venue.name,
      Game_Time = gameDate,
      Day_Night = dayNight,
      Home_Team = teams.home.team.name,
      Home_Team_ID = teams.home.team.id,
      Home_Team_Wins = teams.home.leagueRecord.wins,
      Home_Team_Losses = teams.home.leagueRecord.losses,
      Home_Pitcher = teams.home.probablePitcher.fullName,
      Home_Pitcher_ID = teams.home.probablePitcher.id,
      Away_Team = teams.away.team.name,
      Away_Team_ID = teams.away.team.id,
      Away_Team_Wins = teams.away.leagueRecord.wins,
      Away_Team_Losses = teams.away.leagueRecord.losses,
      Away_Pitcher = teams.away.probablePitcher.fullName,
      Away_Pitcher_ID = teams.away.probablePitcher.id,
      Tie_Game = isTie,
      Home_Team_Score = teams.home.score,
      Home_Team_Is_Winner = teams.home.isWinner,
      Away_Team_Score = teams.away.score,
      Away_Team_Is_Winner = teams.away.isWinner
    )
  
  time <- matchup_df$Game_Time
  dt_utc <- ymd_hms(time, tz = 'UTC')
  dt_est <- with_tz(dt_utc, tzone = 'America/New_York')
  times_est <- format(dt_est, "%I:%M:%p")
  
  matchup_df$Game_Time <- times_est
  matchup_df$Game_Time <- gsub(":(AM|PM)$", " \\1", matchup_df$Game_Time)
  matchup_df$Game_Time_Stamp <- ymd_hms(games_table$gameDate, tz = 'UTC')
  matchup_df$Game_Date_Time_Parsed <- matchup_df$Game_Time_Stamp
  
  return(matchup_df)
}

create_results_df <- function(games_table_df) {
  
  results_df <- games_table_df %>%
    select(
      Game_ID,
      Game_Date,
      Game_Status,
      Game_In_Series,
      Game_Venue,
      Game_Time,
      Day_Night,
      Home_Team,
      Home_Team_ID,
      Home_Team_Score,
      Home_Team_Is_Winner,
      Away_Team,
      Away_Team_ID,
      Away_Team_Score,
      Away_Team_Is_Winner
    ) %>%
    mutate(
      update_date = Sys.time()
    )
  
  return(results_df)
  
}


