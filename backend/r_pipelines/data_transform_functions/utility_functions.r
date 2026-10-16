add_team_abbv_using_team_name <- function(team_df) {
  team_abbv_df <- team_df %>%
    mutate(
      team_abbv = case_when(
        team_name == 'Chicago Cubs' ~ 'CHC',
        team_name == 'Los Angeles Dodgers' ~ 'LAD',
        team_name == 'Milwaukee Brewers' ~ 'MIL',
        team_name == 'Tampa Bay Rays' ~ 'TBR',
        team_name == 'Chicago White Sox' ~ 'CHW',
        team_name == 'San Diego Padres' ~ 'SDP',
        team_name == 'New York Yankees' ~ 'NYY',
        team_name == 'Houston Astros' ~ 'HOU',
        team_name == 'Miami Marlins' ~ 'MIA',
        team_name == 'Washington Nationals' ~ 'WSN',
        team_name == 'Arizona Diamondbacks' ~ 'ARI',
        team_name == 'Kansas City Royals' ~ 'KCR',
        team_name == 'Boston Red Sox' ~ 'BOS',
        team_name == 'Texas Rangers' ~ 'TEX',
        team_name == 'Baltimore Orioles' ~ 'BAL',
        team_name == 'Cleveland Guardians' ~ 'CLE',
        team_name == 'Toronto Blue Jays' ~ 'TOR',
        team_name == 'Minnesota Twins' ~ 'MIN',
        team_name == 'Detroit Tigers' ~ 'DET',
        team_name == 'Pittsburgh Pirates' ~ 'PIT',
        team_name == 'Atlanta Braves' ~ 'ATL',
        team_name == 'Seattle Mariners' ~ 'SEA',
        team_name == 'St. Louis Cardinals' ~ 'STL',
        team_name == 'New York Mets' ~ 'NYM',
        team_name == 'San Francisco Giants' ~ 'SFG',
        team_name == 'Philadelphia Phillies' ~ 'PHI',
        team_name == 'Athletics' ~ 'ATH',
        team_name == 'Cincinnati Reds' ~ 'CIN',
        team_name == 'Los Angeles Angels' ~ 'LAA',
        team_name == 'Colorado Rockies' ~ 'COL',
      )
    )
  return(team_abbv_df)
}