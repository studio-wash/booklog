import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/app_branding.dart';
import 'core/app_theme.dart';
import 'router/app_router.dart';

/// Root widget (Plan: router-shell + wire-branding title).
class BooklogApp extends ConsumerStatefulWidget {
  const BooklogApp({super.key});

  @override
  ConsumerState<BooklogApp> createState() => _BooklogAppState();
}

class _BooklogAppState extends ConsumerState<BooklogApp> {
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: appDisplayName,
      theme: buildBooklogLightTheme(),
      routerConfig: _router,
    );
  }
}
