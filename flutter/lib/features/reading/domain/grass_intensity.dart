// Spec FR-4 — relative intensity within the current strip window (GitHub-style).
// Plan: domain-grass — [monthMax] is the max day total in that window (main 12-month strip or month sheet).

/// Returns 0 = no reading, 1..4 = light → strong from [dayTotal] / [monthMax].
int grassIntensityLevel(int dayTotal, int monthMax) {
  if (dayTotal <= 0) return 0;
  if (monthMax <= 0) return 1;
  final ratio = dayTotal / monthMax;
  if (ratio <= 0.25) return 1;
  if (ratio <= 0.5) return 2;
  if (ratio <= 0.75) return 3;
  return 4;
}

int monthMaxPages(Map<DateTime, int> dayTotals) {
  if (dayTotals.isEmpty) return 0;
  return dayTotals.values.reduce((a, b) => a > b ? a : b);
}
