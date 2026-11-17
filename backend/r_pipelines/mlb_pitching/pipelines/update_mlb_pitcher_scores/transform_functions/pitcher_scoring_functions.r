
############### CALCULATE PITCHER SCORES ##########################

calculate_pitcher_scores <- function(pitcher_statcast_df, game_date = NULL) {

  # 1. Define blocks
  block_control   <- c('BB%', 'K%', 'K/9', 'BB/9', 'K-BB%', 'Chase%', 'Whiff%',
                       'Zone%', 'F-Strike%', 'CStr%', 'SwStr%', 'C+SwStr%')
  
  block_contact   <- c('GB%', 'FB%', 'LD%', 'PU%', 'GB/FB', 'HR/FB', 'IFFB%',
                       'Barrel%', 'HardHit%', 'Z-Contact%', 'O-Contact%',
                       'Contact%', 'EV', 'LA')
  
  block_prevention <- c('ERA', 'FIP', 'WHIP', 'H/9', 'HR/9', 'LOB%')
  
  block_results <- c('AVG', 'OBP', 'SLG', 'OPS', 'BABIP')
  
  block_expected  <- c('xBA', 'xwOBA', 'xSLG', 'xISO', 'xBABIP')
  
  all_stats_to_clean <- c(block_control, block_contact, block_prevention, block_results, block_expected)
  all_numeric_cols   <- c(all_stats_to_clean, 'SIERA')

  pitcher_df <- pitcher_statcast_df
  
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
    Prevention = block_prevention,
    Results = block_results,
    Expected  = block_expected
  )
  
  
  negative_stats <- c(
    'BB%', 'BB/9', 'HardHit%', 'Barrel%', 'FB%', 'LD%', 'HR/FB', 'Contact%',
    'Z-Contact%', 'EV', 'LA', 'xBA', 'xwOBA', 'xSLG', 'xISO', 'xBABIP',
    'ERA', 'FIP', 'WHIP', 'H/9', 'HR/9', 'AVG', 'OBP', 'SLG', 'OPS', 'BABIP'
  )
  
  
  final_pitcher_scores_df <- pitcher_df %>% select(xMLBAMID)
  
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
      
      stat_mean_train <- mean(training_df[[stat_name]], na.rm = TRUE)
      stat_sd_train   <- sd(training_df[[stat_name]], na.rm = TRUE)
      
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
    mutate(
      game_date = game_date,
      update_date = Sys.time()
      )
  
  return(final_pitcher_scores_df)
}

assign_pitcher_role <- function(pitcher_stats_df) {
  pitcher_stats_df <- pitcher_stats_df %>%
    mutate(
      gs_rate = if_else(total_games_pitched == 0, 0, total_games_started / total_games_pitched),
      pitcher_role = case_when(
        total_games_started >= 15 & gs_rate >= 0.60 ~ 'starter',
        total_games_started <= 2 ~ 'reliever',
        TRUE ~ 'hybrid'
      )
    )
  return(pitcher_stats_df)
}
