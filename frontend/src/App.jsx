import reactLogo from './assets/react.svg';
import viteLogo from './assets/vite.svg';
import heroImg from './assets/hero.png';
import { useEffect, useState } from 'react';
import MatchupCard from "./components/MatchupCard.jsx";
import MatchupPitcherDetails from "./components/MatchupPitcherDetails.jsx"

import './App.css';

function App() {
  const [matchups, setMatchups] = useState([]);

  useEffect(() => {
  fetch('https://mlb-games-website.onrender.com/matchups', {
    headers: { 'x-api-key': 'mlb_games_api_key' },
  })
    .then((res) => {
      console.log("STATUS:", res.status);
      return res.json();
    })
    .then((data) => {
      console.log("DATA:", data);
      setMatchups(data.matchups);
    })
    .catch(err => console.log("FETCH ERROR:", err));
  }, []);


  const [pitcher_stats, setPitcherStats] = useState([]);
  
  useEffect(() => {
  fetch('https://mlb-games-website.onrender.com/pitcher_stats', {
    headers: { 'x-api-key': 'mlb_games_api_key' },
  })
    .then((res) => {
      console.log("STATUS:", res.status);
      return res.json();
    })
    .then((data) => {
      console.log("DATA:", data);
      setPitcherStats(data.pitcher_stats);
    })
    .catch(err => console.log("FETCH ERROR:", err));
  }, []);

  const [pitcher_league_averages, setPitcherLeagueAverages] = useState([])

  useEffect(() => {
    fetch('https://mlb-games-website.onrender.com/pitcher_league_averages', {
      headers: {'x-api-key': 'mlb_games_api_kep'},
    })
    .then((data) => {
      console.log("DATA:", data);
      setPitcherLeagueAverages(data.pitcher_league_averages);
    })
    .catch(err => console.log("FETCH ERROR:", err));
  }, []);

  const [tab, setTab] = useState("matchups");
  const [selectedMatchup, setSelectedMatchup] = useState(null);


  return (
  <div style={{
    width: '100vw',
    minHeight: '100vh',
    padding: '20px',
    boxSizing: 'border-box',
    margin: 0
  }}>

    {/* TAB BUTTONS */}
    <div style={{ display: "flex", gap: "20px", marginBottom: "20px" }}>
      <button onClick={() => setTab("matchups")}>Matchups</button>
      <button onClick={() => setTab("details")}>Pitcher Details</button>
      <button onClick={() => setTab("about")}>About Model</button>
    </div>

    {/* MATCHUPS TAB */}
    {tab === "matchups" && (
      <>
        <h1>MLB Matchups</h1>
        {matchups.map((m, i) => (
          <MatchupCard key={i} matchup={m} />
        ))}
      </>
    )}

    {/* MATCHUP DETAILS */}
    {tab === "details" && (
      <div>
        <h1>Matchup Pitcher Details</h1>

        {/* Dropdown */}
        <select
          onChange={(e) => setSelectedMatchup(matchups[e.target.value])}
          style={{ padding: "10px", fontSize: "16px", marginBottom: "20px" }}
        >
          <option value="">Select a matchup...</option>

          {matchups.map((m, i) => (
            <option key={i} value={i}>
              {m.Home_Team} vs {m.Away_Team}
            </option>
          ))}
        </select>

        {/* Show details only when selected */}
        {selectedMatchup && (
          <>
            <MatchupCard matchup={selectedMatchup} />

            {/* Extra info section */}
            <MatchupPitcherDetails 
            matchup={selectedMatchup}
            pitcher_stats={pitcher_stats} />
          </>
        )}



      </div>
    )}

    {/* ABOUT TAB */}
    {tab === "about" && (
      <div>
        <h1>About the Model</h1>
        <p>Explain your matchup engine, probabilities, edges, etc.</p>
      </div>
    )}

  </div>
);

}


export default App;
