// Spec: spec/features/booklog-mvp/booklog-mvp.md — FR-11
// Plan: plan/PLAN-000004_dev-db-export-import/plan.md

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/booklog_export_format.dart';
import '../../providers.dart';

/// Dev-only backup: JSON export / import (empty DB only).
class DataBackupScreen extends ConsumerStatefulWidget {
  const DataBackupScreen({super.key});

  @override
  ConsumerState<DataBackupScreen> createState() => _DataBackupScreenState();
}

class _DataBackupScreenState extends ConsumerState<DataBackupScreen> {
  String? _status;

  Future<void> _export() async {
    setState(() => _status = null);
    try {
      final json = await ref.read(databaseProvider).exportDatabaseAsIndentedJson();
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/booklog_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File(path);
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(path)], subject: 'Booklog backup');
      if (mounted) setState(() => _status = 'Export ready (share sheet opened).');
    } catch (e) {
      if (mounted) setState(() => _status = 'Export failed: $e');
    }
  }

  Future<void> _import() async {
    setState(() => _status = null);
    final pick = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (pick == null || pick.files.isEmpty) return;
    final bytes = pick.files.single.bytes;
    if (bytes == null) {
      setState(() => _status = 'Could not read file bytes.');
      return;
    }
    final s = utf8.decode(bytes, allowMalformed: true);
    try {
      await ref.read(databaseProvider).importDatabaseFromJson(s);
      ref.read(readingDataTickProvider.notifier).state++;
      if (mounted) {
        setState(() => _status = 'Import completed.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import completed.')),
        );
      }
    } on BooklogImportException catch (e) {
      if (mounted) {
        setState(() => _status = e.message);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Import failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & restore (dev)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Export JSON before schema changes; import only works on an **empty** library (no books, no logs).',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _export,
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Export JSON'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _import,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Import JSON'),
          ),
          const SizedBox(height: 24),
          Text(
            'Format version: $booklogExportFormatVersion · Example snippet:',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SelectableText(
            kBooklogExportExampleJson.trim(),
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
          if (_status != null) ...[
            const SizedBox(height: 16),
            Text(_status!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
