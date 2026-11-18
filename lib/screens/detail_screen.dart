import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../models/document.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/photo_service.dart';
import '../utils/expiry_logic.dart';
import '../widgets/status_badge.dart';
import 'add_edit_screen.dart';

/// Detail view: photo viewer, all fields, renewal history, and the
/// edit / delete / mark-renewed actions.
class DetailScreen extends StatefulWidget {
  const DetailScreen({required this.documentId, super.key});

  final int documentId;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  ExpiryDocument? _doc;
  List<RenewalRecord> _history = <RenewalRecord>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await DatabaseService.instance.getDocument(widget.documentId);
    final history = doc == null
        ? <RenewalRecord>[]
        : await DatabaseService.instance.getRenewals(doc.id!);
    if (!mounted) return;
    setState(() {
      _doc = doc;
      _history = history;
      _loading = false;
    });
  }

  Future<void> _edit() async {
    final doc = _doc;
    if (doc == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddEditScreen(document: doc),
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _delete() async {
    final doc = _doc;
    if (doc == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text(
          'This deletes "${doc.title}" and its renewal history. '
          'This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await NotificationService.instance.cancelForDocument(doc);
    await PhotoService().deletePhoto(doc.photoPath);
    await DatabaseService.instance.deleteDocument(doc.id!);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _markRenewed() async {
    final doc = _doc;
    if (doc == null) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year + 1, now.month, now.day),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 30),
      helpText: 'New expiry date after renewal',
    );
    if (picked == null) return;
    await DatabaseService.instance.renewDocument(doc, picked);
    final updated = await DatabaseService.instance.getDocument(doc.id!);
    if (updated != null) {
      await NotificationService.instance.scheduleForDocument(updated);
    }
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Renewed — new expiry ${_formatDate(picked)}. '
          'Reminders rescheduled.',
        ),
      ),
    );
  }

  void _openPhoto() {
    final doc = _doc;
    if (doc == null || doc.photoPath == null) return;
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: Image.file(File(doc.photoPath!)),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doc = _doc;
    return Scaffold(
      appBar: AppBar(
        title: Text(doc?.title ?? 'Document'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: doc == null ? null : _edit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: doc == null ? null : _delete,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : doc == null
              ? const Center(child: Text('Document not found.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        StatusBadge(status: doc.status),
                        const SizedBox(width: 12),
                        Text(
                          daysRemainingText(doc.expiryDate),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (doc.photoPath != null &&
                        File(doc.photoPath!).existsSync())
                      GestureDetector(
                        onTap: _openPhoto,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(doc.photoPath!),
                            height: 260,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('No photo attached'),
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (doc.photoPath != null)
                      const Center(
                        child: Text(
                          'Tap the photo to view it full screen',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _FieldRow(
                      label: 'Type',
                      value: doc.type.label,
                      icon: doc.type.icon,
                    ),
                    _FieldRow(
                      label: 'Document number',
                      value: doc.documentNumber,
                      icon: Icons.numbers_outlined,
                    ),
                    if (doc.issuingAuthority != null)
                      _FieldRow(
                        label: 'Issuing authority',
                        value: doc.issuingAuthority!,
                        icon: Icons.business_outlined,
                      ),
                    _FieldRow(
                      label: 'Expiry date',
                      value: _formatDate(doc.expiryDate),
                      icon: Icons.calendar_today_outlined,
                    ),
                    _FieldRow(
                      label: 'Reminders',
                      value:
                          '30 days, 7 days and 1 day before expiry (9:00am)',
                      icon: Icons.notifications_outlined,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _markRenewed,
                      icon: const Icon(Icons.autorenew_outlined),
                      label: const Text('Mark renewed'),
                    ),
                    const SizedBox(height: 24),
                    if (_history.isNotEmpty) ...<Widget>[
                      Text(
                        'Renewal history',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final r in _history)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.history_outlined),
                            title: Text(
                              '${_formatDate(r.oldExpiryDate)} → '
                              '${_formatDate(r.newExpiryDate)}',
                            ),
                            subtitle: Text(
                              'Renewed on ${_formatDate(r.renewedAt)}',
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
