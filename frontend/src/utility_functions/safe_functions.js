export function safe_fixed(value) {
  if (value === undefined || value === null || isNaN(value)) return "N/A"
  return Number(value).toFixed(4)
}

export function safe_percent(value) {
  if (value === undefined || value === null || isNaN(value)) return "N/A"
  return (value * 100).toFixed(2)
}
