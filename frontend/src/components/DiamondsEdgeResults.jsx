import "./DiamondsEdgeResults.css";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  LabelList
} from "recharts";
export default function DiamondsEdgeResults({ mlb_games_prediction_results }) {

    const prediction_results = mlb_games_prediction_results?.[0];

    if (!prediction_results) {
        return <div>Loading...</div>;
    }

    const winProbData = [
    { range: "<48%", accuracy: prediction_results.Win_Prob_Under_48 },
    { range: "48-50%", accuracy: prediction_results.Win_Prob_48_50 },
    { range: "50-52%", accuracy: prediction_results.Win_Prob_50_52 },
    { range: "52-54%", accuracy: prediction_results.Win_Prob_52_54 },
    { range: "54-56%", accuracy: prediction_results.Win_Prob_54_56 },
    { range: "56-58%", accuracy: prediction_results.Win_Prob_56_58 },
    { range: "58-60%", accuracy: prediction_results.Win_Prob_58_60 },
    { range: "60-62%", accuracy: prediction_results.Win_Prob_60_62 },
    { range: "62-65%", accuracy: prediction_results.Win_Prob_62_65 },
    { range: "65%+", accuracy: prediction_results["Win_Prob_65+"] }
    ];

    return (
    <div>
        {/* Top Metrics Banner */}
        <div className="stats-grid">
        <div className="stat-card">
            <div className="stat-title">Overall Accuracy</div>
            <div 
            className="stat-value"
            style={{ color: prediction_results.overall_accuracy < 50 ? "#ef4444" : "#22c55e" }} // Dark-mode friendly red/green hex
            >
            {prediction_results.overall_accuracy} %
            </div>
        </div>
        </div>

        {/* Chart Section */}
        <div style={{ marginTop: "40px" }}>
        <h2>Accuracy By Prediction Confidence</h2>

        <ResponsiveContainer width="100%" height={300}>
            <BarChart data={winProbData} margin={{ top: 25, right: 10, left: -20, bottom: 5 }}>
            
            {/* 1. Added stroke labels to axis lines so labels aren't hidden by a dark canvas */}
            <XAxis dataKey="range" stroke="#94a3b8" tick={{ fill: '#94a3b8' }} />
            <YAxis domain={[40, 80]} tickFormatter={(value) => `${value}%`} stroke="#94a3b8" tick={{ fill: '#94a3b8' }} /> 
            
            {/* 2. Styled tooltip container background for dark mode styling */}
            <Tooltip 
            formatter={(value) => [`${value}%`, "Accuracy"]} 
            contentStyle={{ backgroundColor: '#1e293b', borderColor: '#475569', color: '#f8fafc' }}
            />

            <Bar dataKey="accuracy" fill="#22c55e"> {/* Brighter vivid green for dark UI view grids */}
                <LabelList
                dataKey="accuracy"
                position="top" 
                fill="#f8fafc" // 3. CHANGED TO OFF-WHITE: Visible on slate/black/dark-gray canvases!
                fontWeight={600}
                formatter={(value) => `${Math.round(value)}%`} 
                />
            </Bar>
            </BarChart>
        </ResponsiveContainer>
        </div>
    </div>
    );
}
