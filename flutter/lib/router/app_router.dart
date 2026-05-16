import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_branding.dart';
import '../features/books/books_screen.dart';
import '../features/dev/data_backup_screen.dart';
import '../features/grass/grass_screen.dart';
import '../features/log_entry/log_entry_screen.dart';
import '../features/shell/booklog_shell_scaffold.dart';
import '../features/shell/history_placeholder_screen.dart';
import '../features/shell/profile_screen.dart';

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

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// PLAN-000006: shell tabs + full-screen `/log` and `/dev/data`.
GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return BooklogShellScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const GrassScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryPlaceholderScreen(),
          ),
          GoRoute(
            path: '/books',
            builder: (context, state) => const BooksScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/log',
        builder: (context, state) {
          final raw = state.uri.queryParameters['bookId'];
          final id = raw != null ? int.tryParse(raw) : null;
          final day = _parseLocalDayQuery(state.uri.queryParameters['day']);
          return LogEntryScreen(initialBookId: id, initialLogDay: day);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/dev/data',
        builder: (context, state) => const DataBackupScreen(),
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          appBar: AppBar(title: Text(appDisplayName)),
          body: Center(child: Text('Not found: ${state.uri}')),
        ),
  );
}
