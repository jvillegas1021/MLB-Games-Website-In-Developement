import { compare_stat_low_color, compare_stat_high_color, compare_stat_general_color } from "../utility_functions/color_functions.js"
import { safe_fixed, safe_percent } from "../utility_functions/safe_functions.js"

export default function MatchupPitcherDetails({ matchup, pitcher_stats, pitcher_league_averages }) {

  if (!pitcher_league_averages || pitcher_league_averages.length === 0) {
    return <div>Loading pitcher league averages...</div>;
  }

  // Build dictionary safely
  const leagueAvg = Object.fromEntries(
    pitcher_league_averages.map(r => [r.stat, r.average])
  );


  const pitch_types = [
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
  ];

  const current_year = new Date().getFullYear();
  const last_year = current_year - 1;

  const home_pitcher_stats = pitcher_stats.find(
    p => p.xMLBAMID === matchup.Home_Pitcher_ID
  );

  const away_pitcher_stats = pitcher_stats.find(
    p => p.xMLBAMID === matchup.Away_Pitcher_ID
  );

  const home_pitcher_usage_list = home_pitcher_stats
    ? pitch_types.map(pt => ({
        pitch: pt.replace(/_/g, " "),
        value: ((home_pitcher_stats[`${pt}_usage%`] || 0) * 100).toFixed(0)
      }))
    : [];

  const home_pitcher_usage_list_filtered = home_pitcher_usage_list.filter(
      u => Number(u.value) > 0
    );

  
  const away_pitcher_usage_list = away_pitcher_stats
    ? pitch_types.map(pt => ({
        pitch: pt.replace(/_/g, " "),   // nicer label
        value: ((away_pitcher_stats[`${pt}_usage%`] || 0) * 100).toFixed(0)
      }))
    : [];

  const away_pitcher_usage_list_filtered = away_pitcher_usage_list.filter(
    u=> Number(u.value) > 0
  )

  // home pitcher expected stats //
  const home_pitcher_xba = safe_fixed(home_pitcher_stats?.xBA)
  const home_pitcher_xslg = safe_fixed(home_pitcher_stats?.xSLG)
  const home_pitcher_xiso = safe_fixed(home_pitcher_stats?.xISO)
  const home_pitcher_xwoba = safe_fixed(home_pitcher_stats?.xWOBA)
  const home_pitcher_xbabip = safe_fixed(home_pitcher_stats?.xBABIP)
  
  // home pitcher stats //
  const home_pitcher_era = safe_fixed(home_pitcher_stats?.ERA)
  const home_pitcher_whip = safe_fixed(home_pitcher_stats?.WHIP)
  const home_pitcher_fip = safe_fixed(home_pitcher_stats?.FIP)
  const home_pitcher_obp = safe_fixed(home_pitcher_stats?.OBP)
  const home_pitcher_ops = safe_fixed(home_pitcher_stats?.OPS)
  
  // home pitcher through 9 stats //
  const home_pitcher_k_9 = safe_fixed(home_pitcher_stats?.["K/9"])
  const home_pitcher_bb_9 = safe_fixed(home_pitcher_stats?.["BB/9"])
  const home_pitcher_h_9 = safe_fixed(home_pitcher_stats?.["H/9"])
  const home_pitcher_hr_9 = safe_fixed(home_pitcher_stats?.["HR/9"])
  const home_pitcher_rs_9 = safe_fixed(home_pitcher_stats?.["RS/9"])
  
  // home pitcher plate discipline stats //
  const home_pitcher_zone_perc = safe_percent(home_pitcher_stats?.["Zone%"])
  const home_pitcher_f_strike_perc = safe_percent(home_pitcher_stats?.["F-Strike%"])
  const home_pitcher_chase_perc = safe_percent(home_pitcher_stats?.["O-Swing%"])
  const home_pitcher_whiff_perc = safe_percent(home_pitcher_stats?.["SwStr%"])
  const home_pitcher_contact_perc = safe_percent(home_pitcher_stats?.["Contact%"])
  
  // home pitcher contact stats //
  const home_pitcher_gb_perc = safe_percent(home_pitcher_stats?.["GB%"])
  const home_pitcher_fb_perc = safe_percent(home_pitcher_stats?.["FB%"])
  const home_pitcher_ld_perc = safe_percent(home_pitcher_stats?.["LD%"])
  const home_pitcher_hardhit_perc = safe_percent(home_pitcher_stats?.["HardHit%"])
  const home_pitcher_barrel_perc = safe_percent(home_pitcher_stats?.["Barrel%"])
  
  
  // away pitcher expected stats //
  const away_pitcher_xba = safe_fixed(away_pitcher_stats?.xBA)
  const away_pitcher_xslg = safe_fixed(away_pitcher_stats?.xSLG)
  const away_pitcher_xiso = safe_fixed(away_pitcher_stats?.xISO)
  const away_pitcher_xwoba = safe_fixed(away_pitcher_stats?.xWOBA)
  const away_pitcher_xbabip = safe_fixed(away_pitcher_stats?.xBABIP)
  
  // away pitcher stats //
  const away_pitcher_era = safe_fixed(away_pitcher_stats?.ERA)
  const away_pitcher_whip = safe_fixed(away_pitcher_stats?.WHIP)
  const away_pitcher_fip = safe_fixed(away_pitcher_stats?.FIP)
  const away_pitcher_obp = safe_fixed(away_pitcher_stats?.OBP)
  const away_pitcher_ops = safe_fixed(away_pitcher_stats?.OPS)
  
  // away pitcher through 9 stats //
  const away_pitcher_k_9 = safe_fixed(away_pitcher_stats?.["K/9"])
  const away_pitcher_bb_9 = safe_fixed(away_pitcher_stats?.["BB/9"])
  const away_pitcher_h_9 = safe_fixed(away_pitcher_stats?.["H/9"])
  const away_pitcher_hr_9 = safe_fixed(away_pitcher_stats?.["HR/9"])
  const away_pitcher_rs_9 = safe_fixed(away_pitcher_stats?.["RS/9"])
  
  // away pitcher plate discipline stats //
  const away_pitcher_zone_perc = safe_percent(away_pitcher_stats?.["Zone%"])
  const away_pitcher_f_strike_perc = safe_percent(away_pitcher_stats?.["F-Strike%"])
  const away_pitcher_chase_perc = safe_percent(away_pitcher_stats?.["O-Swing%"])
  const away_pitcher_whiff_perc = safe_percent(away_pitcher_stats?.["SwStr%"])
  const away_pitcher_contact_perc = safe_percent(away_pitcher_stats?.["Contact%"])
  
  // away pitcher contact stats //
  const away_pitcher_gb_perc = safe_percent(away_pitcher_stats?.["GB%"])
  const away_pitcher_fb_perc = safe_percent(away_pitcher_stats?.["FB%"])
  const away_pitcher_ld_perc = safe_percent(away_pitcher_stats?.["LD%"])
  const away_pitcher_hardhit_perc = safe_percent(away_pitcher_stats?.["HardHit%"])
  const away_pitcher_barrel_perc = safe_percent(away_pitcher_stats?.["Barrel%"])


  return (
  <div
    style={{
      display: "flex",
      justifyContent: "space-between",
      alignItems: "flex-start",
      width: "100%",
      marginTop: "20px"
    }}
    >
      {/* LEFT COLUMN — Home Pitch Mix */}
      <div style={{ width: "30%", textAlign: "center" }}>
        <h3>{matchup.Home_Pitcher} Pitch Usage </h3>

        {home_pitcher_usage_list_filtered.map((u, i) => (
          <div 
            key={i} 
            style={{ 
              display: "flex", 
              alignItems: "center", 
              marginBottom: "8px" 
            }}
          >
            <div style={{ width: "150px" }}>{u.pitch}</div>

            <div 
              style={{ 
                height: "12px",
                width: "200px",
                backgroundColor: "#eee",
                marginLeft: "10px",
                position: "relative"
              }}
            >
              <div
                style={{
                  height: "100%",
                  width: `${u.value * 2}px`,
                  backgroundColor: "steelblue"
                }}
              />
            </div>

            <div style={{ marginLeft: "10px" }}>{u.value}%</div>
          </div>
        ))}
        <h3> {matchup.Home_Pitcher} {last_year} - {current_year} Stats</h3>
        <h3> Expected </h3>
        <div>xBA - {home_pitcher_xba}</div>
        <div>xSLG - {home_pitcher_xslg}</div>
        <div>xISO - {home_pitcher_xiso}</div>
        <div>xWOBA - {home_pitcher_xwoba}</div>
        <div>xBABIP - {home_pitcher_xbabip}</div>

        <h3> Standard </h3>
        <div>ERA - {home_pitcher_era}</div>
        <div>WHIP - {home_pitcher_whip}</div>
        <div>FIP - {home_pitcher_fip}</div>
        <div>OBP - {home_pitcher_obp}</div>
        <div>OPS - {home_pitcher_ops}</div>
        
        <h3> / 9 </h3>
        <div>K/9 - {home_pitcher_k_9}</div>
        <div>BB/9 - {home_pitcher_bb_9}</div>
        <div>H/9 - {home_pitcher_h_9}</div>
        <div>HR/9 - {home_pitcher_hr_9}</div>
        <div>RS/9 - {home_pitcher_rs_9}</div>

        <h3> Plate Discipline </h3>
        <div>Strike Zone % - {home_pitcher_zone_perc}</div>
        <div>F-Strike % - {home_pitcher_f_strike_perc}</div>
        <div>Chase % - {home_pitcher_chase_perc}</div>
        <div>Whiff % - {home_pitcher_whiff_perc}</div>
        <div>Contact % - {home_pitcher_contact_perc}</div>

        <h3> Contact </h3>
        <div>GB % - {home_pitcher_gb_perc}</div>
        <div>FB % - {home_pitcher_fb_perc}</div>
        <div>LD % - {home_pitcher_ld_perc}</div>
        <div>Hard Hit % - {home_pitcher_hardhit_perc}</div>
        <div>Barrel % - {home_pitcher_barrel_perc}</div>
      </div>

      {/* CENTER COLUMN — whatever you want */}
      <div style={{ width: "30%", textAlign: "center" }}>
        <h3>Starting Pitchers Breakdown</h3>

        <div 
          style={{ 
            display: "flex", 
            justifyContent: "space-between", 
            fontSize: "32px", 
            fontWeight: 700,
            marginTop: "10px"
          }}
        >
          <span style={{ color: compare_stat_general_color(matchup.Home_Pitcher_Score, matchup.Away_Pitcher_Score) }}>
            {matchup.Home_Pitcher_Score}
          </span>

          <span style={{ color: compare_stat_general_color(matchup.Away_Pitcher_Score, matchup.Home_Pitcher_Score) }}>
            {matchup.Away_Pitcher_Score}
          </span>
        </div>
      </div>


      {/* RIGHT COLUMN — Away Pitch Mix */}
      <div style={{ width: "30%", textAlign: "center" }}>
        <h3>{matchup.Away_Pitcher} Pitch Usage </h3>

        {away_pitcher_usage_list_filtered.map((u, i) => (
          <div 
            key={i} 
            style={{ 
              display: "flex", 
              alignItems: "center", 
              marginBottom: "8px" 
            }}
          >
            <div style={{ width: "150px" }}>{u.pitch}</div>

            <div 
              style={{ 
                height: "12px",
                width: "200px",
                backgroundColor: "#eee",
                marginLeft: "10px",
                position: "relative"
              }}
            >
              <div
                style={{
                  height: "100%",
                  width: `${u.value * 2}px`,
                  backgroundColor: "crimson",
                  marginLeft: "auto"
                }}
              />
            </div>

            <div style={{ marginLeft: "10px" }}>{u.value}%</div>
          </div>
        ))}
        <h3> {matchup.Away_Pitcher} {last_year} - {current_year} Stats</h3>
        <h3> Expected </h3>
        <div>xBA - {away_pitcher_xba}</div>
        <div>xSLG - {away_pitcher_xslg}</div>
        <div>xISO - {away_pitcher_xiso}</div>
        <div>xWOBA - {away_pitcher_xwoba}</div>
        <div>xBABIP - {away_pitcher_xbabip}</div>
        
        <h3> Standard </h3>
        <div>ERA - {away_pitcher_era}</div>
        <div>WHIP - {away_pitcher_whip}</div>
        <div>FIP - {away_pitcher_fip}</div>
        <div>OBP - {away_pitcher_obp}</div>
        <div>OPS - {away_pitcher_ops}</div>
        
        <h3> / 9 </h3>
        <div>K/9 - {away_pitcher_k_9}</div>
        <div>BB/9 - {away_pitcher_bb_9}</div>
        <div>H/9 - {away_pitcher_h_9}</div>
        <div>HR/9 - {away_pitcher_hr_9}</div>
        <div>RS/9 - {away_pitcher_rs_9}</div>
        
        <h3> Plate Discipline </h3>
        <div>Strike Zone % - {away_pitcher_zone_perc}</div>
        <div>F-Strike % - {away_pitcher_f_strike_perc}</div>
        <div>Chase % - {away_pitcher_chase_perc}</div>
        <div>Whiff % - {away_pitcher_whiff_perc}</div>
        <div>Contact % - {away_pitcher_contact_perc}</div>
        
        <h3> Contact </h3>
        <div>GB % - {away_pitcher_gb_perc}</div>
        <div>FB % - {away_pitcher_fb_perc}</div>
        <div>LD % - {away_pitcher_ld_perc}</div>
        <div>Hard Hit % - {away_pitcher_hardhit_perc}</div>
        <div>Barrel % - {away_pitcher_barrel_perc}</div>
      </div>
    </div>
  );



}
