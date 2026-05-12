import 'dart:async';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Sqflite FFI with isolates deadlocks [WidgetTester.pump] in widget tests.
/// See: https://github.com/tekartik/sqflite/blob/master/sqflite_common_ffi/doc/testing.md
Future<void> testExecutable(Future<void> Function() testMain) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
  await testMain();
}
