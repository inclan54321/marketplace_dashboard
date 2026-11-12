import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class TabNotificar extends StatefulWidget {
  const TabNotificar({super.key});

  @override
  State<TabNotificar> createState() => _TabNotificarState();
}

class _TabNotificarState extends State<TabNotificar> {
  final _tituloController = TextEditingController();
  final _mensajeController = TextEditingController();
  String _tipoSeleccionado = 'info';
  bool _enviando = false;
  List<dynamic> _historial = [];
  bool _cargandoHistorial = true;

  final List<Map<String, String>> _tipos = [
    {'valor': 'info', 'label': 'Info', 'icono': 'ℹ️'},
    {'valor': 'promo', 'label': 'Promo', 'icono': '🎉'},
    {'valor': 'urgente', 'label': 'Urgente', 'icono': '🚨'},
    {'valor': 'exito', 'label': 'Éxito', 'icono': '✅'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _cargandoHistorial = true);
    try {
      final data = await ApiService.getHistorialNotificaciones();
      setState(() {
        _historial = data;
        _cargandoHistorial = false;
      });
    } catch (e) {
      setState(() => _cargandoHistorial = false);
    }
  }

  Future<void> _enviar() async {
    final titulo = _tituloController.text.trim();
    final mensaje = _mensajeController.text.trim();

    if (titulo.isEmpty || mensaje.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Título y mensaje son obligatorios')),
      );
      return;
    }

    // Confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Enviar notificación?'),
        content: Text(
          'Se enviará a TODOS los usuarios:\n\n"$titulo"\n\n$mensaje',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _enviando = true);

    try {
      final result = await ApiService.enviarNotificacion(
        titulo: titulo,
        mensaje: mensaje,
        tipo: _tipoSeleccionado,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Enviadas: ${result['enviadas']} / ${result['total_usuarios']}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        _tituloController.clear();
        _mensajeController.clear();
        _cargarHistorial();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _enviando = false);
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

  Color _colorTipo(String? tipo) {
    switch (tipo) {
      case 'promo': return Colors.purple;
      case 'urgente': return Colors.red;
      case 'exito': return Colors.green;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar Notificación'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === FORMULARIO ===
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📢 Nueva notificación masiva',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Título
                    TextField(
                      controller: _tituloController,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        hintText: 'Ej: ¡Nueva promo disponible!',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Mensaje
                    TextField(
                      controller: _mensajeController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Mensaje',
                        hintText: 'Escribe el cuerpo de la notificación...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tipo
                    const Text(
                      'Tipo de notificación',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _tipos.map((t) {
                        final selected = _tipoSeleccionado == t['valor'];
                        return ChoiceChip(
                          label: Text('${t['icono']} ${t['label']}'),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _tipoSeleccionado = t['valor']!),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Botón
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _enviando ? null : _enviar,
                        icon: _enviando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(_enviando ? 'Enviando...' : 'Enviar a todos'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.indigo,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // === HISTORIAL ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📜 Historial',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _cargarHistorial,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_cargandoHistorial)
              const Center(child: CircularProgressIndicator())
            else if (_historial.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Aún no has enviado notificaciones',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              ..._historial.map((n) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _colorTipo(n['tipo']).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.notifications,
                        color: _colorTipo(n['tipo']),
                      ),
                    ),
                    title: Text(
                      n['titulo'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n['mensaje'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_fechaFormateada(n['fecha'])} • ${n['total_enviadas'] ?? 0} enviadas',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}