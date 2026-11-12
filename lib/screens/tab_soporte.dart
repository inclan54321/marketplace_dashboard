import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'detalle_soporte_screen.dart';

class TabSoporte extends StatefulWidget {
  const TabSoporte({super.key});

  @override
  State<TabSoporte> createState() => _TabSoporteState();
}

class _TabSoporteState extends State<TabSoporte>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soporte'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Nuevos', icon: Icon(Icons.fiber_new, size: 20)),
            Tab(text: 'Respondidos', icon: Icon(Icons.check_circle, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ListaSoporte(respondidos: false),
          _ListaSoporte(respondidos: true),
        ],
      ),
    );
  }
}

class _ListaSoporte extends StatefulWidget {
  final bool respondidos;
  const _ListaSoporte({required this.respondidos});

  @override
  State<_ListaSoporte> createState() => _ListaSoporteState();
}

class _ListaSoporteState extends State<_ListaSoporte>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final data = widget.respondidos
          ? await ApiService.getSoporteRespondidos()
          : await ApiService.getSoporteNuevos();
      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _abrirDetalle(Map<String, dynamic> ticket) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleSoporteScreen(ticket: ticket),
      ),
    );
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.respondidos ? Icons.inbox : Icons.mark_email_read,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              widget.respondidos
                  ? 'No hay tickets respondidos'
                  : 'No hay tickets nuevos',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final t = _items[i];
          final estado = t['estado'] ?? 'nuevo';
          final color = estado == 'nuevo'
              ? Colors.red
              : estado == 'leido'
                  ? Colors.orange
                  : estado == 'respondido'
                      ? Colors.green
                      : Colors.grey;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: ListTile(
              onTap: () => _abrirDetalle(t),
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(Icons.support_agent, color: color),
              ),
              title: Text(
                t['asunto'] ?? 'Sin asunto',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t['usuario_nombre'] ?? 'Usuario',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                  Text(
                    t['mensaje'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      estado,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}