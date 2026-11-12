import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class DenunciasScreen extends StatefulWidget {
  const DenunciasScreen({super.key});

  @override
  State<DenunciasScreen> createState() => _DenunciasScreenState();
}

class _DenunciasScreenState extends State<DenunciasScreen>
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
        title: const Text('Denuncias'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Nuevas', icon: Icon(Icons.fiber_new, size: 20)),
            Tab(text: 'Archivadas', icon: Icon(Icons.archive, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ListaDenuncias(archivadas: false),
          _ListaDenuncias(archivadas: true),
        ],
      ),
    );
  }
}

class _ListaDenuncias extends StatefulWidget {
  final bool archivadas;
  const _ListaDenuncias({required this.archivadas});

  @override
  State<_ListaDenuncias> createState() => _ListaDenunciasState();
}

class _ListaDenunciasState extends State<_ListaDenuncias>
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
      final data = widget.archivadas
          ? await ApiService.getDenunciasArchivadas()
          : await ApiService.getDenunciasNuevas();
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

  Future<void> _cambiarEstado(int id) async {
    try {
      if (widget.archivadas) {
        await ApiService.desarchivarDenuncia(id);
      } else {
        await ApiService.archivarDenuncia(id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.archivadas
                ? '✅ Denuncia restaurada'
                : '📦 Denuncia archivada'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _fechaFormateada(dynamic fecha) {
    if (fecha == null) return '';
    try {
      final dt = DateTime.parse(fecha.toString());
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return fecha.toString();
    }
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
              widget.archivadas
                  ? Icons.archive_outlined
                  : Icons.check_circle_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              widget.archivadas
                  ? 'No hay denuncias archivadas'
                  : 'No hay denuncias nuevas',
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
          final d = _items[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          d['motivo'] ?? 'Sin motivo',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _linea('👤 Denunciante',
                      d['denunciante_nombre'] ?? 'Desconocido'),
                  _linea('🎯 Denunciado',
                      d['denunciado_nombre'] ?? 'Desconocido'),
                  _linea('📦 Producto', d['producto_nombre'] ?? 'N/A'),
                  _linea('📅 Fecha', _fechaFormateada(d['fecha'])),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.archivadas)
                        OutlinedButton.icon(
                          onPressed: () => _cambiarEstado(d['id']),
                          icon: const Icon(Icons.unarchive, size: 18),
                          label: const Text('Restaurar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                          ),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => _cambiarEstado(d['id']),
                          icon: const Icon(Icons.archive, size: 18),
                          label: const Text('Archivar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _linea(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(valor, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}