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

    const winProbData = [
    {
        range: "<48%",
        accuracy: prediction_results.Win_Prob_Under_48
    },
    {
        range: "48-50%",
        accuracy: prediction_results.Win_Prob_48_50
    },
    {
        range: "50-52%",
        accuracy: prediction_results.Win_Prob_50_52
    },
    {
        range: "52-54%",
        accuracy: prediction_results.Win_Prob_52_54
    },
    {
        range: "54-56%",
        accuracy: prediction_results.Win_Prob_54_56
    },
    {
        range: "56-58%",
        accuracy: prediction_results.Win_Prob_56_58
    },
    {
        range: "58-60%",
        accuracy: prediction_results.Win_Prob_58_60
    },
    {
        range: "60-62%",
        accuracy: prediction_results.Win_Prob_60_62 // Maps to your fixed R label!
    },
    {
        range: "62-65%",
        accuracy: prediction_results.Win_Prob_62_65
    },
    {
        range: "65%+",
        accuracy: prediction_results["Win_Prob_65+"]
    }
    ];

    if (!prediction_results) {
        return <div>Loading...</div>;
    }

    return (
        <div>

            {/* Top Metrics */}
            <div className="stats-grid">

                <div className="stat-card">
                    <div className="stat-title">Overall Accuracy</div>
                    <div 
                        className="stat-value"
                        style={{color:
                            prediction_results.overall_accuracy < 50
                            ? "red"
                            : "green"
                        }}
                        >
                        {prediction_results.overall_accuracy} %
                    </div>
                </div>

                <div className="stat-card">
                    <div className="stat-title">Betting Accuracy</div>
                    <div className="stat-value"
                        style={{color:
                            prediction_results.betting_accuracy < 50
                            ? "red"
                            : "green"
                        }}
                        >
                        {prediction_results.betting_accuracy}%
                    </div>
                </div>

                <div className="stat-card">
                    <div className="stat-title">Underdog Accuracy</div>
                    <div className="stat-value"
                        style={{color:
                            prediction_results.underdog_accuracy < 50
                            ? "red"
                            : "green"
                        }}
                        >
                        {prediction_results.underdog_accuracy}%
                    </div>
                </div>

                <div style={{ marginTop: "40px" }}>
                    <h2>Accuracy By Prediction Confidence</h2>

                    <ResponsiveContainer width="100%" height={300}>
                        <BarChart data={winProbData}>
                            <XAxis dataKey="range" />
                            <YAxis />
                            <Tooltip />

                            <Bar
                            dataKey="accuracy"
                            fill="#16a34a"
                            >
                            <LabelList
                                dataKey="accuracy"
                                position="inside"
                                fill="black"
                                formatter={(value) => Math.round(value) }
                            />
                            </Bar>
                        </BarChart>
                        </ResponsiveContainer>
                        ``
            </div>

        </div>
    </div>
    );
}
