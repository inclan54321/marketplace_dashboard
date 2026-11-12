import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class DetalleUsuarioScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const DetalleUsuarioScreen({super.key, required this.usuario});

  @override
  State<DetalleUsuarioScreen> createState() => _DetalleUsuarioScreenState();
}

class _DetalleUsuarioScreenState extends State<DetalleUsuarioScreen> {
  Map<String, dynamic>? _detalle;
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
      final data = await ApiService.getDetalleUsuario(widget.usuario['uid']);
      if (!mounted) return;
      setState(() {
        _detalle = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ==================== ACCIONES ====================

  Future<void> _enviarMensaje() async {
    final tituloCtrl = TextEditingController();
    final mensajeCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('💬 Enviar mensaje'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mensajeCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Mensaje',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
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

    if (ok != true) return;
    if (tituloCtrl.text.trim().isEmpty || mensajeCtrl.text.trim().isEmpty) return;

    try {
      await ApiService.enviarMensajeUsuario(
        widget.usuario['uid'],
        titulo: tituloCtrl.text.trim(),
        mensaje: mensajeCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Mensaje enviado'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _advertir() async {
    final motivoCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ Advertir usuario'),
        content: TextField(
          controller: motivoCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motivo de la advertencia',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Advertir'),
          ),
        ],
      ),
    );

    if (ok != true || motivoCtrl.text.trim().isEmpty) return;

    try {
      await ApiService.advertirUsuario(
        widget.usuario['uid'],
        motivo: motivoCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Usuario advertido'),
          backgroundColor: Colors.orange,
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

  Future<void> _suspender() async {
    final motivoCtrl = TextEditingController();
    int diasSeleccionados = 7;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('🚫 Suspender usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: motivoCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de la suspensión',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Duración:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [7, 30, 90].map((d) {
                    return ChoiceChip(
                      label: Text('$d días'),
                      selected: diasSeleccionados == d,
                      onSelected: (_) =>
                          setDialogState(() => diasSeleccionados = d),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Suspender'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || motivoCtrl.text.trim().isEmpty) return;

    try {
      await ApiService.suspenderUsuario(
        widget.usuario['uid'],
        motivo: motivoCtrl.text.trim(),
        dias: diasSeleccionados,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🚫 Suspendido por $diasSeleccionados días'),
          backgroundColor: Colors.red,
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

  Future<void> _banear() async {
    final motivoCtrl = TextEditingController();

    final confirmar1 = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⛔ Banear usuario'),
        content: const Text(
          'Esto bloqueará al usuario PERMANENTEMENTE. No podrá volver a entrar.\n\n¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, continuar'),
          ),
        ],
      ),
    );

    if (confirmar1 != true) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Motivo del baneo'),
        content: TextField(
          controller: motivoCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motivo (visible para el usuario)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Banear permanentemente'),
          ),
        ],
      ),
    );

    if (ok != true || motivoCtrl.text.trim().isEmpty) return;

    try {
      await ApiService.banearUsuario(
        widget.usuario['uid'],
        motivo: motivoCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⛔ Usuario baneado'),
          backgroundColor: Colors.red,
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

  Future<void> _reactivar() async {
    try {
      await ApiService.reactivarUsuario(widget.usuario['uid']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Usuario reactivado'),
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

  // ==================== HELPERS ====================

  Color _colorEstado(String? estado) {
    switch (estado) {
      case 'advertido':
        return Colors.orange;
      case 'suspendido':
        return Colors.red;
      case 'baneado':
        return Colors.black;
      default:
        return Colors.green;
    }
  }

  String _labelEstado(String? estado) {
    switch (estado) {
      case 'advertido':
        return '⚠️ Advertido';
      case 'suspendido':
        return '🚫 Suspendido';
      case 'baneado':
        return '⛔ Baneado';
      default:
        return '✅ Activo';
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

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final nombre = widget.usuario['nombre'] ?? 'Sin nombre';
    return Scaffold(
      appBar: AppBar(
        title: Text(nombre),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final u = _detalle!['usuario'];
    final estado = u['estado_cuenta'] ?? 'activo';
    final nombre = (u['nombre'] ?? 'Sin nombre').toString();

    return RefreshIndicator(
      onRefresh: _cargar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== CABECERA =====
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.indigo.shade100,
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    u['email'] ?? '',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ===== ESTADO =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _colorEstado(estado).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _colorEstado(estado).withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _labelEstado(estado),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _colorEstado(estado),
                    ),
                  ),
                  if (u['motivo_sancion'] != null) ...[
                    const SizedBox(height: 8),
                    Text('Motivo: ${u['motivo_sancion']}'),
                  ],
                  if (u['fecha_fin_sancion'] != null) ...[
                    const SizedBox(height: 4),
                    Text('Hasta: ${_fechaFormateada(u['fecha_fin_sancion'])}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ===== ESTADÍSTICAS =====
            const Text(
              '📊 Estadísticas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Productos',
                    '${_detalle!['total_productos']}',
                    Icons.shopping_bag,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    'Denuncias',
                    '${_detalle!['total_denuncias']}',
                    Icons.report,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ===== ACCIONES =====
            const Text(
              '🎯 Acciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _accionBtn(
              'Enviar mensaje',
              Icons.message,
              Colors.blue,
              _enviarMensaje,
            ),
            _accionBtn(
              'Advertir',
              Icons.warning_amber,
              Colors.orange,
              _advertir,
            ),
            _accionBtn(
              'Suspender',
              Icons.block,
              Colors.red,
              _suspender,
            ),
            _accionBtn(
              'Banear permanentemente',
              Icons.gavel,
              Colors.black,
              _banear,
            ),
            if (estado != 'activo')
              _accionBtn(
                'Reactivar',
                Icons.check_circle,
                Colors.green,
                _reactivar,
              ),
            const SizedBox(height: 24),

            // ===== HISTORIAL =====
            const Text(
              '📜 Historial de sanciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if ((_detalle!['sanciones'] as List).isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Sin sanciones previas',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              ...(_detalle!['sanciones'] as List).map((s) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      s['tipo'] == 'baneo'
                          ? Icons.gavel
                          : s['tipo'] == 'suspension'
                              ? Icons.block
                              : Icons.warning_amber,
                      color: s['activa'] == true ? Colors.red : Colors.grey,
                    ),
                    title: Text(
                      s['tipo'].toString().toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['motivo'] ?? ''),
                        const SizedBox(height: 4),
                        Text(
                          _fechaFormateada(s['fecha_inicio']),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String valor, IconData icono, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icono, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accionBtn(
    String label,
    IconData icono,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icono, color: color),
          label: Text(label, style: TextStyle(color: color)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: color.withValues(alpha: 0.5)),
            alignment: Alignment.centerLeft,
          ),
        ),
      ),
    );
  }
}