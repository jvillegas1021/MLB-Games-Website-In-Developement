import pandas as pd
from datetime import datetime
import pytz
import numpy as np


from data_transform_functions.utility_functions import safe_div, safe_div_series, convert_ip

def process_starting_pitcher_stats(pitcher_statsapi_df, pitcher_statcast_df):

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

    pitcher_statsapi_df = pitcher_statsapi_df.drop(columns=['hits', 'outs', 'doubles', 'triples'])

    combined_pitcher_df = pd.merge(pitcher_statsapi_df,
                                   pitcher_statcast_df,
                                   how='left',
                                   on=['xMLBAMID', 'season']
                                  )
    
    combined_pitcher_df['inningsPitched'] = convert_ip(combined_pitcher_df['inningsPitched'])
    
    # Extract identity columns BEFORE grouping
    identity_cols = combined_pitcher_df[["xMLBAMID", "player_name", "Throws"]].drop_duplicates("xMLBAMID")
    
    # Group numeric stats
    pitcher_data_sums = (
        combined_pitcher_df
        .groupby("xMLBAMID")
        .sum(numeric_only=True)
        .reset_index()
    )
    
    # Merge identity back
    pitcher_data_sums = pitcher_data_sums.merge(identity_cols, on="xMLBAMID", how="left")
    
    
    league_xwoba = 0.3162979120429958
        
    league_era = 4.15
    
    fip_constant = 3.1495185210234546

    pitch_usage_dict = {}

    for pitch in pitch_types:
        pitch_usage_dict[f'{pitch}_usage%'] = safe_div_series(
            pitcher_data_sums[f'{pitch}_pitches'],
            pitcher_data_sums['pitches']).round(2)

    pitcher_data_sums['inningsPitched'] = convert_ip(pitcher_data_sums['inningsPitched'])

    pitcher_data_sums['BF_per_start'] = np.where(
        pitcher_data_sums['gamesStarted'] == 0,
        0,
        pitcher_data_sums['battersFaced'] / pitcher_data_sums['gamesStarted']
    )

    pitcher_data_sums["IP_per_start"] = np.where(
        pitcher_data_sums["gamesStarted"] == 0,
        0,
        pitcher_data_sums["inningsPitched"] / pitcher_data_sums["gamesStarted"]
    )

    pitcher_data_sums["ERA"] = safe_div_series(
        pitcher_data_sums["earnedRuns"], pitcher_data_sums["inningsPitched"]
    ) * 9

    pitcher_data_sums['WHIP'] = safe_div_series((
            pitcher_data_sums['walks'] + pitcher_data_sums['hits']
    ), pitcher_data_sums["inningsPitched"])

    pitcher_data_sums['FIP'] = (
                                                (13 * pitcher_data_sums['home_runs']) +
                                                (3 * pitcher_data_sums['walks']) -
                                                (2 * pitcher_data_sums['strikeouts'])
                                        ) / pitcher_data_sums["inningsPitched"] + fip_constant

    pitcher_data_sums["LOB%"] = safe_div_series(
        (pitcher_data_sums["hits"] +
         pitcher_data_sums["baseOnBalls"] +
         pitcher_data_sums["hitByPitch"] -
         pitcher_data_sums["runs"])
        ,
        (pitcher_data_sums["hits"] +
         pitcher_data_sums["baseOnBalls"] +
         pitcher_data_sums["hitByPitch"] -
         1.4 * pitcher_data_sums["homeRuns"])
    )

    pitcher_data_sums["DP%"] = safe_div_series(
        pitcher_data_sums["groundIntoDoublePlay"],
        (pitcher_data_sums["battersFaced"]
         - pitcher_data_sums["strikeOuts"]
         - pitcher_data_sums["baseOnBalls"]
         - pitcher_data_sums["hitByPitch"])
    )

    pitcher_data_sums["RS/9"] = safe_div_series(
        pitcher_data_sums["runs"], pitcher_data_sums["inningsPitched"]
    ) * 9

    pitcher_data_sums["GO/AO"] = safe_div_series(
        pitcher_data_sums["groundOuts"], pitcher_data_sums["airOuts"]
    )

    pitcher_data_sums["H/9"] = safe_div_series(
        pitcher_data_sums["hits"], pitcher_data_sums["inningsPitched"]
    ) * 9

    pitcher_data_sums["BB/9"] = safe_div_series(
        pitcher_data_sums["baseOnBalls"], pitcher_data_sums["inningsPitched"]
    ) * 9

    pitcher_data_sums["HR/9"] = safe_div_series(
        pitcher_data_sums["homeRuns"], pitcher_data_sums["inningsPitched"]
    ) * 9

    pitcher_data_sums["K/9"] = safe_div_series(
        pitcher_data_sums["strikeOuts"], pitcher_data_sums["inningsPitched"]
    ) * 9

    pitcher_data_sums["TTO%"] = safe_div_series((pitcher_data_sums['home_runs'] + pitcher_data_sums[
        'walks'] + pitcher_data_sums['strikeouts']), (
                                                            pitcher_data_sums['plate_appearances'] -
                                                            pitcher_data_sums['non_at_bats']))


    batter_hand_list = ['general', 'RHB_', 'LHB_']

    for hand in batter_hand_list:
        prefix = '' if hand == 'general' else hand

        pitcher_data_sums[f'{prefix}at_bats'] = (pitcher_data_sums[f'{prefix}plate_appearances'] - pitcher_data_sums[f'{prefix}non_at_bats'])
        
        pitcher_data_sums[f'{prefix}AVG'] = safe_div_series(pitcher_data_sums[f'{prefix}hits'] , pitcher_data_sums[f'{prefix}at_bats'])

        pitcher_data_sums[f'{prefix}total_bases'] = (
            pitcher_data_sums[f'{prefix}singles'] * 1 +
            pitcher_data_sums[f'{prefix}doubles'] * 2 +
            pitcher_data_sums[f'{prefix}triples'] * 3 +
            pitcher_data_sums[f'{prefix}home_runs'] * 4
        )

        pitcher_data_sums[f'{prefix}SLG'] = safe_div_series(pitcher_data_sums[f'{prefix}total_bases'], pitcher_data_sums[f'{prefix}at_bats'])

        pitcher_data_sums[f'{prefix}ISO'] = pitcher_data_sums[f'{prefix}SLG'] - pitcher_data_sums[f'{prefix}AVG']

        pitcher_data_sums[f'{prefix}BABIP'] = safe_div_series(
            (
                pitcher_data_sums[f'{prefix}hits'] -
                pitcher_data_sums[f'{prefix}home_runs']
            ),
            (
                pitcher_data_sums[f'{prefix}at_bats'] -
                pitcher_data_sums[f'{prefix}strikeouts'] -
                pitcher_data_sums[f'{prefix}home_runs'] +
                pitcher_data_sums[f'{prefix}sac_flies'] +
                pitcher_data_sums[f'{prefix}sac_fly_double_plays']
            ))
    
        pitcher_data_sums[f'{prefix}OBP'] = safe_div_series(
            (
                pitcher_data_sums[f'{prefix}hits'] +
                pitcher_data_sums[f'{prefix}walks'] +
                pitcher_data_sums[f'{prefix}hit_by_pitches']
            ),
            (
                pitcher_data_sums[f'{prefix}at_bats'] +
                pitcher_data_sums[f'{prefix}walks'] +
                pitcher_data_sums[f'{prefix}hit_by_pitches'] +
                pitcher_data_sums[f'{prefix}sacrifices']
            ))

        pitcher_data_sums[f'{prefix}OPS'] = pitcher_data_sums[f'{prefix}OBP'] + pitcher_data_sums[f'{prefix}SLG']
        
        pitcher_data_sums[f'{prefix}EV'] = safe_div_series(pitcher_data_sums[f'{prefix}launch_speed_sum'] , pitcher_data_sums[f'{prefix}batted_balls'])
        pitcher_data_sums[f'{prefix}LA'] = safe_div_series(pitcher_data_sums[f'{prefix}launch_angle_sum'] , pitcher_data_sums[f'{prefix}batted_balls'])
        pitcher_data_sums[f'{prefix}HardHit%'] = safe_div_series(pitcher_data_sums[f'{prefix}hard_hit_balls'] , pitcher_data_sums[f'{prefix}batted_balls'])
        pitcher_data_sums[f'{prefix}Barrel%'] = safe_div_series(pitcher_data_sums[f'{prefix}barrel_balls'] , pitcher_data_sums[f'{prefix}batted_balls'])

        # --- Batted-ball profile ---
        pitcher_data_sums[f'{prefix}GB%'] = safe_div_series(pitcher_data_sums[f'{prefix}GB'] , pitcher_data_sums[f'{prefix}batted_balls'])
        pitcher_data_sums[f'{prefix}FB%'] = safe_div_series(pitcher_data_sums[f'{prefix}FB'] , pitcher_data_sums[f'{prefix}batted_balls'])
        pitcher_data_sums[f'{prefix}LD%'] = safe_div_series(pitcher_data_sums[f'{prefix}LD'] , pitcher_data_sums[f'{prefix}batted_balls'])
        pitcher_data_sums[f'{prefix}IFFB%'] = safe_div_series(pitcher_data_sums[f'{prefix}PU'] , pitcher_data_sums[f'{prefix}FB'])
        pitcher_data_sums[f'{prefix}HR/FB'] = safe_div_series(pitcher_data_sums[f'{prefix}home_runs'] , pitcher_data_sums[f'{prefix}FB'])
        pitcher_data_sums[f'{prefix}GB/FB'] = safe_div_series(pitcher_data_sums[f'{prefix}GB'] , pitcher_data_sums[f'{prefix}FB'])

        # --- Plate discipline ---
        pitcher_data_sums[f'{prefix}Zone%'] = safe_div_series(pitcher_data_sums[f'{prefix}pitches_in_zone'] , pitcher_data_sums[f'{prefix}pitches'])
        pitcher_data_sums[f'{prefix}Z-Swing%'] = safe_div_series(pitcher_data_sums[f'{prefix}swings_in_zone'] , pitcher_data_sums[f'{prefix}pitches_in_zone'])
        pitcher_data_sums[f'{prefix}O-Swing%'] = safe_div_series(pitcher_data_sums[f'{prefix}swings_outside_zone'] , pitcher_data_sums[f'{prefix}pitches_outside_zone'])

        pitcher_data_sums[f'{prefix}Contact%'] = safe_div_series(pitcher_data_sums[f'{prefix}contacted_balls'] , pitcher_data_sums[f'{prefix}swings'])
        pitcher_data_sums[f'{prefix}Z-Contact%'] = safe_div_series(pitcher_data_sums[f'{prefix}contacted_balls_in_zone'] , pitcher_data_sums[f'{prefix}swings_in_zone'])
        pitcher_data_sums[f'{prefix}O-Contact%'] = safe_div_series(pitcher_data_sums[f'{prefix}contacted_balls_outside_zone'] , pitcher_data_sums[f'{prefix}swings_outside_zone'])

        pitcher_data_sums[f'{prefix}Swing%'] = safe_div_series(pitcher_data_sums[f'{prefix}swings'] , pitcher_data_sums[f'{prefix}pitches'])
        pitcher_data_sums[f'{prefix}SwStr%'] = safe_div_series(pitcher_data_sums[f'{prefix}whiffs'] , pitcher_data_sums[f'{prefix}pitches'])
        pitcher_data_sums[f'{prefix}CStr%'] = safe_div_series(pitcher_data_sums[f'{prefix}called_strikes'] , pitcher_data_sums[f'{prefix}pitches'])
        pitcher_data_sums[f'{prefix}C+SwStr%'] = safe_div_series((pitcher_data_sums[f'{prefix}called_strikes'] + pitcher_data_sums[f'{prefix}whiffs']) , pitcher_data_sums[f'{prefix}pitches'])

        pitcher_data_sums[f'{prefix}F-Strike%'] = safe_div_series(pitcher_data_sums[f'{prefix}first_pitch_strikes'] , pitcher_data_sums[f'{prefix}first_pitches'])

        # --- K,BB family ---
        pitcher_data_sums[f'{prefix}K%'] = safe_div_series(pitcher_data_sums[f'{prefix}strikeouts'] , pitcher_data_sums[f'{prefix}plate_appearances'])
        pitcher_data_sums[f'{prefix}BB%'] = safe_div_series(pitcher_data_sums[f'{prefix}walks'] , pitcher_data_sums[f'{prefix}plate_appearances'])
        pitcher_data_sums[f'{prefix}K/BB'] = safe_div_series(pitcher_data_sums[f'{prefix}strikeouts'] , pitcher_data_sums[f'{prefix}walks'])
        pitcher_data_sums[f'{prefix}K-BB%'] = pitcher_data_sums[f'{prefix}K%'] - pitcher_data_sums[f'{prefix}BB%']

        pitcher_data_sums[f'{prefix}xBA'] = safe_div_series(pitcher_data_sums[f'{prefix}ba_speedangle_sum'] , pitcher_data_sums[f'{prefix}batted_balls'])
        pitcher_data_sums[f'{prefix}xWOBA'] = safe_div_series(pitcher_data_sums[f'{prefix}woba_speedangle_sum'] , pitcher_data_sums[f'{prefix}batted_balls'])
        pitcher_data_sums[f'{prefix}xSLG'] = safe_div_series(pitcher_data_sums[f'{prefix}slg_speedangle_sum'] , pitcher_data_sums[f'{prefix}batted_balls'])
        pitcher_data_sums[f'{prefix}xISO'] = safe_div_series(pitcher_data_sums[f'{prefix}iso_value_sum'] , pitcher_data_sums[f'{prefix}batted_balls'])
        pitcher_data_sums[f'{prefix}xBABIP'] = safe_div_series(pitcher_data_sums[f'{prefix}babip_value_sum'] , pitcher_data_sums[f'{prefix}batted_balls'])

        # You supply league_xwOBA and league_ERA from your 2025 benchmark
        pitcher_data_sums[f'{prefix}xERA'] = league_era + (pitcher_data_sums[f'{prefix}xWOBA'] - league_xwoba) * 1.15 * 9

    pitcher_data_sums = pitcher_data_sums.rename(columns={
        "gamesStarted": "GS",
        "inningsPitched": "IP",
        "battersFaced": "BF",
        "wins": "Wins",
        "losses": "Losses"
    })

    for stat, value in pitch_usage_dict.items():
        pitcher_data_sums[stat] = value

    pitcher_data_sums['update_date'] = datetime.now(pytz.timezone("America/New_York"))
    
    columns_to_keep = []

    columns_to_keep_info = [
        'xMLBAMID', 'player_name', 'Throws'
    ]

    columns_to_keep_static = [
        'GS', 'Wins', 'Losses', 'IP', 'BF', 'IP_per_start', 'ERA', 'WHIP', 'FIP', 'LOB%', 'DP%',
        'K/9', 'BB/9', 'H/9', 'HR/9', 'RS/9', 'TTO%'
    ]

    columns_to_keep_dynamic = [
        'AVG', 'SLG', 'ISO', 'BABIP', 'OBP', 'OPS',
        'EV', 'LA', 'HardHit%', 'Barrel%',
        'GB%', 'FB%', 'LD%', 'IFFB%', 'HR/FB', 'GB/FB',
        'Zone%', 'Z-Swing%', 'O-Swing%', 'Contact%', 'Z-Contact%', 'O-Contact%', 'Swing%', 'CStr%',
        'SwStr%', 'C+SwStr%', 'F-Strike%',
        'K%', 'BB%', 'K/BB', 'K-BB%',
        'xBA', 'xWOBA', 'xSLG', 'xISO', 'xBABIP',
        'xERA'
    ]

    
    columns_to_keep.extend(columns_to_keep_info)
    columns_to_keep.extend(columns_to_keep_static)

    prefixes = ["", "RHB_", "LHB_"]

    for prefix in prefixes:
        for suffix in columns_to_keep_dynamic:
            column = f'{prefix}{suffix}'
            if column in pitcher_data_sums.columns:
                columns_to_keep.append(column)

    for pitch_type in pitch_types:
        suffix = '_usage%'
        column = f'{pitch_type}{suffix}'
        if column in pitcher_data_sums.columns:
            columns_to_keep.append(column)

    columns_to_keep.append('update_date')
    
    pitcher_data_summed_cleaned_df = pitcher_data_sums[columns_to_keep]
    
    final_df = pitcher_data_summed_cleaned_df.copy()

    return final_df


def process_starting_pitcher_current_year_stats(pitcher_statsapi_df, pitcher_statcast_df):
    
    # FOR CURRENT SEASON ONLY
    current_year = datetime.now().year
    current_year_statcast_filter = pitcher_statcast_df['season'] == current_year
    current_year_statcast_df = pitcher_statcast_df[current_year_statcast_filter].copy()

    current_year_statsapi_filter = pitcher_statsapi_df['season'] == current_year
    current_year_statsapi_df = pitcher_statsapi_df[current_year_statsapi_filter].copy()

    final_df = process_starting_pitcher_stats(current_year_statsapi_df, current_year_statcast_df)
    
    return final_df


def process_team_pitching_df(
        game_id: int,
        game_official_date,
        team_name: str,
        team_id: int,
        team_pitchers_player_ids: list[int],
        all_pitcher_stats_statsapi: pd.DataFrame,
        all_pitcher_stats_statcast: pd.DataFrame
    ) -> pd.DataFrame:


    all_pitcher_stats_statsapi = all_pitcher_stats_statsapi.drop(columns=['hits', 'outs', 'doubles', 'triples'])
    
    # --- Merge full pitcher dataset ---
    all_pitcher_stats_combined = pd.merge(
        all_pitcher_stats_statsapi,
        all_pitcher_stats_statcast,
        how='left',
        on=['xMLBAMID', 'season']
    )

    # --- Constants ---
    league_xwoba = 0.3162979120429958
    league_era = 4.15
    fip_constant = 3.1495185210234546
    
    # --- Filter to pitchers on this team ---
    roster_pitching_df = all_pitcher_stats_combined[
        all_pitcher_stats_combined['xMLBAMID'].isin(team_pitchers_player_ids)
    ].copy()

    if roster_pitching_df.empty:
        return None
    roster_pitching_df['inningsPitched'] = convert_ip(roster_pitching_df['inningsPitched'])
    
    team_totals = roster_pitching_df.select_dtypes(include='number').sum()
    
    team_ip = team_totals['inningsPitched']
    team_at_bats = team_totals['plate_appearances'] - team_totals['non_at_bats']
    
    team_era = safe_div(team_totals['earnedRuns'], team_ip) * 9
    team_whip = safe_div((team_totals['walks'] + team_totals['hits']), team_ip)
    team_fip = (
        (13 * team_totals['homeRuns']) +
        (3 * (team_totals['baseOnBalls'] + team_totals['hitByPitch'])) -
        (2 * team_totals['strikeOuts'])
    ) / team_ip + fip_constant

    team_lob_perc = safe_div((team_totals['hits'] +
                        team_totals['baseOnBalls'] +
                        team_totals['hitByPitch'] -
                        team_totals['runs'])
                        ,
                        (team_totals['hits'] +
                         team_totals['baseOnBalls'] +
                         team_totals['hitByPitch'] -
                         team_totals['homeRuns']
                        ))
    team_dp_perc = safe_div(
        team_totals["groundIntoDoublePlay"]
        ,
        team_totals['battersFaced'] -
        team_totals['strikeOuts'] - 
        team_totals['baseOnBalls'] -
        team_totals['hitByPitch']
    )
    team_k_nine = safe_div(team_totals['strikeOuts'], team_ip) * 9
    team_bb_nine = safe_div(team_totals['baseOnBalls'], team_ip) * 9
    team_h_nine = safe_div(team_totals['hits'], team_ip) * 9
    team_hr_nine = safe_div(team_totals['homeRuns'], team_ip) * 9
    team_r_nine = safe_div(team_totals['runs'], team_ip) * 9

    team_tto_perc = safe_div(
        team_totals['home_runs'] +
        team_totals['walks'] +
        team_totals['strikeouts'],
        team_totals['plate_appearances']
    )

    
    # --- Derived totals ---
    team_avg = safe_div(team_totals["hits"] , team_at_bats)
    team_total_bases = (
            team_totals['singles'] * 1 +
            team_totals['doubles'] * 2 +
            team_totals['triples'] * 3 +
            team_totals['home_runs'] * 4
        )
    team_slg = safe_div(team_total_bases, team_at_bats)
    team_iso = team_slg - team_avg
    team_babip = safe_div(
        team_totals['hits'] -
        team_totals['homeRuns']
        ,
        team_at_bats -
        team_totals['strikeOuts'] -
        team_totals['homeRuns'] +
        team_totals['sacFlies']
    )
    team_obp_num = (
            team_totals['hits'] +
            team_totals['walks'] +
            team_totals['hit_by_pitches']
    )
    team_obp_denom = (
        team_at_bats +
        team_totals['walks'] +
        team_totals['hit_by_pitches'] +
        team_totals['sacrifices']
    )
    team_obp = safe_div(team_obp_num, team_obp_denom)
    team_ops = team_obp + team_slg

    team_ev = safe_div(team_totals["launch_speed_sum"] , team_totals["batted_balls"])
    team_la = safe_div(team_totals["launch_angle_sum"] , team_totals["batted_balls"])
    team_hard_hit_perc = safe_div(team_totals["hard_hit_balls"] , team_totals["batted_balls"])
    team_barrel_perc = safe_div(team_totals["barrel_balls"] , team_totals["batted_balls"])
    
    # --- Batted-ball profile ---
    team_gb_perc = safe_div(team_totals["GB"] , team_totals["batted_balls"])
    team_fb_perc = safe_div(team_totals["FB"] , team_totals["batted_balls"])
    team_ld_perc = safe_div(team_totals["LD"] , team_totals["batted_balls"])
    team_iffb_perc = safe_div(team_totals["PU"] , team_totals["FB"])
    team_hr_fb = safe_div(team_totals["homeRuns"] , team_totals["FB"])
    team_gb_fb = safe_div(team_totals["GB"] , team_totals["FB"])
    
    # --- Plate discipline ---
    team_zone_perc = safe_div(team_totals["pitches_in_zone"] , team_totals["pitches"])
    team_z_swing_perc = safe_div(team_totals["swings_in_zone"] , team_totals["pitches_in_zone"])
    team_o_swing_perc = safe_div(team_totals["swings_outside_zone"] , team_totals["pitches_outside_zone"])
    
    team_contact_perc = safe_div(team_totals["contacted_balls"] , team_totals["swings"])
    team_z_contact_perc = safe_div(team_totals["contacted_balls_in_zone"] , team_totals["swings_in_zone"])
    team_o_contact_perc = safe_div(team_totals["contacted_balls_outside_zone"] , team_totals["swings_outside_zone"])
    
    team_swing_perc = safe_div(team_totals["swings"] , team_totals["pitches"])
    team_swing_strike_perc = safe_div(team_totals["whiffs"] , team_totals["pitches"])
    team_called_strike_perc = safe_div(team_totals["called_strikes"] , team_totals["pitches"])
    team_called_strike_swing_perc = safe_div((team_totals["called_strikes"] + team_totals["whiffs"]) , team_totals["pitches"])
    
    team_f_strike_perc = safe_div(team_totals["first_pitch_strikes"] , team_totals["first_pitches"])
    
    # --- K/BB family ---
    team_k_perc = safe_div(team_totals["strikeOuts"] , team_totals["battersFaced"])
    team_bb_perc = safe_div(team_totals["baseOnBalls"] , team_totals["battersFaced"])
    team_k_bb = safe_div(team_totals["strikeOuts"] , team_totals["baseOnBalls"])
    team_k_minus_bb_perc = team_k_perc - team_bb_perc
    
    team_xba = safe_div(team_totals['ba_speedangle_sum'] , team_totals['batted_balls'])
    team_xwoba = safe_div(team_totals['woba_speedangle_sum'] , team_totals['batted_balls'])
    team_xslg = safe_div(team_totals['slg_speedangle_sum'] , team_totals['batted_balls'])
    team_xiso = safe_div(team_totals['iso_value_sum'] , team_totals['batted_balls'])
    team_xbabip = safe_div(team_totals['babip_value_sum'] , team_totals['batted_balls'])


    team_df = pd.DataFrame({
        'gamePk': [game_id],
        'officialDate': [game_official_date],
        'team_name': [team_name],
        'team_id': [team_id],
        'ERA': [team_era],
        'WHIP': [team_whip],
        'FIP': [team_fip],
        'LOB%': [team_lob_perc],
        'DP%': [team_dp_perc],
        'K/9': [team_k_nine],
        'BB/9': [team_bb_nine],
        'H/9': [team_h_nine],
        'HR/9': [team_hr_nine],
        'RS/9': [team_r_nine],
        'TTO%': [team_tto_perc],
        'AVG': [team_avg],
        'SLG': [team_slg],
        'ISO': [team_iso],
        'BABIP': [team_babip],
        'OBP': [team_obp],
        'OPS': [team_ops],
        'EV': [team_ev],
        'LA': [team_la],
        'HardHit%': [team_hard_hit_perc],
        'Barrel%': [team_barrel_perc],
        'GB%': [team_gb_perc],
        'FB%': [team_fb_perc],
        'LD%': [team_ld_perc],
        'IFFB%': [team_iffb_perc],
        'HR/FB': [team_hr_fb],
        'GB/FB': [team_gb_fb],
        'Zone%': [team_zone_perc],
        'Z-Swing%': [team_z_swing_perc],
        'O-Swing%': [team_o_swing_perc],
        'Contact%': [team_contact_perc],
        'Z-Contact%': [team_z_contact_perc],
        'O-Contact%': [team_o_contact_perc],
        'Swing%': [team_swing_perc],
        'SwStr%': [team_swing_strike_perc],
        'CStr%': [team_called_strike_perc],
        'C+SwStr%': [team_called_strike_swing_perc],
        'F-Strike%': [team_f_strike_perc],
        'K%': [team_k_perc],
        'BB%': [team_bb_perc],
        'K/BB': [team_k_bb],
        'K-BB%': [team_k_minus_bb_perc],
        'xBA': [team_xba],
        'xWOBA': [team_xwoba],
        'xSLG': [team_xslg],
        'xISO': [team_xiso],
        'xBABIP': [team_xbabip]
    })


    team_df['pitcher_player_ids'] = [team_pitchers_player_ids]
    team_df['update date'] = datetime.now(pytz.timezone("America/New_York"))


    return team_df



def process_team_batting_df(game_id: int, 
                            game_official_date, 
                            team_name: str, 
                            team_id: int, 
                            team_batters_player_ids: list[int],
                            all_batter_stats_statcast: pd.DataFrame) -> pd.DataFrame:
    wBB = 0.691
    wHBP = 0.722
    w1B = 0.882
    w2B = 1.252
    w3B = 1.584
    wHR = 2.037

    league_woba = 0.313
    wOBAScale = 1.232
    R_PA_lg = 0.118

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

    suffix_list = ['K%', 'BB%', 'GB%', 'FB%', 'LD%', 'GB/FB', 'ISO', 'OPS',
                   'BABIP', 'AVG', 'OBP', 'SLG', 'BB/K', 'HR/FB', 'IFFB%', 'Barrel%', 'HardHit%',
                   'O-Swing%', 'Z-Swing%', 'Z-Contact%', 'O-Contact%', 'Contact%', 'Chase%',
                   'Whiff%', 'SwStr%', 'F-Strike%', 'EV', 'LA', 'wOBA', 'wRAA', 'wRC', 'wRC+',
                   'xWOBA', 'xBA', 'xSLG', 'xISO', 'xBABIP']


    roster_batting_df = all_batter_stats_statcast[
        all_batter_stats_statcast['xMLBAMID'].isin(team_batters_player_ids)
        ].copy()


    if roster_batting_df.empty:
        return None
    
    team_totals = roster_batting_df.select_dtypes(include='number').sum()

    pitcher_hand_list = ['general', 'RHP_', 'LHP_']

    team_batting_metrics = {}

    for hand in pitcher_hand_list:
        prefix = "" if hand == "general" else f"{hand}"

        #  K /  BB family
        team_k_perc = safe_div(team_totals[f'{prefix}strikeouts'], team_totals[f'{prefix}plate_appearances'])
        team_bb_perc  = safe_div(team_totals[f'{prefix}walks'], team_totals[f'{prefix}plate_appearances'])
        team_bb_k_perc = safe_div(team_totals[f'{prefix}walks'], team_totals[f'{prefix}strikeouts'])
        # GB  / FB / LD
        team_gb_fb_ld = team_totals[f'{prefix}GB'] + team_totals[f'{prefix}FB'] + team_totals[f'{prefix}LD']
        team_gb_perc = safe_div(team_totals[f'{prefix}GB'], team_gb_fb_ld)
        team_fb_perc = safe_div(team_totals[f'{prefix}FB'], team_gb_fb_ld)
        team_ld_perc = safe_div(team_totals[f'{prefix}LD'], team_gb_fb_ld)
        team_hr_fb_perc = safe_div(team_totals[f'{prefix}home_runs'], team_totals[f'{prefix}FB'])
        team_gb_fb_perc = safe_div(team_totals[f'{prefix}GB'], team_totals[f'{prefix}FB'])
        team_iffb_perc = safe_div(team_totals[f'{prefix}PU'], team_totals[f'{prefix}FB'])
        # --- TEAM AT-BATS ---
        team_at_bats = team_totals[f'{prefix}plate_appearances'] - team_totals[f'{prefix}non_at_bats']
        # --- AVG ---
        team_avg = safe_div(team_totals[f'{prefix}hits'], team_at_bats)
        # --- TOTAL BASES ---
        team_total_bases = (
            team_totals[f'{prefix}singles'] * 1 +
            team_totals[f'{prefix}doubles'] * 2 +
            team_totals[f'{prefix}triples'] * 3 +
            team_totals[f'{prefix}home_runs'] * 4
        )
        # --- SLG ---
        team_slg = safe_div(team_total_bases, team_at_bats)
        # --- ISO ---
        team_iso = team_slg - team_avg
        # --- BABIP ---
        team_babip_num = team_totals[f'{prefix}hits'] - team_totals[f'{prefix}home_runs']
        team_babip_denom = (
            team_at_bats
            - team_totals[f'{prefix}strikeouts']
            - team_totals[f'{prefix}home_runs']
            + team_totals[f'{prefix}sac_flies']
            + team_totals[f'{prefix}sac_fly_double_plays']
        )
        team_babip = safe_div(team_babip_num, team_babip_denom)
        # --- OBP ---
        team_obp_num = (
            team_totals[f'{prefix}hits'] +
            team_totals[f'{prefix}walks'] +
            team_totals[f'{prefix}hit_by_pitches']
        )
        team_obp_denom = (
            team_at_bats +
            team_totals[f'{prefix}walks'] +
            team_totals[f'{prefix}hit_by_pitches'] +
            team_totals[f'{prefix}sacrifices']
        )
        team_obp = safe_div(team_obp_num, team_obp_denom)
        # --- OPS ---
        team_ops = team_obp + team_slg
        # EV  / LA
        team_ev  = safe_div(team_totals[f'{prefix}launch_speed_sum'] , team_totals[f'{prefix}batted_balls'])
        team_la = safe_div(team_totals[f'{prefix}launch_angle_sum'] , team_totals[f'{prefix}batted_balls'])
        # CONTACT QUALITY ESTS
        team_xba = safe_div(team_totals[f'{prefix}ba_speedangle_sum'], team_totals[f'{prefix}batted_balls'])
        team_xwoba = safe_div(team_totals[f'{prefix}woba_speedangle_sum'], team_totals[f'{prefix}batted_balls'])
        team_xslg = safe_div(team_totals[f'{prefix}slg_speedangle_sum'], team_totals[f'{prefix}batted_balls'])
        team_xiso = safe_div(team_totals[f'{prefix}iso_value_sum'], team_totals[f'{prefix}batted_balls'])
        team_xbabip = safe_div(team_totals[f'{prefix}babip_value_sum'], team_totals[f'{prefix}batted_balls'])
        # contact % family
        team_hard_hit_perc = safe_div(team_totals[f'{prefix}hard_hit_balls'],
                              team_totals[f'{prefix}batted_balls'])
        
        team_z_swing = safe_div(team_totals[f'{prefix}swings_in_zone'],
                                  team_totals[f'{prefix}pitches_in_zone'])
        
        team_z_contact = safe_div(team_totals[f'{prefix}contacted_balls_in_zone'],
                                  team_totals[f'{prefix}swings_in_zone'])
        
        team_contact   = safe_div(team_totals[f'{prefix}contacted_balls'],
                                  team_totals[f'{prefix}swings'])
        
        team_o_contact = safe_div(team_totals[f'{prefix}contacted_balls_outside_zone'],
                                  team_totals[f'{prefix}swings_outside_zone'])
                                  
        team_o_swing   = safe_div(team_totals[f'{prefix}swings_outside_zone'],
                                  team_totals[f'{prefix}pitches_outside_zone'])
        
        team_barrel_perc = safe_div(team_totals[f'{prefix}barrel_balls'], team_totals[f'{prefix}batted_balls'])
        
        team_swing_perc = safe_div(team_totals[f'{prefix}whiffs'], team_totals[f'{prefix}pitches'])

        team_f_strike_perc = safe_div(team_totals[f'{prefix}first_pitch_strikes'] , team_totals[f'{prefix}first_pitches'])
        # --- Team wOBA ---
        team_woba_numerator = (
            wBB  * team_totals[f'{prefix}walks'] +
            wHBP * team_totals[f'{prefix}hit_by_pitches'] +
            w1B  * team_totals[f'{prefix}singles'] +
            w2B  * team_totals[f'{prefix}doubles'] +
            w3B  * team_totals[f'{prefix}triples'] +
            wHR  * team_totals[f'{prefix}home_runs']
        )
        team_woba = team_woba_numerator / team_totals[f'{prefix}plate_appearances'] if team_totals[f'{prefix}plate_appearances'] > 0 else 0
        # --- Team wRAA ---
        team_wraa = ((team_woba - league_woba) / wOBAScale) * team_totals[f'{prefix}plate_appearances'] if team_totals[f'{prefix}plate_appearances'] > 0 else 0
        # --- Team wRC ---
        team_wrc = team_wraa + (R_PA_lg * team_totals[f'{prefix}plate_appearances'])
        # --- Team wRC+ ---
        team_wrc_plus = 100 * ((team_wrc / team_totals[f'{prefix}plate_appearances']) / R_PA_lg) if team_totals[f'{prefix}plate_appearances'] > 0 else 0


        swings = team_totals[f'{prefix}swings']
        swings_oz = team_totals[f'{prefix}swings_outside_zone']
        contact = team_totals[f'{prefix}contacted_balls']
        whiffs = team_totals[f'{prefix}whiffs']
        pitches_oz = team_totals[f'{prefix}pitches_outside_zone']

        team_chase = safe_div(swings_oz, pitches_oz)
        team_whiff = safe_div(whiffs, swings)
        
        # Add to dictionary team batting metrics
        team_batting_metrics[f'{prefix}K%'] = team_k_perc
        team_batting_metrics[f'{prefix}BB%'] = team_bb_perc
        team_batting_metrics[f'{prefix}GB%'] = team_gb_perc
        team_batting_metrics[f'{prefix}FB%'] = team_fb_perc
        team_batting_metrics[f'{prefix}LD%'] = team_ld_perc
        team_batting_metrics[f'{prefix}GB/FB'] = team_gb_fb_perc
        team_batting_metrics[f'{prefix}ISO'] = team_iso
        team_batting_metrics[f'{prefix}OPS'] = team_ops
        team_batting_metrics[f'{prefix}BABIP'] = team_babip
        team_batting_metrics[f'{prefix}AVG'] = team_avg
        team_batting_metrics[f'{prefix}OBP'] = team_obp
        team_batting_metrics[f'{prefix}SLG'] = team_slg
        team_batting_metrics[f'{prefix}BB/K'] = team_bb_k_perc
        team_batting_metrics[f'{prefix}HR/FB'] = team_hr_fb_perc
        team_batting_metrics[f'{prefix}IFFB%'] = team_iffb_perc
        team_batting_metrics[f'{prefix}Barrel%'] = team_barrel_perc
        team_batting_metrics[f'{prefix}HardHit%'] = team_hard_hit_perc
        team_batting_metrics[f'{prefix}O-Swing%'] = team_o_swing
        team_batting_metrics[f'{prefix}Z-Swing%'] = team_z_swing
        team_batting_metrics[f'{prefix}Z-Contact%'] = team_z_contact
        team_batting_metrics[f'{prefix}O-Contact%'] = team_o_contact
        team_batting_metrics[f'{prefix}Contact%'] = team_contact
        team_batting_metrics[f'{prefix}Chase%'] = team_chase
        team_batting_metrics[f'{prefix}Whiff%'] = team_whiff
        team_batting_metrics[f'{prefix}SwStr%'] = team_swing_perc
        team_batting_metrics[f'{prefix}F-Strike%'] = team_f_strike_perc
        team_batting_metrics[f'{prefix}EV'] = team_ev
        team_batting_metrics[f'{prefix}LA'] = team_la
        team_batting_metrics[f'{prefix}wOBA'] = team_woba
        team_batting_metrics[f'{prefix}wRAA'] = team_wraa
        team_batting_metrics[f'{prefix}wRC'] = team_wrc
        team_batting_metrics[f'{prefix}wRC+'] = team_wrc_plus
        team_batting_metrics[f'{prefix}xWOBA'] = team_xwoba
        team_batting_metrics[f'{prefix}xBA'] = team_xba
        team_batting_metrics[f'{prefix}xSLG'] = team_xslg
        team_batting_metrics[f'{prefix}xISO'] = team_xiso
        team_batting_metrics[f'{prefix}xBABIP'] = team_xbabip


        
    team_pitchtype_metrics = {}

    for pitch in pitch_types:
        swings = team_totals[f"{pitch}_swings"]
        swings_oz = team_totals[f"{pitch}_swings_outside_zone"]
        contact = team_totals[f"{pitch}_contact"]
        whiffs = team_totals[f"{pitch}_whiffs"]
        pitches_oz = team_totals[f"{pitch}_outside_zone"]

        team_pitchtype_metrics[f"{pitch}_Chase%"] = safe_div(swings_oz, pitches_oz)
        team_pitchtype_metrics[f"{pitch}_Contact%"] = safe_div(contact, swings)
        team_pitchtype_metrics[f"{pitch}_Whiff%"] = safe_div(whiffs, swings)

    split_metrics = {}

    for split in suffix_list:
        split_metrics[f"{split}_split"] = team_batting_metrics[f"LHP_{split}"] - team_batting_metrics[f"RHP_{split}"]

    team_df = pd.DataFrame({
        'gamePk': [game_id],
        'officialDate': [game_official_date],
        'team_name': [team_name],
        'team_id': [team_id]
    })

    batting_df = pd.DataFrame([team_batting_metrics])
    pitch_type_df = pd.DataFrame([team_pitchtype_metrics])
    split_df = pd.DataFrame([split_metrics])

    team_df = pd.concat([team_df, batting_df, pitch_type_df, split_df], axis = 1)


    team_df['hitter_player_ids'] = [team_batters_player_ids]
    team_df['update date'] = datetime.now(pytz.timezone("America/New_York"))

    return team_df

def process_mlb_team_record_info(league_id, league_df):
    mlb_teams_df_list = []
    
    league_name = 'AL' if league_id == 103 else 'NL'
    league_level = league_df['records']
    
    for division in range(0, len(league_level)):
        division_level = league_level[division]
        league_id = division_level['league']['id']
        division_id = division_level['division']['id']

        team_level = division_level['teamRecords']
        for team in range(0, len(team_level)):
            team_record_dict = {}
            
            team_id = team_level[team]['team']['id']
            team_name = team_level[team]['team']['name']
            season = team_level[team]['season']
            division_rank = team_level[team]['divisionRank']
            sport_rank = team_level[team]['sportRank']
            winning_precentage = team_level[team]['winningPercentage']
            runs_allowed = team_level[team]['runsAllowed']
            runs_scored = team_level[team]['runsScored']
            run_differential = team_level[team]['runDifferential']
            
            split_record_level = team_level[team]['records']['splitRecords']
            for split_record in range(0, len(split_record_level)):
                key = split_record_level[split_record]['type']
                value = split_record_level[split_record]['pct']
                team_record_dict[key] = value

            division_record_level = team_level[team]['records']['divisionRecords']
            for division_record in range(0, len(division_record_level)):
                key = division_record_level[division_record]['division']['id']
                value = division_record_level[division_record]['pct']
                key_name = f'division_id_{key}'
                team_record_dict[key_name] = value

            league_record_level = team_level[team]['records']['leagueRecords']
            for league_record in range(0, len(league_record_level)):
                key = league_record_level[league_record]['league']['id']
                value = league_record_level[league_record]['pct']
                key_name = f'league_id_{key}'
                team_record_dict[key_name] = value

            team_df = pd.DataFrame({
                'team_name': [team_name],
                'team_id': [team_id],
                'league_name': [league_name],
                'league_id': [league_id],
                'division_id': [division_id],
                'season': [season],
                'division_rank': [division_rank],
                'sport_rank': [sport_rank],
                'winning_percentage': [winning_precentage],
                'runs_allowed': [runs_allowed],
                'runs_scored': [runs_scored],
                'run_differential': [run_differential]
            })

            for key, value in team_record_dict.items():
                team_df[key] = value

            
            mlb_teams_df_list.append(team_df)
            
    mlb_team_records = pd.concat(mlb_teams_df_list)

    return(mlb_team_records)





