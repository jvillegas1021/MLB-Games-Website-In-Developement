import pandas as pd
from datetime import datetime
import pytz
import numpy as np

def add_generic_flags(statcast_df: pd.DataFrame) -> pd.DataFrame:
    
    flagged_statcast_df = statcast_df.copy()
    
    strike_zone = [1,2,3,4,5,6,7,8,9]
    
    all_events_list =   flagged_statcast_df['events'].unique()
    all_descriptions_list = flagged_statcast_df['description'].unique()

    swinging_strike_event_list = ['swinging_strike', 'swinging_strike_blocked']

    contact_event_list = ['foul', 'foul_tip', 'hit_into_play', 'foul_pitchout']

    strike_event_list = ['foul', 'foul_tip', 'hit_into_play', 'foul_pitchout',
                         'swinging_strike', 'swinging_strike_blocked', 'called_strike']

    swing_event_list = contact_event_list + swinging_strike_event_list

    strikeout_event_list = ['strikeout', 'strikeout_double_play']

    walk_event_list = ['walk', 'intent_walk']

    error_event_list = ['catcher_interf', 'field_error']

    field_out_event_list = ['grounded_into_double_play', 'field_out', 'force_out', 'sac_bunt',
                      'fielders_choice', 'fielders_choice_out', 'double_play', 'triple_play',
                      'sac_fly', 'sac_fly_double_play']

    out_event_list = strikeout_event_list + field_out_event_list

    base_hit_event_list = ['single', 'double', 'triple', 'home_run']

    non_ab_event_list = ['walk', 'intent_walk', 'hit_by_pitch', 'sac_bunt',
                         'sac_fly', 'sac_fly_double_play', 'catcher_interf']
    
    sacrifice_event_list = ['sac_bunt', 'sac_fly', 'sac_fly_double_play']

    fielders_choice_event_list = ['fielders_choice', 'fielders_choice_out']

    # STANDARD FLAGS
    for event in all_events_list:
        flagged_statcast_df[f'is_{event}'] = flagged_statcast_df['events'] == event

    for description in all_descriptions_list:
        flagged_statcast_df[f'is_{description}'] = flagged_statcast_df['description'] == description
    

    # CUSTOM FLAGS
    
    flagged_statcast_df['is_rhp'] = flagged_statcast_df['p_throws'] == 'R'
    flagged_statcast_df['is_lhp'] = flagged_statcast_df['p_throws'] == 'L'
    flagged_statcast_df['is_rhb'] = flagged_statcast_df['stand'] == 'R'
    flagged_statcast_df['is_lhb'] = flagged_statcast_df['stand'] == 'L'
    flagged_statcast_df['is_in_zone'] = flagged_statcast_df['zone'].isin(strike_zone)
    flagged_statcast_df['is_outside_zone'] = ~flagged_statcast_df['is_in_zone']
    flagged_statcast_df['is_swing'] = flagged_statcast_df['description'].isin(swing_event_list)
    flagged_statcast_df['is_swing_in_zone'] = (flagged_statcast_df['is_in_zone'] & flagged_statcast_df['is_swing'])
    flagged_statcast_df['is_swing_outside_zone'] = (flagged_statcast_df['is_outside_zone'] & flagged_statcast_df['is_swing'])
    flagged_statcast_df['is_contact'] = flagged_statcast_df['description'].isin(contact_event_list)
    flagged_statcast_df['is_contact_in_zone'] = (flagged_statcast_df['is_in_zone'] & flagged_statcast_df['is_contact'])
    flagged_statcast_df['is_contact_outside_zone'] = (flagged_statcast_df['is_outside_zone'] & flagged_statcast_df['is_contact'])
    flagged_statcast_df['is_whiff'] = flagged_statcast_df['description'].isin(swinging_strike_event_list)
    flagged_statcast_df['is_whiff_in_zone'] = (flagged_statcast_df['is_in_zone'] & flagged_statcast_df['is_whiff'])
    flagged_statcast_df['is_whiff_outside_zone'] = (flagged_statcast_df['is_outside_zone'] & flagged_statcast_df['is_whiff'])
    flagged_statcast_df['is_first_pitch'] = flagged_statcast_df['pitch_number'] == 1
    flagged_statcast_df['is_first_pitch_strike'] = flagged_statcast_df['is_first_pitch'] & flagged_statcast_df['description'].isin(strike_event_list)
    flagged_statcast_df['is_sacrifice'] = flagged_statcast_df['events'].isin(sacrifice_event_list)
    flagged_statcast_df['is_error'] = flagged_statcast_df['events'].isin(error_event_list)
    flagged_statcast_df['is_fielders_choice'] = flagged_statcast_df['events'].isin(fielders_choice_event_list)
    flagged_statcast_df['is_out'] = flagged_statcast_df['events'].isin(out_event_list)
    flagged_statcast_df['is_strikeout_event'] = flagged_statcast_df['events'].isin(strikeout_event_list)
    flagged_statcast_df['is_field_out_event'] = flagged_statcast_df['events'].isin(field_out_event_list)

    # stat flags
    flagged_statcast_df['is_pa'] = flagged_statcast_df['events'].notna()
    flagged_statcast_df['is_not_ab'] = flagged_statcast_df['events'].isin(non_ab_event_list)
    flagged_statcast_df['is_ab'] = flagged_statcast_df['is_pa'] & ~flagged_statcast_df['is_not_ab']
    flagged_statcast_df['is_hit'] = flagged_statcast_df['events'].isin(base_hit_event_list)

    flagged_statcast_df['is_batted_ball'] = flagged_statcast_df['bb_type'].notna()
    flagged_statcast_df['is_line_drive'] = flagged_statcast_df['bb_type'].eq('line_drive')
    flagged_statcast_df['is_ground_ball'] = flagged_statcast_df['bb_type'].eq('ground_ball')
    flagged_statcast_df['is_fly_ball'] = flagged_statcast_df['bb_type'].eq('fly_ball')
    flagged_statcast_df['is_popup'] = flagged_statcast_df['bb_type'].eq('popup')
    flagged_statcast_df['is_hard_hit_ball'] = flagged_statcast_df['launch_speed'] >= 95
    
    flagged_statcast_df["launch_speed_bip"] = flagged_statcast_df["launch_speed"].where(
        flagged_statcast_df["bb_type"].notna()
        )

    flagged_statcast_df["launch_angle_bip"] = flagged_statcast_df["launch_angle"].where(
        flagged_statcast_df["bb_type"].notna()
        )

    flagged_statcast_df['estimated_ba_using_speedangle_bip'] = flagged_statcast_df['estimated_ba_using_speedangle'].where(
        flagged_statcast_df['bb_type'].notna()
    )

    flagged_statcast_df['estimated_woba_using_speedangle_bip'] = flagged_statcast_df['estimated_woba_using_speedangle'].where(
        flagged_statcast_df['bb_type'].notna()
    )

    flagged_statcast_df['babip_value_bip'] = flagged_statcast_df['babip_value'].where(
        flagged_statcast_df['bb_type'].notna()
    )

    flagged_statcast_df['iso_value_bip'] = flagged_statcast_df['iso_value'].where(
        flagged_statcast_df['bb_type'].notna()
    )

    flagged_statcast_df['estimated_slg_using_speedangle_bip'] = flagged_statcast_df['estimated_slg_using_speedangle'].where(
        flagged_statcast_df['bb_type'].notna()
    )

    ev = flagged_statcast_df["launch_speed_bip"]
    la = flagged_statcast_df["launch_angle_bip"]

    min_la = (26 - (ev - 98)).clip(lower=8)
    max_la = (30 + (ev - 98)).clip(upper=50)

    flagged_statcast_df["is_barrel_ball"] = (
        (ev >= 98) &
        (la >= min_la) &
        (la <= max_la)
    )

    


    return(flagged_statcast_df)


def add_pitch_level_flags(statcast_df: pd.DataFrame) -> pd.DataFrame:
    
    flagged_statcast_df = statcast_df.copy()
    pitch_types = [
        "2_Seam_Fastball",
        "4_Seam_Fastball",
        "Changeup",
        "Curveball",
        "Cutter",
        "Eephus",
        "Forkball",
        "Knuckle_Curve",
        "Knuckleball",
        "Other",
        "Pitch_Out",
        "Screwball",
        "Sinker",
        "Slider",
        "Slow_Curve",
        "Slurve",
        "Split_Finger",
        "Sweeper",
        "Unknown"
    ]

    pitch_type_columns = {}

    for pitch in pitch_types:
        # Base flags
        pitch_flag = flagged_statcast_df['pitch_names_cleaned'] == pitch
        pitch_type_columns[f'is_{pitch}'] = pitch_flag

        # Stat flags
        pitch_type_columns[f'is_{pitch}_hit'] = pitch_flag & flagged_statcast_df['is_hit']
        pitch_type_columns[f'is_{pitch}_single'] = pitch_flag & flagged_statcast_df['is_single']
        pitch_type_columns[f'is_{pitch}_double'] = pitch_flag & flagged_statcast_df['is_double']
        pitch_type_columns[f'is_{pitch}_triple'] = pitch_flag & flagged_statcast_df['is_triple']
        pitch_type_columns[f'is_{pitch}_home_run'] = pitch_flag & flagged_statcast_df['is_home_run']
        
        pitch_type_columns[f'is_{pitch}_walk'] = pitch_flag & flagged_statcast_df['is_walk']
        pitch_type_columns[f'is_{pitch}_strikeout'] = pitch_flag & flagged_statcast_df['is_strikeout']
        pitch_type_columns[f'is_{pitch}_out'] = pitch_flag & flagged_statcast_df['is_field_out']
        
        pitch_type_columns[f'is_{pitch}_ab'] = pitch_flag & flagged_statcast_df['is_ab']
        pitch_type_columns[f'is_{pitch}_pa'] = pitch_flag & flagged_statcast_df['is_pa']

        # Batted Balls
        pitch_type_columns[f'is_{pitch}_bip'] = pitch_flag & flagged_statcast_df['is_batted_ball']
        pitch_type_columns[f'is_{pitch}_barrel'] = pitch_flag & flagged_statcast_df['is_barrel_ball']
        pitch_type_columns[f'is_{pitch}_hit_into_play'] = pitch_flag & flagged_statcast_df['is_hit_into_play']
        pitch_type_columns[f'is_{pitch}_ground_ball'] = pitch_flag & flagged_statcast_df['is_ground_ball']
        pitch_type_columns[f'is_{pitch}_fly_ball'] = pitch_flag & flagged_statcast_df['is_fly_ball']
        pitch_type_columns[f'is_{pitch}_line_drive'] = pitch_flag & flagged_statcast_df['is_line_drive']
        pitch_type_columns[f'is_{pitch}_popup'] = pitch_flag & flagged_statcast_df['is_popup']

        # xStats
        pitch_type_columns[f'{pitch}_xba'] = flagged_statcast_df['estimated_ba_using_speedangle_bip'] * pitch_flag
        pitch_type_columns[f'{pitch}_xslg'] = flagged_statcast_df['estimated_slg_using_speedangle_bip'] * pitch_flag
        pitch_type_columns[f'{pitch}_xiso'] = flagged_statcast_df['iso_value_bip'] * pitch_flag
        pitch_type_columns[f'{pitch}_xbabip'] = flagged_statcast_df['babip_value_bip'] * pitch_flag
        pitch_type_columns[f'{pitch}_xwoba'] = flagged_statcast_df['estimated_woba_using_speedangle_bip'] * pitch_flag

        # Zone flags
        pitch_type_columns[f'is_{pitch}_in_zone'] = pitch_flag & flagged_statcast_df['is_in_zone']
        pitch_type_columns[f'is_{pitch}_outside_zone'] = pitch_flag & flagged_statcast_df['is_outside_zone']

        # Swing flags
        pitch_type_columns[f'is_{pitch}_swing'] = pitch_flag & flagged_statcast_df['is_swing']
        pitch_type_columns[f'is_{pitch}_swing_in_zone'] = pitch_flag & flagged_statcast_df['is_swing_in_zone']
        pitch_type_columns[f'is_{pitch}_swing_outside_zone'] = pitch_flag & flagged_statcast_df['is_swing_outside_zone']

        # Contact flags
        pitch_type_columns[f'is_{pitch}_contact'] = pitch_flag & flagged_statcast_df['is_contact']
        pitch_type_columns[f'is_{pitch}_contact_in_zone'] = pitch_flag & flagged_statcast_df['is_contact_in_zone']
        pitch_type_columns[f'is_{pitch}_contact_outside_zone'] = pitch_flag & flagged_statcast_df['is_contact_outside_zone']

        # Whiff flags
        pitch_type_columns[f'is_{pitch}_whiff'] = pitch_flag & flagged_statcast_df['is_whiff']
        pitch_type_columns[f'is_{pitch}_whiff_in_zone'] = pitch_flag & flagged_statcast_df['is_whiff_in_zone']
        pitch_type_columns[f'is_{pitch}_whiff_outside_zone'] = pitch_flag & flagged_statcast_df['is_whiff_outside_zone']

    flagged_statcast_df = pd.concat(
        [flagged_statcast_df, pd.DataFrame(pitch_type_columns)],
        axis=1
    )

    return(flagged_statcast_df)


def create_count_flags(statcast_df: pd.DataFrame) -> pd.DataFrame:

    flagged_statcast_df = add_generic_flags(statcast_df)

    flagged_statcast_df = add_pitch_level_flags(flagged_statcast_df)
   

    return (flagged_statcast_df)

