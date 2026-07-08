import { mlb_team_colors } from "../mlb_colors.js";

import {
  prediction_status_color,
  edge_color,
  era_color,
  win_loss_color,
  probability_color
} from "../utility_functions/color_functions.js";

import { bet_icon } from "../utility_functions/icon_functions.js";
import WinProbBar from "./WinProbBar.jsx";


export default function MatchupCard({ matchup }) {
    const home_team_color = mlb_team_colors[matchup.Home_Team];
    const away_team_color = mlb_team_colors[matchup.Away_Team];

    const prediction_color = prediction_status_color(matchup.Prediction_Status);

    const home_edge_color = edge_color(matchup.Home_Team_Betting_Edge);
    const away_edge_color = edge_color(matchup.Away_Team_Betting_Edge);

    const home_era_color = era_color(matchup.Home_Pitcher_ERA);
    const away_era_color = era_color(matchup.Away_Pitcher_ERA);

    const home_pitcher_record_color = win_loss_color(matchup.Home_Pitcher_Wins, matchup.Home_Pitcher_Losses);
    const away_pitcher_record_color = win_loss_color(matchup.Away_Pitcher_Wins, matchup.Away_Pitcher_Losses);

    const win_probability_color = probability_color(matchup.Win_Probability);

    const home_bet_icon_espn = bet_icon(matchup.Home_Team_ESPN_Odds, matchup.Away_Team_ESPN_Odds);
    const away_bet_icon_espn = bet_icon(matchup.Away_Team_ESPN_Odds, matchup.Home_Team_ESPN_Odds);
    
    const home_bet_icon_model = bet_icon(matchup.Home_Team_Model_Odds, matchup.Away_Team_Model_Odds);
    const away_bet_icon_model = bet_icon(matchup.Away_Team_Model_Odds, matchup.Home_Team_Model_Odds);

    return (
      <div style={{
        padding: '20px',
        margin: '0 auto',
        borderBottom: '1px solid #ccc',
        width: '90%',
        minHeight: '300px',
        boxSizing: 'border-box'
      }}>
        {/* 3-column layout */}
        <div style={{
          display: 'flex',
          justifyContent: 'space-between',
          width: '100%'
        }}>
          {/* LEFT: Home team */}
          <div style={{ width: '30%', textAlign: 'center' }}>
            <img
              src={`/mlb_logos/${matchup.Home_Team}.png`}
              alt={matchup.Home_Team}
              style={{ width: '80px' }}
            />
            <div style={{ fontSize: "28px", fontWeight: 700, marginTop: 4, color: home_team_color }}>
              {matchup.Home_Team}
            </div>
            <div style={{ fontSize: "18px", fontWeight: 600, marginTop: 4, color: "#000" }}>
              Home
            </div>
            <div style={{fontWeight: 660, marginTop: 4, color: "black" }}>
              {matchup.Home_Pitcher} ({matchup.Home_Pitcher_Hand})
            </div>
            <div>
              <span style={{ fontWeight: 600, color: "#000" }}>W-L: </span>
              <span style={{ fontWeight: 600, color: home_pitcher_record_color }}>{matchup.Home_Pitcher_Wins} - {matchup.Home_Pitcher_Losses}</span>
            </div>
            <div>
              <span style={{ fontWeight: 600, color: "#000" }}>ERA: </span>
              <span style={{ fontWeight: 600, color: home_era_color }}> {matchup.Home_Pitcher_ERA}</span>
              </div>
            <div>
              <span style={{ fontWeight: 600, color: "#000" }}>ESPN Odds: </span>
              <span style={{ fontWeight: 600, color: "#000"}}>{matchup.Home_Team_ESPN_Odds}</span> {home_bet_icon_espn}
              </div>
            <div>
            <span style={{ fontWeight: 600, color: "#000" }}>Model Odds: </span>
            <span style={{ fontWeight: 600, color: "#000"}}>{matchup.Home_Team_Model_Odds}</span> {home_bet_icon_model}
              </div>
            <div>
              <span style={{ fontWeight: 600, color: "#000" }}>Edge: </span>
              <span style={{ fontWeight: 600, color: home_edge_color }}>
              {matchup.Home_Team_Betting_Edge} </span>
              </div>
          </div>

          {/* CENTER: Game info */}
          <div style={{ width: '40%', fontWeight: 600, color: "#000" }}>
            <p>Game Date: {matchup.Game_Date}</p>
            <p>Game Time: {matchup.Game_Time}</p>
            <p>Game Status: {matchup.Game_Status}</p>
            <p>Ball Park: {matchup.Game_Venue}</p>
            <p>
              Day / Night: {matchup.Day_Night === "day" ? "☀️" : "🌑"}
            </p>

            <p>
              <span style={{ fontWeight: 600, color: "#000" }}>Predicted Winner: </span>
              <span style={{fontWeight: 700, color: "#000"}}>{matchup.Predicted_Winner}</span>
              <img
                src={`/mlb_logos/${matchup.Predicted_Winner}.png`}
                onError={(e) => { e.target.src = "/mlb_logos/MLB-Logo.png"; }}
                alt={matchup.Predicted_Winner}
                style={{ width: '60px', marginLeft: '8px' }}
              />
            </p>

            <p>
              <span style={{ fontWeight: 600, color: '#000' }}>Win Probability: </span>{" "}
              <span style={{ fontWeight: 600, color: win_probability_color }}>
                {matchup.Win_Probability} %
              </span>
            </p>

            <WinProbBar
            probability={matchup.Win_Probability}
            homeColor={mlb_team_colors[matchup.Home_Team]}
            awayColor={mlb_team_colors[matchup.Away_Team]}
            winner={matchup.Predicted_Winner}
            homeTeam={matchup.Home_Team}
            awayTeam={matchup.Away_Team}
          />

            <p style={{ fontWeight: 'bold', color: prediction_color }}>
              {matchup.Prediction_Status}
            </p>


          </div>

          {/* RIGHT: Away team */}
        <div style={{ width: '30%', textAlign: 'center' }}>
          <img
            src={`/mlb_logos/${matchup.Away_Team}.png`}
            alt={matchup.Away_Team}
            style={{ width: '80px' }}
          />
          <div style={{ fontSize: "28px", fontWeight: 700, marginTop: 4, color: away_team_color }}>
            {matchup.Away_Team}
          </div>
          <div style={{ fontSize: "18px", fontWeight: 600, marginTop: 4, color: "#000" }}>
              Away
            </div>
          <div style={{ fontWeight: 660, marginTop: 4, color: "black" }}>
            {matchup.Away_Pitcher} ({matchup.Away_Pitcher_Hand})
          </div>
          <div>
            <span style={{ fontWeight: 600, color: "#000" }}>W-L: </span>
            <span style={{ fontWeight: 600, color: away_pitcher_record_color }}>
              {matchup.Away_Pitcher_Wins} - {matchup.Away_Pitcher_Losses}
            </span>
          </div>
          <div>
            <span style={{ fontWeight: 600, color: "#000" }}>ERA: </span>
            <span style={{ fontWeight: 600, color: away_era_color }}>
              {matchup.Away_Pitcher_ERA}
            </span>
          </div>
          <div>
            <span style={{ fontWeight: 600, color: "#000" }}>ESPN Odds: </span>
            <span style={{ fontWeight: 600, color: "#000"}}>
              {matchup.Away_Team_ESPN_Odds}
            </span> {away_bet_icon_espn}
          </div>
          <div>
            <span style={{ fontWeight: 600, color: "#000" }}>Model Odds: </span>
            <span style={{ fontWeight: 600, color: "#000"}}>
              {matchup.Away_Team_Model_Odds}
            </span> {away_bet_icon_model}
          </div>
          <div>
            <span style={{ fontWeight: 600, color: "#000" }}>Edge: </span>
            <span style={{ fontWeight: 600, color: away_edge_color }}>
              {matchup.Away_Team_Betting_Edge}
            </span>
            </div>
          </div>
        </div>
      </div>
    )
}