import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _AppBootstrap());
}

/// Shows UI immediately so iOS never sits on a blank screen while SQLite opens.
class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  Object? _error;
  AppDatabase? _db;

  @override
  void initState() {
    super.initState();
    _openDb();
  }

  Future<void> _openDb() async {
    try {
      final db = await AppDatabase.open();
      if (mounted) setState(() => _db = db);
    } catch (e, st) {
      debugPrint('AppDatabase.open failed: $e\n$st');
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Could not open the local database.\n\n$_error',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (_db == null) {
      return MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: const Scaffold(
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Starting…'),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return ProviderScope(
      overrides: [databaseProvider.overrideWithValue(_db!)],
      child: const BooklogApp(),
    );
  }
}
