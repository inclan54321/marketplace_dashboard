import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'detalle_usuario_screen.dart';

class TabUsuarios extends StatefulWidget {
  const TabUsuarios({super.key});

  @override
  State<TabUsuarios> createState() => _TabUsuariosState();
}

class _TabUsuariosState extends State<TabUsuarios> {
  List<dynamic> _usuarios = [];
  List<dynamic> _filtrados = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getUsuarios();
      setState(() {
        _usuarios = data;
        _filtrados = data;
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

  void _filtrar(String texto) {
    final t = texto.toLowerCase();
    setState(() {
      _filtrados = _usuarios.where((u) {
        final nombre = (u['nombre'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        return nombre.contains(t) || email.contains(t);
      }).toList();
    });
  }

  Future<void> _abrirDetalle(Map<String, dynamic> usuario) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleUsuarioScreen(usuario: usuario),
      ),
    );
    // Refrescar al volver
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _cargar, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: _filtrar,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtrados.isEmpty
                    ? const Center(child: Text('No hay usuarios'))
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.builder(
                          itemCount: _filtrados.length,
                          itemBuilder: (_, i) {
                            final u = _filtrados[i];
                            final nombre = (u['nombre'] ?? 'Sin nombre').toString();
                            return ListTile(
                              onTap: () => _abrirDetalle(u),
                              leading: CircleAvatar(
                                backgroundColor: Colors.indigo.shade100,
                                child: Text(
                                  nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.indigo),
                                ),
                              ),
                              title: Text(nombre),
                              subtitle: Text(u['email'] ?? ''),
                              trailing: const Icon(Icons.chevron_right),
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