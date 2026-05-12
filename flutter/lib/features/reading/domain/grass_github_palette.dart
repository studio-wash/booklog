// Spec FR-4, FR-5 — GitHub contribution–style greens (light UI).
// Colors approximate github.com profile contribution graph (light theme).

import 'package:flutter/material.dart';

/// Fill for contribution level 0..4 (0 = no pages that day).
Color githubGrassCellFill(int level) {
  switch (level.clamp(0, 4)) {
    case 1:
      return const Color(0xFF9BE9A8);
    case 2:
      return const Color(0xFF40C463);
    case 3:
      return const Color(0xFF30A14E);
    case 4:
      return const Color(0xFF216E39);
    case 0:
    default:
      return const Color(0xFFEBEDF0);
  }
}

/// Border around each cell (GitHub uses a faint grid).
Color get githubGrassCellBorder => const Color(0xFFD0D7DE);

/// Text on cell: white on saturated greens, dark gray otherwise.
Color githubGrassDayNumberColor(int level) {
  if (level >= 2) return Colors.white;
  return const Color(0xFF57606A);
}

/// Strong border for “today” (same palette as grass; no accent color circle).
Color get githubGrassTodayBorder => const Color(0xFF1B5E20);
