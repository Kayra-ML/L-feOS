import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/note_provider.dart';
import '../widgets/note_card.dart';

/// "Second Brain" ekranı: notlar listesi, ekleme, etiketler.
class SecondBrainScreen extends StatefulWidget {
  const SecondBrainScreen({super.key});

  @override
  State<SecondBrainScreen> createState() => _SecondBrainScreenState();
}

class _SecondBrainScreenState extends State<SecondBrainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoteProvider>().load();
    });
  }

  Future<void> _addNote() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
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
            const Text('Yeni Not', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Başlık'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'İçerik'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tagsCtrl,
              decoration: const InputDecoration(hintText: 'Etiketler (virgülle ayırın)'),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.of(ctx).pop(true);
              },
              child: const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Ekle')),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;
    final tags = tagsCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    try {
      await context.read<NoteProvider>().addNote(
            title: titleCtrl.text.trim(),
            content: contentCtrl.text.trim().isEmpty ? null : contentCtrl.text.trim(),
            tags: tags,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Not eklenemedi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NoteProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          if (provider.isLoading) const LinearProgressIndicator(minHeight: 2),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Text('Notlar yüklenemedi: ${provider.error}', style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.load,
              child: provider.notes.isEmpty && !provider.isLoading
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Center(child: Text('Henüz not yok.', style: TextStyle(color: AppColors.textDim))),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 90, top: 8),
                      itemCount: provider.notes.length,
                      itemBuilder: (context, i) => NoteCard(note: provider.notes[i]),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        tooltip: 'Yeni not ekle',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
