import reactLogo from './assets/react.svg';
import viteLogo from './assets/vite.svg';
import heroImg from './assets/hero.png';
import { useEffect, useState } from 'react';
import MatchupCard from "./components/MatchupCard.jsx";
import MatchupScoringBreakdown from "./components/MatchupScoringBreakdown.jsx"
import DiamondsEdgeResults from './components/DiamondsEdgeResults.jsx';

import './App.css';

function App() {
  const getLocalDate = () => {
  const now = new Date();

  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');

  return `${year}-${month}-${day}`;
};

const [matchups, setMatchups] = useState([]);
const [selectedDate, setSelectedDate] = useState(getLocalDate());
  
  useEffect(() => {

    const url = selectedDate 
      ? `https://mlb-games-website.onrender.com/mlb_matchup_card?game_date=${selectedDate}`
      : 'https://mlb-games-website.onrender.com/mlb_matchup_card';

    fetch(url, {
      headers: { 'x-api-key': 'mlb_games_api_key' },
    })
      .then((res) => res.json())
      .then((data) => {
        console.log("MATCHUP DATA:", data);
        setMatchups(data.matchups || []);
      })
      .catch(err => console.log("FETCH ERROR:", err));
  }, [selectedDate]); // <-- Crucial: triggers the network request on calendar change


  const [mlb_games_prediction_results, setMLBGamesPredictionResults] = useState([]);

  useEffect(() => {
    fetch('https://mlb-games-website.onrender.com/diamonds_edge_results', {
      headers: {'x-api-key': 'mlb_games_api_key'},
    })
    .then((res) => res.json())
    .then((data) => {
      console.log("PRED DATA:", data);
      setMLBGamesPredictionResults(data.mlb_games_prediction_results || []);
    })
    .catch(err => console.log("FETCH ERROR:", err));
  }, []);

  const [tab, setTab] = useState("matchups");
  const [selectedMatchup, setSelectedMatchup] = useState(null);

  // Clear selected detail card if the base matchups array shifts due to a new date
  useEffect(() => {
    setSelectedMatchup(null);
  }, [matchups]);


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

        {/* GLOBAL DATE PICKER ELEMENT */}
        <div style={{ marginBottom: '25px', display: 'flex', alignItems: 'center', gap: '10px' }}>
          <label style={{ fontWeight: 'bold' }}>Game Date: </label>
          <input 
            type="date" 
            value={selectedDate}
            onChange={(e) => setSelectedDate(e.target.value)}
            style={{ padding: '8px', fontSize: '15px', borderRadius: '4px', border: '1px solid #ccc' }}
          />
        </div>


        {matchups.length > 0 ? (
          matchups.map((m, i) => (
            <MatchupCard key={i} matchup={m} />
          ))
        ) : (
          <p style={{ color: '#666' }}>No games on the card for this date.</p>
        )}
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

        {/* Dropdown - Now automatically shows games for whatever date is active! */}
        <select
          onChange={(e) => setSelectedMatchup(matchups[e.target.value])}
          value={matchups.indexOf(selectedMatchup)}
          style={{ padding: "10px", fontSize: "16px", marginBottom: "20px", width: "100%", maxWidth: "400px" }}
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
            <MatchupScoringBreakdown matchup={selectedMatchup} />
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
