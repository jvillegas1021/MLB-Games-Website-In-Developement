import { compare_stat_low_color, compare_stat_high_color, compare_stat_general_color } from "../utility_functions/color_functions.js";
import { safe_fixed, safe_percent } from "../utility_functions/safe_functions.js";
import { mlb_team_colors } from "../mlb_colors.js";
import { MirrorBar, ScoreBar } from "../utility_functions/chart_functions.jsx";


export default function MatchupScoringBreakdown({ matchup }) {

  const home_team_color = mlb_team_colors[matchup.Home_Team];
  const away_team_color = mlb_team_colors[matchup.Away_Team];

  return (
  <div className="matchup-scoring-details-card" 
       style={{ display: "flex", justifyContent: "center" }}>

    <div style={{ width: "70%", margin: "0 auto" }}>

        {/* 1 — Pitcher Control Score */}
        <h3 style={{ marginTop: "25px" }}>Pitcher Control Score</h3>
        <ScoreBar 
            awayValue={matchup.Away_pitcher_control}
            homeValue={matchup.Home_pitcher_control}
            awayColor={away_team_color}
            homeColor={home_team_color}
            dividerIcon='🎯'
        />

        {/* 5 — Batting Discipline Score */}
        <h3 style={{ marginTop: "25px" }}>Batting Discipline Score</h3>
        <ScoreBar 
            awayValue={matchup.Away_batting_discipline}
            homeValue={matchup.Home_batting_discipline}
            awayColor={away_team_color}
            homeColor={home_team_color}
            dividerIcon='⚖️'
        />
      
        {/* 3 — Pitcher Contact Score */}
        <h3 style={{ marginTop: "25px" }}>Pitcher Contact Score</h3>
        <ScoreBar 
            awayValue={matchup.Away_pitcher_contact}
            homeValue={matchup.Home_pitcher_contact}
            awayColor={away_team_color}
            homeColor={home_team_color}
            dividerIcon='🛡️'
        />

        {/* 5 — Batting Contact Score */}
        <h3 style={{ marginTop: "25px" }}>Batting Contact Score</h3>
        <ScoreBar 
            awayValue={matchup.Away_batting_impact}
            homeValue={matchup.Home_batting_impact}
            awayColor={away_team_color}
            homeColor={home_team_color}
            dividerIcon='💥'
        />

        {/* 4 — Pitcher Expeceted Score */}
        <h3 style={{ marginTop: "25px" }}>Pitcher Expected Results Score</h3>
        <ScoreBar 
            awayValue={matchup.Away_pitcher_expected}
            homeValue={matchup.Home_pitcher_expected}
            awayColor={away_team_color}
            homeColor={home_team_color}
            dividerIcon='📉'
        />

        {/* 5 — Batting Expected Score */}
        <h3 style={{ marginTop: "25px" }}>Batting Expected Results Score</h3>
        <ScoreBar 
            awayValue={matchup.Away_batting_expected}
            homeValue={matchup.Home_batting_expected}
            awayColor={away_team_color}
            homeColor={home_team_color}
            dividerIcon='📈'
        />

        
        </div>
  </div>
);

}
