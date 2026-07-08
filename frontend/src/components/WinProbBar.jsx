export default function WinProbBar({ probability, homeColor, awayColor, winner, homeTeam }) {
    if (winner === "No Prediction") {
      return (
        <div style={{
          width: "100%",
          height: "20px",
          backgroundColor: "gray80",
          border: "1px solid gray40",
          borderRadius: "4px"
        }} />
      );
    }
  
    const prob = probability / 100;
  
    const fillX = winner === homeTeam ? prob : 1 - prob;
  
    return (
      <div style={{
        width: "100%",
        height: "20px",
        position: "relative",
        border: "1px solid gray40",
        borderRadius: "4px",
        overflow: "hidden"
      }}>
        <div style={{
          position: "absolute",
          left: 0,
          top: 0,
          bottom: 0,
          width: "100%",
          backgroundColor: homeColor
        }} />
  
        <div style={{
          position: "absolute",
          left: `${fillX * 100}%`,
          top: 0,
          bottom: 0,
          width: `${(1 - fillX) * 100}%`,
          backgroundColor: awayColor
        }} />
  
        <div style={{
          position: "absolute",
          left: `${fillX * 100}%`,
          top: 0,
          bottom: 0,
          width: "2px",
          backgroundColor: "white"
        }} />
      </div>
    );
  }
  