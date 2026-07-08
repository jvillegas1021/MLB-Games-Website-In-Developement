import pandas as pd
from datetime import datetime
import pytz
import numpy as np

def compute_count_stats_pitcher(statcast_df) :

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

    # -------------------------
    # Base Aggs
    # -------------------------
    base_aggs = {
        "pitches": ("pitch_name", "count"),
        "pitches_in_zone": ("is_in_zone", "sum"),
        "pitches_outside_zone": ("is_outside_zone", "sum"),
        "swings": ("is_swing", "sum"),
        "swings_in_zone": ("is_swing_in_zone", "sum"),
        "swings_outside_zone": ("is_swing_outside_zone", "sum"),
        "contacted_balls": ("is_contact", "sum"),
        "contacted_balls_in_zone": ("is_contact_in_zone", "sum"),
        "contacted_balls_outside_zone": ("is_contact_outside_zone", "sum"),
        "whiffs": ("is_whiff", "sum"),
        "whiffs_in_zone": ("is_whiff_in_zone", "sum"),
        "whiffs_outside_zone": ("is_whiff_outside_zone", "sum"),
        "first_pitches": ("is_first_pitch", "sum"),
        "first_pitch_strikes": ("is_first_pitch_strike", "sum"),
        "called_strikes": ("is_called_strike", "sum"),
        "plate_appearances": ("is_pa", "sum"),
        "non_at_bats": ("is_not_ab", "sum"),
        "walks": ("is_walk", "sum"),
        "hit_by_pitches": ("is_hit_by_pitch", "sum"),
        "strikeouts": ("is_strikeout_event", "sum"),
        "field_outs": ("is_field_out_event", "sum"),
        "sac_flies": ("is_sac_fly", "sum"),
        "sac_fly_double_plays": ("is_sac_fly_double_play", "sum"),
        "sac_bunts": ("is_sac_bunt", "sum"),
        "field_errors": ("is_field_error", "sum"),
        "fielders_choices": ("is_fielders_choice", "sum"),
        "sacrifices": ("is_sacrifice", "sum"),
        "outs": ("is_out", "sum"),
        "hits": ("is_hit", "sum"),
        "singles": ("is_single", "sum"),
        "doubles": ("is_double", "sum"),
        "triples": ("is_triple", "sum"),
        "home_runs": ("is_home_run", "sum"),
        "hits_into_play": ("is_hit_into_play", "sum"),
        "GB": ("is_ground_ball", "sum"),
        "FB": ("is_fly_ball", "sum"),
        "LD": ("is_line_drive", "sum"),
        "PU": ("is_popup", "sum"),
        "batted_balls": ("is_batted_ball", "sum"),
        "hard_hit_balls": ("is_hard_hit_ball", "sum"),
        "barrel_balls": ("is_barrel_ball", "sum"),
        "launch_speed_sum": ("launch_speed_bip", "sum"),
        "launch_angle_sum": ("launch_angle_bip", "sum"),
        "ba_speedangle_sum": ("estimated_ba_using_speedangle_bip", "sum"),
        "woba_speedangle_sum": ("estimated_woba_using_speedangle_bip", "sum"),
        "babip_value_sum": ("babip_value_bip", "sum"),
        "iso_value_sum": ("iso_value_bip", "sum"),
        "slg_speedangle_sum": ("estimated_slg_using_speedangle_bip", "sum"),
    }
    # -------------------------
    #  Pitch Aggs
    # -------------------------
    pitch_aggs = {}
    for pitch in pitch_types:
        pitch_aggs[f"{pitch}_pitches"] = (f"is_{pitch}", "sum")

        pitch_aggs[f"{pitch}_hits"] = (f"is_{pitch}_hit", "sum")
        pitch_aggs[f"{pitch}_singles"] = (f"is_{pitch}_single", "sum")
        pitch_aggs[f"{pitch}_doubles"] = (f"is_{pitch}_double", "sum")
        pitch_aggs[f"{pitch}_triples"] = (f"is_{pitch}_triple", "sum")
        pitch_aggs[f"{pitch}_home_runs"] = (f"is_{pitch}_home_run", "sum")

        pitch_aggs[f"{pitch}_walks"] = (f"is_{pitch}_walk", "sum")
        pitch_aggs[f"{pitch}_strikeouts"] = (f"is_{pitch}_strikeout", "sum")
        pitch_aggs[f"{pitch}_outs"] = (f"is_{pitch}_out", "sum")

        pitch_aggs[f"{pitch}_abs"] = (f"is_{pitch}_ab", "sum")
        pitch_aggs[f"{pitch}_pas"] = (f"is_{pitch}_pa", "sum")

        pitch_aggs[f"{pitch}_bips"] = (f"is_{pitch}_bip", "sum")
        pitch_aggs[f"{pitch}_barrels"] = (f"is_{pitch}_barrel", "sum")
        pitch_aggs[f"{pitch}_hit_into_plays"] = (f"is_{pitch}_hit_into_play", "sum")
        pitch_aggs[f"{pitch}_ground_balls"] = (f"is_{pitch}_ground_ball", "sum")
        pitch_aggs[f"{pitch}_fly_balls"] = (f"is_{pitch}_fly_ball", "sum")
        pitch_aggs[f"{pitch}_line_drives"] = (f"is_{pitch}_line_drive", "sum")
        pitch_aggs[f"{pitch}_popups"] = (f"is_{pitch}_popup", "sum")

        pitch_aggs[f"{pitch}_xba_sum"] = (f"{pitch}_xba", "sum")
        pitch_aggs[f"{pitch}_xslg_sum"] = (f"{pitch}_xslg", "sum")
        pitch_aggs[f"{pitch}_xiso_sum"] = (f"{pitch}_xiso", "sum")
        pitch_aggs[f"{pitch}_xbabip_sum"] = (f"{pitch}_xbabip", "sum")
        pitch_aggs[f"{pitch}_xwoba_sum"] = (f"{pitch}_xwoba", "sum")

        pitch_aggs[f"{pitch}_in_zone"] = (f"is_{pitch}_in_zone", "sum")
        pitch_aggs[f"{pitch}_outside_zone"] = (f"is_{pitch}_outside_zone", "sum")

        pitch_aggs[f"{pitch}_swings"] = (f"is_{pitch}_swing", "sum")
        pitch_aggs[f"{pitch}_swings_in_zone"] = (f"is_{pitch}_swing_in_zone", "sum")
        pitch_aggs[f"{pitch}_swings_outside_zone"] = (f"is_{pitch}_swing_outside_zone", "sum")

        pitch_aggs[f"{pitch}_contact"] = (f"is_{pitch}_contact", "sum")
        pitch_aggs[f"{pitch}_contact_in_zone"] = (f"is_{pitch}_contact_in_zone", "sum")
        pitch_aggs[f"{pitch}_contact_outside_zone"] = (f"is_{pitch}_contact_outside_zone", "sum")

        pitch_aggs[f"{pitch}_whiffs"] = (f"is_{pitch}_whiff", "sum")
        pitch_aggs[f"{pitch}_whiffs_in_zone"] = (f"is_{pitch}_whiff_in_zone", "sum")
        pitch_aggs[f"{pitch}_whiffs_outside_zone"] = (f"is_{pitch}_whiff_outside_zone", "sum")

    # -------------------------
    # Throw Lookup
    # -------------------------
    throws_lookup = (
        statcast_df.groupby("pitcher")["p_throws"]
        .first()  # or .unique().str[0]
        .rename("Throws")
    )

    generic_df = (
        statcast_df
        .groupby(['pitcher', 'game_year'])
        .agg(**base_aggs)
    )

    generic_df = generic_df.copy().reset_index()


    lhb_df = (
        statcast_df[statcast_df['is_lhb']]
        .groupby(['pitcher', 'game_year'])
        .agg(**base_aggs)
        .add_prefix("LHB_")
    )
    lhb_df = lhb_df.copy().reset_index()

    rhb_df = (
        statcast_df[statcast_df['is_rhb']]
        .groupby(['pitcher', 'game_year'])
        .agg(**base_aggs)
        .add_prefix("RHB_")
    )
    rhb_df = rhb_df.copy().reset_index()

    pitch_df = (
        statcast_df
        .groupby(['pitcher', 'game_year'])
        .agg(**pitch_aggs)
    )
    pitch_df = pitch_df.copy().reset_index()

    lhb_df = lhb_df.drop(columns=["pitcher", "game_year"])
    rhb_df = rhb_df.drop(columns=["pitcher", "game_year"])
    pitch_df = pitch_df.drop(columns=["pitcher", "game_year"])
    # Concat
    joined_df = pd.concat([generic_df, lhb_df, rhb_df, pitch_df], axis=1)

    joined_df["Throws"] = joined_df["pitcher"].map(throws_lookup)
    # Final
    final_df = joined_df.rename(columns={"pitcher": "xMLBAMID", "game_year": "season"})
    final_df["update_date"] = datetime.now(pytz.timezone("America/New_York"))

    return final_df


def compute_count_stats_batter(statcast_df):

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

    # -------------------------
    # 2. Base aggregations + generic_df
    # -------------------------
    base_aggs = {
        "pitches": ("pitch_name", "count"),
        "pitches_in_zone": ("is_in_zone", "sum"),
        "pitches_outside_zone": ("is_outside_zone", "sum"),
        "swings": ("is_swing", "sum"),
        "swings_in_zone": ("is_swing_in_zone", "sum"),
        "swings_outside_zone": ("is_swing_outside_zone", "sum"),
        "contacted_balls": ("is_contact", "sum"),
        "contacted_balls_in_zone": ("is_contact_in_zone", "sum"),
        "contacted_balls_outside_zone": ("is_contact_outside_zone", "sum"),
        "whiffs": ("is_whiff", "sum"),
        "whiffs_in_zone": ("is_whiff_in_zone", "sum"),
        "whiffs_outside_zone": ("is_whiff_outside_zone", "sum"),
        "first_pitches": ("is_first_pitch", "sum"),
        "first_pitch_strikes": ("is_first_pitch_strike", "sum"),
        "called_strikes": ("is_called_strike", "sum"),
        "plate_appearances": ("is_pa", "sum"),
        "non_at_bats": ("is_not_ab", "sum"),
        "walks": ("is_walk", "sum"),
        "hit_by_pitches": ("is_hit_by_pitch", "sum"),
        "strikeouts": ("is_strikeout_event", "sum"),
        "field_outs": ("is_field_out_event", "sum"),
        "sac_flies": ("is_sac_fly", "sum"),
        "sac_fly_double_plays": ("is_sac_fly_double_play", "sum"),
        "sac_bunts": ("is_sac_bunt", "sum"),
        "field_errors": ("is_field_error", "sum"),
        "fielders_choices": ("is_fielders_choice", "sum"),
        "sacrifices": ("is_sacrifice", "sum"),
        "outs": ("is_out", "sum"),
        "hits": ("is_hit", "sum"),
        "singles": ("is_single", "sum"),
        "doubles": ("is_double", "sum"),
        "triples": ("is_triple", "sum"),
        "home_runs": ("is_home_run", "sum"),
        "hits_into_play": ("is_hit_into_play", "sum"),
        "GB": ("is_ground_ball", "sum"),
        "FB": ("is_fly_ball", "sum"),
        "LD": ("is_line_drive", "sum"),
        "PU": ("is_popup", "sum"),
        "batted_balls": ("is_batted_ball", "sum"),
        "hard_hit_balls": ("is_hard_hit_ball", "sum"),
        "barrel_balls": ("is_barrel_ball", "sum"),
        "launch_speed_sum": ("launch_speed_bip", "sum"),
        "launch_angle_sum": ("launch_angle_bip", "sum"),
        "ba_speedangle_sum": ("estimated_ba_using_speedangle_bip", "sum"),
        "woba_speedangle_sum": ("estimated_woba_using_speedangle_bip", "sum"),
        "babip_value_sum": ("babip_value_bip", "sum"),
        "iso_value_sum": ("iso_value_bip", "sum"),
        "slg_speedangle_sum": ("estimated_slg_using_speedangle_bip", "sum"),
    }
    # -------------------------
    # 4. Pitch-type aggregations
    # -------------------------
    pitch_aggs = {}
    for pitch in pitch_types:
        pitch_aggs[f"{pitch}_pitches"] = (f"is_{pitch}", "sum")

        pitch_aggs[f"{pitch}_hits"] = (f"is_{pitch}_hit", "sum")
        pitch_aggs[f"{pitch}_singles"] = (f"is_{pitch}_single", "sum")
        pitch_aggs[f"{pitch}_doubles"] = (f"is_{pitch}_double", "sum")
        pitch_aggs[f"{pitch}_triples"] = (f"is_{pitch}_triple", "sum")
        pitch_aggs[f"{pitch}_home_runs"] = (f"is_{pitch}_home_run", "sum")

        pitch_aggs[f"{pitch}_walks"] = (f"is_{pitch}_walk", "sum")
        pitch_aggs[f"{pitch}_strikeouts"] = (f"is_{pitch}_strikeout", "sum")
        pitch_aggs[f"{pitch}_outs"] = (f"is_{pitch}_out", "sum")

        pitch_aggs[f"{pitch}_abs"] = (f"is_{pitch}_ab", "sum")
        pitch_aggs[f"{pitch}_pas"] = (f"is_{pitch}_pa", "sum")

        pitch_aggs[f"{pitch}_bips"] = (f"is_{pitch}_bip", "sum")
        pitch_aggs[f"{pitch}_barrels"] = (f"is_{pitch}_barrel", "sum")
        pitch_aggs[f"{pitch}_hit_into_plays"] = (f"is_{pitch}_hit_into_play", "sum")
        pitch_aggs[f"{pitch}_ground_balls"] = (f"is_{pitch}_ground_ball", "sum")
        pitch_aggs[f"{pitch}_fly_balls"] = (f"is_{pitch}_fly_ball", "sum")
        pitch_aggs[f"{pitch}_line_drives"] = (f"is_{pitch}_line_drive", "sum")
        pitch_aggs[f"{pitch}_popups"] = (f"is_{pitch}_popup", "sum")

        pitch_aggs[f"{pitch}_xba_sum"] = (f"{pitch}_xba", "sum")
        pitch_aggs[f"{pitch}_xslg_sum"] = (f"{pitch}_xslg", "sum")
        pitch_aggs[f"{pitch}_xiso_sum"] = (f"{pitch}_xiso", "sum")
        pitch_aggs[f"{pitch}_xbabip_sum"] = (f"{pitch}_xbabip", "sum")
        pitch_aggs[f"{pitch}_xwoba_sum"] = (f"{pitch}_xwoba", "sum")
        
        
        pitch_aggs[f"{pitch}_in_zone"] = (f"is_{pitch}_in_zone", "sum")
        pitch_aggs[f"{pitch}_outside_zone"] = (f"is_{pitch}_outside_zone", "sum")

        pitch_aggs[f"{pitch}_swings"] = (f"is_{pitch}_swing", "sum")
        pitch_aggs[f"{pitch}_swings_in_zone"] = (f"is_{pitch}_swing_in_zone", "sum")
        pitch_aggs[f"{pitch}_swings_outside_zone"] = (f"is_{pitch}_swing_outside_zone", "sum")

        pitch_aggs[f"{pitch}_contact"] = (f"is_{pitch}_contact", "sum")
        pitch_aggs[f"{pitch}_contact_in_zone"] = (f"is_{pitch}_contact_in_zone", "sum")
        pitch_aggs[f"{pitch}_contact_outside_zone"] = (f"is_{pitch}_contact_outside_zone", "sum")

        pitch_aggs[f"{pitch}_whiffs"] = (f"is_{pitch}_whiff", "sum")
        pitch_aggs[f"{pitch}_whiffs_in_zone"] = (f"is_{pitch}_whiff_in_zone", "sum")
        pitch_aggs[f"{pitch}_whiffs_outside_zone"] = (f"is_{pitch}_whiff_outside_zone", "sum")

    stance_lookup = (
        statcast_df.groupby("batter")["stand"]
        .unique()
        .apply(lambda x: "S" if len(x) > 1 else x[0])
    )

    generic_df = (
        statcast_df
        .groupby(['batter', 'game_year'])
        .agg(**base_aggs)
    )
    generic_df = generic_df.copy().reset_index()
    # -------------------------
    # 3. Pitcher Handeness dfs
    # -------------------------
    lhp_df = (
        statcast_df[statcast_df['is_lhp']]
        .groupby(['batter', 'game_year'])
        .agg(**base_aggs)
        .add_prefix('LHP_')
    )
    lhp_df = lhp_df.copy().reset_index()

    rhp_df = (
        statcast_df[statcast_df['is_rhp']]
        .groupby(['batter', 'game_year'])
        .agg(**base_aggs)
        .add_prefix('RHP_')
    )
    rhp_df = rhp_df.copy().reset_index()

    pitch_df = (
        statcast_df
        .groupby(['batter', 'game_year'])
        .agg(**pitch_aggs)
    )
    pitch_df = pitch_df.copy().reset_index()

    lhp_df = lhp_df.drop(columns=["batter", "game_year"])
    rhp_df = rhp_df.drop(columns=["batter", "game_year"])
    pitch_df = pitch_df.drop(columns=["batter", "game_year"])


    # -------------------------
    # 4. Join all
    # -------------------------
    joined_df = pd.concat([
        generic_df,
        lhp_df,
        rhp_df,
        pitch_df], axis=1
    )

    # -------------------------
    # 5. Merge stance + flatten
    # -------------------------
    joined_df['Stance'] = joined_df['batter'].map(stance_lookup)

    final_df = (joined_df
                .rename(columns={"batter": "xMLBAMID", "game_year": "season"}))

    final_df['update_date'] = datetime.now(pytz.timezone("America/New_York"))

    return final_df