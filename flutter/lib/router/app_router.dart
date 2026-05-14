import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_branding.dart';
import '../features/books/books_screen.dart';
import '../features/dev/data_backup_screen.dart';
import '../features/grass/grass_screen.dart';
import '../features/log_entry/log_entry_screen.dart';

DateTime? _parseLocalDayQuery(String? value) {
  if (value == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return null;
  }
  final parts = value.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// Plan: router-shell — `/` grass, `/books`, `/log`; PLAN-000004 — `/dev/data` backup.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const GrassScreen()),
      GoRoute(path: '/books', builder: (context, state) => const BooksScreen()),
      GoRoute(
        path: '/dev/data',
        builder: (context, state) => const DataBackupScreen(),
      ),
      GoRoute(
        path: '/log',
        builder: (context, state) {
          final raw = state.uri.queryParameters['bookId'];
          final id = raw != null ? int.tryParse(raw) : null;
          final day = _parseLocalDayQuery(state.uri.queryParameters['day']);
          return LogEntryScreen(initialBookId: id, initialLogDay: day);
        },
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          appBar: AppBar(title: Text(appDisplayName)),
          body: Center(child: Text('Not found: ${state.uri}')),
        ),
  );
}
