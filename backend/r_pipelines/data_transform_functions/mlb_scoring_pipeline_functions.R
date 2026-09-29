##################### CALCULATE BATTING SCORES #################

calculate_roster_batting_scores <- function(team_batting_df) {
  team_batting_df = team_batting_df
  # create blocks
  
  # 1. CORE DISCIPLINE 
  block_discipline <- c('Chase%', 'Whiff%', 'BB%', 'K%', 'Contact%', 'F-Strike%')
  block_impact     <- c('Barrel%', 'HardHit%', 'EV', 'ISO', 'LD%', 'GB%', 'FB%')
  block_expected   <- c('xBA', 'xSLG', 'xBABIP', 'xISO')
  block_results    <- c('OPS', 'AVG', 'OBP', 'SLG', 'BABIP')
  block_vs_rhp <- c('RHP_OPS', 'RHP_AVG', 'RHP_OBP', 'RHP_SLG', 'RHP_ISO', 'RHP_K%', 'RHP_BB%')
  block_vs_lhp <- c('LHP_OPS', 'LHP_AVG', 'LHP_OBP', 'LHP_SLG', 'LHP_ISO', 'LHP_K%', 'LHP_BB%')
  block_fastballs  <- c('4_Seam_Fastball_Whiff%', '2_Seam_Fastball_Whiff%', 'Sinker_Whiff%', 'Cutter_Whiff%')
  block_breaking   <- c('Slider_Whiff%', 'Sweeper_Whiff%', 'Curveball_Whiff%', 'Changeup_Whiff%', 'Split_Finger_Whiff%')
  
  
  # Create a master list of all tracking stats to clean in the next step
  all_stats_to_clean <- c(block_discipline, block_impact, block_expected, 
                          block_results, block_vs_lhp, block_vs_rhp, block_fastballs, block_breaking)
  
  
  # 1. Combine all your block stats plus runs_scored into one master list
  all_numeric_cols <- c(all_stats_to_clean, 'xWOBA')
  
  # 2. Force every stat column to be numeric (fixes character/factor text issues)
  team_batting_df[all_numeric_cols] <- lapply(
    team_batting_df[all_numeric_cols], 
    function(x) as.numeric(as.character(x))
  )
  
  # 3. Clean up NA values by replacing them with the league average for that stat
  for (col in all_numeric_cols) {
    if (any(is.na(team_batting_df[[col]]))) {
      league_avg <- mean(team_batting_df[[col]], na.rm = TRUE)
      
      # If a stat is completely blank for some reason, default to 0
      if (is.na(league_avg)) league_avg <- 0 
      
      team_batting_df[[col]][is.na(team_batting_df[[col]])] <- league_avg
    }
  }
  
  
  # 1. Create a structured list linking each block to its specific stats
  blocks_list <- list(
    Discipline = block_discipline,
    Impact     = block_impact,
    Expected   = block_expected,
    Results    = block_results,
    VS_LHP     = block_vs_lhp,
    VS_RHP     = block_vs_rhp,
    Fastballs  = block_fastballs,
    Breaking   = block_breaking
  )
  
  
  # 2. Define a master vector of stats where LOWER values are better.
  # Any stat NOT on this list will automatically be treated as "Positive/Higher is better".
  negative_stats <- c(
    'K%', 'Chase%', 'Whiff%', 'F-Strike%', 'GB%', 'IFFB%', 'RHP_K%', 'LHP_K%',
    '4_Seam_Fastball_Whiff%', '2_Seam_Fastball_Whiff%', 'Sinker_Whiff%', 'Cutter_Whiff%',
    'Slider_Whiff%', 'Sweeper_Whiff%', 'Curveball_Whiff%', 'Changeup_Whiff%', 'Split_Finger_Whiff%',
    'RHP_K%', 'LHP_K%'
  )
  
  # 3. Initialize a clean data frame to hold all our final team scores
  # We will start with just the team identifiers
  final_team_scores_df <- team_batting_df %>% 
    select(team_id, team_name)
  
  
  
  # Loop through each of the 7 skill blocks
  for (block_name in names(blocks_list)) {
    
    # 1. Pull the specific stats for this current block
    block_stats <- blocks_list[[block_name]]
    
    # 2. Extract and format the matrix safely
    X_raw <- team_batting_df %>% select(all_of(block_stats))
    X_mat <- data.matrix(X_raw)
    
    # Safety Check: If a column has 0 variance (all values are identical), 
    # scaling it creates NaNs. We replace those NaNs with 0 to prevent glmnet from crashing.
    X_scaled <- scale(X_mat)
    X_scaled[is.na(X_scaled)] <- 0
    
    y_raw <- team_batting_df$xWOBA
    y_scaled <- as.vector(scale(y_raw))
    
    # 3. Fit the Ridge Regression model for this block
    ridge_model <- cv.glmnet(X_scaled, y_scaled, alpha = 0)
    
    # 4. Extract importance weights (coefficients) and normalize them to sum to 1.00
    raw_coefficients <- as.vector(as.matrix(coef(ridge_model, s = "lambda.min")))[-1] 
    
    # Safety Check: If a coefficient is NaN due to zero variance, force it to 0
    raw_coefficients[is.na(raw_coefficients)] <- 0
    
    # Ensure we don't divide by zero if all weights happen to be zero
    sum_coefs <- sum(abs(raw_coefficients))
    if (sum_coefs == 0) sum_coefs <- 1
    
    normalized_weights <- abs(raw_coefficients) / sum_coefs
    
    # 5. Build an internal matrix to store component points for each team
    team_component_points <- matrix(0, nrow = nrow(team_batting_df), ncol = length(block_stats))
    
    # 6. Calculate the scores for each individual stat in the block
    for (i in 1:length(block_stats)) {
      stat_name <- block_stats[i]
      weight    <- normalized_weights[i]
      
      # Calculate team Z-scores for this stat
      stat_values <- team_batting_df[[stat_name]]
      
      stat_mean <- mean(stat_values, na.rm = TRUE)
      stat_sd   <- sd(stat_values, na.rm = TRUE)
      
      # Safety Check for Z-Score standard deviation dividing by zero
      if (is.na(stat_sd) || stat_sd == 0) {
        z_scores <- rep(0, length(stat_values))
      } else {
        z_scores <- (stat_values - stat_mean) / stat_sd
      }
      
      # If the stat is on our negative list (like K% or Whiff%), flip the sign 
      if (stat_name %in% negative_stats) {
        z_scores <- z_scores * -1
      }
      
      # Multiply by the ridge importance weight
      team_component_points[, i] <- z_scores * weight
    }
    
    # 7. Sum the individual components together to get the raw composite score
    raw_composite_score <- rowSums(team_component_points, na.rm = TRUE)
    
    # 8. Scale to our classic Index scale (Mean = 100, Standard Deviation = 15)
    avg_comp <- mean(raw_composite_score, na.rm = TRUE)
    sd_comp  <- sd(raw_composite_score, na.rm = TRUE)
    
    if (is.na(sd_comp) || sd_comp == 0) sd_comp <- 1
    
    index_score <- 100 + ((raw_composite_score - avg_comp) / sd_comp) * 15
    
    # 9. Apply your custom logic: Divide by 10 to turn the 100-baseline index into a clean points scale!
    final_points_score <- round(index_score / 10, 2)
    
    # 10. Append this new score column to your final scores dataframe
    column_output_name <- paste0("score_", tolower(block_name))
    final_team_scores_df[[column_output_name]] <- final_points_score
  }
  
  
  final_team_scores_df <- final_team_scores_df %>%
    mutate(
      update_date = Sys.time())
  
  return(final_team_scores_df)
}

############### CALCULATE PITCHER SCORES ##########################

calculate_pitcher_scores <- function(pitcher_df) {
  pitcher_df = pitcher_df
  # pitch usage columns
  pitch_usage_cols <- c(
    '2_Seam_Fastball_usage%', '4_Seam_Fastball_usage%', 'Changeup_usage%', 'Curveball_usage%', 
    'Cutter_usage%', 'Sinker_usage%', 'Slider_usage%', 'Split_Finger_usage%', 'Sweeper_usage%'
  )
  
  # 1. define blocks
  block_control   <- c('BB%', 'Zone%', 'F-Strike%', 'K/BB')
  block_strikeout <- c('K%', 'SwStr%', 'C+SwStr%', 'O-Swing%', 'Contact%', 'CStr%')
  block_contact   <- c('Barrel%', 'HardHit%', 'EV', 'GB%', 'LD%', 'FB%')
  block_expected  <- c('xBA', 'xSLG', 'xBABIP', 'xISO', 'xERA')
  block_vs_lhb    <- c('LHB_OPS', 'LHB_ISO', 'LHB_K%', 'LHB_BB%', 'LHB_xWOBA', 'LHB_Barrel%', 'LHB_CStr%')
  block_vs_rhb    <- c('RHB_OPS', 'RHB_ISO', 'RHB_K%', 'RHB_BB%', 'RHB_xWOBA', 'RHB_Barrel%', 'RHB_CStr%')
  
  # Create a master list of all tracking stats to clean in the next step
  all_stats_to_clean <- c(block_control, block_strikeout, block_contact, 
                          block_expected, block_vs_lhb, block_vs_rhb)
  
  
  # 1. Combine all your block stats plus runs_scored into one master list
  all_numeric_cols <- c(all_stats_to_clean, 'xWOBA')
  
  # 2. Force every stat column to be numeric (fixes character/factor text issues)
  pitcher_df[all_numeric_cols] <- lapply(
    pitcher_df[all_numeric_cols], 
    function(x) as.numeric(as.character(x))
  )
  
  # 3. Clean up NA values by replacing them with the league average for that stat
  for (col in all_numeric_cols) {
    if (any(is.na(pitcher_df[[col]]))) {
      league_avg <- mean(pitcher_df[[col]], na.rm = TRUE)
      
      # If a stat is completely blank for some reason, default to 0
      if (is.na(league_avg)) league_avg <- 0 
      
      pitcher_df[[col]][is.na(pitcher_df[[col]])] <- league_avg
    }
  }
  
  
  # 1. Create a structured list linking each block to its specific stats
  blocks_list <- list(
    Control   = block_control,
    Strikeout = block_strikeout,
    Contact   = block_contact,
    Expected  = block_expected,
    Vs_LHB    = block_vs_lhb,
    Vs_RHB    = block_vs_rhb
  )
  
  
  # 2. Define a master vector of stats where LOWER values are better.
  # Any stat NOT on this list will automatically be treated as "Positive/Higher is better".
  negative_stats <- c(
    'BB%', 'Contact%', 'Barrel%', 'HardHit%', 'EV', 'LD%', 'xBA', 'xSLG', 'xBABIP', 'xISO', 'xERA',
    'LHB_OPS', 'LHB_ISO', 'LHB_BB%', 'LHB_xWOBA', 'LHB_Barrel%',
    'RHB_OPS', 'RHB_ISO', 'RHB_BB%', 'RHB_xWOBA', 'RHB_Barrel%'
  )
  
  # 3. Initialize a clean data frame to hold all our final team scores
  # We will start with just the team identifiers
  final_pitcher_scores_df <- pitcher_df %>% 
    select(any_of(c("xMLBAMID", "player_name", "Throws")), any_of(pitch_usage_cols))
  
  
  # Loop through each of the 7 skill blocks
  for (block_name in names(blocks_list)) {
    
    # 1. Pull the specific stats for this current block
    block_stats <- blocks_list[[block_name]]
    
    # 2. Extract and format the matrix safely
    X_raw <- pitcher_df %>% select(all_of(block_stats))
    X_mat <- data.matrix(X_raw)
    
    # Safety Check: If a column has 0 variance (all values are identical), 
    # scaling it creates NaNs. We replace those NaNs with 0 to prevent glmnet from crashing.
    X_scaled <- scale(X_mat)
    X_scaled[is.na(X_scaled)] <- 0
    
    y_raw <- pitcher_df$xWOBA
    y_scaled <- as.vector(scale(y_raw))
    
    # 3. Fit the Ridge Regression model for this block
    ridge_model <- cv.glmnet(X_scaled, y_scaled, alpha = 0)
    
    # 4. Extract importance weights (coefficients) and normalize them to sum to 1.00
    raw_coefficients <- as.vector(as.matrix(coef(ridge_model, s = "lambda.min")))[-1] 
    
    # Safety Check: If a coefficient is NaN due to zero variance, force it to 0
    raw_coefficients[is.na(raw_coefficients)] <- 0
    
    # Ensure we don't divide by zero if all weights happen to be zero
    sum_coefs <- sum(abs(raw_coefficients))
    if (sum_coefs == 0) sum_coefs <- 1
    
    normalized_weights <- abs(raw_coefficients) / sum_coefs
    
    # 5. Build an internal matrix to store component points for each team
    pitcher_component_points <- matrix(0, nrow = nrow(pitcher_df), ncol = length(block_stats))
    
    # 6. Calculate the scores for each individual stat in the block
    for (i in 1:length(block_stats)) {
      stat_name <- block_stats[i]
      weight    <- normalized_weights[i]
      
      # Calculate team Z-scores for this stat
      stat_values <- pitcher_df[[stat_name]]
      
      stat_mean <- mean(stat_values, na.rm = TRUE)
      stat_sd   <- sd(stat_values, na.rm = TRUE)
      
      # Safety Check for Z-Score standard deviation dividing by zero
      if (is.na(stat_sd) || stat_sd == 0) {
        z_scores <- rep(0, length(stat_values))
      } else {
        z_scores <- (stat_values - stat_mean) / stat_sd
      }
      
      # If the stat is on our negative list (like K% or Whiff%), flip the sign 
      if (stat_name %in% negative_stats) {
        z_scores <- z_scores * -1
      }
      
      # Multiply by the ridge importance weight
      pitcher_component_points[, i] <- z_scores * weight
    }
    
    # 7. Sum the individual components together to get the raw composite score
    raw_composite_score <- rowSums(pitcher_component_points, na.rm = TRUE)
    
    # 8. Scale to our classic Index scale (Mean = 100, Standard Deviation = 15)
    avg_comp <- mean(raw_composite_score, na.rm = TRUE)
    sd_comp  <- sd(raw_composite_score, na.rm = TRUE)
    
    if (is.na(sd_comp) || sd_comp == 0) sd_comp <- 1
    
    index_score <- 100 + ((raw_composite_score - avg_comp) / sd_comp) * 15
    
    # 9. Apply your custom logic: Divide by 10 to turn the 100-baseline index into a clean points scale!
    final_points_score <- round(index_score / 10, 2)
    
    # 10. Append this new score column to your final scores dataframe
    column_output_name <- paste0("score_", tolower(block_name))
    final_pitcher_scores_df[[column_output_name]] <- final_points_score
  }
  
  
  final_pitcher_scores_df <- final_pitcher_scores_df %>%
    mutate(
      update_date = Sys.time())
  
  return(final_pitcher_scores_df)
} 

########## FILTER STARTING PITCHERS #############
filter_starting_pitcher <- function(pitcher_df) {
  starting_pitcher_df <- pitcher_df %>%
    filter(GS > 10 & IP_per_start >= 4.0)
  return(starting_pitcher_df)
}

########## FILTER HYBRID PITCHERS #############
filter_hybrid_pitcher <- function(pitcher_df) {
  hybrid_pitcher_df <- pitcher_df %>%
    filter((GS > 0 & GS <= 10) | (GS > 10 & IP_per_start < 4.0))
  return(hybrid_pitcher_df)
}

########## FILTER RELIEF PITCHERS #############
filter_relief_pitcher <- function(pitcher_df) {
  relief_pitcher_df <- pitcher_df %>%
    filter(GS == 0 & IP >= 10)
  return(relief_pitcher_df)
}