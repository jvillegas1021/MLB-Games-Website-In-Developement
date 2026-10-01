import { mlb_team_colors } from "../mlb_colors.js";

import {
  prediction_status_color,
  edge_color,
  era_color,
  win_loss_color,
  probability_color
} from "../utility_functions/color_functions.js";

import { 
  bet_icon,
  money_icon
 } from "../utility_functions/icon_functions.js";

import WinProbBar from "./WinProbBar.jsx";


export default function MatchupCard({ matchup }) {
    const home_team_color = mlb_team_colors[matchup.Home_Team];
    const away_team_color = mlb_team_colors[matchup.Away_Team];

    const prediction_color = prediction_status_color(matchup.Prediction_Status);

    const home_edge_color_current = edge_color(matchup.Home_Team_Current_Edge);
    const away_edge_color_current = edge_color(matchup.Away_Team_Current_Edge);
    const home_edge_color_open = edge_color(matchup.Home_Team_Open_Edge);
    const away_edge_color_open = edge_color(matchup.Away_Team_Open_Edge);

    const home_era_color = era_color(matchup.Home_Pitcher_ERA);
    const away_era_color = era_color(matchup.Away_Pitcher_ERA);

    const home_pitcher_record_color = win_loss_color(matchup.Home_Pitcher_Wins, matchup.Home_Pitcher_Losses);
    const away_pitcher_record_color = win_loss_color(matchup.Away_Pitcher_Wins, matchup.Away_Pitcher_Losses);

    const win_probability_color = probability_color(matchup.Win_Probability);
    const predicted_winner_color = mlb_team_colors[matchup.Predicted_Winner];
    const best_bet_color = mlb_team_colors[matchup.Bet_Team_Current];

    const home_bet_icon_current = bet_icon(matchup.home_close_odds, matchup.away_close_odds);
    const away_bet_icon_current = bet_icon(matchup.away_close_odds, matchup.home_close_odds);
    const home_bet_icon_open = bet_icon(matchup.home_open_odds, matchup.away_open_odds);
    const away_bet_icon_open = bet_icon(matchup.away_open_odds, matchup.home_open_odds);
    
    const home_bet_icon_model = bet_icon(matchup.Home_Team_Model_Odds, matchup.Away_Team_Model_Odds);
    const away_bet_icon_model = bet_icon(matchup.Away_Team_Model_Odds, matchup.Home_Team_Model_Odds);

    const home_money_icon = money_icon(matchup.Home_Team, matchup.Predicted_Winner, matchup.Place_Bet);
    const away_money_icon = money_icon(matchup.Away_Team, matchup.Predicted_Winner, matchup.Place_Bet);
    const home_money_icon_open = money_icon(matchup.Home_Team, matchup.Predicted_Winner, matchup.Place_Bet_Open);
    const away_money_icon_open = money_icon(matchup.Away_Team, matchup.Predicted_Winner, matchup.Place_Bet_Open);
    

    return (
      <div 
        className="matchup-card-wrapper"
        style={{
          padding: '20px',
          margin: '0 auto',
          borderBottom: '1px solid #ccc',
          width: '90%',
          minHeight: '300px',
          boxSizing: 'border-box'
        }}
        >

        {/* 3-column layout */}
        <div 
          className="matchup-card-columns"
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            width: '100%'
          }}
        >

          {/* LEFT: Away team */}
          <div className="matchup-card-column" style={{ width: '30%', textAlign: 'center' }}>
            <img
              src={`/mlb_logos/${matchup.Away_Team}.png`}
              alt={matchup.Away_Team}
              style={{ width: '80px' }}
            />
            <div className="team-title" style={{ fontSize: "28px", fontWeight: 700, marginTop: 4, color: away_team_color }}>
              {matchup.Away_Team}
            </div>
            <div style={{ fontWeight: 600}}>
              ({matchup.Away_Team_Wins} - {matchup.Away_Team_Losses})
            </div>
            <div className="ha-label">🚗</div>
            <div style={{ fontWeight: 660, marginTop: 4}}>
              {matchup.Away_Pitcher} ({matchup.Away_Pitcher_Hand})
            </div>
            <div>
              <span style={{ fontWeight: 600}}>W-L: </span>
              <span style={{ fontWeight: 600, color: away_pitcher_record_color }}>
                {matchup.Away_Pitcher_Wins} - {matchup.Away_Pitcher_Losses}
              </span>
            </div>
            <div>
              <span style={{ fontWeight: 600}}>ERA: </span>
              <span style={{ fontWeight: 600, color: away_era_color }}>
                {Number(matchup.Away_Pitcher_ERA).toFixed(2)}
              </span>
            </div>
            <div>
              <span style={{ fontWeight: 600}}>Model Odds: </span>
              <span style={{ fontWeight: 600}}>
                {matchup.Away_Team_Model_Odds}
              </span> {away_bet_icon_model}
            </div>
            <div>
              <span style={{ fontWeight: 600}}>Open Odds: </span>
              <span style={{ fontWeight: 600}}>
                {matchup.away_open_odds}
              </span> {away_bet_icon_open}
            </div>
            <div>
              <span style={{ fontWeight: 600}}>Open Edge: </span>
              <span style={{ fontWeight: 600, color: away_edge_color_open }}>
                {matchup.Away_Team_Open_Edge}
              </span>   {away_money_icon_open}
            </div>
            <div>
              <span style={{ fontWeight: 600}}>Current Odds: </span>
              <span style={{ fontWeight: 600}}>
                {matchup.away_close_odds}
              </span> {away_bet_icon_current}
            </div>
            <div>
              <span style={{ fontWeight: 600}}>Current Edge: </span>
              <span style={{ fontWeight: 600, color: away_edge_color_current }}>
                {matchup.Away_Team_Current_Edge}
              </span>   {away_money_icon}
            </div>
          </div>

          {/* CENTER: Game info */}
          <div className="matchup-card-column matchup-card-center" style={{ width: '40%', fontWeight: 600 }}>
            <p>Game ID: {matchup.Game_ID}</p>
            <p>Game Date: {matchup.Game_Date}</p>
            <p>Game Time: {matchup.Game_Time}</p>
            <p>Ball Park: {matchup.Game_Venue}</p>
            <p>Day / Night: {matchup.Day_Night === "day" ? "☀️" : "🌑"}</p>
            <p>Over / Under: {matchup.over_under}</p>
            <p>Moneyline: {matchup.details}</p>
            
            {/* NEW: Opening Line Engine Track */}
            <p style={{ display: 'flex', alignItems: 'center', margin: '4px 0' }}> 
              <span style={{ fontWeight: 600 }}>Open Odds Bet: </span>
              <span className="team-title" style={{ fontWeight: 600, color: best_bet_color, marginLeft: '4px' }}>
                {matchup.Bet_Team_Open}
              </span>
              {matchup.Bet_Team_Open !== "No Bet" && (
                <img
                  src={`/mlb_logos/${matchup.Bet_Team_Open}.png`}
                  onError={(e) => { e.target.src = "/mlb_logos/MLB-Logo.png"; }}
                  alt={matchup.Bet_Team_Open}
                  style={{ width: '30px', height: '30px', marginLeft: '8px', objectFit: 'contain' }} // Logo Shrunk
                />
              )}
            </p>

            {/* UPDATED: Current Line Engine Track */}
            <p style={{ display: 'flex', alignItems: 'center', margin: '4px 0' }}> 
              <span style={{ fontWeight: 600 }}>Current Odds Bet: </span>
              <span className="team-title" style={{ fontWeight: 600, color: best_bet_color, marginLeft: '4px' }}>
                {matchup.Bet_Team_Current}
              </span>
              {matchup.Bet_Team_Current !== "No Bet" && (
                <img
                  src={`/mlb_logos/${matchup.Bet_Team_Current}.png`}
                  onError={(e) => { e.target.src = "/mlb_logos/MLB-Logo.png"; }}
                  alt={matchup.Bet_Team_Current}
                  style={{ width: '30px', height: '30px', marginLeft: '8px', objectFit: 'contain' }} // Logo Shrunk
                />
              )}
            </p>

            {/* Predicted Winner Platform */}
            <p style={{ display: 'flex', alignItems: 'center', margin: '8px 0 4px 0', borderTop: '1px solid #eee', paddingTop: '4px' }}>
              <span style={{ fontWeight: 600 }}>Predicted Winner: </span>
              <span className="team-title" style={{ fontWeight: 600, color: predicted_winner_color, marginLeft: '4px' }}>
                {matchup.Predicted_Winner}
              </span>
              <img
                src={`/mlb_logos/${matchup.Predicted_Winner}.png`}
                onError={(e) => { e.target.src = "/mlb_logos/MLB-Logo.png"; }}
                alt={matchup.Predicted_Winner}
                style={{ width: '30px', height: '30px', marginLeft: '8px', objectFit: 'contain' }} // Logo Shrunk
              />
            </p>

            <p>
              <span style={{ fontWeight: 600 }}>Prediction Confidence : </span>{" "}
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
              dividerIcon='💎'
            />

            <p style={{ fontWeight: 'bold', color: prediction_color, marginTop: '8px' }}>
              {matchup.Prediction_Status}
            </p>
          </div>

          {/* RIGHT: Home team */}
        <div className="matchup-card-column" style={{ width: '30%', textAlign: 'center' }}>

            <img
              src={`/mlb_logos/${matchup.Home_Team}.png`}
              alt={matchup.Home_Team}
              style={{ width: '80px' }}
            />
            <div className="team-title" style={{ fontSize: "28px", fontWeight: 700, marginTop: 4, color: home_team_color }}>
              {matchup.Home_Team}
            </div>
            <div style={{ fontWeight: 600}}>
              ({matchup.Home_Team_Wins} - {matchup.Home_Team_Losses})
            </div>
            <div className="ha-label">🏠</div>
            <div style={{fontWeight: 660, marginTop: 4}}>
              {matchup.Home_Pitcher} ({matchup.Home_Pitcher_Hand})
            </div>
            <div>
              <span style={{ fontWeight: 600}}>W-L: </span>
              <span style={{ fontWeight: 600, color: home_pitcher_record_color }}>{matchup.Home_Pitcher_Wins} - {matchup.Home_Pitcher_Losses}</span>
            </div>
            <div>
              <span style={{ fontWeight: 600}}>ERA: </span>
              <span style={{ fontWeight: 600, color: home_era_color }}> {Number(matchup.Home_Pitcher_ERA).toFixed(2)}</span>
            </div>
            <div>
              <span style={{ fontWeight: 600}}>Model Odds: </span>
              <span style={{ fontWeight: 600}}>
                {matchup.Home_Team_Model_Odds}
              </span> {home_bet_icon_model}
            </div>
            <div>
              <span style={{ fontWeight: 600}}>Open Odds: </span>
              <span style={{ fontWeight: 600}}>
                {matchup.home_open_odds}
              </span> {home_bet_icon_open}
            </div>
            <div>
              <span style={{ fontWeight: 600}}>Open Edge: </span>
              <span style={{ fontWeight: 600, color: home_edge_color_open }}>
                {matchup.Home_Team_Open_Edge}
              </span>   {home_money_icon_open}
            </div>
            <div>
              <span style={{ fontWeight: 600}}>Current Odds: </span>
              <span style={{ fontWeight: 600}}>
                {matchup.home_close_odds}
              </span> {home_bet_icon_current}
            </div>
            <div>
              <span style={{ fontWeight: 600}}>Current Edge: </span>
              <span style={{ fontWeight: 600, color: home_edge_color_current }}>
                {matchup.Home_Team_Current_Edge}
              </span>   {home_money_icon}
            </div>
          </div>
        </div>
      </div>
    )
}
