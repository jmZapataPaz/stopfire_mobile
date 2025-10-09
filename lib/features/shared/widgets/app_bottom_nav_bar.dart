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
    auth.ensureRoleParsed();
    final acc = context.watch<AccountProvider?>();
    final accRole = acc?.account?.rolId;
    if (auth.roleId == null && accRole != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (auth.roleId == null) auth.setRoleId(accRole);
      });
    }

    final isBombero = auth.roleId == 2;

    if (isBombero) {
      return BottomAppBar(
        color: Theme.of(context).colorScheme.surface,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _SingleNavItem(icon: Icons.map, label: 'Mapa', selected: true),
            ],
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
  const _SingleNavItem({required this.icon, required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final color = selected ? Theme.of(context).colorScheme.primary : Theme.of(context).iconTheme.color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}