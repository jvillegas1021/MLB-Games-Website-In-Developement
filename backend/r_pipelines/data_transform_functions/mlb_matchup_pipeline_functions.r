##### CREATE MATCHUP DF ##############
create_matchup_df <- function(games_table) {
     matchup_df <- games_table %>%
      dplyr::select(
        gamePk,
        officialDate,
        status.detailedState,
        status.abstractGameCode,
        seriesGameNumber,
        venue.name,
        gameDate,
        dayNight,
        teams.home.team.name,
        teams.home.team.id,
        teams.home.leagueRecord.wins,
        teams.home.leagueRecord.losses,
        teams.home.probablePitcher.fullName,
        teams.home.probablePitcher.id,
        teams.away.team.name,
        teams.away.team.id,
        teams.away.leagueRecord.wins,
        teams.away.leagueRecord.losses,
        teams.away.probablePitcher.fullName,
        teams.away.probablePitcher.id
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
        Away_Pitcher_ID = teams.away.probablePitcher.id
      ) %>%
       dplyr::mutate(
         Game_ID = as.character(Game_ID),
         Home_Pitcher_ID = as.character(Home_Pitcher_ID),
         Away_Pitcher_ID = as.character(Away_Pitcher_ID)
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
######################### ASSIGN ODDS TABLE ##############################

assign_odds_and_win_probability_to_teams <- function(matchup_df, odds_df) {
    
    recent_odds_df <- odds_df %>%
      group_by(game_id) %>%
      slice_max(order_by = update_date, n = 1, with_ties = FALSE) %>% 
      ungroup()
  
    matchup_df <- matchup_df %>%
      left_join(recent_odds_df,
              by=c('Game_ID' = 'game_id'),
              relationship = 'one-to-one') %>%
      mutate(
        Home_Open_Win_Probability = if_else(
          home_open_odds < 0,
          round((abs(home_open_odds) / (abs(home_open_odds) + 100)) * 100, 2),
          round((100 / (home_open_odds + 100)) * 100, 2)
        ),
        Home_Current_Win_Probability = if_else(
          home_close_odds < 0,
          round((abs(home_close_odds) / (abs(home_close_odds) + 100)) * 100, 2),
          round((100 / (home_close_odds + 100)) * 100, 2)
        ),
        Away_Open_Win_Probability = if_else(
          away_open_odds < 0,
          round((abs(away_open_odds) / (abs(away_open_odds) + 100)) * 100, 2),
          round((100 / (away_open_odds + 100)) * 100, 2)
        ),
        Away_Current_Win_Probability = if_else(
          away_close_odds < 0,
          round((abs(away_close_odds) / (abs(away_close_odds) + 100)) * 100, 2),
          round((100 / (away_close_odds + 100)) * 100, 2)
        )
    )
    return(matchup_df)
    }

    
########################## FILTER PITCHER STAT DATAFRAMES ###############################
filter_pitchers_for_matchup <- function(matchup_df, pitcher_stats_df) {

    valid_ids <- c(matchup_df$Home_Pitcher_ID, matchup_df$Away_Pitcher_ID)

    pitcher_stats_df <- pitcher_stats_df %>%
        filter(xMLBAMID %in% valid_ids)

    return(pitcher_stats_df)
    }

############################ Guard for NA starting Pitchers  ##############################
no_starting_pitchers_guard <- function(matchup_df) {
    matchup_df <- matchup_df %>%
        mutate(
            Home_Pitcher_ID = as.character(Home_Pitcher_ID),
            Away_Pitcher_ID = as.character(Away_Pitcher_ID),
            Home_Pitcher = if_else(
                is.na(Home_Pitcher_ID), paste0(Home_Team, '-Pitcher'), Home_Pitcher
                ),
            Home_Pitcher_ID = if_else(
                is.na(Home_Pitcher_ID), paste0(Home_Team, '-Pitcher'), Home_Pitcher_ID
                ),
            Away_Pitcher = if_else(
                is.na(Away_Pitcher_ID), paste0(Away_Team, '-Pitcher'), Away_Pitcher
                ),
            Away_Pitcher_ID = if_else(
                is.na(Away_Pitcher_ID), paste0(Away_Team, '-Pitcher'), Away_Pitcher_ID
                )
            )
    return(matchup_df)
    }


########################### ASSIGN STARTING PITCHER THROWING HANDS ###########################
assign_starting_pitcher_throwing_hands_wins_loses_era <- function(matchup_df, pitcher_stats_df, pitcher_stats_current_year_df) {
    
    matchup_df <- matchup_df %>%
    mutate(
        Home_Pitcher_ID = as.character(Home_Pitcher_ID),
        Away_Pitcher_ID = as.character(Away_Pitcher_ID)
        )
        
    pitcher_stats_df <- pitcher_stats_df %>%
    mutate(
        xMLBAMID = as.character(xMLBAMID)
          ) %>%
    select(
        xMLBAMID,
        Throws
        )

    pitcher_stats_current_year_df <- pitcher_stats_current_year_df %>%
    mutate(
        xMLBAMID = as.character(xMLBAMID)
          ) %>%
    select(
        xMLBAMID,
        Wins,
        Losses,
        ERA
        )
    
    home_pitcher_df <- matchup_df %>%
    select(
        Game_ID,
        Home_Pitcher_ID
        )
    
    home_pitcher_df <- home_pitcher_df %>%
    left_join(
        pitcher_stats_df,
        by=c('Home_Pitcher_ID' = 'xMLBAMID')
        ) %>%
    mutate(
        Throws = if_else(is.na(Throws), 'NA', Throws)
    ) %>%
    rename(
        Home_Pitcher_Hand = Throws
        ) %>%
    left_join(
        pitcher_stats_current_year_df,
        by=c('Home_Pitcher_ID' = 'xMLBAMID')
        ) %>%
    rename(
        Home_Pitcher_Wins = Wins,
        Home_Pitcher_Losses = Losses,
        Home_Pitcher_ERA = ERA
        ) %>%
    select(
        Game_ID,
        Home_Pitcher_ID,
        Home_Pitcher_Hand,
        Home_Pitcher_Wins,
        Home_Pitcher_Losses,
        Home_Pitcher_ERA
        )
    
    away_pitcher_df <- matchup_df %>%
    select(
        Game_ID,
        Away_Pitcher_ID
        )
    
    away_pitcher_df <- away_pitcher_df %>%
    left_join(
        pitcher_stats_df,
        by=c('Away_Pitcher_ID' = 'xMLBAMID')
        ) %>%
    mutate(
        Throws = if_else(is.na(Throws), 'NA', Throws)
    ) %>%
    rename(
        Away_Pitcher_Hand = Throws
        ) %>%
    left_join(
        pitcher_stats_current_year_df,
        by=c('Away_Pitcher_ID' = 'xMLBAMID')
        ) %>%
    rename(
        Away_Pitcher_Wins = Wins,
        Away_Pitcher_Losses = Losses,
        Away_Pitcher_ERA = ERA
        ) %>%
    select(
        Game_ID,
        Away_Pitcher_ID,
        Away_Pitcher_Hand,
        Away_Pitcher_Wins,
        Away_Pitcher_Losses,
        Away_Pitcher_ERA
        )

    matchup_df <- matchup_df %>%
    left_join(home_pitcher_df, by = c("Game_ID", "Home_Pitcher_ID")) %>%
    relocate(Home_Pitcher_Hand, .after = Home_Pitcher_ID) %>%
    left_join(away_pitcher_df, by = c("Game_ID", "Away_Pitcher_ID")) %>%
    relocate(Away_Pitcher_Hand, .after = Away_Pitcher_ID)
    
    return(matchup_df)
}

######################## ASSIGN STARTING PITCHER SCORES ###########################
assign_pitcher_scores <- function(matchup_df, pitcher_df) {
  
  pitcher_df <- pitcher_df %>%
    select(
      xMLBAMID,
      score_control,
      score_strikeout,
      score_contact,
      score_expected,
      score_vs_lhb,
      score_vs_rhb
    ) %>%
    mutate(
      xMLBAMID = as.character(xMLBAMID)
    )
 
  home_pitcher_df <- matchup_df %>%
    select(
      Game_ID,
      Home_Pitcher_ID
    )
  
  away_pitcher_df <- matchup_df %>%
    select(
      Game_ID,
      Away_Pitcher_ID
    )
  
  home_pitcher_scores_df <- home_pitcher_df %>%
    left_join(
      pitcher_df,
      by = c('Home_Pitcher_ID' = 'xMLBAMID')
    ) %>%
    rename(
      Home_pitcher_control = score_control,
      Home_pitcher_strikeout = score_strikeout,
      Home_pitcher_contact = score_contact,
      Home_pitcher_expected = score_expected,
      Home_pitcher_vs_lhb = score_vs_lhb,
      Home_pitcher_vs_rhb = score_vs_rhb
    )
  
  away_pitcher_scores_df <- away_pitcher_df %>%
    left_join(
      pitcher_df,
      by = c('Away_Pitcher_ID' = 'xMLBAMID')
    ) %>%
    rename(
      Away_pitcher_control = score_control,
      Away_pitcher_strikeout = score_strikeout,
      Away_pitcher_contact = score_contact,
      Away_pitcher_expected = score_expected,
      Away_pitcher_vs_lhb = score_vs_lhb,
      Away_pitcher_vs_rhb = score_vs_rhb
    )
  
  matchup_df_pitcher_scores_complete <- matchup_df %>%
    left_join(
      home_pitcher_scores_df,
      by = c('Game_ID', 'Home_Pitcher_ID')
    ) %>%
    left_join(
      away_pitcher_scores_df,
      by = c('Game_ID', 'Away_Pitcher_ID')
    )
  
  return(matchup_df_pitcher_scores_complete)
}
######################## ASSIGN TEAM BATTING LINEUPS FULL ROSTER ###########################
assign_team_batting_scores <- function(matchup_df, team_batting_df) {
  
  team_batting_df <- team_batting_df %>%
    select(
      -team_name,
      -update_date
    )
  
  home_team_df <- matchup_df %>%
    select(
      Game_ID,
      Home_Team_ID
    )
  
  away_team_df <- matchup_df %>%
    select(
      Game_ID,
      Away_Team_ID
    )
  
  home_team_batting_scores_df <- home_team_df %>%
    left_join(
      team_batting_df,
      by = c('Home_Team_ID' = 'team_id')
    ) %>%
    rename(
      Home_batting_discipline = score_discipline,
      Home_batting_impact = score_impact,
      Home_batting_expected = score_expected,
      Home_batting_results = score_results,
      Home_batting_vs_lhp = score_vs_lhp,
      Home_batting_vs_rhp = score_vs_rhp,
      Home_batting_fastballs = score_fastballs,
      Home_batting_breaking = score_breaking
    )
  
  away_team_batting_scores_df <- away_team_df %>%
    left_join(
      team_batting_df,
      by = c('Away_Team_ID' = 'team_id')
    ) %>%
    rename(
      Away_batting_discipline = score_discipline,
      Away_batting_impact = score_impact,
      Away_batting_expected = score_expected,
      Away_batting_results = score_results,
      Away_batting_vs_lhp = score_vs_lhp,
      Away_batting_vs_rhp = score_vs_rhp,
      Away_batting_fastballs = score_fastballs,
      Away_batting_breaking = score_breaking
    )
  
  matchup_df_batting_scores_complete <- matchup_df %>%
    left_join(
      home_team_batting_scores_df,
      by = c('Game_ID', 'Home_Team_ID')
    ) %>%
    left_join(
      away_team_batting_scores_df,
      by = c('Game_ID', 'Away_Team_ID')
    )
  
  return(matchup_df_batting_scores_complete)
}


######### PROABABLE PITCHER & PITCHER STATS & LINE UP HYDRATION FLAGS##################################
probable_pitcher_and_lineup_hydration_flags <- function(matchup_df, starting_pitcher_df) {
    
    matchup_df <- matchup_df %>%
        mutate(
            Home_Pitcher_Stats_Available = Home_Pitcher_ID %in% starting_pitcher_df$xMLBAMID,
            Away_Pitcher_Stats_Available = Away_Pitcher_ID %in% starting_pitcher_df$xMLBAMID,
            Pitcher_Stats_Available = Home_Pitcher_Stats_Available & Away_Pitcher_Stats_Available
        )

    return(matchup_df)
    }
########################## CALCULATE MATCHUP SCORE ###############################
calculate_matchup_score <- function(matchup_df) {
  
  matchup_df <- matchup_df %>%
    mutate(
      # 1. Plate Discipline Battles (Hitter Eye vs Pitcher Control)
      Home_Offense_Edge_Disc  = Home_batting_discipline - Away_pitcher_control,
      Away_Offense_Edge_Disc  = Away_batting_discipline - Home_pitcher_control,
      
      # 2. Batted Ball Battles (Hitter Impact vs Pitcher Contact Suppression)
      Home_Offense_Edge_Pow   = Home_batting_impact - Away_pitcher_contact,
      Away_Offense_Edge_Pow   = Away_batting_impact - Home_pitcher_contact,
      
      # 3. Expected Performance Battles (Hitter Expected vs Pitcher Expected)
      Home_Offense_Edge_Exp   = Home_batting_expected - Away_pitcher_expected,
      Away_Offense_Edge_Exp   = Away_batting_expected - Home_pitcher_expected,
      
      # 4. Total Net Game Margins (Home Advantage minus Away Advantage)
      Net_Discipline_Margin   = Home_Offense_Edge_Disc - Away_Offense_Edge_Disc,
      Net_Power_Margin        = Home_Offense_Edge_Pow - Away_Offense_Edge_Pow,
      Net_Expected_Margin     = Home_Offense_Edge_Exp - Away_Offense_Edge_Exp,
      
      Master_Matchup_Score = (Net_Discipline_Margin * 0.18238419) + 
        (Net_Power_Margin      * 0.07179902) + 
        (Net_Expected_Margin   * 0.06473861),
      
      Master_Matchup_Score = replace_na(Master_Matchup_Score, 0)
    )
  
  return(matchup_df)
}

############################# CALCULATE FATIGUE SCORE ####################################
calculate_team_travel_fatigue_score <- function(matchup_df, team_travel_df) {

    team_travel_df <- team_travel_df %>%
        mutate(
            fatigue_score = replace_na(fatigue_score, 0)
            )
    
    matchup_df <- matchup_df %>%
        left_join(
            team_travel_df %>% select(team_name, fatigue_score),
            by = c("Home_Team" = "team_name")
        ) %>%
        rename(Home_Fatigue_Score = fatigue_score) %>%
        
        left_join(
            team_travel_df %>% select(team_name, fatigue_score),
            by = c("Away_Team" = "team_name")
        ) %>%
        rename(Away_Fatigue_Score = fatigue_score) %>%
        
        # Add fatigue into context scores
        mutate(
            Home_Fatigue_Adjust = pmax(pmin(Home_Fatigue_Score, 1), -1),
            Away_Fatigue_Adjust = pmax(pmin(Away_Fatigue_Score, 1), -1),
        
            Home_Context_Score = Home_Context_Score - Home_Fatigue_Adjust,
            Away_Context_Score = Away_Context_Score - Away_Fatigue_Adjust
        ) %>%
 
        # Drop the temporary fatigue columns
        select(-Home_Fatigue_Score, -Away_Fatigue_Score)
    
    return(matchup_df)
}


##################### CALCULATE WIN PROB AND PREDICTION #####################
calculate_win_prob_prediction <- function(matchup_df,
                                          probability_model) {
    
  matchup_df <- matchup_df %>%
  mutate(
      Predicted_Winner = if_else(Master_Matchup_Score >= 0, Home_Team, Away_Team),
      Predicted_Loser = if_else(Predicted_Winner == Home_Team, Away_Team, Home_Team),
      Win_Probability = round((predict(probability_model, newdata = matchup_df, type = "response") * 100), 2),
      Win_Probability = if_else(Master_Matchup_Score < 0,
                                100 - Win_Probability,
                                Win_Probability)
      )
  
  matchup_df <- matchup_df %>%
    mutate(
      Win_Probability = if_else(
      !Pitcher_Stats_Available,
      NA_real_,
      Win_Probability
      ),
      Predicted_Winner = if_else(
          !Pitcher_Stats_Available,
          "No Prediction",
          Predicted_Winner
      ),
      Predicted_Loser = if_else(
          !Pitcher_Stats_Available,
          "No Prediction",
          Predicted_Loser
      )
    )
      
  matchup_df <- matchup_df %>%
      mutate(
          Prediction_Status = case_when(
              !Pitcher_Stats_Available ~ "No Prediction",
              TRUE ~ "Full Prediction"
          )
      )

  return(matchup_df)
  }
################## CALCULATE MODEL ODDS AND EDGE ################################
calculate_model_odds_and_edge <- function(matchup_df) {
  
  matchup_df <- matchup_df %>%
    mutate(
      
      winner_win_prob = round(Win_Probability, 2),
      loser_win_prob  = round(100 - winner_win_prob, 2),
      
      Home_Team_Model_Win_Probability = if_else(
        Predicted_Winner == Home_Team, winner_win_prob, loser_win_prob
      ),
      Away_Team_Model_Win_Probability = if_else(
        Predicted_Winner == Away_Team, winner_win_prob, loser_win_prob
      ),

    
      # fair probabilities (0–1)
      p_fair = winner_win_prob / 100,
      q_fair = loser_win_prob  / 100,
    
      winner_odds_int = if_else(
        p_fair > 0.5,
        -(p_fair / (1 - p_fair)) * 100,          # favorite
        ((1 - p_fair) / p_fair) * 100            # underdog (rare for "winner")
      ),
      loser_odds_int = if_else(
        q_fair > 0.5,
        -(q_fair / (1 - q_fair)) * 100,          # favorite (rare for "loser")
        ((1 - q_fair) / q_fair) * 100            # underdog
      ),

      # assign numeric odds to teams
      Home_Odds_Num = if_else(
        Predicted_Winner == Home_Team,
        winner_odds_int,
        loser_odds_int
      ),
      Away_Odds_Num = if_else(
        Predicted_Winner == Home_Team,
        loser_odds_int,
        winner_odds_int
      ),
      
      # formatted odds for display
      Home_Team_Model_Odds = if_else(
        Home_Odds_Num < 0,
        round(abs(Home_Odds_Num)) * (-1),
        round(Home_Odds_Num) * 1
      ),
      Away_Team_Model_Odds = if_else(
        Away_Odds_Num < 0,
        round(abs(Away_Odds_Num)) * (-1),
        round(Away_Odds_Num) * 1
      ),
      
      
      # compute edge using numeric odds
      Home_Team_Open_Edge = round(Home_Team_Model_Win_Probability - Home_Open_Win_Probability, 2),
      Home_Team_Current_Edge = round(Home_Team_Model_Win_Probability - Home_Current_Win_Probability, 2),
      Away_Team_Open_Edge = round(Away_Team_Model_Win_Probability - Away_Open_Win_Probability, 2),
      Away_Team_Current_Edge = round(Away_Team_Model_Win_Probability - Away_Current_Win_Probability, 2)

    )
  
  return(matchup_df)
}
################## betting logic ##############################
calculate_betting_logic <- function(matchup_df, min_favorite_edge = 2.0, min_underdog_edge = 5.0) {
  
  betting_df <- matchup_df %>%
    mutate(
      # 1. Clean up edge inputs safely (on a 0-100 scale)
      Home_Team_Current_Edge = as.numeric(replace_na(Home_Team_Current_Edge, 0)),
      Away_Team_Current_Edge = as.numeric(replace_na(Away_Team_Current_Edge, 0)),
      
      # 2. Explicitly flag who the sportsbook thinks is the favorite/underdog
      Vegas_Favorite = case_when(
        home_close_odds < away_close_odds ~ Home_Team,
        home_close_odds > away_close_odds ~ Away_Team,
        TRUE ~ "Even"
      ),
      
      # 3. Dynamic Threshold check for HOME team (Scale: 50.0)
      Place_Bet_Home_Current = case_when(
        # Home is your model's favorite -> requires a smaller edge (e.g., +2.0%)
        Home_Team_Model_Win_Probability >= 50.0 & Home_Team_Current_Edge >= min_favorite_edge ~ TRUE,
        # Home is your model's underdog -> requires a much tighter edge (e.g., +5.0%)
        Home_Team_Model_Win_Probability < 50.0 & Home_Team_Current_Edge >= min_underdog_edge ~ TRUE,
        TRUE ~ FALSE
      ),
      
      # 4. Dynamic Threshold check for AWAY team (Scale: 50.0)
      Place_Bet_Away_Current = case_when(
        # Away is your model's favorite -> requires a smaller edge (e.g., +2.0%)
        Away_Team_Model_Win_Probability >= 50.0 & Away_Team_Current_Edge >= min_favorite_edge ~ TRUE,
        # Away is your model's underdog -> requires a much tighter edge (e.g., +5.0%)
        Away_Team_Model_Win_Probability < 50.0 & Away_Team_Current_Edge >= min_underdog_edge ~ TRUE,
        TRUE ~ FALSE
      ),
      
      # 5. Assign final bet selection
      Bet_Team_Current = case_when(
        Place_Bet_Home_Current & Place_Bet_Away_Current ~ "No Bet", # Conflict shield
        Place_Bet_Home_Current ~ Home_Team,
        Place_Bet_Away_Current ~ Away_Team,
        TRUE ~ "No Bet"
      ),
      
      # 6. Label the pick type so you can track performance perfectly
      Bet_Type = case_when(
        Bet_Team_Current == "No Bet" ~ "No Bet",
        Bet_Team_Current == Vegas_Favorite ~ "Favorite Bet",
        TRUE ~ "Underdog Bet"
      )
    )
  
  return(betting_df)
}


#################### add update date ###########################

add_update_date <- function(matchup_df) {
  matchup_df <- matchup_df %>%
    mutate(
      matchup_card_update_date = Sys.time())
  
  return(matchup_df)
}



