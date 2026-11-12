import 'package:flutter/material.dart';
import 'tab_overview.dart';
import 'tab_usuarios.dart';
import 'tab_productos.dart';
import 'tab_notificar.dart';
import 'tab_soporte.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _index = 0;

  final _tabs = const [
    TabOverview(),
    TabUsuarios(),
    TabProductos(),
    TabNotificar(),
    TabSoporte(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Resumen'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Usuarios'),
          NavigationDestination(icon: Icon(Icons.shopping_bag), label: 'Productos'),
          NavigationDestination(icon: Icon(Icons.notifications_active), label: 'Notificar'),
          NavigationDestination(icon: Icon(Icons.support_agent), label: 'Soporte'),
        ],
      ),
    );
  }
}