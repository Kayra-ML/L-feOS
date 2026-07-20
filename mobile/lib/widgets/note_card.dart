import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/second_brain_note.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note});

  final SecondBrainNote note;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_alt_rounded, size: 18, color: AppColors.aiPurple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ],
            ),
            if (note.content != null && note.content!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(note.content!, style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
            ],
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: note.tags
                    .map((t) => Chip(
                          label: Text(t, style: const TextStyle(fontSize: 11)),
                          backgroundColor: AppColors.aiPurple.withOpacity(.12),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
            if (note.date != null && note.date!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(note.date!, style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}
