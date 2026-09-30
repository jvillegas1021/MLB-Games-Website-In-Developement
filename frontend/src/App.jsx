import reactLogo from './assets/react.svg';
import viteLogo from './assets/vite.svg';
import heroImg from './assets/hero.png';
import { useEffect, useState } from 'react';
import MatchupCard from "./components/MatchupCard.jsx";
import MatchupScoringBreakdown from "./components/MatchupScoringBreakdown.jsx"
import DiamondsEdgeResults from './components/DiamondsEdgeResults.jsx';

import './App.css';

function App() {
  const [matchups, setMatchups] = useState([]);

  useEffect(() => {
  fetch('https://mlb-games-website.onrender.com/mlb_matchup_card', {
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


  const [mlb_games_prediction_results, setMLBGamesPredictionResults] = useState([])

  useEffect(() => {
    fetch('https://mlb-games-website.onrender.com/diamonds_edge_results', {
      headers: {'x-api-key': 'mlb_games_api_key'},
    })
    .then((res) => {
      console.log("STATUS:", res.status);
      return res.json();
    })
    .then((data) => {
      console.log("DATA:", data);
      setMLBGamesPredictionResults(data.mlb_games_prediction_results);
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
      <button onClick={() => setTab("details")}>Scoring Breakdown</button>
      <button onClick={() => setTab("about")}>Diamond's Edge</button>
    </div>

    {/* MATCHUPS TAB */}
    {tab === "matchups" && (
      <>
        <img 
        src="/website_images/Diamonds_Edge_Logo_Transparent.png"
        alt="MLB Logo"
        style={{ width: "200px", marginBottom: "20px" }}
        />
        <h1 className="shiny">The Diamond's Edge</h1>

        {matchups.map((m, i) => (
          <MatchupCard key={i} matchup={m} />
        ))}
      </>
    )}

    {/* MATCHUP DETAILS */}
    {tab === "details" && (
      <div>
        <img 
        src="/website_images/Diamonds_Edge_Logo_Transparent.png"
        alt="MLB Logo"
        style={{ width: "200px", marginBottom: "20px" }}
        />
        <h1>Scoring Breakdown</h1>

        {/* Dropdown */}
        <select
          onChange={(e) => setSelectedMatchup(matchups[e.target.value])}
          style={{ padding: "10px", fontSize: "16px", marginBottom: "20px" }}
        >
          <option value="">Select a matchup...</option>

          {matchups.map((m, i) => (
            <option key={i} value={i}>
              {m.Away_Team} vs {m.Home_Team}
            </option>
          ))}
        </select>

        {/* Show details only when selected */}
        {selectedMatchup && (
          <>
            <MatchupCard matchup={selectedMatchup} />

            {/* Extra info section */}
            <MatchupScoringBreakdown 
            matchup={selectedMatchup}
            />
          </>
        )}



      </div>
    )}

    {/* ABOUT TAB */}
    {tab === "about" && (
      <div>
        <img 
        src="/website_images/Diamonds_Edge_Logo_Transparent.png"
        alt="MLB Logo"
        style={{ width: "200px", marginBottom: "20px" }}
        />
        <DiamondsEdgeResults
        mlb_games_prediction_results={mlb_games_prediction_results}
        />
      </div>
    )}

  </div>
);

}


export default App;
