create_team_batting_df <- function(team_name,
                                   team_id,
                                   team_abbv,
                                   game_date,
                                   mlb_batting_roster_gameday_df,
                                   batter_stats_statcast_df) {
  
  lineup_ids <- mlb_batting_roster_gameday_df %>%
    filter(roster_date == game_date,
           team_id == !!team_id) %>%
    pull(roster_lineup_ids)
  
  
  split_up_linup_ids <- str_split(lineup_ids, ",") %>% unlist()
  
  filtered_batter_statcast <- batter_stats_statcast_df %>%
    filter(xMLBAMID %in% split_up_linup_ids)
  
  if (nrow(filtered_batter_statcast) == 0 || length(filtered_batter_statcast) == 0){
    return(tibble())
  }
  
  wBB <- 0.698
  wHBP <- 0.729
  w1B <- 0.890
  w2B <- 1.261
  w3B <- 1.596
  wHR <- 2.049
  
  league_woba <- 0.316
  wOBAScale <- 1.238
  R_PA_lg <- 0.118
  
  # create team df
  team_batting_df <- data.frame(team_name = team_name,
                                team_id = team_id,
                                team_abbv = team_abbv,
                                game_date = game_date)
  
  batter_stats_summarized <- filtered_batter_statcast %>%
    summarise(
      # --- Intermediate Sums needed for calculations ---
      # (These will automatically be dropped at the end, leaving only your rates)
      pa  = as.numeric(sum(plate_appearances, na.rm = TRUE)),
      so  = as.numeric(sum(strikeouts, na.rm = TRUE)),
      bb  = as.numeric(sum(walks, na.rm = TRUE)),
      hbp = as.numeric(sum(hit_by_pitches, na.rm = TRUE)),
      h   = as.numeric(sum(hits, na.rm = TRUE)),
      b1  = as.numeric(sum(singles, na.rm = TRUE)),
      b2  = as.numeric(sum(doubles, na.rm = TRUE)),
      b3  = as.numeric(sum(triples, na.rm = TRUE)),
      hr  = as.numeric(sum(home_runs, na.rm = TRUE)),
      sf  = as.numeric(sum(sac_flies, na.rm = TRUE)),
      
      gb  = as.numeric(sum(GB, na.rm = TRUE)),
      fb  = as.numeric(sum(FB, na.rm = TRUE)),
      ld  = as.numeric(sum(LD, na.rm = TRUE)),
      pu  = as.numeric(sum(PU, na.rm = TRUE)),
      
      # --- Calculations ---
      `K%` = so / pa,
      `BB%` = bb / pa,
      `BB/K` = bb / so,
      
      `GB%` = gb / (gb + fb + ld),
      `FB%` = fb / (gb + fb + ld),
      `LD%` = ld / (gb + fb + ld),
      `HR/FB` = hr / fb,
      `GB/FB` = gb / fb,
      `IFFB%` = pu / fb,
      
      at_bats = pa - sum(non_at_bats, na.rm = TRUE), 
      AVG = h / at_bats,
      SLG = ((b1 * 1) + (b2 * 2) + (b3 * 3) + (hr * 4)) / at_bats,
      ISO = SLG - AVG,
      
      BABIP = (h - hr) / (at_bats - so - hr + sf),
      OBP = (h + bb + hbp) / (at_bats + bb + hbp + sf),
      OPS = OBP + SLG,
      
      # Statcast averages
      EV = sum(launch_speed_sum, na.rm = TRUE) / sum(batted_balls, na.rm = TRUE),
      LA = sum(launch_angle_sum, na.rm = TRUE) / sum(batted_balls, na.rm = TRUE),
      xBA = sum(ba_speedangle_sum, na.rm = TRUE) / sum(batted_balls, na.rm = TRUE),
      xWOBA = sum(woba_speedangle_sum, na.rm = TRUE) / sum(batted_balls, na.rm = TRUE),
      xSLG = sum(slg_speedangle_sum, na.rm = TRUE) / sum(batted_balls, na.rm = TRUE),
      xISO = sum(iso_value_sum, na.rm = TRUE) / sum(batted_balls, na.rm = TRUE),
      xBABIP = sum(babip_value_sum, na.rm = TRUE) / sum(batted_balls, na.rm = TRUE),
      
      `HardHit%` = sum(hard_hit_balls, na.rm = TRUE) / sum(batted_balls, na.rm = TRUE),
      `Barrel%` = sum(barrel_balls, na.rm = TRUE) / sum(batted_balls, na.rm = TRUE),
      
      # Plate Discipline
      `Z-Swing%` = sum(swings_in_zone, na.rm = TRUE) / sum(pitches_in_zone, na.rm = TRUE),
      `Z-Contact%` = sum(contacted_balls_in_zone, na.rm = TRUE) / sum(swings_in_zone, na.rm = TRUE),
      `Contact%` = sum(contacted_balls, na.rm = TRUE) / sum(swings, na.rm = TRUE),
      `O-Contact%` = sum(contacted_balls_outside_zone, na.rm = TRUE) / sum(swings_outside_zone, na.rm = TRUE),
      `O-Swing%` = sum(swings_outside_zone, na.rm = TRUE) / sum(pitches_outside_zone, na.rm = TRUE),
      `Chase%` = sum(swings_outside_zone, na.rm = TRUE) / sum(pitches_outside_zone, na.rm = TRUE), 
      `Whiff%` = sum(whiffs, na.rm = TRUE) / sum(swings, na.rm = TRUE),
      `SwStr%` = sum(whiffs, na.rm = TRUE) / sum(pitches, na.rm = TRUE),
      `F-Strike%` = sum(first_pitch_strikes, na.rm = TRUE) / pa, 
      
      # Advanced Linear Weights
      woba_num = (wBB * bb) + (wHBP * hbp) + (w1B * b1) + (w2B * b2) + (w3B * b3) + (wHR * hr),
      wOBA = if_else(pa == 0, 0, woba_num / pa),
      wRAA = if_else(pa == 0, 0, ((wOBA - league_woba) / wOBAScale) * pa),
      wRC = wRAA + (R_PA_lg * pa),
      `wRC+` = if_else(pa == 0, 0, 100 * (((wRAA / pa) / R_PA_lg) + 1))
    ) %>%
    select(
      'K%', 'BB%', 'BB/K', 'O-Swing%', 'Z-Swing%', 'Chase%', 'Whiff%',
      'GB%', 'FB%', 'LD%', 'GB/FB', 'HR/FB', 'IFFB%', 'Barrel%', 'HardHit%',
      'Z-Contact%', 'O-Contact%', 'Contact%', 'EV', 'LA',
      'ISO', 'OPS', 'BABIP', 'AVG', 'OBP', 'SLG', 'wOBA', 'wRAA', 'wRC', 'wRC+',
      'xWOBA', 'xBA', 'xSLG', 'xISO', 'xBABIP'
    ) %>%
    mutate(
      batter_ids = lineup_ids,
      update_date = Sys.time()
    )
  
  final_team_batting_df <- bind_cols(team_batting_df, batter_stats_summarized)
  
  return(final_team_batting_df)
  
}

create_mlb_teams_batting_df <- function(game_day = as.Date(format(Sys.time(), tz = "America/New_York")),
                                        mlb_roster_df,
                                        batter_statcast_df,
                                        mlb_teams) {
  current_date <- game_day
  
  batting_df_list <- c()
  
  for (team in 1:nrow(mlb_teams)) {
    mlb_team_id <- as.character(mlb_teams[team, 2])
    mlb_team_name <- mlb_teams[team, 3]
    mlb_team_abbv <- mlb_teams[team, 8]
    
    mlb_team_batting_df <- create_team_batting_df(
      team_name = mlb_team_name,
      team_id = mlb_team_id,
      team_abbv = mlb_team_abbv,
      game_date = current_date,
      mlb_batting_roster_gameday_df = mlb_batting_roster_gameday_df,
      batter_stats_statcast_df = batter_stats_statcast_df
    )
    
    batting_df_list[[length(batting_df_list) + 1]] <- mlb_team_batting_df
  }
  
  final_mlb_teams_batting_df <- bind_rows(batting_df_list)
  
  return(final_mlb_teams_batting_df)
}