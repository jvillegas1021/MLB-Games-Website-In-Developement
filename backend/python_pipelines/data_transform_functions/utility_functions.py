from datetime import datetime, timedelta
import pandas as pd
import numpy as np
import pytz

def safe_div(n, d):
    # Handle zero or None denominator immediately
    if d == 0 or d is None:
        return 0

    try:
        result = n / d
    except Exception:
        return 0

    # Scalar path
    if isinstance(result, (int, float, np.floating)):
        if np.isnan(result) or np.isinf(result):
            return 0
        return result

    # Pandas Series/DataFrame path
    return result.replace([np.inf, -np.inf], np.nan).fillna(0)

def safe_div_series(n, d):
    # Replace 0 denominator with NA so division doesn't blow up
    d = d.replace(0, pd.NA)

    # Perform division
    out = n.div(d)

    # Convert to numeric nullable float BEFORE fillna to avoid FutureWarning
    out = pd.to_numeric(out, errors="coerce").astype("Float64")

    # Replace NA with 0 (safe)
    return out.fillna(0)



def subtract_minutes_from_times(time_list, minutes=45):
    updated_times = []
    for t in time_list:
        dt = datetime.combine(datetime.today(), t)
        new_dt = dt - timedelta(minutes=minutes)
        updated_times.append(new_dt.time())
    return updated_times

def filter_relievers(df):
    df = df.copy()
    df = df[df["games_played"] > 0]
    df["IP_per_G"] = df["IP"] / df["games_played"]
    return df[(df["IP_per_G"] < 3.0) & (df["IP"] >= 5)]

def convert_ip(ip_series):
    ip_series = ip_series.astype(float)
    whole = ip_series.astype(int)
    decimal = ip_series - whole
    outs = (decimal * 10).round().astype(int)
    return whole + outs / 3


def compute_travel_distance_around_earth(team_travel_df):
    columns_to_radians = ['last_venue_longitude', 'last_venue_latitude', 'current_venue_longitude',
                          'current_venue_latitude']

    for column in columns_to_radians:
        team_travel_df[column + '_rad'] = np.radians(team_travel_df[column])
    
    # haversine equation
    difference_in_longitudes = team_travel_df['current_venue_longitude_rad'] - team_travel_df['last_venue_longitude_rad']
    difference_in_latitudes = team_travel_df['current_venue_latitude_rad'] - team_travel_df['last_venue_latitude_rad']
    a_value = np.sin(difference_in_longitudes / 2)** 2 + np.cos(team_travel_df['last_venue_latitude_rad']) * np.cos(team_travel_df['current_venue_latitude_rad']) * np.sin(difference_in_latitudes / 2) ** 2
    c_value = 2 * np.arctan2(np.sqrt(a_value), np.sqrt(1 - a_value))
    distance_traveled = c_value * 6378.1

    team_travel_df['travel_distance_km'] = distance_traveled

    return team_travel_df

def add_update_date(player_df):
    player_df['update_date'] = datetime.now(pytz.timezone("America/New_York"))

    return player_df
    
def convert_batter_df_types_statsapi(player_df) :
    columns_to_str_list = ['xMLBAMID', 'team_name']
    columns_to_float_list = ['avg', 'obp', 'slg', 'ops', 'stolenBasePercentage', 'caughtStealingPercentage',
                          'babip', 'groundOutsToAirouts', 'atBatsPerHomeRun']

    player_df['season'] = player_df['season'].astype(int)
    for column in columns_to_str_list:
        player_df[column] = player_df[column].fillna("").astype(str)
        player_df[column] = player_df[column].astype(str)

    
    for column in columns_to_float_list:
        player_df[column] = player_df[column].fillna("").astype(str)
        player_df[column] = pd.to_numeric(player_df[column], errors='coerce')

    return player_df


def convert_pitcher_df_types_statsapi(player_df) :
    columns_to_str_list = ['xMLBAMID', 'team_name']
    columns_to_float_list = ['season', 'avg', 'obp', 'slg', 'ops', 'stolenBasePercentage', 'caughtStealingPercentage', 'era',
                             'inningsPitched', 'whip', 'strikePercentage', 'groundOutsToAirouts', 'winPercentage',
                             'pitchesPerInning', 'strikeoutWalkRatio', 'strikeoutsPer9Inn', 'walksPer9Inn', 'hitsPer9Inn',
                             'runsScoredPer9', 'homeRunsPer9']
    
    player_df['season'] = player_df['season'].astype(int)
    for column in columns_to_str_list:
        player_df[column] = player_df[column].fillna("").astype(str)
        player_df[column] = player_df[column].astype(str)

    
    for column in columns_to_float_list:
        player_df[column] = player_df[column].fillna("").astype(str)
        player_df[column] = pd.to_numeric(player_df[column], errors='coerce')

    return player_df
