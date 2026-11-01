#workbook
library(tidyverse)
library(baseballr)

stats_cast_2024_df <- 1

statcast_2024_df <- read.csv("C:/Users/14088/Desktop/statcast_data/statcast_data_2024.csv")
view(cleaned_statcast_df)

# clean df - select only columns we need
cleaned_statcast_df <- statcast_2024_df %>%
  select(
    pitcher,
    p_throws,
    player_name,
    batter,
    game_date,
    game_year,
    events,
    description,
    zone,
    pitch_number,
    bb_type,
    launch_speed,
    launch_angle,
    estimated_ba_using_speedangle,
    estimated_woba_using_speedangle,
    iso_value,
    estimated_slg_using_speedangle,
    babip_value
  ) %>%
  mutate(
    pitcher = as.character(pitcher),
    batter = as.character(batter),
    launch_angle = as.numeric(launch_angle),
    iso_value = as.numeric(iso_value),
    babip_value = as.numeric(babip_value)
  )

# set events lists and zone
strike_zone <- seq(1:9)

# Define a flag for pitches that actually finish a play

swinging_strike_event_list = c('swinging_strike', 'swinging_strike_blocked')

contact_event_list = c('foul', 'foul_tip', 'hit_into_play', 'foul_pitchout')

strike_event_list = c('foul', 'foul_tip', 'hit_into_play', 'foul_pitchout',
                     'swinging_strike', 'swinging_strike_blocked', 'called_strike')

swing_event_list = c(contact_event_list, swinging_strike_event_list)

strikeout_event_list = c('strikeout', 'strikeout_double_play')

walk_event_list = c('walk', 'intent_walk')

error_event_list = c('catcher_interf', 'field_error')

field_out_event_list = c('grounded_into_double_play', 'field_out', 'force_out', 'sac_bunt',
                        'fielders_choice', 'fielders_choice_out', 'double_play', 'triple_play',
                        'sac_fly', 'sac_fly_double_play')

out_event_list = c(strikeout_event_list, field_out_event_list)

base_hit_event_list = c('single', 'double', 'triple', 'home_run')

non_ab_event_list = c('walk', 'intent_walk', 'hit_by_pitch', 'sac_bunt',
                     'sac_fly', 'sac_fly_double_play', 'catcher_interf')

sacrifice_event_list = c('sac_bunt', 'sac_fly', 'sac_fly_double_play')

fielders_choice_event_list = c('fielders_choice', 'fielders_choice_out')

pitcher_statcast_df <- cleaned_statcast_df %>%
  group_by(pitcher) %>%
  summarise(
    pitches = n(),
    # denominators
    plate_appearances = sum(!events == "", na.rm = TRUE),
    srikeouts = sum(events %in% strikeout_event_list, na.rm = TRUE),
    pitches_outside_zone = sum(!(zone %in% strike_zone), na.rm = TRUE),
    pitches_inside_zone = sum(zone %in% strike_zone, na.rm = TRUE),
    swings = sum(events %in% swing_event_list),
    
  )



view(pitcher_statcast_df %>% filter(pitcher == 621111))
statline_from_statcast(statcast_2024_df)
     