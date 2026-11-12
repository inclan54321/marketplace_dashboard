import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'denuncias_screen.dart';

class TabOverview extends StatefulWidget {
  const TabOverview({super.key});

  @override
  State<TabOverview> createState() => _TabOverviewState();
}

class _TabOverviewState extends State<TabOverview> {
  Map<String, dynamic>? _data;
  int _denunciasNuevas = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getResumen();
      final nuevas = await ApiService.getDenunciasNuevasCount();
      setState(() {
        _data = data;
        _denunciasNuevas = nuevas;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _abrirDenuncias() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DenunciasScreen()),
    );
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen General'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _cargar, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorWidget()
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: GridView.count(
                    padding: const EdgeInsets.all(16),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: [
                      _kpi('Usuarios', _data!['total_usuarios'],
                          Icons.people, Colors.blue),
                      _kpi('Productos', _data!['total_productos'],
                          Icons.shopping_bag, Colors.orange),
                      _kpi('Activos', _data!['productos_activos'],
                          Icons.check_circle, Colors.green),
                      _kpi('Pendientes', _data!['productos_pendientes'],
                          Icons.hourglass_top, Colors.amber),
                      _kpi('Chats', _data!['total_chats'],
                          Icons.chat, Colors.purple),
                      _kpi(
                        'Denuncias',
                        _data!['total_denuncias'],
                        Icons.report,
                        Colors.red,
                        badge: _denunciasNuevas,
                        onTap: _abrirDenuncias,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _kpi(
    String titulo,
    dynamic valor,
    IconData icono,
    Color color, {
    int badge = 0,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Card(
        elevation: 3,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icono, size: 36, color: color),
                  const SizedBox(height: 8),
                  Text(
                    '$valor',
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(titulo, style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
            if (badge > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _errorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}