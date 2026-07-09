##### CREATE MATCHUP DF ##############
create_matchup_df <- function(games_table) {
     matchup_df <- games_table %>%
      dplyr::select(
        gamePk,
        officialDate,
        status.detailedState,
        seriesGameNumber,
        venue.name,
        gameDate,
        dayNight,
        teams.home.team.name,
        teams.home.team.id,
        teams.home.probablePitcher.fullName,
        teams.home.probablePitcher.id,
        teams.away.team.name,
        teams.away.team.id,
        teams.away.probablePitcher.fullName,
        teams.away.probablePitcher.id
      ) %>%
      dplyr::rename(
        Game_ID = gamePk,
        Game_Date = officialDate,
        Game_Status = status.detailedState,
        Game_In_Series = seriesGameNumber,
        Game_Venue = venue.name,
        Game_Time = gameDate,
        Day_Night = dayNight,
        Home_Team = teams.home.team.name,
        Home_Team_ID = teams.home.team.id,
        Home_Pitcher = teams.home.probablePitcher.fullName,
        Home_Pitcher_ID = teams.home.probablePitcher.id,
        Away_Team = teams.away.team.name,
        Away_Team_ID = teams.away.team.id,
        Away_Pitcher = teams.away.probablePitcher.fullName,
        Away_Pitcher_ID = teams.away.probablePitcher.id
      )
    
    time <- matchup_df$Game_Time
    dt_utc <- ymd_hms(time, tz = 'UTC')
    dt_est <- with_tz(dt_utc, tzone = 'America/New_York')
    times_est <- format(dt_est, "%I:%M:%p")
    
    matchup_df$Game_Time <- times_est
    matchup_df$Game_Time_Stamp <- ymd_hms(games_table$gameDate, tz = 'UTC')
    matchup_df$Game_Date_Time_Parsed <- matchup_df$Game_Time_Stamp

    return(matchup_df)
    }
######################### ASSIGN ODDS TABLE ##############################

assign_odds_to_teams <- function(matchup_df, odds_df) {
    
    matchup_df <- matchup_df %>%
    left_join(odds_df,
              by=c('Home_Team',
                   'Away_Team',
                   'Game_Date_Time_Parsed' = 'Game_Timestamp'),
              relationship = 'one-to-one')
    return(matchup_df)
    }

############################ ASSIGN LEAGUE AND DIVISION IDS ###########################
assign_league_and_division_ids <- function(matchup_df, mlb_team_record_df) {
  
  mlb_team_record_df <- mlb_team_record_df %>%
    select(team_id, league_name, league_id, division_id)

  home_df <- matchup_df %>% distinct(Home_Team_ID)
  away_df <- matchup_df %>% distinct(Away_Team_ID)

  home_team_record_df <- home_df %>%
    left_join(mlb_team_record_df,
              by = c('Home_Team_ID' = 'team_id'),
              relationship = 'one-to-one') %>%
    rename(Home_Team_League = league_name,
           Home_Team_League_ID = league_id,
           Home_Team_Division_ID = division_id) %>%
    select(Home_Team_ID,
           Home_Team_League,
           Home_Team_League_ID,
           Home_Team_Division_ID)

  away_team_record_df <- away_df %>%
    left_join(mlb_team_record_df,
              by = c('Away_Team_ID' = 'team_id'),
              relationship = 'one-to-one') %>%
    rename(Away_Team_League = league_name,
           Away_Team_League_ID = league_id,
           Away_Team_Division_ID = division_id) %>%
    select(Away_Team_ID,
           Away_Team_League,
           Away_Team_League_ID,
           Away_Team_Division_ID)

  matchup_df <- matchup_df %>%
    left_join(home_team_record_df,
              by='Home_Team_ID',
             relationship='many-to-one') %>%
    left_join(away_team_record_df,
              by='Away_Team_ID',
             relationship='many-to-one')

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
######################## PARSE LINE UP ##############################
parse_lineup <- function(x) {
    x |>
      gsub("[{}]", "", x = _) |>
      strsplit(",") |>
      unlist() |>
      as.integer()
}

####################### ASSIGN HITTER LINEUPS LISTS TO TEAMS ############################
assign_batting_lineups_with_hydration_status <- function(matchup_df, team_batting_df, hist_team_batting_df) {
  
  prev_team_batting_stats_df <- hist_team_batting_df %>%
    select(gamePk, team_id) %>%
    mutate(game_id_team_id_label = paste0(gamePk, '-', team_id))
  
  current_team_batting_stats_df <- team_batting_df %>%
    select(gamePk, team_id) %>%
    mutate(game_id_team_id_label = paste0(gamePk, '-', team_id))
  
  # HOME hydration
  matchup_df <- matchup_df %>%
    mutate(
      game_id_team_id_label_home = paste0(Game_ID, '-', Home_Team_ID),
      Home_Lineup_Hydrated = if_else(
        game_id_team_id_label_home %in% prev_team_batting_stats_df$game_id_team_id_label |
          game_id_team_id_label_home %in% current_team_batting_stats_df$game_id_team_id_label,
        TRUE,
        FALSE
      )
    )
  
  # AWAY hydration
  matchup_df <- matchup_df %>%
    mutate(
      game_id_team_id_label_away = paste0(Game_ID, '-', Away_Team_ID),
      Away_Lineup_Hydrated = if_else(
        game_id_team_id_label_away %in% prev_team_batting_stats_df$game_id_team_id_label |
          game_id_team_id_label_away %in% current_team_batting_stats_df$game_id_team_id_label,
        TRUE,
        FALSE
      )
    )
  
  return(matchup_df)
}

####################### ASSIGN HITTER LINEUPS LISTS TO TEAMS HISTORICAL ############################

assign_batting_lineups_with_hydration_status_historical <- function(matchup_df, team_batting_df) {

    matchup_df <- matchup_df %>%
      mutate(
        Game_Time_Stamp = with_tz(Game_Time_Stamp, "America/New_York")
      )
    home_table <- matchup_df %>%
        select(
            home_gamepk_team_name_label,
            Game_Time_Stamp,
        ) %>%
        left_join(
          team_batting_df,
          by = c('home_gamepk_team_name_label' = 'gamepk_team_name_label')
        ) %>%
        mutate(
          Home_Lineup_Hydrated = if_else(
            (Game_Time_Stamp - minutes(60)) <= `update date`,
            'Yes',
            'No'
          )
        ) %>%
        rename(
          Home_Batting_Lineup = hitter_player_ids
        ) %>%
        select(
            home_gamepk_team_name_label,
            Home_Batting_Lineup,
            Home_Lineup_Hydrated
        )
    
    
    away_table <- matchup_df %>% 
        select(
            away_gamepk_team_name_label,
            Game_Time_Stamp,
        ) %>%
        left_join(
            team_batting_df,
            by = c('away_gamepk_team_name_label' = 'gamepk_team_name_label')
        ) %>%
        mutate(
            Away_Lineup_Hydrated = if_else(
                (Game_Time_Stamp - minutes(60)) <= `update date`,
                'Yes',
                'No'
              )
        ) %>%
        rename(
            Away_Batting_Lineup = hitter_player_ids
        ) %>%
        select(
            away_gamepk_team_name_label,
            Away_Batting_Lineup,
            Away_Lineup_Hydrated
        )
    
    matchup_df <- matchup_df %>%
    left_join(
      home_table,
      by = c('home_gamepk_team_name_label')
    ) %>%
    left_join(
      away_table,
      by = c('away_gamepk_team_name_label')
    )


return(matchup_df)

}
############### join for ballpark factor ####################
join_ball_park_df <- function(matchup_df, ball_park_factor_df) {
    
    matchup_df <- matchup_df %>%
    left_join(ball_park_factor_df, by = c('Game_Venue' = 'Venue', 'Day_Night'))
    matchup_df <- matchup_df %>%
        rename(Park_Factor = Park.Factor)

    return(matchup_df)
    }

######### PROABABLE PITCHER & PITCHER STATS & LINE UP HYDRATION FLAGS##################################
probable_pitcher_and_lineup_hydration_flags <- function(matchup_df, starting_pitcher_df) {
    
    matchup_df <- matchup_df %>%
    mutate(Probable_Pitchers = if_else(
        Home_Pitcher != 'TBD' & Away_Pitcher != 'TBD',
           'Yes',
           'No'
           )
        )
    
    matchup_df <- matchup_df %>%
        mutate(
            Home_Pitcher_Stats_Available = Home_Pitcher_ID %in% starting_pitcher_df$xMLBAMID,
            Away_Pitcher_Stats_Available = Away_Pitcher_ID %in% starting_pitcher_df$xMLBAMID,
            Pitcher_Stats_Available = Home_Pitcher_Stats_Available & Away_Pitcher_Stats_Available
        )
    
    
    matchup_df <- matchup_df %>%
      mutate(
        Lineup_Hydration = if_else(
          Home_Lineup_Hydrated == TRUE & Away_Lineup_Hydrated == TRUE,
          "Yes",
          "No"
        )
      )

    return(matchup_df)
    }

###################### Calculate Pitcher Score ALL #########################################
calculate_starting_pitcher_scores <- function(matchup_df,
                                              starting_pitcher_df,
                                              starting_pitcher_recent_form_df,
                                              pitcher_season_benchmark_df,
                                              pitcher_recent_form_benchmark_df) {
    
    home_season_pitcher_df <- starting_pitcher_df %>%
        filter(xMLBAMID %in% matchup_df$Home_Pitcher_ID)
        
    home_recent_pitcher_df <- starting_pitcher_recent_form_df %>%
        filter(xMLBAMID %in% matchup_df$Home_Pitcher_ID)
        
    away_season_pitcher_df <- starting_pitcher_df %>%
        filter(xMLBAMID %in% matchup_df$Away_Pitcher_ID)
        
    away_recent_pitcher_df <- starting_pitcher_recent_form_df %>%
        filter(xMLBAMID %in% matchup_df$Away_Pitcher_ID)
        
    home_starting_pitcher_season_score_df <- starting_pitcher_season_scores(home_season_pitcher_df,
                                                              pitcher_season_benchmark_df)  
        
    home_starting_pitcher_recent_score_df <- starting_pitcher_recent_scores(home_recent_pitcher_df,
                                                              pitcher_recent_form_benchmark_df)    
        
    home_starting_pitcher_total_score <- starting_pitcher_total_score(home_starting_pitcher_season_score_df,
                                                                      home_starting_pitcher_recent_score_df,
                                                                      label = "Home_Pitcher_Score")
    
    away_starting_pitcher_season_score_df <- starting_pitcher_season_scores(away_season_pitcher_df,
                                                              pitcher_season_benchmark_df)
    
    away_starting_pitcher_recent_score_df <- starting_pitcher_recent_scores(away_recent_pitcher_df,
                                                              pitcher_recent_form_benchmark_df)     
    
       
    away_starting_pitcher_total_score <- starting_pitcher_total_score(away_starting_pitcher_season_score_df,
                                                                 away_starting_pitcher_recent_score_df,
                                                                 label = "Away_Pitcher_Score")        
    
    matchup_df <- matchup_df %>%
    left_join(home_starting_pitcher_total_score,
              by = c("Home_Pitcher_ID" = "pitcher")
              )
    
    matchup_df <- matchup_df %>%
    left_join(away_starting_pitcher_total_score,
              by = c("Away_Pitcher_ID" = "pitcher")
              )
    
    matchup_df <- matchup_df %>%
      mutate(
        Home_Pitcher_Score = if_else(is.na(Home_Pitcher_Score), 0, Home_Pitcher_Score),
        Away_Pitcher_Score = if_else(is.na(Away_Pitcher_Score), 0, Away_Pitcher_Score)
      )

    return(matchup_df)
    }


################################# CALCULATE PITCHER SEASON SCORE##################################
starting_pitcher_season_scores <- function(starting_pitcher_season_df,
                                    season_benchmark_df) {
    # create pitcher score df
    score_table <- data.frame(pitcher = starting_pitcher_season_df$xMLBAMID)
    
    columns_list <- unique(season_benchmark_df$stat)

    for (stat in columns_list) {
        stat_benchmark <- season_benchmark_df[season_benchmark_df$stat == stat, ]
        min_stat <- stat_benchmark$min
        first_q_stat <- stat_benchmark$first_q
        second_q_stat <- stat_benchmark$second_q
        third_q_stat <- stat_benchmark$third_q
        max_stat <- stat_benchmark$max
        scale_points <- stat_benchmark$weight
        high_low <- stat_benchmark$high_low


        pitcher_stat_value <- starting_pitcher_season_df[[stat]]
        points <- numeric(length(pitcher_stat_value))
        
        if (high_low == "low") {
            points[pitcher_stat_value > max_stat]      <- 0.0
            points[pitcher_stat_value < max_stat]      <- 0.25
            points[pitcher_stat_value < third_q_stat]  <- 0.50
            points[pitcher_stat_value < second_q_stat] <- 0.75
            points[pitcher_stat_value < first_q_stat]  <- 1.00
        } else {
            points[pitcher_stat_value < min_stat]      <- 0.0
            points[pitcher_stat_value > min_stat]      <- 0.25
            points[pitcher_stat_value > first_q_stat]  <- 0.50
            points[pitcher_stat_value > second_q_stat] <- 0.75
            points[pitcher_stat_value > third_q_stat]  <- 1.00
        }


        score_table[[stat]] <- points * scale_points
    }
    score_table$Season_Score <- rowSums(score_table[, -1])
    final_score_table <- score_table %>%
        select(pitcher,
              Season_Score) %>%
      mutate(
        pitcher = as.character(pitcher)
      )
    return(final_score_table)
}

################################# CALCULATE PITCHER RECENT SCORE##################################
starting_pitcher_recent_scores <- function(starting_pitcher_recent_form_df,
                                    recent_form_benchmark) {
    
    recent_score_table <- data.frame(pitcher = starting_pitcher_recent_form_df$xMLBAMID)

    columns_list <- unique(recent_form_benchmark$stat)

    for (stat in columns_list) {
        stat_benchmark <- recent_form_benchmark[recent_form_benchmark$stat == stat, ]
        min_stat <- stat_benchmark$min
        first_q_stat <- stat_benchmark$first_q
        second_q_stat <- stat_benchmark$second_q
        third_q_stat <- stat_benchmark$third_q
        max_stat <- stat_benchmark$max
        scale_points <- stat_benchmark$weight
        high_low <- stat_benchmark$high_low


        pitcher_stat_value <- starting_pitcher_recent_form_df[[stat]]
        points <- numeric(length(pitcher_stat_value))
        if (high_low == "low") {
            points[pitcher_stat_value > max_stat]      <- 0.0
            points[pitcher_stat_value < max_stat]      <- 0.25
            points[pitcher_stat_value < third_q_stat]  <- 0.50
            points[pitcher_stat_value < second_q_stat] <- 0.75
            points[pitcher_stat_value < first_q_stat]  <- 1.00
        } else {
            points[pitcher_stat_value < min_stat]      <- 0.0
            points[pitcher_stat_value > min_stat]      <- 0.25
            points[pitcher_stat_value > first_q_stat]  <- 0.50
            points[pitcher_stat_value > second_q_stat] <- 0.75
            points[pitcher_stat_value > third_q_stat]  <- 1.00
        }

        recent_score_table[[stat]] <- points * scale_points
    }
    recent_score_table$Recent_Score <- rowSums(recent_score_table[ , -1])
    final_recent_score_table <- recent_score_table %>%
        select(pitcher, Recent_Score) %>%
      mutate(
        pitcher = as.character(pitcher)
      )

    starting_pitcher_recent_form_df <- starting_pitcher_recent_form_df %>%
    select(
        xMLBAMID,
        'Number of Starts'
        ) %>%
    mutate(
        xMLBAMID = as.character(xMLBAMID)
        )
    
    final_recent_score_table <- final_recent_score_table %>%
    left_join(starting_pitcher_recent_form_df, by=c('pitcher' = 'xMLBAMID'))

    return(final_recent_score_table)
}

############################### CALCULATE TOTAL PITCHER SCORE ##########################
starting_pitcher_total_score <- function(starting_pitcher_season_df,
                                         starting_pitcher_recent_form_df,
                                         label) {
 
    # combine both season and recent
    final_score_table <- starting_pitcher_season_df %>%
    left_join(starting_pitcher_recent_form_df, by='pitcher')

    # calculate pitcher complete score

    final_score_table <- final_score_table %>%
      mutate(
        !!label := case_when(
          `Number of Starts` == 3 ~ Season_Score * .7 + Recent_Score * .3,
          `Number of Starts` == 2 ~ Season_Score * .8 + Recent_Score * .2,
          `Number of Starts` == 1 ~ Season_Score * .9 + Recent_Score * .1,
          TRUE ~ Season_Score
        )
      )

    # Select pitcher + dynamically named score column
    final_score_table <- final_score_table %>%
      select(pitcher, all_of(label))

    return(final_score_table)
    }
####################################CALCULATE TEAM BATTING SCORE ALL ######################################################
calculate_team_batting_scores <- function(matchup_df,
                                          team_batting_df, hist_team_batting_df,
                                          team_batting_benchmark_df) {
  
  
  updated_game_id_team_list <- hist_team_batting_df %>%
    select(gamePk, team_name)
  
  # HOME TEAMS -------------------------------------------------------------
  
  home_team_list <- matchup_df %>%
    select(Game_ID, Home_Team)
  
  # rows in home_team_list NOT in historical table
  not_updated_home_team_list <- home_team_list %>%
    anti_join(updated_game_id_team_list,
              by = c("Game_ID" = "gamePk",
                     "Home_Team" = "team_name"))
  
  # rows in home_team_list THAT ARE in historical table
  updated_home_team_list <- home_team_list %>%
    semi_join(updated_game_id_team_list,
              by = c("Game_ID" = "gamePk",
                     "Home_Team" = "team_name"))
  
  # AWAY TEAMS -------------------------------------------------------------
  
  away_team_list <- matchup_df %>%
    select(Game_ID, Away_Team)
  
  not_updated_away_team_list <- away_team_list %>%
    anti_join(updated_game_id_team_list,
              by = c("Game_ID" = "gamePk",
                     "Away_Team" = "team_name"))
  
  updated_away_team_list <- away_team_list %>%
    semi_join(updated_game_id_team_list,
              by = c("Game_ID" = "gamePk",
                     "Away_Team" = "team_name"))
  
  
  
  not_updated_home_team_batting_score_df <- NULL
  updated_home_team_batting_score_df <- NULL
  
  
  not_updated_away_team_batting_score_df <- NULL
  updated_away_team_batting_score_df <- NULL
  
  
  if (nrow(not_updated_home_team_list) > 0) {
    not_updated_home_team_df <- not_updated_home_team_list %>%
      left_join(team_batting_df, by=c('Home_Team' = 'team_name'), relationship = "many-to-one")
      
    
    not_updated_home_team_batting_score_df <- team_batting_scores(not_updated_home_team_df,
                                                      team_batting_benchmark_df,
                                                      label = "Home_Batting_Score",
                                                      team_column = 'Home_Team')
  }
  
  if (nrow(updated_home_team_list) > 0) {
    updated_home_team_df <- updated_home_team_list %>%
      left_join(hist_team_batting_df, by=c('Game_ID' = 'gamePk', 'Home_Team' = 'team_name'))
    
    updated_home_team_batting_score_df <- team_batting_scores(updated_home_team_df,
                                                              team_batting_benchmark_df,
                                                              label = "Home_Batting_Score",
                                                              team_column = 'Home_Team')
  }
  
  
  if (nrow(not_updated_away_team_list) > 0) {
    not_updated_away_team_df <- not_updated_away_team_list %>%
      left_join(team_batting_df, by=c('Away_Team' = 'team_name'), relationship = "many-to-one")
    
    
    not_updated_away_team_batting_score_df <- team_batting_scores(not_updated_away_team_df,
                                                                  team_batting_benchmark_df,
                                                                  label = "Away_Batting_Score",
                                                                  team_column = 'Away_Team')
  }
  
  if (nrow(updated_away_team_list) > 0) {
    updated_away_team_df <- updated_away_team_list %>%
      left_join(hist_team_batting_df, by=c('Game_ID' = 'gamePk', 'Away_Team' = 'team_name'))
    
    updated_away_team_batting_score_df <- team_batting_scores(updated_away_team_df,
                                                              team_batting_benchmark_df,
                                                              label = "Away_Batting_Score",
                                                              team_column = 'Away_Team')
  }
  
  
  if (!is.null(not_updated_home_team_batting_score_df) &&
      nrow(not_updated_home_team_batting_score_df) > 0 &&
      !is.null(updated_home_team_batting_score_df) &&
      nrow(updated_home_team_batting_score_df) > 0) {
    
    # mixed case
    home_team_batting_score_df <- bind_rows(
      not_updated_home_team_batting_score_df,
      updated_home_team_batting_score_df
    )
    
  } else if (!is.null(not_updated_home_team_batting_score_df) &&
             nrow(not_updated_home_team_batting_score_df) > 0) {
    
    # only not-updated exists
    home_team_batting_score_df <- not_updated_home_team_batting_score_df
    
  } else {
    
    # only updated exists (or both empty)
    home_team_batting_score_df <- updated_home_team_batting_score_df
  }
  
  if (!is.null(not_updated_away_team_batting_score_df) &&
      nrow(not_updated_away_team_batting_score_df) > 0 &&
      !is.null(updated_away_team_batting_score_df) &&
      nrow(updated_away_team_batting_score_df) > 0) {
    
    # mixed case
    away_team_batting_score_df <- bind_rows(
      not_updated_away_team_batting_score_df,
      updated_away_team_batting_score_df
    )
    
  } else if (!is.null(not_updated_away_team_batting_score_df) &&
             nrow(not_updated_away_team_batting_score_df) > 0) {
    
    # only not-updated exists
    away_team_batting_score_df <- not_updated_away_team_batting_score_df
    
  } else {
    
    # only updated exists (or both empty)
    away_team_batting_score_df <- updated_away_team_batting_score_df
  }
  
  
  matchup_df <- matchup_df %>%
  left_join(home_team_batting_score_df,
            by = c("Home_Team" = "Home_Team", "Game_ID" = "Game_ID")
            ) %>%
  left_join(away_team_batting_score_df,
            by = c("Away_Team" = "Away_Team", "Game_ID" = "Game_ID")
            )

  return(matchup_df)
  }
    
################################# CALCULATE TEAM BATTING SCORE##################################
team_batting_scores <- function(team_batting_df, benchmark_df, label, team_column) {
    # create final score df
  
  id_columns <- team_batting_df %>%
    select(Game_ID, !!team_column, hitter_player_ids)

  score_table <- data.frame(team_name = team_batting_df[[team_column]])

  columns_list <- unique(benchmark_df$stat)

  for (stat in columns_list) {
      stat_benchmark <- benchmark_df[benchmark_df$stat == stat, ]
      min_stat <- stat_benchmark$min
      first_q_stat <- stat_benchmark$first_q
      second_q_stat <- stat_benchmark$second_q
      third_q_stat <- stat_benchmark$third_q
      max_stat <- stat_benchmark$max
      scale_points <- stat_benchmark$weight
      high_low <- stat_benchmark$high_low


      team_batting_stat_value <- team_batting_df[[stat]]
      points <- numeric(length(team_batting_stat_value))
      
      if (high_low == "low") {
          points[team_batting_stat_value > max_stat]      <- 0.0
          points[team_batting_stat_value < max_stat]      <- 0.25
          points[team_batting_stat_value < third_q_stat]  <- 0.50
          points[team_batting_stat_value < second_q_stat] <- 0.75
          points[team_batting_stat_value < first_q_stat]  <- 1.00
      } else {
          points[team_batting_stat_value < min_stat]      <- 0.0
          points[team_batting_stat_value > min_stat]      <- 0.25
          points[team_batting_stat_value > first_q_stat]  <- 0.50
          points[team_batting_stat_value > second_q_stat] <- 0.75
          points[team_batting_stat_value > third_q_stat]  <- 1.00
      }
      
      score_table[[stat]] <- points * scale_points
  }
  score_table[[label]] <- rowSums(score_table[ , -1])
  
  final_score_table <- cbind(
    id_columns,
    score_table %>%
      select(all_of(label))
  )
  
  final_score_table <- final_score_table %>%
    rename(!!paste0(team_column, "_Batting_Lineup") := hitter_player_ids)
  
  return(final_score_table)
  }

################################# CALCULATE TEAM BATTING SCORE HISTORICAL##################################
team_batting_scores_historical <- function(team_batting_df, benchmark_df, label) {
    # create final score df
    score_table <- data.frame(gamepk_team_name_label = team_batting_df[["gamepk_team_name_label"]])
    columns_list <- unique(benchmark_df$stat)

    for (stat in columns_list) {
        stat_benchmark <- benchmark_df[benchmark_df$stat == stat, ]
        min_stat <- stat_benchmark$min
        first_q_stat <- stat_benchmark$first_q
        second_q_stat <- stat_benchmark$second_q
        third_q_stat <- stat_benchmark$third_q
        max_stat <- stat_benchmark$max
        scale_points <- stat_benchmark$weight
        high_low <- stat_benchmark$high_low


        team_batting_stat_value <- team_batting_df[[stat]]
        points <- numeric(length(team_batting_stat_value))
        if (high_low == "low") {
            points[team_batting_stat_value > max_stat]      <- 0.0
            points[team_batting_stat_value < max_stat]      <- 0.25
            points[team_batting_stat_value < third_q_stat]  <- 0.50
            points[team_batting_stat_value < second_q_stat] <- 0.75
            points[team_batting_stat_value < first_q_stat]  <- 1.00
        } else {
            points[team_batting_stat_value < min_stat]      <- 0.0
            points[team_batting_stat_value > min_stat]      <- 0.25
            points[team_batting_stat_value > first_q_stat]  <- 0.50
            points[team_batting_stat_value > second_q_stat] <- 0.75
            points[team_batting_stat_value > third_q_stat]  <- 1.00
        }

        score_table[[stat]] <- points * scale_points
    }
    score_table[[label]] <- rowSums(score_table[ , -1])
    final_score_table <- score_table %>%
        select(gamepk_team_name_label, all_of(label))
    return(final_score_table)
    }

########################## CALCULATE TEAM PITCHING SCORES ALL #####################
calculate_team_pitching_scores <- function(matchup_df,
                                           team_pitching_df, hist_team_pitching_df,
                                           team_pitching_benchmark_df) {
  
  
  updated_game_id_team_list <- hist_team_pitching_df %>%
    select(gamePk, team_name)
  
  # HOME TEAMS -------------------------------------------------------------
  
  home_team_list <- matchup_df %>%
    select(Game_ID, Home_Team)
  
  # rows in home_team_list NOT in historical table
  not_updated_home_team_list <- home_team_list %>%
    anti_join(updated_game_id_team_list,
              by = c("Game_ID" = "gamePk",
                     "Home_Team" = "team_name"))
  
  # rows in home_team_list THAT ARE in historical table
  updated_home_team_list <- home_team_list %>%
    semi_join(updated_game_id_team_list,
              by = c("Game_ID" = "gamePk",
                     "Home_Team" = "team_name"))
  
  # AWAY TEAMS -------------------------------------------------------------
  
  away_team_list <- matchup_df %>%
    select(Game_ID, Away_Team)
  
  not_updated_away_team_list <- away_team_list %>%
    anti_join(updated_game_id_team_list,
              by = c("Game_ID" = "gamePk",
                     "Away_Team" = "team_name"))
  
  updated_away_team_list <- away_team_list %>%
    semi_join(updated_game_id_team_list,
              by = c("Game_ID" = "gamePk",
                     "Away_Team" = "team_name"))
  
  
  
  not_updated_home_team_pitching_score_df <- NULL
  updated_home_team_pitching_score_df <- NULL
  
  
  not_updated_away_team_pitching_score_df <- NULL
  updated_away_team_pitching_score_df <- NULL
  
  
  if (nrow(not_updated_home_team_list) > 0) {
    not_updated_home_team_df <- not_updated_home_team_list %>%
      left_join(team_pitching_df, by=c('Home_Team' = 'team_name'), relationship = "many-to-one")
    
    
    not_updated_home_team_pitching_score_df <- team_pitching_scores(not_updated_home_team_df,
                                                                    team_pitching_benchmark_df,
                                                                    label = "Home_Pitching_Score",
                                                                    team_column = 'Home_Team')
  }
  
  if (nrow(updated_home_team_list) > 0) {
    updated_home_team_df <- updated_home_team_list %>%
      left_join(hist_team_pitching_df, by=c('Game_ID' = 'gamePk', 'Home_Team' = 'team_name'))
    
    updated_home_team_pitching_score_df <- team_pitching_scores(updated_home_team_df,
                                                                team_pitching_benchmark_df,
                                                                label = "Home_Pitching_Score",
                                                                team_column = 'Home_Team')
  }
  
  
  if (nrow(not_updated_away_team_list) > 0) {
    not_updated_away_team_df <- not_updated_away_team_list %>%
      left_join(team_pitching_df, by=c('Away_Team' = 'team_name'), relationship = "many-to-one")
    
    
    not_updated_away_team_pitching_score_df <- team_pitching_scores(not_updated_away_team_df,
                                                                    team_pitching_benchmark_df,
                                                                    label = "Away_Pitching_Score",
                                                                    team_column = 'Away_Team')
  }
  
  if (nrow(updated_away_team_list) > 0) {
    updated_away_team_df <- updated_away_team_list %>%
      left_join(hist_team_pitching_df, by=c('Game_ID' = 'gamePk', 'Away_Team' = 'team_name'))
    
    updated_away_team_pitching_score_df <- team_pitching_scores(updated_away_team_df,
                                                                team_pitching_benchmark_df,
                                                                label = "Away_Pitching_Score",
                                                                team_column = 'Away_Team')
  }
  
  
  if (!is.null(not_updated_home_team_pitching_score_df) &&
      nrow(not_updated_home_team_pitching_score_df) > 0 &&
      !is.null(updated_home_team_pitching_score_df) &&
      nrow(updated_home_team_pitching_score_df) > 0) {
    
    # mixed case
    home_team_pitching_score_df <- bind_rows(
      not_updated_home_team_pitching_score_df,
      updated_home_team_pitching_score_df
    )
    
  } else if (!is.null(not_updated_home_team_pitching_score_df) &&
             nrow(not_updated_home_team_pitching_score_df) > 0) {
    
    # only not-updated exists
    home_team_pitching_score_df <- not_updated_home_team_pitching_score_df
    
  } else {
    
    # only updated exists (or both empty)
    home_team_pitching_score_df <- updated_home_team_pitching_score_df
  }
  
  if (!is.null(not_updated_away_team_pitching_score_df) &&
      nrow(not_updated_away_team_pitching_score_df) > 0 &&
      !is.null(updated_away_team_pitching_score_df) &&
      nrow(updated_away_team_pitching_score_df) > 0) {
    
    # mixed case
    away_team_pitching_score_df <- bind_rows(
      not_updated_away_team_pitching_score_df,
      updated_away_team_pitching_score_df
    )
    
  } else if (!is.null(not_updated_away_team_pitching_score_df) &&
             nrow(not_updated_away_team_pitching_score_df) > 0) {
    
    # only not-updated exists
    away_team_pitching_score_df <- not_updated_away_team_pitching_score_df
    
  } else {
    
    # only updated exists (or both empty)
    away_team_pitching_score_df <- updated_away_team_pitching_score_df
  }
  
  
  matchup_df <- matchup_df %>%
    left_join(home_team_pitching_score_df,
              by = c("Home_Team" = "Home_Team", "Game_ID" = "Game_ID")
    ) %>%
    left_join(away_team_pitching_score_df,
              by = c("Away_Team" = "Away_Team", "Game_ID" = "Game_ID")
    )
  
  return(matchup_df)
}

################################# CALCULATE TEAM PITCHING SCORE##################################
team_pitching_scores <- function(team_pitching_df, benchmark_df, label, team_column) {
  # create final score df
  
  id_columns <- team_pitching_df %>%
    select(Game_ID, !!team_column)
  
  score_table <- data.frame(team_name = team_pitching_df[[team_column]])
  columns_list <- unique(benchmark_df$stat)
  
  for (stat in columns_list) {
    stat_benchmark <- benchmark_df[benchmark_df$stat == stat, ]
    min_stat <- stat_benchmark$min
    first_q_stat <- stat_benchmark$first_q
    second_q_stat <- stat_benchmark$second_q
    third_q_stat <- stat_benchmark$third_q
    max_stat <- stat_benchmark$max
    scale_points <- stat_benchmark$weight
    high_low <- stat_benchmark$high_low
    
    
    team_pitching_stat_value <- team_pitching_df[[stat]]
    points <- numeric(length(team_pitching_stat_value))
    
    if (high_low == "low") {
      points[team_pitching_stat_value > max_stat]      <- 0.0
      points[team_pitching_stat_value < max_stat]      <- 0.25
      points[team_pitching_stat_value < third_q_stat]  <- 0.50
      points[team_pitching_stat_value < second_q_stat] <- 0.75
      points[team_pitching_stat_value < first_q_stat]  <- 1.00
    } else {
      points[team_pitching_stat_value < min_stat]      <- 0.0
      points[team_pitching_stat_value > min_stat]      <- 0.25
      points[team_pitching_stat_value > first_q_stat]  <- 0.50
      points[team_pitching_stat_value > second_q_stat] <- 0.75
      points[team_pitching_stat_value > third_q_stat]  <- 1.00
    }
    
    score_table[[stat]] <- points * scale_points
  }
  score_table[[label]] <- rowSums(score_table[ , -1])
  
  final_score_table <- cbind(
    id_columns,
    score_table %>%
      select(all_of(label))
  )
  
  return(final_score_table)
}

################################# CALCULATE TEAM PITCHING SCORE HISTORICAL##################################
team_pitching_scores_historical <- function(team_pitching_df, benchmark_df, label) {
    # create final score df
    score_table <- data.frame(gamepk_team_name_label = team_pitching_df[["gamepk_team_name_label"]])
    columns_list <- unique(benchmark_df$stat)

    for (stat in columns_list) {
        stat_benchmark <- benchmark_df[benchmark_df$stat == stat, ]
        min_stat <- stat_benchmark$min
        first_q_stat <- stat_benchmark$first_q
        second_q_stat <- stat_benchmark$second_q
        third_q_stat <- stat_benchmark$third_q
        max_stat <- stat_benchmark$max
        scale_points <- stat_benchmark$weight
        high_low <- stat_benchmark$high_low


        team_pitching_stat_value <- team_pitching_df[[stat]]
        points <- numeric(length(team_pitching_stat_value))
        if (high_low == "low") {
            points[team_pitching_stat_value > max_stat]      <- 0.0
            points[team_pitching_stat_value < max_stat]      <- 0.25
            points[team_pitching_stat_value < third_q_stat]  <- 0.50
            points[team_pitching_stat_value < second_q_stat] <- 0.75
            points[team_pitching_stat_value < first_q_stat]  <- 1.00
        } else {
            points[team_pitching_stat_value < min_stat]      <- 0.0
            points[team_pitching_stat_value > min_stat]      <- 0.25
            points[team_pitching_stat_value > first_q_stat]  <- 0.50
            points[team_pitching_stat_value > second_q_stat] <- 0.75
            points[team_pitching_stat_value > third_q_stat]  <- 1.00
        }

        score_table[[stat]] <- points * scale_points
    }
    score_table[[label]] <- rowSums(score_table[ , -1])
    final_score_table <- score_table %>%
        select(gamepk_team_name_label, all_of(label))
    return(final_score_table)
    }
######################### CALCULATE PLATTON ADVANTAGE SCORE########################
    
calculate_platoon_splits_advantage <-function(matchup_df, batter_df, batter_splits_df) {
    matchup_df <- matchup_df %>%
      mutate(
        Home_Team_Lineup = lapply(Home_Batting_Lineup, parse_lineup),
        Away_Team_Lineup = lapply(Away_Batting_Lineup, parse_lineup)
      )
      
    matchup_df$Home_Team_Platoon_Splits <- numeric(nrow(matchup_df))
    matchup_df$Away_Team_Platoon_Splits <- numeric(nrow(matchup_df))

    

    
    for (row in 1:nrow(matchup_df)) {
         
        home_player_ids <- batter_df %>%
        filter(batter_id %in% matchup_df$Home_Team_Lineup[[row]]) %>%
        select(batter_id, playerid) %>%
        left_join(batter_splits_df, by =c('playerid' = 'playerId'))

        away_player_ids <- batter_df %>%
        filter(xMLBAMID %in% matchup_df$Away_Team_Lineup[[row]]) %>%
        select(xMLBAMID, playerid) %>%
        left_join(batter_splits_df, by =c('playerid' = 'playerId'))
        
        team_wOBA_splits <- sum(home_player_ids$wOBA_splits, na.rm=TRUE) * 1.0
        team_ISO_splits <- sum(home_player_ids$ISO_splits, na.rm=TRUE) * 0.5
        team_BB_perc_splits <- sum(home_player_ids$`BB%_splits`, na.rm=TRUE) * 0.2
        team_K_perc_splits <- sum(home_player_ids$`K%_splits`, na.rm=TRUE) * -0.3
        
        team_platoon_advantage = (
            team_wOBA_splits +
            team_ISO_splits + 
            team_BB_perc_splits + 
            team_K_perc_splits
            )
        
        away_throwing_hand <- matchup_df$Away_Pitcher_Hand[row]
        
        if (away_throwing_hand == 'NA') {
          matchup_df$Home_Context_Score[row] = matchup_df$Home_Context_Score[row] + 0
        } else if (away_throwing_hand == 'L' && team_platoon_advantage > 0) {
            matchup_df$Home_Context_Score[row] = matchup_df$Home_Context_Score[row] + abs(team_platoon_advantage) * 0.5
        } else if (away_throwing_hand == 'R' && team_platoon_advantage < 0) {
            matchup_df$Home_Context_Score[row] = matchup_df$Home_Context_Score[row] + abs(team_platoon_advantage) * 0.5
        } else {
            matchup_df$Home_Context_Score[row] = matchup_df$Home_Context_Score[row] + 0
        }

        matchup_df$Home_Team_Platoon_Splits[row] <- round(team_platoon_advantage, 4)
        
        team_wOBA_splits <- sum(away_player_ids$wOBA_splits, na.rm=TRUE) * 1.0
        team_ISO_splits <- sum(away_player_ids$ISO_splits, na.rm=TRUE) * 0.5
        team_BB_perc_splits <- sum(away_player_ids$`BB%_splits`, na.rm=TRUE) * 0.2
        team_K_perc_splits <- sum(away_player_ids$`K%_splits`, na.rm=TRUE) * -0.3
        
        team_platoon_advantage = (
            team_wOBA_splits +
            team_ISO_splits + 
            team_BB_perc_splits + 
            team_K_perc_splits
            )
        
        home_throwing_hand <- matchup_df$Home_Pitcher_Hand[row]
        
        if (home_throwing_hand == 'NA') {
          matchup_df$Away_Context_Score[row] = matchup_df$Away_Context_Score[row] + 0
        } else if (home_throwing_hand == 'L' && team_platoon_advantage > 0) {
            matchup_df$Away_Context_Score[row] = matchup_df$Away_Context_Score[row] + abs(team_platoon_advantage) * 0.5
        } else if (home_throwing_hand == 'R' && team_platoon_advantage < 0) {
            matchup_df$Away_Context_Score[row] = matchup_df$Away_Context_Score[row] + abs(team_platoon_advantage) * 0.5
        } else {
            matchup_df$Away_Context_Score[row] = matchup_df$Away_Context_Score[row] + 0
        }

        matchup_df$Away_Team_Platoon_Splits[row] <- round(team_platoon_advantage, 4)
    }
    
    return(matchup_df)

}

############################## CALCULATE TEAM RECORD SCORE ##############################
calculate_team_record_scores <- function(matchup_df, mlb_team_record_df, mlb_team_record_benchmark) {
  
  lookup_table <- mlb_team_record_benchmark %>%
    select(stat, first_q, second_q, third_q, min, max, weight, high_low)
  
  home_cols <- c(
    'winning_percentage_home',
    'home_league_opponent_record',
    'home_division_opponent_record',
    'home_day_night_record',
    'home_pitcher_hand_record',
    'home_location_hand_record'
  )
  
  away_cols <- c(
    'winning_percentage_away',
    'away_league_opponent_record',
    'away_division_opponent_record',
    'away_day_night_record',
    'away_pitcher_hand_record',
    'away_location_hand_record'
  )
  
  weighted_stats <- c(
    run_differential = "run_differential",
    winners          = "winners",
    runs_allowed     = "runs_allowed",
    runs_scored      = "runs_scored",
    oneRun           = "oneRun",
    lastTen          = "lastTen",
    extraInning      = "extraInning"
  )
  
  
  columns_remove_na <- c(
    "home_league_opponent_record",
    "home_division_opponent_record",
    "home_day_night_record",
    "home_pitcher_hand_record",
    "home_location_hand_record",
    "away_league_opponent_record",
    "away_division_opponent_record",
    "away_day_night_record",
    "away_pitcher_hand_record",
    "away_location_hand_record"
  )
  
  home_df <- matchup_df %>%
    select(
      Game_ID,
      Day_Night,
      Home_Team,
      Home_Team_ID,
      Home_Team_League_ID,
      Home_Team_Division_ID,
      Home_Pitcher_Hand
    ) %>%
    left_join(mlb_team_record_df,
              by=c('Home_Team_ID' = 'team_id'),
              relationship='many-to-one')
  
  away_df <- matchup_df %>%
    select(
      Game_ID,
      Day_Night,
      Away_Team,
      Away_Team_ID,
      Away_Team_League_ID,
      Away_Team_Division_ID,
      Away_Pitcher_Hand
    ) %>%
    left_join(mlb_team_record_df,
              by=c('Away_Team_ID' = 'team_id'),
              relationship='many-to-one')
  
  combined_record_df <- home_df %>%
    inner_join(away_df,
               by='Game_ID',
               relationship='one-to-one',
               suffix=c('_home', '_away')
    )
  
  team_record_df <- combined_record_df %>%
    mutate(
      home_league_opponent_record = case_when(
        Away_Team_League_ID == 103 ~ league_id_103_home,
        Away_Team_League_ID == 104 ~ league_id_104_home),
      home_division_opponent_record = case_when(
        Away_Team_Division_ID == 200 ~ division_id_200_home,
        Away_Team_Division_ID == 201 ~ division_id_201_home,
        Away_Team_Division_ID == 202 ~ division_id_202_home,
        Away_Team_Division_ID == 203 ~ division_id_203_home,
        Away_Team_Division_ID == 204 ~ division_id_204_home,
        Away_Team_Division_ID == 205 ~ division_id_205_home
      ),
      home_day_night_record = if_else(
        Day_Night_home == 'day', day_home, night_home
      ),
      home_pitcher_hand_record = if_else(
        Away_Pitcher_Hand == 'L', left_home, right_home
      ),
      home_location_hand_record = if_else(
        Away_Pitcher_Hand == 'L', leftHome_home, rightHome_home
      )
    ) %>%
    mutate(
      away_league_opponent_record = case_when(
        Home_Team_League_ID == 103 ~ league_id_103_away,
        Home_Team_League_ID == 104 ~ league_id_104_away),
      away_division_opponent_record = case_when(
        Home_Team_Division_ID == 200 ~ division_id_200_away,
        Home_Team_Division_ID == 201 ~ division_id_201_away,
        Home_Team_Division_ID == 202 ~ division_id_202_away,
        Home_Team_Division_ID == 203 ~ division_id_203_away,
        Home_Team_Division_ID == 204 ~ division_id_204_away,
        Home_Team_Division_ID == 205 ~ division_id_205_away
      ),
      away_day_night_record = if_else(
        Day_Night_away == 'day', day_away, night_away
      ),
      away_pitcher_hand_record = if_else(
        Home_Pitcher_Hand == 'L', left_away, right_away
      ),
      away_location_hand_record = if_else(
        Home_Pitcher_Hand == 'L', leftAway_away, rightAway_away
      )
    )
  
  
  team_record_df <- team_record_df %>%
    mutate(across(all_of(columns_remove_na), ~ replace_na(.x, 0)))
  
  
  # scoring
  team_record_df <- team_record_df %>%
    mutate(
      Home_Team_Record_Score = 0,
      Away_Team_Record_Score = 0,
      Home_Team_Record_Score = rowSums(across(all_of(home_cols)) > 0.5),
      Away_Team_Record_Score = rowSums(across(all_of(away_cols)) > 0.5),
    )
  
  
  for (stat in names(weighted_stats)) {
    row <- lookup_table[lookup_table$stat == stat, ]
    
    home_col <- paste0(weighted_stats[[stat]], '_home')
    away_col <- paste0(weighted_stats[[stat]], '_away')
    
    home_score_col <- paste0(weighted_stats[[stat]], "_home_score")
    away_score_col <- paste0(weighted_stats[[stat]], "_away_score")
    
    team_record_df[[home_score_col]] <- team_record_score_stat(
      value = team_record_df[[home_col]],
      first_q = row$first_q,
      second_q = row$second_q,
      third_q = row$third_q,
      min = row$min,
      max = row$max,
      high_low = row$high_low,
      weight = row$weight
    )
    
    team_record_df[[away_score_col]] <- team_record_score_stat(
      value = team_record_df[[away_col]],
      first_q = row$first_q,
      second_q = row$second_q,
      third_q = row$third_q,
      min = row$min,
      max = row$max,
      high_low = row$high_low,
      weight = row$weight
    )
  }
  
  team_record_df <- team_record_df %>%
    mutate(
      Home_Team_Record_Score = Home_Team_Record_Score + rowSums(across(all_of(ends_with('_home_score')))),
      Away_Team_Record_Score = Away_Team_Record_Score + rowSums(across(all_of(ends_with('_away_score'))))
    )
  
  final_team_record_df <- team_record_df %>%
    select(
      Game_ID,
      Home_Team_Record_Score,
      Away_Team_Record_Score
    ) %>%
    right_join(matchup_df,
               by='Game_ID',
               relationship='one-to-one')
  
  
  return(final_team_record_df)
}
############################ STAT RECORD FUNCTION ###############################
team_record_score_stat <- function(value, first_q, second_q, third_q, min_val, max_val, high_low, weight) {
  
  # LOW stats (lower is better)
  if (high_low == "low") {
    raw_score <- dplyr::case_when(
      value > max_val      ~ 0.00,
      value > third_q      ~ 0.25,
      value > second_q     ~ 0.50,
      value > first_q      ~ 0.75,
      value <= first_q     ~ 1.00
    )
  }
  
  # HIGH stats (higher is better)
  else if (high_low == "high") {
    raw_score <- dplyr::case_when(
      value < min_val      ~ 0.00,
      value < first_q      ~ 0.25,
      value < second_q     ~ 0.50,
      value < third_q      ~ 0.75,
      value >= third_q     ~ 1.00
    )
  }
  
  # multiply by weight
  return(raw_score * weight)
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

############################# CALCULATE FATIGUE SCORE HISTORICAL####################################
calculate_team_travel_fatigue_score_historical <- function(matchup_df, team_travel_df) {

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
            Home_Fatigue_Adjust = 0,
            Away_Fatigue_Adjust = 0,
        
            Home_Context_Score = Home_Context_Score - Home_Fatigue_Adjust,
            Away_Context_Score = Away_Context_Score - Away_Fatigue_Adjust
        ) %>%
 
        # Drop the temporary fatigue columns
        select(-Home_Fatigue_Score, -Away_Fatigue_Score)
    
    return(matchup_df)
}
############################ CALCULATE POWER SCORE ############################
calculate_power_boost_score <- function(matchup_df,
                                  starting_pitcher_filtered_df,
                                  team_batting_df,
                                  mlb_team_league_batting_averages_df) {

  trimmed_starting_pitcher_stats_df <- starting_pitcher_filtered_df %>%
    select(xMLBAMID,
           `FB%`)
  
  trimmed_team_batting_df <- team_batting_df %>%
    select(team_id,
           `FB%`)

  league_avg_fb <- mlb_team_league_batting_averages_df %>%
    filter(stat == 'FB%') %>%
    pull(average)
  
  home_power_synergy_df <- matchup_df %>%
    select(Game_ID,
           Home_Team,
           Home_Team_ID,
           Away_Pitcher_ID,
           Away_Pitcher_Hand,
           Park_Factor) %>%
    left_join(
      trimmed_starting_pitcher_stats_df,
      by=c('Away_Pitcher_ID' = 'xMLBAMID'),
      relationship='one-to-one'
    ) %>%
    left_join(
      trimmed_team_batting_df,
      by=c('Home_Team_ID' = 'team_id'),
      relationship='many-to-one',
      suffix=c('_pitcher', '_batting')
    ) %>%
    mutate(
      home_power_boost = 
        (Park_Factor > 100) *
        (`FB%_pitcher` > league_avg_fb) *
        (`FB%_batting` > league_avg_fb),
      home_power_boost = replace_na(home_power_boost, 0)
    )
  
  away_power_synergy_df <- matchup_df %>%
    select(Game_ID,
           Away_Team,
           Away_Team_ID,
           Home_Pitcher_ID,
           Home_Pitcher_Hand,
           Park_Factor) %>%
    left_join(
      trimmed_starting_pitcher_stats_df,
      by=c('Home_Pitcher_ID' = 'xMLBAMID'),
      relationship='one-to-one'
    ) %>%
    left_join(
      trimmed_team_batting_df,
      by=c('Away_Team_ID' = 'team_id'),
      relationship='many-to-one',
      suffix=c('_pitcher', '_batting')
    ) %>%
    mutate(
      away_power_boost = 
        (Park_Factor > 100) *
        (`FB%_pitcher` > league_avg_fb) *
        (`FB%_batting` > league_avg_fb),
      away_power_boost = replace_na(away_power_boost, 0)
    )
  
  combined_power_synergy_df <- home_power_synergy_df %>%
    left_join(
      away_power_synergy_df,
      by='Game_ID',
      relationship='one-to-one'
    ) %>%
    mutate(
      Home_Power_Score = home_power_boost,
      Away_Power_Score = away_power_boost
    ) %>%
    select(
      Game_ID,
      Home_Power_Score,
      Away_Power_Score
    )
  
  matchup_df <- matchup_df %>%
    left_join(
      combined_power_synergy_df,
      by='Game_ID',
      relationship='one-to-one'
    )
  
  return(matchup_df)
  
}

##################### CALCULATE RESULT SPLITS ########################
calculate_team_split_score <- function(matchup_df,
                                  starting_pitcher_df,
                                  team_batting_df,
                                  mlb_team_league_batting_splits_df) {
  
  xBA_L <- mlb_team_league_batting_splits_df %>%
    filter(split_stat == 'xBA') %>%
    pull(split_left)
  xWOBA_L <- mlb_team_league_batting_splits_df %>%
    filter(split_stat == 'xWOBA') %>%
    pull(split_left)
  xSLG_L <- mlb_team_league_batting_splits_df %>%
    filter(split_stat == 'xSLG') %>%
    pull(split_left)
  xISO_L <- mlb_team_league_batting_splits_df %>%
    filter(split_stat == 'xISO') %>%
    pull(split_left)
  xBABIP_L <- mlb_team_league_batting_splits_df %>%
    filter(split_stat == 'xBABIP') %>%
    pull(split_left)
  
  xBA_R <- mlb_team_league_batting_splits_df %>%
    filter(split_stat == 'xBA') %>%
    pull(split_right)
  xWOBA_R <- mlb_team_league_batting_splits_df %>%
    filter(split_stat == 'xWOBA') %>%
    pull(split_right)
  xSLG_R <- mlb_team_league_batting_splits_df %>%
    filter(split_stat == 'xSLG') %>%
    pull(split_right)
  xISO_R <- mlb_team_league_batting_splits_df %>%
    filter(split_stat == 'xISO') %>%
    pull(split_right)
  xBABIP_R <- mlb_team_league_batting_splits_df %>%
    filter(split_stat == 'xBABIP') %>%
    pull(split_right)
  
  league_split_dict <- list(
    xBA    = list(L = xBA_L,    R = xBA_R),
    xWOBA  = list(L = xWOBA_L,  R = xWOBA_R),
    xSLG   = list(L = xSLG_L,   R = xSLG_R),
    xISO   = list(L = xISO_L,   R = xISO_R),
    xBABIP = list(L = xBABIP_L, R = xBABIP_R)
  )
  
  trimmed_team_batting_df <- team_batting_df %>%
    select(
      team_id,
      RHP_xBA,
      RHP_xWOBA,
      RHP_xSLG,
      RHP_xISO,
      RHP_xBABIP,,
      LHP_xBA,
      LHP_xWOBA,
      LHP_xSLG,
      LHP_xISO,
      LHP_xBABIP
    )
  
  trimmed_starting_pitcher_df <- starting_pitcher_df %>%
    mutate(xMLBAMID = as.character(xMLBAMID)) %>%
    select(
      xMLBAMID,
      xBA,
      xWOBA,
      xSLG,
      xISO,
      xBABIP
    )
  
  split_scores <- c('xBA_score', 'xWOBA_score', 'xSLG_score', 'xISO_score', 'xBABIP_score')
  
  home_split_df <- matchup_df %>%
    select(Game_ID,
           Home_Team,
           Home_Team_ID,
           Away_Pitcher_ID,
           Away_Pitcher_Hand) %>%
    left_join(
      trimmed_starting_pitcher_df,
      by=c('Away_Pitcher_ID' = 'xMLBAMID'),
      relationship='one-to-one'
    ) %>%
    left_join(
      trimmed_team_batting_df,
      by=c('Home_Team_ID' = 'team_id'),
      relationship='many-to-one'
    ) %>%
    mutate(
      xBA_league_split    = if_else(Away_Pitcher_Hand == "L", league_split_dict$xBA$L, league_split_dict$xBA$R),
      xWOBA_league_split  = if_else(Away_Pitcher_Hand == "L", league_split_dict$xWOBA$L, league_split_dict$xWOBA$R),
      xSLG_league_split   = if_else(Away_Pitcher_Hand == "L", league_split_dict$xSLG$L, league_split_dict$xSLG$R),
      xISO_league_split   = if_else(Away_Pitcher_Hand == "L", league_split_dict$xISO$L, league_split_dict$xISO$R),
      xBABIP_league_split = if_else(Away_Pitcher_Hand == "L", league_split_dict$xBABIP$L, league_split_dict$xBABIP$R),
      xBA_team_split = if_else(Away_Pitcher_Hand == 'L', LHP_xBA - xBA_league_split, RHP_xBA - xBA_league_split),
      xWOBA_team_split = if_else(Away_Pitcher_Hand == 'L', LHP_xWOBA - xWOBA_league_split, RHP_xWOBA - xWOBA_league_split),
      xSLG_team_split = if_else(Away_Pitcher_Hand == 'L', LHP_xSLG - xSLG_league_split, RHP_xSLG - xSLG_league_split),
      xISO_team_split = if_else(Away_Pitcher_Hand == 'L', LHP_xISO - xISO_league_split, RHP_xISO - xISO_league_split),
      xBABIP_team_split = if_else(Away_Pitcher_Hand == 'L', LHP_xBABIP - xBABIP_league_split, RHP_xBABIP - xBABIP_league_split),
      xBA_pitcher_split = xBA - xBA_league_split,
      xWOBA_pitcher_split = xWOBA - xWOBA_league_split,
      xSLG_pitcher_split = xSLG - xSLG_league_split,
      xISO_pitcher_split = xISO - xISO_league_split,
      xBABIP_pitcher_split = xBABIP - xBABIP_league_split,
      xBA_score = xBA_team_split + xBA_pitcher_split,
      xWOBA_score = xWOBA_team_split + xWOBA_pitcher_split,
      xSLG_score = xSLG_team_split + xSLG_pitcher_split,
      xISO_score = xISO_team_split + xISO_pitcher_split,
      xBABIP_score = xBABIP_team_split + xBABIP_pitcher_split,
      Home_Team_Split_Score = rowSums(across(all_of(split_scores)), na.rm = TRUE),
      Home_Team_Split_Score = round(Home_Team_Split_Score * 10, 1)
    ) %>%
    select(Game_ID, Home_Team_Split_Score)
  
  away_split_df <- matchup_df %>%
    select(Game_ID,
           Away_Team,
           Away_Team_ID,
           Home_Pitcher_ID,
           Home_Pitcher_Hand) %>%
    left_join(
      trimmed_starting_pitcher_df,
      by=c('Home_Pitcher_ID' = 'xMLBAMID'),
      relationship='one-to-one'
    ) %>%
    left_join(
      trimmed_team_batting_df,
      by=c('Away_Team_ID' = 'team_id'),
      relationship='many-to-one'
    ) %>%
    mutate(
      xBA_league_split    = if_else(Home_Pitcher_Hand == "L", league_split_dict$xBA$L, league_split_dict$xBA$R),
      xWOBA_league_split  = if_else(Home_Pitcher_Hand == "L", league_split_dict$xWOBA$L, league_split_dict$xWOBA$R),
      xSLG_league_split   = if_else(Home_Pitcher_Hand == "L", league_split_dict$xSLG$L, league_split_dict$xSLG$R),
      xISO_league_split   = if_else(Home_Pitcher_Hand == "L", league_split_dict$xISO$L, league_split_dict$xISO$R),
      xBABIP_league_split = if_else(Home_Pitcher_Hand == "L", league_split_dict$xBABIP$L, league_split_dict$xBABIP$R),
      xBA_team_split = if_else(Home_Pitcher_Hand == 'L', LHP_xBA - xBA_league_split, RHP_xBA - xBA_league_split),
      xWOBA_team_split = if_else(Home_Pitcher_Hand == 'L', LHP_xWOBA - xWOBA_league_split, RHP_xWOBA - xWOBA_league_split),
      xSLG_team_split = if_else(Home_Pitcher_Hand == 'L', LHP_xSLG - xSLG_league_split, RHP_xSLG - xSLG_league_split),
      xISO_team_split = if_else(Home_Pitcher_Hand == 'L', LHP_xISO - xISO_league_split, RHP_xISO - xISO_league_split),
      xBABIP_team_split = if_else(Home_Pitcher_Hand == 'L', LHP_xBABIP - xBABIP_league_split, RHP_xBABIP - xBABIP_league_split),
      xBA_pitcher_split = xBA - xBA_league_split,
      xWOBA_pitcher_split = xWOBA - xWOBA_league_split,
      xSLG_pitcher_split = xSLG - xSLG_league_split,
      xISO_pitcher_split = xISO - xISO_league_split,
      xBABIP_pitcher_split = xBABIP - xBABIP_league_split,
      xBA_score = xBA_team_split + xBA_pitcher_split,
      xWOBA_score = xWOBA_team_split + xWOBA_pitcher_split,
      xSLG_score = xSLG_team_split + xSLG_pitcher_split,
      xISO_score = xISO_team_split + xISO_pitcher_split,
      xBABIP_score = xBABIP_team_split + xBABIP_pitcher_split,
      Away_Team_Split_Score = rowSums(across(all_of(split_scores)), na.rm = TRUE),
      Away_Team_Split_Score = round(Away_Team_Split_Score * 10, 1)
    ) %>%
    select(Game_ID, Away_Team_Split_Score)
  
  matchup_df <- matchup_df %>%
    left_join(home_split_df,
              by='Game_ID',
              relationship = 'one-to-one') %>%
    left_join(away_split_df,
              by='Game_ID',
              relationship = 'one-to-one')
  
  
  
  
  return(matchup_df)
  
}
############################# CALCULATE PITCHER VS BATTING TEAM BREAK DOWN################

process_pitcher_vs_team_batting_score <- function(home_team_df, away_team_df) {

    
    pitch_type_list <- c("2_Seam_Fastball", "4_Seam_Fastball", "Changeup", "Curveball",
                         "Cutter", "Eephus", "Forkball", "Knuckle_Curve",
                         "Knuckleball", "Other", "Pitch_Out", "Screwball",
                         "Sinker", "Slider", "Slow_Curve", "Slurve",
                         "Split_Finger", "Sweeper", "Unknown")

    team_df_list <- list(
      Home = home_team_df,
      Away = away_team_df
    )

    for (prefix in names(team_df_list)) {

        team_df <- team_df_list[[prefix]]

        team_df <- as.data.frame(team_df_list[[prefix]], stringsAsFactors = FALSE)

        # Convert ALL pitch-related columns to numeric
        for (pitch in pitch_type_list) {
            for (suffix in c("_usage%", "_Contact%", "_Whiff%", "_Chase%")) {
                colname <- paste0(pitch, suffix)
                if (colname %in% names(team_df)) {
                    team_df[[colname]] <- as.numeric(team_df[[colname]])
                }
            }
        }


        contact_col <- paste0(prefix, "_Lineup_Contact_Score")
        whiff_col   <- paste0(prefix, "_Lineup_Whiff_Score")
        chase_col   <- paste0(prefix, "_Lineup_Chase_Score")

        contact_total_score <- numeric(nrow(team_df))
        whiff_total_score <- numeric(nrow(team_df))
        chase_total_score <- numeric(nrow(team_df))
        
        
        for (pitch in pitch_type_list) {
            
            pitch_usage_string   <- paste0(pitch, "_usage%")
            pitch_contact_string <- paste0(pitch, "_Contact%")
            pitch_whiff_string   <- paste0(pitch, "_Whiff%")
            pitch_chase_string   <- paste0(pitch, "_Chase%")
            
            pitch_contact_score <- team_df[[pitch_usage_string]] * team_df[[pitch_contact_string]]
            pitch_whiff_score   <- team_df[[pitch_usage_string]] * team_df[[pitch_whiff_string]]
            pitch_chase_score   <- team_df[[pitch_usage_string]] * team_df[[pitch_chase_string]]

            contact_total_score <- contact_total_score + pitch_contact_score
            whiff_total_score <- whiff_total_score + pitch_whiff_score
            chase_total_score <- chase_total_score + pitch_chase_score

            }

        team_df[[contact_col]] <- contact_total_score
        team_df[[whiff_col]] <- whiff_total_score
        team_df[[chase_col]] <- chase_total_score
        
        team_df_list[[prefix]] <- team_df

        }
    
    home_team_df <- team_df_list[["Home"]]
    away_team_df <- team_df_list[["Away"]]
    
    matchup_df <- home_team_df %>%
    select(Game_ID, Home_Lineup_Contact_Score, Home_Lineup_Whiff_Score, Home_Lineup_Chase_Score) %>%
    left_join(away_team_df %>% 
              select(Game_ID, Away_Lineup_Contact_Score, Away_Lineup_Whiff_Score, Away_Lineup_Chase_Score),
              by='Game_ID') %>%
    mutate(
        Home_Pitcher_vs_Away_Batting_Score = 
        case_when(Home_Lineup_Contact_Score >= Away_Lineup_Contact_Score ~ 1, TRUE ~ 0) +
        case_when(Home_Lineup_Whiff_Score <= Away_Lineup_Whiff_Score ~ 1, TRUE ~ 0) +
        case_when(Home_Lineup_Chase_Score <= Away_Lineup_Chase_Score ~ 1, TRUE ~ 0),

        Away_Pitcher_vs_Home_Batting_Score =
        case_when(Away_Lineup_Contact_Score > Home_Lineup_Contact_Score ~ 1, TRUE ~ 0) +
        case_when(Away_Lineup_Whiff_Score < Home_Lineup_Whiff_Score ~ 1, TRUE ~ 0) +
        case_when(Away_Lineup_Chase_Score < Home_Lineup_Chase_Score ~ 1, TRUE ~ 0)
        )

    final_matchup_df <- matchup_df %>%
    select(Game_ID, Home_Pitcher_vs_Away_Batting_Score, Away_Pitcher_vs_Home_Batting_Score)
    
    return(final_matchup_df)
    
}
                                                                               
   
############################ CALCULATE PITCHER VS BATTING TEAM BREAK DOWN #######################
calculate_pitcher_vs_team_batting_score <- function(matchup_df, starting_pitcher_df, team_batting_df) {

    home_team_df <- matchup_df %>%
    select(Game_ID, Home_Team, Away_Pitcher_ID) %>%
    left_join(starting_pitcher_df, by=c('Away_Pitcher_ID' = 'xMLBAMID')) %>%
    left_join(team_batting_df, by=c('Home_Team' = 'team_name'), relationship = 'many-to-one')

    away_team_df <- matchup_df %>%
    select(Game_ID, Away_Team, Home_Pitcher_ID) %>%
    left_join(starting_pitcher_df, by=c('Home_Pitcher_ID' = 'xMLBAMID')) %>%
    left_join(team_batting_df, by=c('Away_Team' = 'team_name'), relationship = 'many-to-one')

    pitcher_vs_team_batting_df <- process_pitcher_vs_team_batting_score(home_team_df, away_team_df)

    matchup_df <- matchup_df %>%
    left_join(pitcher_vs_team_batting_df, by='Game_ID')

    return(matchup_df)
}

    
############################ CALCULATE CONTEXT SCORE#######################################
calculate_team_context_scores <- function(matchup_df)  {
    
    matchup_df <- matchup_df %>%
    mutate(Home_Context_Score = .5,
          Away_Context_Score = 0)
    
    return(matchup_df)

}




##################### CALCULATE TOTAL SCORES ###################
calculate_total_scores <- function(matchup_df) {
  
  matchup_df <- matchup_df %>%
    mutate(
      Home_Batting_Score = Home_Batting_Score * 0.8,
      Home_Pitching_Score = Home_Pitching_Score * 0.2,
      Home_Context_Score = Home_Context_Score * 0.25,
      Home_Team_Record_Score = Home_Team_Record_Score * 0.25,
      Home_Pitcher_vs_Away_Team_Batting_Score = Home_Pitcher_vs_Away_Batting_Score * 0.25,
      Home_Team_Split_Score = Home_Team_Split_Score * 0.25,
      Home_Power_Score = Home_Power_Score * 0.25,
      
      Away_Batting_Score = Away_Batting_Score * 0.8,
      Away_Pitching_Score = Away_Pitching_Score * 0.2,
      Away_Context_Score = Away_Context_Score * 0.25,
      Away_Team_Record_Score = Away_Team_Record_Score * 0.25,
      Away_Pitcher_vs_Away_Team_Batting_Score = Away_Pitcher_vs_Home_Batting_Score * 0.25,
      Away_Team_Split_Score = Away_Team_Split_Score * 0.25,
      Away_Power_Score = Away_Power_Score * 0.25
    )
  
  home_scoring_columns <- str_subset(names(matchup_df), '^Home_.*_Score$')
  away_scoring_columns <- str_subset(names(matchup_df), '^Away_.*_Score$')
  
  matchup_df <- matchup_df %>%
    mutate(
      Home_Team_Total_Score = rowSums(across(all_of(home_scoring_columns)), na.rm = TRUE),
      Away_Team_Total_Score = rowSums(across(all_of(away_scoring_columns)), na.rm = TRUE),
      Predicted_Winner = case_when(
        Home_Team_Total_Score > Away_Team_Total_Score ~ Home_Team,
        Home_Team_Total_Score < Away_Team_Total_Score ~ Away_Team,
        TRUE ~ "Tie"
      ),
      Predicted_Loser = case_when(
        Home_Team_Total_Score > Away_Team_Total_Score ~ Away_Team,
        Home_Team_Total_Score < Away_Team_Total_Score ~ Home_Team,
        TRUE ~ "Tie"
      ),
      Score_Difference = round(abs(Home_Team_Total_Score - Away_Team_Total_Score), 4) * 0.25
    )
         
  return(matchup_df)
  
  }

##################### CALCULATE WIN PROB AND PREDICTION #####################
calculate_win_prob_prediction <- function(matchup_df,
                                          probability_model) {
    
  matchup_df <- matchup_df %>%
  mutate(
      Win_Probability = round((predict(probability_model, newdata = matchup_df, type = "response") * 100), 2)
      )
  
  matchup_df <- matchup_df %>%
    mutate(
      Win_Probability = if_else(
      Probable_Pitchers == "No" | !Pitcher_Stats_Available,
      NA_real_,
      Win_Probability
      ),
      Predicted_Winner = if_else(
          Probable_Pitchers == "No" | !Pitcher_Stats_Available,
          "No Prediction",
          Predicted_Winner
      ),
      Predicted_Loser = if_else(
          Probable_Pitchers == "No" | !Pitcher_Stats_Available,
          "No Prediction",
          Predicted_Loser
      )
    )
      
  matchup_df <- matchup_df %>%
      mutate(
          Prediction_Status = case_when(
              Probable_Pitchers == "No" ~ "No Prediction",
              !Pitcher_Stats_Available ~ "No Prediction",
              Lineup_Hydration == "No" ~ "Not Hydrated Prediction",
              TRUE ~ "Full Prediction"
          )
      )

  return(matchup_df)
  }
################## CALCULATE MODEL ODDS AND EDGE ################################
calculate_model_odds_and_edge <- function(matchup_df) {
  
  matchup_df <- matchup_df %>%
    mutate(
      winner_win_prob = Win_Probability,
      loser_win_prob  = 100 - winner_win_prob,
    
      # fair probabilities (0–1)
      p_fair = winner_win_prob / 100,
      q_fair = loser_win_prob  / 100,
    
      # add 4% vig (total prob = 1.04)
      vig_factor = 1.04,
      p_vig = p_fair * vig_factor,
      q_vig = q_fair * vig_factor,
    
      # numeric odds with vig
      winner_odds_int = if_else(
        p_vig > 0.5,
        -(p_vig / (1 - p_vig)) * 100,          # favorite
        ((1 - p_vig) / p_vig) * 100            # underdog (rare for "winner")
      ),
      loser_odds_int = if_else(
        q_vig > 0.5,
        -(q_vig / (1 - q_vig)) * 100,          # favorite (rare for "loser")
        ((1 - q_vig) / q_vig) * 100            # underdog
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
        paste0("- ", round(abs(Home_Odds_Num))),
        paste0("+ ", round(Home_Odds_Num))
      ),
      Away_Team_Model_Odds = if_else(
        Away_Odds_Num < 0,
        paste0("- ", round(abs(Away_Odds_Num))),
        paste0("+ ", round(Away_Odds_Num))
      ),
      
      # convert ESPN odds to numeric
      Home_ESPN_Num = as.integer(Home_Team_ESPN_Odds),
      Away_ESPN_Num = as.integer(Away_Team_ESPN_Odds),
      
      # compute edge using numeric odds
      Home_Team_Betting_Edge = Home_ESPN_Num - round(Home_Odds_Num),
      Away_Team_Betting_Edge = Away_ESPN_Num - round(Away_Odds_Num)
    )
  
  return(matchup_df)
}

################## ROUND DISPLAY COLUMNS FOR MATCHUP #######################
round_display_columns_for_matchup_df <- function(matchup_df) {
    cols_to_round <- c('Home_Total_Score', 'Home_Pitcher_Score', 'Home_Batting_Score',
    'Home_Pitching_Score', 'Home_Team_Split_Score', 'Home_Pitcher_vs_Away_Batting_Score',
    'Home_Power_Score', 'Home_Team_Record_Score', 'Home_Context_Score',
    'Away_Total_Score', 'Away_Pitcher_Score', 'Away_Batting_Score',
    'Away_Pitching_Score', 'Away_Team_Split_Score', 'Away_Pitcher_vs_Away_Batting_Score',
    'Away_Power_Score', 'Away_Team_Record_Score', 'Away_Context_Score')

    # round display columns
    matchup_df <- matchup_df %>%
    mutate(
      across(all_of(cols_to_round), ~ round(.x, 2))
    )

    return(matchup_df)
    }

############### ROUND DISPLAY COLUMNS FOR PITCHER DF #################
round_display_columns_for_pitcher_df <- function(pitcher_df) {

    # pitcher_data
    pitcher_df$WHIP <- round(pitcher_df$WHIP, 2)
    pitcher_df$`K%` <- round(pitcher_df$`K%` * 100, 2)
    pitcher_df$`BB%` <- round(pitcher_df$`BB%` * 100, 2)

    return(pitcher_df)
}

################## CREATE HISTORICAL MATCHUP DF ######################
create_historical_matchup_df <- function(matchup_df, historical_matchup_df) {
  
  
  historical_game_id_list <- historical_matchup_df$Game_ID
  
  
  historical_matchup_final_df<- matchup_df %>%
    filter((!(Game_ID %in% historical_game_id_list)) &
             Prediction_Status == 'Full Prediction')
  return(historical_matchup_final_df)
  
}

################## CREATE Active MATCHUP DF ######################
create_active_matchup_df <- function(matchup_df, historical_matchup_df) {
  
  historical_game_id_list <- historical_matchup_df$Game_ID
  current_game_id_list <- matchup_df$Game_ID
  
  
  current_matchup_filtered_df <- matchup_df %>%
    filter(!(Game_ID %in% historical_game_id_list))
  
  historical_matchup_filtered_df <- historical_matchup_df %>%
    filter(Game_ID %in% current_game_id_list)
  
  
  current_matchup_final_df <- rbind(historical_matchup_filtered_df, current_matchup_filtered_df) %>%
    arrange(Game_Time, ascending=TRUE)
  
  return(current_matchup_final_df)
  
}

#################### FINAL DISPLAY MATCHUP DF (SELECT) ######################
create_final_display_matchup_df <- function(matchup_df) {
    
    matchup_display_df <- matchup_df %>%
        select(
            Game_ID,
            Game_Date,
            Game_Date_Time_Parsed,
            Game_Status,
            Game_Venue,
            Park_Factor,
            Game_Time,
            Day_Night,
            Home_Team,
            Home_Team_ESPN_Odds,
            Home_Team_Model_Odds,
            Home_Team_Betting_Edge,
            Home_Pitcher,
            Home_Pitcher_ID,
            Home_Pitcher_Hand,
            Home_Pitcher_Wins,
            Home_Pitcher_Losses,
            Home_Pitcher_ERA,
            Home_Team_Batting_Lineup,
            Home_Pitcher_Score,
            Home_Batting_Score,
            Home_Pitching_Score,
            Home_Team_Split_Score,
            Home_Pitcher_vs_Away_Batting_Score,
            Home_Power_Score,
            Home_Team_Record_Score,
            Home_Context_Score,
            Away_Team,
            Away_Team_ESPN_Odds,
            Away_Team_Model_Odds,
            Away_Team_Betting_Edge,
            Away_Pitcher,
            Away_Pitcher_ID,
            Away_Pitcher_Hand,
            Away_Pitcher_Wins,
            Away_Pitcher_Losses,
            Away_Pitcher_ERA,
            Away_Team_Batting_Lineup,
            Away_Pitcher_Score,
            Away_Batting_Score,
            Away_Pitching_Score,
            Away_Team_Split_Score,
            Away_Pitcher_vs_Home_Batting_Score,
            Away_Power_Score,
            Away_Team_Record_Score,
            Away_Context_Score,
            Home_Team_Total_Score,
            Away_Team_Total_Score,
            Predicted_Winner,
            Predicted_Loser,
            Score_Difference,
            Win_Probability,
            Home_Lineup_Hydrated,
            Away_Lineup_Hydrated,
            Prediction_Status
        ) %>%
      mutate(update_date = Sys.time()) %>%
      arrange(Game_Time, ascending=TRUE)
    return(matchup_display_df)
    }

#################### CHECK COLOR FOR SPLITS ###################
check_color_for_platoon_splits <- function(platoon_splits, opposing_pitcher_hand) {

    platoon_splits <- as.numeric(platoon_splits)[1]
    opposing_pitcher_hand <- as.character(opposing_pitcher_hand)[1]

    if (is.na(platoon_splits) || is.na(opposing_pitcher_hand)) {
        return("black")
    }

    if ((platoon_splits >= 0 && opposing_pitcher_hand == "L") ||
        (platoon_splits < 0  && opposing_pitcher_hand == "R")) {
        return("green")
    } else {
        return("red")
    }
}


################# CHECK COLOR FOR STAT HIGH###################
check_color_for_stat_high <- function(stat_x, stat_y) {
    if (stat_x > stat_y) {
        return('green')
    } else if (stat_x < stat_y) {
        return('red')
    } else return('black')
}
################ CHECK COLOR FOR STAT LOW ##################

check_color_for_stat_low <- function(stat_x, stat_y) {
    if (stat_x < stat_y) {
        return('green')
    } else if (stat_x > stat_y) {
        return('red')
    } else return('black')
}

