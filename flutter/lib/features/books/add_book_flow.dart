import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart';

// PLAN-000008 — search picker → form → return saved Book.

Future<Book?> pushAddBookFlow(BuildContext context) {
  return context.push<Book?>('/books/add/search');
}
