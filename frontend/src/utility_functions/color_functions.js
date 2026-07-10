
export function prediction_status_color(prediction_status) {
    if (prediction_status == 'Full Prediction') return "green";
    if (prediction_status == 'Not Hydrated Prediction') return "orange";
    return "red"
}

export function edge_color(edge) {
    if (edge > 0) return "green";
    if (edge < 0) return "red";
    return "grey";
  }

  export function era_color(era) {
    if (era <= 4.25) return "green";
    if (era > 4.25) return "red";
    return "black";
  }

  export function win_loss_color(wins, losses) {
    if ((wins - losses) > 0) return "green";
    if ((wins - losses) < 0) return "red";
    return "orange"
  }

export function probability_color(probability) {
  if (probability > 0) return "green";
  if (probability < 0) return "red";
  return "orange"
}

export function compare_stat_low_color(stat, compare_stat) {
  if (stat < compare_stat) return "green";
  if (stat > compare_stat) return "red";
  return "orange"
}