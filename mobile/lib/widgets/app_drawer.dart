import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../screens/settings_screen.dart';

/// Sol tarafta gizlenebilir gezinme çekmecesi (sidebar).
///
/// Kategoriler: Daily, Görevler, Life, Second Brain.
/// [selectedIndex] ile aktif sekme vurgulanır, [onSelect] seçim değişince
/// çağrılır ve çekmece otomatik kapanır.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _items = [
    _NavItem(icon: Icons.today_rounded, label: 'Daily'),
    _NavItem(icon: Icons.check_circle_outline_rounded, label: 'Görevler'),
    _NavItem(icon: Icons.menu_book_rounded, label: 'Life'),
    _NavItem(icon: Icons.psychology_alt_rounded, label: 'Second Brain'),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.panel,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.hexagon_rounded, color: AppColors.aiPurple, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'LifeOS',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'KATEGORİLER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .8,
                    color: AppColors.textFaint,
                  ),
                ),
              ),
            ),
            for (var i = 0; i < _items.length; i++)
              _DrawerTile(
                item: _items[i],
                selected: i == selectedIndex,
                onTap: () {
                  Navigator.of(context).pop();
                  onSelect(i);
                },
              ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: AppColors.textDim),
              title: const Text('Ayarlar', style: TextStyle(color: AppColors.textDim)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({required this.item, required this.selected, required this.onTap});

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected ? Colors.white.withOpacity(.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: selected ? Colors.white : AppColors.textDim,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
