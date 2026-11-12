import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class DetalleSoporteScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;
  const DetalleSoporteScreen({super.key, required this.ticket});

  @override
  State<DetalleSoporteScreen> createState() => _DetalleSoporteScreenState();
}

class _DetalleSoporteScreenState extends State<DetalleSoporteScreen> {
  final _respuestaCtrl = TextEditingController();
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    if (widget.ticket['estado'] == 'nuevo') {
      _marcarLeido();
    }
  }

  Future<void> _marcarLeido() async {
    try {
      await ApiService.marcarSoporteLeido(widget.ticket['id']);
    } catch (_) {}
  }

  @override
  void dispose() {
    _respuestaCtrl.dispose();
    super.dispose();
  }

  Future<void> _responder() async {
    final respuesta = _respuestaCtrl.text.trim();
    if (respuesta.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe una respuesta')),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enviar respuesta'),
        content: const Text(
          'El usuario recibirá una notificación con tu respuesta.\n\n¿Enviar?',
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
      await ApiService.responderSoporte(widget.ticket['id'], respuesta);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Respuesta enviada'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _cerrar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar ticket'),
        content: const Text('¿Marcar este ticket como cerrado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar ticket'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ApiService.cerrarSoporte(widget.ticket['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📭 Ticket cerrado')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _fechaFormateada(dynamic fecha) {
    if (fecha == null) return '-';
    try {
      final dt = DateTime.parse(fecha.toString());
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return fecha.toString();
    }
  }

  Color _colorEstado(String? estado) {
    switch (estado) {
      case 'nuevo':
        return Colors.red;
      case 'leido':
        return Colors.orange;
      case 'respondido':
        return Colors.green;
      case 'cerrado':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    final estado = t['estado'] ?? 'nuevo';
    final yaRespondido = estado == 'respondido' || estado == 'cerrado';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket de Soporte'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (estado != 'cerrado')
            IconButton(
              onPressed: _cerrar,
              icon: const Icon(Icons.archive),
              tooltip: 'Cerrar ticket',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ESTADO
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _colorEstado(estado).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                estado.toUpperCase(),
                style: TextStyle(
                  color: _colorEstado(estado),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // USUARIO
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  child: Text(
                    (t['usuario_nombre'] ?? '?').toString()[0].toUpperCase(),
                    style: const TextStyle(color: Colors.indigo),
                  ),
                ),
                title: Text(t['usuario_nombre'] ?? 'Usuario'),
                subtitle: Text(t['usuario_email'] ?? ''),
              ),
            ),
            const SizedBox(height: 16),

            // ASUNTO
            const Text(
              '📌 Asunto',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(t['asunto'] ?? 'Sin asunto'),
            const SizedBox(height: 16),

            // MENSAJE
            const Text(
              '💬 Mensaje del usuario',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(t['mensaje'] ?? ''),
            ),
            const SizedBox(height: 8),
            Text(
              '📅 ${_fechaFormateada(t['fecha'])}',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
            const SizedBox(height: 20),

            // RESPUESTA PREVIA
            if (t['respuesta'] != null &&
                t['respuesta'].toString().isNotEmpty) ...[
              const Text(
                '✅ Tu respuesta',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(t['respuesta']),
              ),
              const SizedBox(height: 8),
              Text(
                '📅 ${_fechaFormateada(t['fecha_respuesta'])}',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],

            // CAMPO RESPUESTA
            if (!yaRespondido) ...[
              const Text(
                '✍️ Responder',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _respuestaCtrl,
                maxLines: 5,
                maxLength: 1000,
                decoration: const InputDecoration(
                  hintText: 'Escribe tu respuesta al usuario...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _enviando ? null : _responder,
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
                  label: Text(_enviando ? 'Enviando...' : 'Enviar respuesta'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}