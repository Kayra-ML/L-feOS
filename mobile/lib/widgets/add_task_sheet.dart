import 'package:flutter/material.dart';

import '../core/theme.dart';

class AddTaskResult {
  AddTaskResult({required this.title, required this.type, required this.priority, this.date});
  final String title;
  final String type;
  final String priority;
  final String? date;
}

/// Yeni görev/rutin ekleme için alttan açılan form.
Future<AddTaskResult?> showAddTaskSheet(BuildContext context) {
  final titleCtrl = TextEditingController();
  String type = 'Görev';
  String priority = 'Orta';
  DateTime date = DateTime.now();

  return showModalBottomSheet<AddTaskResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return Padding(
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
                const Text('Yeni Görev', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: 'Görev başlığı...'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: type,
                        dropdownColor: AppColors.panel2,
                        decoration: const InputDecoration(labelText: 'Tür'),
                        items: const ['Görev', 'Rutin', 'Dinlenme']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) => setState(() => type = v ?? type),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: priority,
                        dropdownColor: AppColors.panel2,
                        decoration: const InputDecoration(labelText: 'Öncelik'),
                        items: const ['Yüksek', 'Orta', 'Düşük']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) => setState(() => priority = v ?? priority),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.event_rounded, size: 18),
                  label: Text(
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  ),
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
                    if (titleCtrl.text.trim().isEmpty) return;
                    final iso =
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    Navigator.of(ctx).pop(
                      AddTaskResult(title: titleCtrl.text.trim(), type: type, priority: priority, date: iso),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text('Ekle'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
