##################### CALCULATE BATTING SCORES #################

calculate_roster_batting_scores <- function(team_batting_df) {
  team_batting_df = team_batting_df
  # create blocks
  
  # 1. CORE DISCIPLINE 
  block_discipline <- c('K%', 'BB%', 'BB/K', 'Z-Swing%', 'Chase%', 'Whiff%')
  block_contact     <- c('GB%', 'FB%', 'LD%', 'GB/FB', 'HR/FB', 'IFFB%', 'Barrel%', 'HardHit%',
                         'Z-Contact%', 'O-Contact%', 'Contact%', 'EV', 'LA')
  block_expected   <- c('xWOBA', 'xBA', 'xSLG', 'xISO', 'xBABIP')
  
  
  # Create a master list of all tracking stats to clean in the next step
  all_stats_to_clean <- c(block_discipline, block_contact, block_expected)
  
  # 1. Combine all your block stats plus runs_scored into one master list
  all_numeric_cols <- c(all_stats_to_clean, 'R')
  
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
    Contact   = block_contact,
    Expected   = block_expected
  )
  
  
  # 2. Define a master vector of stats where LOWER values are better.
  # Any stat NOT on this list will automatically be treated as "Positive/Higher is better".
  negative_stats <- c(
    'K%', 'Chase%', 'Whiff%', 'GB%', 'IFFB%', 'GB/FB', 'O-Contact%')
  
  # 3. Initialize a clean data frame to hold all our final team scores
  # We will start with just the team identifiers
  final_team_scores_df <- team_batting_df %>% 
    select(team_id, team_full_name, team_abbreviation, game_date)
  
  
  
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
    
    y_raw <- team_batting_df$R
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

calculate_pitcher_scores <- function(pitcher_statcast_df, pitcher_fg_df, game_date = NULL) {
  # 1. Define blocks
  block_control   <- c('BB%', 'K%', 'K/9', 'BB/9', 'K-BB%', 'Chase%', 'Whiff%',
                       'Zone%', 'F-Strike%', 'CStr%', 'SwStr%', 'C+SwStr%')
  
  block_contact   <- c('GB%', 'FB%', 'LD%', 'PU%', 'GB/FB', 'HR/FB', 'IFFB%',
                       'Barrel%', 'HardHit%', 'Z-Contact%', 'O-Contact%',
                       'Contact%', 'EV', 'LA')
  
  block_expected  <- c('xBA', 'xwOBA', 'xSLG', 'xISO', 'xBABIP')
  
  all_stats_to_clean <- c(block_control, block_contact, block_expected)
  all_numeric_cols   <- c(all_stats_to_clean, 'SIERA')
  
  
  pitcher_df <- pitcher_statcast_df %>%
    left_join(pitcher_fg_df %>% select(xMLBAMID, SIERA), by = c("pitcher" = "xMLBAMID"))
  
  
  training_df <- pitcher_df %>% 
    filter(!is.na(SIERA))
  

  training_df[all_numeric_cols] <- lapply(training_df[all_numeric_cols], function(x) as.numeric(as.character(x)))
  pitcher_df[all_stats_to_clean] <- lapply(pitcher_df[all_stats_to_clean], function(x) as.numeric(as.character(x)))
  
  for (col in all_stats_to_clean) {
    league_avg <- mean(training_df[[col]], na.rm = TRUE)
    if (is.na(league_avg)) league_avg <- 0 
    
    if (any(is.na(training_df[[col]]))) {
      training_df[[col]][is.na(training_df[[col]])] <- league_avg
    }
    if (any(is.na(pitcher_df[[col]]))) {
      pitcher_df[[col]][is.na(pitcher_df[[col]])] <- league_avg
    }
  }
  
  
  blocks_list <- list(
    Control   = block_control,
    Contact   = block_contact,
    Expected  = block_expected
  )
  
  
  negative_stats <- c(
    'BB%', 'BB/9', 'HardHit%', 'Barrel%', 'FB%', 'LD%', 'HR/FB', 'Contact%',
    'Z-Contact%', 'EV', 'LA', 'xBA', 'xwOBA', 'xSLG', 'xISO', 'xBABIP'
  )
  
  
  final_pitcher_scores_df <- pitcher_df %>% select(pitcher)
  
  for (block_name in names(blocks_list)) {
    block_stats <- blocks_list[[block_name]]
    
    
    X_train_raw <- training_df %>% select(all_of(block_stats))
    X_train_mat <- data.matrix(X_train_raw)
    X_train_scaled <- scale(X_train_mat)
    X_train_scaled[is.na(X_train_scaled)] <- 0
    
    y_train_raw <- training_df$SIERA
    y_train_scaled <- as.vector(scale(y_train_raw))
    
    
    ridge_model <- cv.glmnet(X_train_scaled, y_train_scaled, alpha = 0)
    raw_coefficients <- as.vector(as.matrix(coef(ridge_model, s = "lambda.min")))[-1] 
    raw_coefficients[is.na(raw_coefficients)] <- 0
    
    sum_coefs <- sum(abs(raw_coefficients))
    if (sum_coefs == 0) sum_coefs <- 1
    normalized_weights <- abs(raw_coefficients) / sum_coefs
    
    
    pitcher_component_points <- matrix(0, nrow = nrow(pitcher_df), ncol = length(block_stats))
    
    for (i in 1:length(block_stats)) {
      stat_name <- block_stats[i]
      weight    <- normalized_weights[i]
      
      stat_values_all <- pitcher_df[[stat_name]]
      
      stat_mean_train <- mean(training_df[[col]], na.rm = TRUE)
      stat_sd_train   <- sd(training_df[[col]], na.rm = TRUE)
      
      if (is.na(stat_sd_train) || stat_sd_train == 0) {
        z_scores <- rep(0, length(stat_values_all))
      } else {
        z_scores <- (stat_values_all - stat_mean_train) / stat_sd_train
      }
      
      if (stat_name %in% negative_stats) {
        z_scores <- z_scores * -1
      }
      
      pitcher_component_points[, i] <- z_scores * weight
    }
    
    raw_composite_score <- rowSums(pitcher_component_points, na.rm = TRUE)
    
    avg_comp_train <- mean(raw_composite_score[pitcher_df$pitcher %in% training_df$pitcher], na.rm = TRUE)
    sd_comp_train  <- sd(raw_composite_score[pitcher_df$pitcher %in% training_df$pitcher], na.rm = TRUE)
    if (is.na(sd_comp_train) || sd_comp_train == 0) sd_comp_train <- 1
    
    index_score <- 100 + ((raw_composite_score - avg_comp_train) / sd_comp_train) * 15
    final_points_score <- round(index_score / 10, 2)
    
    column_output_name <- paste0("score_", tolower(block_name))
    final_pitcher_scores_df[[column_output_name]] <- final_points_score
  }
  
  if (is.null(game_date)) {
    game_date = Sys.Date()
  }
  
  final_pitcher_scores_df <- final_pitcher_scores_df %>%
    rename(xMLBAMID = pitcher) %>%
    mutate(
      game_date = game_date,
      update_date = Sys.time()
      )
  
  return(final_pitcher_scores_df)
}

