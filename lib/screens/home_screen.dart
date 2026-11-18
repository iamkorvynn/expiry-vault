import 'package:material_ui/material_ui.dart';

import '../models/document.dart';
import '../services/database_service.dart';
import '../utils/expiry_logic.dart';
import '../widgets/document_card.dart';

enum _StatusFilter { all, valid, expiringSoon, expired }

extension on _StatusFilter {
  String get label => switch (this) {
        _StatusFilter.all => 'All',
        _StatusFilter.valid => 'Valid',
        _StatusFilter.expiringSoon => 'Expiring soon',
        _StatusFilter.expired => 'Expired',
      };

  ExpiryStatus? get status => switch (this) {
        _StatusFilter.all => null,
        _StatusFilter.valid => ExpiryStatus.valid,
        _StatusFilter.expiringSoon => ExpiryStatus.expiringSoon,
        _StatusFilter.expired => ExpiryStatus.expired,
      };
}

/// Dashboard: documents sorted by expiry date, with search, type
/// filter and status filter, plus a summary strip.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ExpiryDocument> _all = <ExpiryDocument>[];
  bool _loading = true;
  String _query = '';
  DocumentType? _typeFilter;
  _StatusFilter _statusFilter = _StatusFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final docs = await DatabaseService.instance.getAllDocuments();
    if (!mounted) return;
    setState(() {
      _all = docs;
      _loading = false;
    });
  }

  List<ExpiryDocument> get _filtered {
    return _all.where((doc) {
      if (_typeFilter != null && doc.type != _typeFilter) return false;
      final status = _statusFilter.status;
      if (status != null && doc.status != status) return false;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final haystack =
            '${doc.title} ${doc.documentNumber} '
            '${doc.issuingAuthority ?? ''} ${doc.type.label}'.toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList(growable: false);
  }

  Future<void> _openAdd() async {
    await Navigator.of(context).pushNamed('/add');
    await _load();
  }

  Future<void> _openDetail(ExpiryDocument doc) async {
    await Navigator.of(context).pushNamed('/detail', arguments: doc.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;
    final expiredCount =
        _all.where((d) => d.status == ExpiryStatus.expired).length;
    final soonCount =
        _all.where((d) => d.status == ExpiryStatus.expiringSoon).length;
    final validCount =
        _all.where((d) => d.status == ExpiryStatus.valid).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ExpiryVault'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'ExpiryVault',
              applicationVersion: '1.0.0',
              applicationLegalese:
                  'Your documents stay on this device. No account, no cloud.',
              children: const <Widget>[
                Text(
                  'Add your PUC, insurance, licence, RC, passport and '
                  'other documents. ExpiryVault reminds you 30, 7 and 1 '
                  'day(s) before each one expires.',
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add document'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, number or issuer',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                if (_all.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: <Widget>[
                        _SummaryChip(
                          label: '$validCount valid',
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 8),
                        _SummaryChip(
                          label: '$soonCount expiring soon',
                          color: Colors.amber.shade800,
                        ),
                        const SizedBox(width: 8),
                        _SummaryChip(
                          label: '$expiredCount expired',
                          color: Colors.red.shade700,
                        ),
                      ],
                    ),
                  ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: <Widget>[
                      for (final f in _StatusFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f.label),
                            selected: _statusFilter == f,
                            onSelected: (_) =>
                                setState(() => _statusFilter = f),
                          ),
                        ),
                      const SizedBox(width: 8),
                      DropdownButton<DocumentType?>(
                        value: _typeFilter,
                        hint: const Text('All types'),
                        underline: const SizedBox.shrink(),
                        items: <DropdownMenuItem<DocumentType?>>[
                          const DropdownMenuItem<DocumentType?>(
                            value: null,
                            child: Text('All types'),
                          ),
                          for (final t in DocumentType.values)
                            DropdownMenuItem<DocumentType?>(
                              value: t,
                              child: Text(t.label),
                            ),
                        ],
                        onChanged: (v) => setState(() => _typeFilter = v),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _all.isEmpty
                      ? _EmptyState(onAdd: _openAdd)
                      : filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No documents match this filter.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final doc = filtered[index];
                                  return DocumentCard(
                                    document: doc,
                                    onTap: () => _openDetail(doc),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(32),
      children: <Widget>[
        const SizedBox(height: 48),
        Icon(
          Icons.folder_open_outlined,
          size: 72,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'No documents yet',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Add your first document — PUC, insurance, licence, RC or '
          'passport — and ExpiryVault will remind you before it expires.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add your first document'),
        ),
      ],
    );
  }
}
