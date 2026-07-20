import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/journal.dart';

class JournalTile extends StatelessWidget {
  const JournalTile({super.key, required this.journal, required this.onDelete});

  final Journal journal;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.aiPurple,
          child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 18),
        ),
        title: Text(journal.content, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [journal.category, journal.date, journal.time]
              .where((e) => e != null && e.isNotEmpty)
              .join(' · '),
          style: const TextStyle(color: AppColors.textDim, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textFaint),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
