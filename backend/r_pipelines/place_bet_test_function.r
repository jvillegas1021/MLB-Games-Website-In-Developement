library(httr)
library(jsonlite)
library(tidyverse)
library(lubridate)
library(DBI)
library(RPostgres)
library(shiny)
library(magick)
library(png)
library(writexl)
library(ggimage)
library(crayon)
source('data_extract_functions/extract_data_from_database.r')
matchup_df <- get_data_from_database("historical_matchup_df")
matchup__df_filtered <- matchup_df %>%
  filter(
    Game_Date == '2026-07-12',
    (!(Home_Team_ESPN_Odds == 'Game Started' | Away_Team_ESPN_Odds == 'Game Started'))
  ) %>%
  mutate(
    Home_Team_ESPN_Odds = as.numeric(Home_Team_ESPN_Odds),
    Away_Team_ESPN_Odds = as.numeric(Away_Team_ESPN_Odds),
    
    Bet_Team = if_else(Predicted_Winner == Home_Team, "Home", "Away"),
    Favorite = if_else(Home_Team_ESPN_Odds < Away_Team_ESPN_Odds, "Home", "Away"),
    
    Betting_Edge = if_else(
      Bet_Team == "Home",
      Home_Team_Betting_Edge,
      Away_Team_Betting_Edge
    ),
    
    Bet_Team_Favorite_Underdog =
      if_else(Bet_Team == Favorite, "Favorite", "Underdog"),
    
    Place_Bet = Betting_Edge > 0
  ) %>%
  select(
    Home_Team,
    Home_Team_ESPN_Odds,
    Home_Team_Model_Odds,
    Home_Team_Betting_Edge,
    Away_Team,
    Away_Team_ESPN_Odds,
    Away_Team_Model_Odds,
    Away_Team_Betting_Edge,
    Predicted_Winner,
    Bet_Team,
    Favorite,
    Bet_Team_Favorite_Underdog,
    Betting_Edge,
    Place_Bet
  )
view(matchup__df_filtered)

view(matchup_df)
