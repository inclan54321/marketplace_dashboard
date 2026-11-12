import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TabProductos extends StatefulWidget {
  const TabProductos({super.key});

  @override
  State<TabProductos> createState() => _TabProductosState();
}

class _TabProductosState extends State<TabProductos> {
  List<dynamic> _productos = [];
  bool _loading = true;
  String _filtroEstado = 'todos';
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getProductos();
      setState(() {
        _productos = data;
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

  List<dynamic> get _filtrados {
    var lista = _productos;

    if (_filtroEstado != 'todos') {
      lista =
          lista.where((p) => p['estado_moderacion'] == _filtroEstado).toList();
    }

    if (_busqueda.isNotEmpty) {
      final q = _busqueda.toLowerCase();
      lista = lista.where((p) {
        final nombre = (p['nombre'] ?? '').toString().toLowerCase();
        final vendedor = (p['vendedor_nombre'] ?? '').toString().toLowerCase();
        final categoria = (p['categoria'] ?? '').toString().toLowerCase();
        return nombre.contains(q) ||
            vendedor.contains(q) ||
            categoria.contains(q);
      }).toList();
    }

    return lista;
  }

  Color _colorEstado(String? estado) {
    switch (estado) {
      case 'aprobado':
        return Colors.green;
      case 'pendiente':
        return Colors.amber;
      case 'rechazado':
        return Colors.red;
      case 'eliminado_admin':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  // ===== ELIMINAR =====
  Future<void> _confirmarEliminar(Map<String, dynamic> producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🗑️ ¿Eliminar producto?'),
        content: Text(
          '"${producto['nombre']}" será eliminado.\n\n'
          'Motivo: Violó las normas de la comunidad.\n\n'
          'El vendedor será notificado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ApiService.eliminarProducto(producto['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Producto eliminado'),
          backgroundColor: Colors.black,
        ),
      );
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ===== RESTAURAR =====
  Future<void> _confirmarRestaurar(Map<String, dynamic> producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🔄 ¿Restaurar producto?'),
        content: Text(
          '"${producto['nombre']}" volverá a estar visible.\n\n'
          'El vendedor será notificado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ApiService.restaurarProducto(producto['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Producto restaurado'),
          backgroundColor: Colors.green,
        ),
      );
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _cargar, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              onChanged: (v) => setState(() => _busqueda = v),
              decoration: InputDecoration(
                hintText: 'Buscar por producto, vendedor o categoría...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _busqueda = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                'todos',
                'aprobado',
                'pendiente',
                'rechazado',
                'eliminado_admin'
              ]
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(e.replaceAll('_admin', '')),
                          selected: _filtroEstado == e,
                          onSelected: (_) => setState(() => _filtroEstado = e),
                        ),
                      ))
                  .toList(),
            ),
          ),
          if (!_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filtrados.length} resultado${filtrados.length == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              _busqueda.isNotEmpty
                                  ? 'No se encontraron productos con "$_busqueda"'
                                  : 'No hay productos',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.builder(
                          itemCount: filtrados.length,
                          itemBuilder: (_, i) {
                            final p = filtrados[i];
                            final estaEliminado =
                                p['estado_moderacion'] == 'eliminado_admin';

                            return Dismissible(
                              key: ValueKey('producto_${p['id']}'),
                              direction: DismissDirection.endToStart,
                              // Color de fondo diferente según estado
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: estaEliminado
                                      ? Colors.green
                                      : Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      estaEliminado
                                          ? Icons.restore
                                          : Icons.delete,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      estaEliminado ? 'Restaurar' : 'Eliminar',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              confirmDismiss: (_) async {
                                if (estaEliminado) {
                                  await _confirmarRestaurar(p);
                                } else {
                                  await _confirmarEliminar(p);
                                }
                                return false;
                              },
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: ListTile(
                                  onLongPress: () {
                                    if (estaEliminado) {
                                      _confirmarRestaurar(p);
                                    } else {
                                      _confirmarEliminar(p);
                                    }
                                  },
                                  title: Text(
                                    p['nombre'] ?? 'Sin nombre',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      decoration: estaEliminado
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: estaEliminado
                                          ? Colors.grey
                                          : null,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '₡${p['precio']} • ${p['categoria'] ?? ''}',
                                      ),
                                      Text(
                                        '👤 ${p['vendedor_nombre'] ?? ''}',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _colorEstado(
                                                  p['estado_moderacion'])
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          p['estado_moderacion'] ?? '?',
                                          style: TextStyle(
                                            color: _colorEstado(
                                                p['estado_moderacion']),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '👁 ${p['vistas'] ?? 0}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}