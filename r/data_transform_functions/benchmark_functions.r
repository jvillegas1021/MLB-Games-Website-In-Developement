################################# CALCULATE PITCHING BENCHMARK##################################

pitcher_benchmark <- function(pitcher_data) {

    columns_low <- c('WHIP', 'FIP', 'BB/9', 'H/9', 'RS/9', 'TTO%', 'AVG',
                    'SLG', 'ISO', 'BABIP', 'OBP', 'OPS', 'EV', 'LA', 'HardHit%', 'Barrel%',
                    'FB%', 'LD%', 'HR/FB', 'Z-Swing%', 'Contact%', 'Z-Contact%', 'Swing%',
                    'BB%', 'xBA', 'xSLG', 'xISO', 'xBABIP', 'xWOBA')
                     
    
    columns_high <- c('LOB%', 'DP%', 'K/9', 'GB%', 'IFFB%', 'GB/FB', 'O-Swing%',
                      'Zone%', 'O-Contact%', 'SwStr%', 'CStr%', 'C+SwStr%', 'F-Strike%', 'K%',
                      'K/BB', 'K-BB%')
    
    
    columns_to_scale <- c(columns_low, columns_high, "ERA")

    # 1) force numeric
    pitcher_data[columns_to_scale] <- lapply(
        pitcher_data[columns_to_scale],
        function(x) as.numeric(as.character(x))
    )

    # filter on IP AFTER conversion
    pitcher_df_filter <- pitcher_data %>%
        filter(IP > 75,
               GS > 15)

    scaled_df <- pitcher_df_filter
    scaled_df[columns_to_scale] <- lapply(
        pitcher_df_filter[columns_to_scale],
        scale
    )

    cor_table <- cor(scaled_df[, columns_to_scale], use = "complete.obs")
    stat_cor <- cor_table[, "ERA"]

    cor_df <- data.frame(
        stat = names(stat_cor),
        cor = stat_cor,
        abs_cor = abs(stat_cor)
    ) %>%
        arrange(desc(abs_cor)) %>%
        mutate(
            quantile_rank = ntile(abs_cor, 5),
            weight = case_when(
                quantile_rank == 1 ~ 0.20,
                quantile_rank == 2 ~ 0.40,
                quantile_rank == 3 ~ 0.60,
                quantile_rank == 4 ~ 0.80,
                quantile_rank == 5 ~ 1.00
            )
        )

    pitcher_benchmark_df <- cor_df %>%
        select(stat, cor, abs_cor, quantile_rank, weight) %>%
        mutate(high_low = if_else(stat %in% columns_low, "low", "high"))

    name_list <- unique(pitcher_benchmark_df$stat)

    pitcher_filtered_df <- pitcher_df_filter %>%
        select(all_of(name_list))

    pitcher_low_filtered_df <- pitcher_filtered_df %>%
        select(all_of(columns_low))

    pitcher_high_filtered_df <- pitcher_filtered_df %>%
        select(all_of(columns_high))

    ## LOW STATS: 0, 0.125, 0.25, 0.375, 0.5
    stat_low_list <- list()
    for (column in columns_low) {
        stat_df <- data.frame(
            stat     = column,
            min      = quantile(pitcher_low_filtered_df[[column]], 0.00,  na.rm = TRUE),
            first_q  = quantile(pitcher_low_filtered_df[[column]], 0.125, na.rm = TRUE),
            second_q = quantile(pitcher_low_filtered_df[[column]], 0.25,  na.rm = TRUE),
            third_q  = quantile(pitcher_low_filtered_df[[column]], 0.375, na.rm = TRUE),
            max      = quantile(pitcher_low_filtered_df[[column]], 0.50,  na.rm = TRUE)
        )
        stat_low_list <- append(stat_low_list, list(stat_df))
    }
    stat_low_df <- do.call(rbind, stat_low_list)

    ## HIGH STATS: 0.5, 0.625, 0.75, 0.875, 1
    stat_high_list <- list()
    for (column in columns_high) {
        stat_df <- data.frame(
            stat     = column,
            min      = quantile(pitcher_high_filtered_df[[column]], 0.50,  na.rm = TRUE),
            first_q  = quantile(pitcher_high_filtered_df[[column]], 0.625, na.rm = TRUE),
            second_q = quantile(pitcher_high_filtered_df[[column]], 0.75,  na.rm = TRUE),
            third_q  = quantile(pitcher_high_filtered_df[[column]], 0.875, na.rm = TRUE),
            max      = quantile(pitcher_high_filtered_df[[column]], 1.00,  na.rm = TRUE)
        )
        stat_high_list <- append(stat_high_list, list(stat_df))
    }
    stat_high_df <- do.call(rbind, stat_high_list)

    final_df <- rbind(stat_low_df, stat_high_df)

    pitcher_benchmark_df <- left_join(final_df, pitcher_benchmark_df, by = "stat")
    
    pitcher_benchmark_df <- pitcher_benchmark_df %>%
    arrange(
        desc(quantile_rank)
        ) %>%
    mutate(update_date = Sys.Date())
    
    return(pitcher_benchmark_df)
}



################################# BATTING BENCHMARK ########################################
team_batting_benchmark <- function(team_batting_df) {

    columns_low <- c('K%', 'GB%', 'GB/FB', 'IFFB%', 'O-Swing%', 'O-Contact%',
                     'Chase%', 'Whiff%', 'SwStr%', 'F-Strike%')
        
    columns_high <- c('FB%', 'BB%', 'ISO', 'LD%', 'OPS', 'BABIP', 'AVG', 'OBP',
                      'SLG', 'BB/K', 'HR/FB', 'Barrel%', 'HardHit%', 'Z-Swing%', 'Z-Contact%',
                      'Contact%', 'EV', 'LA', 'wOBA', 'wRAA', 'wRC', 'wRC+', 'xBA', 'xSLG',
                      'xISO', 'xBABIP')

    
    columns_to_scale <- c(columns_low, columns_high, "xWOBA")

    team_batting_df[columns_to_scale] <- lapply(team_batting_df[columns_to_scale], function(x) as.numeric(as.character(x)))
    
    scaled_df <- team_batting_df
    scaled_df[columns_to_scale] <- lapply(team_batting_df[columns_to_scale], scale)
    cor_table <- cor(scaled_df[, columns_to_scale], use = "complete.obs")
    
    xwoba_cor <- cor_table[, "xWOBA"]
        
    cor_df <- data.frame(
        stat = names(xwoba_cor),
        cor = xwoba_cor,
        abs_cor = abs(xwoba_cor)
        )
    
    cor_df <- cor_df %>%
        arrange(desc(abs_cor))
    
    cor_df <- cor_df %>%
        mutate(quantile_rank = ntile(cor_df$abs_cor, 5),
               weight = case_when(
                   quantile_rank == 1 ~ 0.20,
                   quantile_rank == 2 ~ 0.40,
                   quantile_rank == 3 ~ 0.60,
                   quantile_rank == 4 ~ .80,
                   quantile_rank == 5 ~ 1.0
                   )
               )
    
    team_batting_benchmark_df <- cor_df %>%
    select(stat, cor, abs_cor, quantile_rank, weight)
    
    team_batting_benchmark_df <- team_batting_benchmark_df %>%
    mutate(high_low = if_else(stat %in% columns_low, "low", "high"))
    
    name_list <- (unique(team_batting_benchmark_df$stat))

    batting_filtered_df <- team_batting_df %>%
    select(all_of(name_list))
                                                
    batting_low_filtered_df <- batting_filtered_df %>%
    select(all_of(columns_low))
    
    batting_high_filtered_df <- batting_filtered_df %>%
    select(all_of(columns_high))
    
    stat_low_list <- list()
    
    for (column in columns_low) {
            
        stat_df <- data.frame(
            stat = column,
            min      = quantile(batting_low_filtered_df[[ column ]], probs = 0.00, na.rm = TRUE),
            first_q  = quantile(batting_low_filtered_df[[ column ]], probs = 0.125, na.rm = TRUE),
            second_q = quantile(batting_low_filtered_df[[ column ]], probs = 0.25, na.rm = TRUE),
            third_q  = quantile(batting_low_filtered_df[[ column ]], probs = 0.375, na.rm = TRUE),
            max      = quantile(batting_low_filtered_df[[ column ]], probs = 0.50, na.rm = TRUE)
        )

    
        stat_low_list <- append(stat_low_list, list(stat_df))
    }
    
    stat_low_df <- do.call(rbind, stat_low_list)
    
    stat_high_list <- list()
    
    for (column in columns_high) {
        
        stat_df <- data.frame(
            stat = column,
            min = quantile(batting_high_filtered_df[[ column ]], probs = 0.5, na.rm = TRUE),
            first_q = quantile(batting_high_filtered_df[[ column ]], probs = 0.625, na.rm = TRUE),
            second_q = quantile(batting_high_filtered_df[[ column ]], probs = .750, na.rm = TRUE),
            third_q = quantile(batting_high_filtered_df[[ column ]], probs = .825, na.rm = TRUE),
            max = quantile(batting_high_filtered_df[[ column ]], probs = 1.0, na.rm = TRUE)
            )
    
        stat_high_list <- append(stat_high_list, list(stat_df))
    }
    
    stat_high_df <- do.call(rbind, stat_high_list)
    
    
    final_df <- rbind(stat_low_df, stat_high_df)
    
    team_batting_benchmark_df <- left_join(final_df, team_batting_benchmark_df, by = "stat")

    team_batting_benchmark_df <- team_batting_benchmark_df %>%
    arrange(
        desc(quantile_rank)
        ) %>%
    mutate(update_date = Sys.Date())
                                           
    return(team_batting_benchmark_df)

}

########################## TEAM PITCHING BENCHMARK ########################################

team_pitching_benchmark <- function(team_pitching_df) {
    
    
    team_pitching_df[] <- lapply(team_pitching_df, function(x) {
      if (inherits(x, "integer64")) as.numeric(x) else x
    })
    ## CREATE CORRELATION DF WITH WEIGHTS ##
    columns_low <- c('WHIP', 'FIP', 'BB/9', 'H/9', 'HR/9', 'RS/9', 'AVG',
                    'SLG', 'ISO', 'BABIP', 'OBP', 'OPS', 'EV', 'LA', 'HardHit%', 'Barrel%',
                    'FB%', 'LD%', 'HR/FB', 'Z-Swing%', 'Contact%', 'Z-Contact%', 'BB%', 'Swing%',
                    'xBA', 'xSLG', 'xISO', 'xBABIP', 'xWOBA')
                     
    
    columns_high <- c('LOB%', 'DP%', 'K/9', 'TTO%', 'GB%', 'GB/FB', 'Zone%', 'O-Swing%',
                      'SwStr%', 'CStr%', 'C+SwStr%', 'F-Strike%', 'K%', 'K/BB')
                      


    
    columns_to_scale <- c(columns_low, columns_high, "ERA")
    
    scaled_df <- team_pitching_df
    scaled_df[columns_to_scale] <- lapply(team_pitching_df[columns_to_scale], scale)
    
    cor_table <- cor(scaled_df[, columns_to_scale], use = "complete.obs")
    
    stat_cor <- cor_table[, "ERA"]
    
    cor_df <- data.frame(
        stat = names(stat_cor),
        cor = stat_cor,
        abs_cor = abs(stat_cor)
    ) %>%
        arrange(desc(abs_cor)) %>%
        mutate(
            quantile_rank = ntile(abs_cor, 5),
            weight = case_when(
                quantile_rank == 1 ~ 0.20,
                quantile_rank == 2 ~ 0.40,
                quantile_rank == 3 ~ 0.60,
                quantile_rank == 4 ~ 0.80,
                quantile_rank == 5 ~ 1.00
            )
        )
    
    
    team_pitching_benchmark_df <- cor_df %>%
    select(stat, cor, abs_cor, quantile_rank, weight)
    
    team_pitching_benchmark_df <- team_pitching_benchmark_df %>%
    mutate(high_low = if_else(stat %in% columns_low, "low", "high"))
    
    name_list <- (unique(team_pitching_benchmark_df$stat))
        
    pitching_filtered_df <- team_pitching_df %>%
    select(all_of(name_list))
    
    pitching_low_filtered_df <- pitching_filtered_df %>%
    select(all_of(columns_low))
    
    pitching_high_filtered_df <- pitching_filtered_df %>%
    select(all_of(columns_high))
    
    stat_low_list <- list()
    
    for (column in columns_low) {
        
        stat_df <- data.frame(
            stat = column,
            min = quantile(pitching_low_filtered_df[[ column ]], probs = 0.5),
            first_q = quantile(pitching_low_filtered_df[[ column ]], probs = 0.375),
            second_q = quantile(pitching_low_filtered_df[[ column ]], probs = .250),
            third_q = quantile(pitching_low_filtered_df[[ column ]], probs = .125),
            max = quantile(pitching_low_filtered_df[[ column ]], probs = 0)
            )
    
        stat_low_list <- append(stat_low_list, list(stat_df))
    }
    
    stat_low_df <- do.call(rbind, stat_low_list)
    
    stat_high_list <- list()
    
    for (column in columns_high) {
        
        stat_df <- data.frame(
            stat = column,
            min = quantile(pitching_high_filtered_df[[ column ]], probs = 0.5),
            first_q = quantile(pitching_high_filtered_df[[ column ]], probs = 0.625),
            second_q = quantile(pitching_high_filtered_df[[ column ]], probs = .750),
            third_q = quantile(pitching_high_filtered_df[[ column ]], probs = .825),
            max = quantile(pitching_high_filtered_df[[ column ]], probs = 1.0)
            )
    
        stat_high_list <- append(stat_high_list, list(stat_df))
    }
    
    stat_high_df <- do.call(rbind, stat_high_list)
    
    final_df <- rbind(stat_low_df, stat_high_df)
    
    team_pitching_benchmark_df <- left_join(final_df, team_pitching_benchmark_df, by = "stat")

    team_pitching_benchmark_df <- team_pitching_benchmark_df %>%
    arrange(
        desc(quantile_rank)
        ) %>%
    mutate(update_date = Sys.Date())
    
    return(team_pitching_benchmark_df)
    
    }

########################## MLB TEAM RECORD BENCHMARK ########################################
mlb_team_record_benchmark <- function(mlb_team_record_df) {

    columns_low <- c('runs_allowed')
        
    columns_high <- c('runs_scored', 'run_differential', 'home', 'away', 'left', 'leftHome', 'leftAway', 'rightHome', 'rightAway',
                     'right', 'lastTen', 'extraInning', 'oneRun', 'winners', 'day', 'night')

    
    columns_to_scale <- c(columns_low, columns_high, "winning_percentage")

    mlb_team_record_df[columns_to_scale] <- lapply(mlb_team_record_df[columns_to_scale], function(x) as.numeric(as.character(x)))
    
    scaled_df <- mlb_team_record_df
    scaled_df[columns_to_scale] <- lapply(mlb_team_record_df[columns_to_scale], scale)
    cor_table <- cor(scaled_df[, columns_to_scale], use = "complete.obs")
    
    winning_percentage_cor <- cor_table[, "winning_percentage"]

    cor_df <- data.frame(
        stat = names(winning_percentage_cor),
        cor = winning_percentage_cor,
        abs_cor = abs(winning_percentage_cor)
    ) %>%
        arrange(desc(abs_cor)) %>%
        mutate(
            quantile_rank = ntile(abs_cor, 10),
            weight = case_when(
                quantile_rank == 1 ~ 0.10,
                quantile_rank == 2 ~ 0.20,
                quantile_rank == 3 ~ 0.30,
                quantile_rank == 4 ~ 0.40,
                quantile_rank == 5 ~ 0.50,
                quantile_rank == 6 ~ 0.60,
                quantile_rank == 7 ~ 0.70,
                quantile_rank == 8 ~ 0.80,
                quantile_rank == 9 ~ 0.90,
                quantile_rank == 10 ~ 1.00
            )
        )

    mlb_team_benchmark_df <- cor_df %>%
        select(stat, cor, abs_cor, quantile_rank, weight) %>%
        mutate(high_low = if_else(stat %in% columns_low, "low", "high"))

    name_list <- unique(mlb_team_benchmark_df$stat)

    mlb_team_filtered_df <- mlb_team_record_df %>%
        select(all_of(name_list))

    mlb_team_low_filtered_df <- mlb_team_filtered_df %>%
        select(all_of(columns_low))

    mlb_team_high_filtered_df <- mlb_team_filtered_df %>%
        select(all_of(columns_high))

    ## LOW STATS: 0, 0.125, 0.25, 0.375, 0.5
    stat_low_list <- list()
    for (column in columns_low) {
        stat_df <- data.frame(
            stat     = column,
            min      = quantile(mlb_team_low_filtered_df[[column]], 0.00,  na.rm = TRUE),
            first_q  = quantile(mlb_team_low_filtered_df[[column]], 0.125, na.rm = TRUE),
            second_q = quantile(mlb_team_low_filtered_df[[column]], 0.25,  na.rm = TRUE),
            third_q  = quantile(mlb_team_low_filtered_df[[column]], 0.375, na.rm = TRUE),
            max      = quantile(mlb_team_low_filtered_df[[column]], 0.50,  na.rm = TRUE)
        )
        stat_low_list <- append(stat_low_list, list(stat_df))
    }
    stat_low_df <- do.call(rbind, stat_low_list)

    ## HIGH STATS: 0.5, 0.625, 0.75, 0.875, 1
    stat_high_list <- list()
    for (column in columns_high) {
        stat_df <- data.frame(
            stat     = column,
            min      = quantile(mlb_team_high_filtered_df[[column]], 0.50,  na.rm = TRUE),
            first_q  = quantile(mlb_team_high_filtered_df[[column]], 0.625, na.rm = TRUE),
            second_q = quantile(mlb_team_high_filtered_df[[column]], 0.75,  na.rm = TRUE),
            third_q  = quantile(mlb_team_high_filtered_df[[column]], 0.875, na.rm = TRUE),
            max      = quantile(mlb_team_high_filtered_df[[column]], 1.00,  na.rm = TRUE)
        )
        stat_high_list <- append(stat_high_list, list(stat_df))
    }
    stat_high_df <- do.call(rbind, stat_high_list)

    final_df <- rbind(stat_low_df, stat_high_df)

    mlb_team_benchmark_df <- left_join(final_df, mlb_team_benchmark_df, by = "stat")
    
    mlb_team_benchmark_df <- mlb_team_benchmark_df %>%
    arrange(
        desc(quantile_rank)
        ) %>%
    mutate(update_date = Sys.Date())
    
    return(mlb_team_benchmark_df)
}

##################### CALCULATE LEAGUE PITCHER AVERAGES #################
mlb_pitcher_league_averages <- function(starting_pitcher_stats_df) {
  
  league_pitcher_averages_df <- starting_pitcher_stats_df %>%
    select(-xMLBAMID,
           -player_name,
           -Throws,
           -GS,
           -`update_date`) %>%
    summarise(across(
      everything(),
      list(
        min  = ~ min(.x, na.rm = TRUE),
        average = ~ mean(.x, na.rm = TRUE),
        mid_tier  = ~ quantile(.x, 0.50, na.rm = TRUE),
        top_tier  = ~ quantile(.x, 0.75, na.rm = TRUE),
        elite_tier  = ~ quantile(.x, 0.90, na.rm = TRUE),
        max  = ~ max(.x, na.rm = TRUE)
      )
    )) %>%
    mutate(
      across(where(is.numeric), as.double)
    ) %>%
    pivot_longer(
      everything(),
      names_to = c("stat", "metric"),
      names_pattern = "^(.*)_(min|average|mid_tier|top_tier|elite_tier|max)$",
      values_to = "value"
    ) %>%
    pivot_wider(
      names_from = metric,
      values_from = value
    ) %>%
    mutate(update_date = Sys.Date())
  
  return(league_pitcher_averages_df)
}


################## CALCULATE LEAGUE BATTING AVERAGES ############################
mlb_team_league_batting_averages <- function(team_batting_df) {
  
  league_batting_averages_df <- team_batting_df %>%
    select(-gamePk,
           -officialDate,
           -team_name,
           -team_id,
           -hitter_player_ids,
           -`update date`) %>%
    summarise(across(
      everything(),
      list(
        min  = ~ min(.x, na.rm = TRUE),
        average = ~ mean(.x, na.rm = TRUE),
        mid_tier  = ~ quantile(.x, 0.50, na.rm = TRUE),
        top_tier  = ~ quantile(.x, 0.75, na.rm = TRUE),
        elite_tier  = ~ quantile(.x, 0.90, na.rm = TRUE),
        max  = ~ max(.x, na.rm = TRUE)
      )
    )) %>%
    mutate(
      across(where(is.numeric), as.double)
    ) %>%
    pivot_longer(
      everything(),
      names_to = c("stat", "metric"),
      names_pattern = "^(.*)_(min|average|mid_tier|top_tier|elite_tier|max)$",
      values_to = "value"
    ) %>%
    pivot_wider(
      names_from = metric,
      values_from = value
    ) %>%
    mutate(update_date = Sys.Date())
  
  return(league_batting_averages_df)
}

###################### CALCULATE LEAGUE SPLITS ################################
mlb_team_league_batting_splits <- function(team_batting_df) {
  league_batting_averages <- team_batting_df %>%
    select(-gamePk,
           -officialDate,
           -team_name,
           -team_id,
           -hitter_player_ids,
           -`update date`) %>%
    summarise(across(
      everything(),
      list(
        min  = ~ min(.x, na.rm = TRUE),
        average = ~ mean(.x, na.rm = TRUE),
        mid_tier  = ~ quantile(.x, 0.50, na.rm = TRUE),
        top_tier  = ~ quantile(.x, 0.75, na.rm = TRUE),
        elite_tier  = ~ quantile(.x, 0.90, na.rm = TRUE),
        max  = ~ max(.x, na.rm = TRUE)
      )
    )) %>%
    mutate(
      across(where(is.numeric), as.double)
    ) %>%
    pivot_longer(
      everything(),
      names_to = c("stat", "metric"),
      names_pattern = "^(.*)_(min|average|mid_tier|top_tier|elite_tier|max)$",
      values_to = "value"
    ) %>%
    pivot_wider(
      names_from = metric,
      values_from = value
    )
  
  
  
  league_average_splits <- league_batting_averages %>%
    select(stat,
           average)
  
  rhp_columns <- str_starts(league_average_splits$stat, c('RHP'))
  lhp_columns <- str_starts(league_average_splits$stat, c('LHP'))
  
  
  rhp_df <- league_average_splits[rhp_columns, ]
  rhp_df <- rhp_df %>%
    rename(stat_right = stat,
           average_right = average)
  
  lhp_df <- league_average_splits[lhp_columns, ]
  lhp_df <- lhp_df %>%
    rename(stat_left = stat,
           average_left = average)
  
  
  splits_df <- bind_cols(rhp_df, lhp_df)
  splits_df <- splits_df %>%
    mutate(league_split = average_left - average_right)
  
  cleaned_stat_columns <- str_remove(splits_df$stat_right, 'RHP_')
  
  splits_df <- splits_df %>%
    mutate(split_stat = cleaned_stat_columns) %>%
    select(-stat_right,
           -stat_left) %>%
    relocate(split_stat, .before=average_right) %>%
    rename(split_right = average_right,
           split_left = average_left) %>%
    mutate(update_date = Sys.Date())
  
  return(splits_df)
}

