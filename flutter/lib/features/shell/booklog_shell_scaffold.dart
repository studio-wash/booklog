import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';

/// [FloatingActionButtonLocation.centerDocked]보다 하단바 안쪽으로 더 내린 위치.
class BooklogCenterDockedFabLocation extends FloatingActionButtonLocation {
  const BooklogCenterDockedFabLocation({this.sinkIntoBar = 14});

  /// Default centerDocked 대비 아래로 밀어 넣는 px (FAB가 바에 더 걸치게).
  final double sinkIntoBar;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final fabSize = scaffoldGeometry.floatingActionButtonSize;
    final fabX = (scaffoldGeometry.scaffoldSize.width - fabSize.width) / 2.0;
    final fabY =
        scaffoldGeometry.contentBottom - fabSize.height / 2.0 + sinkIntoBar;
    return Offset(fabX, fabY);
  }
}

/// Bottom nav shell (PLAN-000006 reference #12): Home, History, +, Books, Profile.
class BooklogShellScaffold extends ConsumerWidget {
  const BooklogShellScaffold({super.key, required this.child});

  final Widget child;

  static int _tabIndexForPath(String path) {
    if (path.startsWith('/history')) return 1;
    if (path.startsWith('/books')) return 3;
    if (path.startsWith('/profile')) return 4;
    return 0;
  }

  Future<void> _openLog(BuildContext context, WidgetRef ref) async {
    final snap = await ref.read(currentReadingProvider.future);
    if (!context.mounted) return;
    if (snap != null) {
      context.push('/log?bookId=${snap.book.id}');
    } else {
      context.push('/log');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final selected = _tabIndexForPath(path);
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: child,
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openLog(context, ref),
        tooltip: 'Log reading',
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: const BooklogCenterDockedFabLocation(
        sinkIntoBar: 14,
      ),
      bottomNavigationBar: BottomAppBar(
        height: 56 + bottomPad,
        padding: EdgeInsets.only(bottom: bottomPad),
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.black26,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Home',
              selected: selected == 0,
              onTap: () => context.go('/'),
            ),
            _NavItem(
              icon: Icons.history_outlined,
              selectedIcon: Icons.history,
              label: 'History',
              selected: selected == 1,
              onTap: () => context.go('/history'),
            ),
            const SizedBox(width: 56),
            _NavItem(
              icon: Icons.menu_book_outlined,
              selectedIcon: Icons.menu_book,
              label: 'Books',
              selected: selected == 3,
              onTap: () => context.go('/books'),
            ),
            _NavItem(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Profile',
              selected: selected == 4,
              onTap: () => context.go('/profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
