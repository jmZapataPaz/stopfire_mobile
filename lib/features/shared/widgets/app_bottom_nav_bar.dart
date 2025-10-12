import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stopfire_mobile/features/auth/presentation/state/auth_provider.dart';
import 'package:stopfire_mobile/features/account/presentation/state/account_provider.dart';
import 'package:stopfire_mobile/features/account/presentation/pages/account_page.dart';

class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  const AppBottomNavBar({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final acc = context.watch<AccountProvider?>();
    final accRole = acc?.account?.rolId;
    if (auth.roleId == null && accRole != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (auth.roleId == null) auth.setRoleId(accRole);
      });
    }

    final isBombero = auth.roleId == 2;

    if (isBombero) {
      return SafeArea(
        top: false,
        child: BottomAppBar(
          color: Theme.of(context).colorScheme.surface,
          child: SizedBox(
            height: kBottomNavigationBarHeight, 
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _SingleNavItem(icon: Icons.map, label: 'Mapa', selected: true, compact: true),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final idx = selectedIndex.clamp(0, 1);
    return NavigationBar(
      selectedIndex: idx,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.map), label: 'Mapa'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Cuenta'),
      ],
      onDestinationSelected: (i) {
        if (i == 1) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AccountPage()),
          );
        }
      },
    );
  }
}

class _SingleNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  const _SingleNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Theme.of(context).colorScheme.primary : Theme.of(context).iconTheme.color;
    final vPad = compact ? 5.0 : 8.0; // un poco menor
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: vPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 12, height: 1.0), // altura de línea compacta
          ),
        ],
      ),
    );
  }
}