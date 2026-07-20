import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/task.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, required this.onToggle});

  final Task task;
  final VoidCallback onToggle;

  Color _priorityColor() {
    switch (task.priority) {
      case 'Yüksek':
        return AppColors.danger;
      case 'Düşük':
        return AppColors.textFaint;
      default:
        return AppColors.aiPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: ListTile(
        onTap: onToggle,
        leading: Icon(
          task.isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: task.isDone ? AppColors.success : AppColors.textDim,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            color: task.isDone ? AppColors.textFaint : AppColors.text,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: (task.type != null || task.date != null)
            ? Text(
                [task.type, task.date].where((e) => e != null && e.isNotEmpty).join(' · '),
                style: const TextStyle(color: AppColors.textDim, fontSize: 12),
              )
            : null,
        trailing: task.priority != null && task.priority!.isNotEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _priorityColor().withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  task.priority!,
                  style: TextStyle(color: _priorityColor(), fontSize: 11, fontWeight: FontWeight.w700),
                ),
              )
            : null,
      ),
    );
  }
}
