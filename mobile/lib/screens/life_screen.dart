import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/journal_provider.dart';
import '../widgets/journal_tile.dart';

/// "Life" ekranı — Notion "Journals" veritabanına karşılık gelir.
class LifeScreen extends StatefulWidget {
  const LifeScreen({super.key});

  @override
  State<LifeScreen> createState() => _LifeScreenState();
}

class _LifeScreenState extends State<LifeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalProvider>().load();
    });
  }

  Future<void> _addJournal() async {
    final contentCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    DateTime date = DateTime.now();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Yeni Günlük Kaydı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(
                controller: contentCtrl,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Ne oldu?'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryCtrl,
                decoration: const InputDecoration(hintText: 'Kategori (ör: Yazılım, Spor)'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.event_rounded, size: 18),
                label: Text('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) setState(() => date = picked);
                },
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  if (contentCtrl.text.trim().isEmpty) return;
                  Navigator.of(ctx).pop(true);
                },
                child: const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Ekle')),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok != true || !mounted) return;
    try {
      await context.read<JournalProvider>().addJournal(
            content: contentCtrl.text.trim(),
            category: categoryCtrl.text.trim().isEmpty ? null : categoryCtrl.text.trim(),
            date: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kayıt eklenemedi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JournalProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          if (provider.isLoading) const LinearProgressIndicator(minHeight: 2),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Text('Günlükler yüklenemedi: ${provider.error}', style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.load,
              child: provider.journals.isEmpty && !provider.isLoading
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Center(child: Text('Henüz günlük kaydı yok.', style: TextStyle(color: AppColors.textDim))),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 90, top: 8),
                      itemCount: provider.journals.length,
                      itemBuilder: (context, i) {
                        final j = provider.journals[i];
                        return JournalTile(
                          journal: j,
                          onDelete: () => provider.deleteJournal(j.id),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addJournal,
        tooltip: 'Yeni günlük kaydı ekle',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
