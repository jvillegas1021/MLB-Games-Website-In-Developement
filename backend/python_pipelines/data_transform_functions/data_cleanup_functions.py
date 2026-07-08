import pandas as pd

def remove_empty_pitch_types(statcast_df: pd.DataFrame) -> pd.DataFrame:

    statcast_df = statcast_df.dropna(subset=['pitch_type'])

    return statcast_df

def remove_excess_columns(statcast_df: pd.DataFrame) -> pd.DataFrame:

    columns_to_keep = ['pitch_type', 'pitch_name', 'game_year', 'batter', 'pitcher', 'events', 'game_pk', 'at_bat_number',
                       'description', 'pitch_number', 'zone', 'stand', 'p_throws', 'type', 'bb_type', 'launch_speed',
                       'launch_angle', 'effective_speed', 'hit_distance_sc', 'estimated_ba_using_speedangle',
                       'estimated_woba_using_speedangle', 'woba_value', 'woba_denom', 'babip_value', 'iso_value',
                       'launch_speed_angle', 'estimated_slg_using_speedangle'
                       ]
    final_statcast_df = statcast_df[columns_to_keep]

    return final_statcast_df


def change_pitch_names(statcast_df: pd.DataFrame) -> pd.DataFrame:

    cleaned_statcast_df = statcast_df.copy()

    cleaned_statcast_df['pitch_names_cleaned'] = (
        cleaned_statcast_df['pitch_name']
        .str.replace(' ', '_', regex=False)
        .str.replace('-', '_', regex=False)
    )

    return cleaned_statcast_df

def remove_two_pitcher_at_bats(statcast_df: pd.DataFrame) -> pd.DataFrame:
    # 1. Identify ABs with >1 pitcher
    bad_abs = (
    statcast_df
    .groupby(['batter', 'game_pk', 'at_bat_number'])['p_throws']
    .nunique()
    .reset_index(name='p_hand_count')
    .query("p_hand_count > 1")
    [['batter', 'game_pk', 'at_bat_number']]
    )
    
    # 2. Remove those ABs from the main DF
    cleaned_statcast_df = statcast_df.merge(
        bad_abs,
        on=['batter', 'game_pk', 'at_bat_number'],
        how='left',
        indicator=True
    ).query("_merge == 'left_only'").drop(columns="_merge")


    return (cleaned_statcast_df)