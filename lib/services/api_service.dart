import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  // ===== RESUMEN =====
  static Future<Map<String, dynamic>> getResumen() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.resumen}'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error ${res.statusCode}');
  }

  // ===== USUARIOS =====
  static Future<List<dynamic>> getUsuarios() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarios}'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error ${res.statusCode}');
  }

  static Future<Map<String, dynamic>> getDetalleUsuario(String uid) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/usuarios/$uid/detalle'),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error ${res.statusCode}');
  }

  // ===== PRODUCTOS =====
  static Future<List<dynamic>> getProductos() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error ${res.statusCode}');
  }

  // ===== DENUNCIAS =====
  static Future<int> getDenunciasNuevasCount() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/denuncias/contador'),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['nuevas'] ?? 0;
    }
    throw Exception('Error ${res.statusCode}');
  }

  static Future<List<dynamic>> getDenunciasNuevas() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/denuncias/nuevas'),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error ${res.statusCode}');
  }

  static Future<List<dynamic>> getDenunciasArchivadas() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/denuncias/archivadas'),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error ${res.statusCode}');
  }

  static Future<void> archivarDenuncia(int id) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/denuncias/$id/archivar'),
    );
    if (res.statusCode != 200) throw Exception('Error ${res.statusCode}');
  }

  static Future<void> desarchivarDenuncia(int id) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/denuncias/$id/desarchivar'),
    );
    if (res.statusCode != 200) throw Exception('Error ${res.statusCode}');
  }

  // ===== NOTIFICACIONES MASIVAS =====
  static Future<Map<String, dynamic>> enviarNotificacion({
    required String titulo,
    required String mensaje,
    required String tipo,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/notificaciones/enviar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'titulo': titulo, 'mensaje': mensaje, 'tipo': tipo}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error ${res.statusCode}: ${res.body}');
  }

  static Future<List<dynamic>> getHistorialNotificaciones() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/notificaciones/historial'),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error ${res.statusCode}');
  }

  // ===== ACCIONES DE USUARIO (sanciones) =====
  static Future<void> enviarMensajeUsuario(
    String uid, {
    required String titulo,
    required String mensaje,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/usuarios/$uid/mensaje'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'titulo': titulo, 'mensaje': mensaje}),
    );
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }
  }

  static Future<void> advertirUsuario(
    String uid, {
    required String motivo,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/usuarios/$uid/advertir'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'motivo': motivo}),
    );
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }
  }

  static Future<void> suspenderUsuario(
    String uid, {
    required String motivo,
    required int dias,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/usuarios/$uid/suspender'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'motivo': motivo, 'dias': dias}),
    );
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }
  }

  static Future<void> banearUsuario(
    String uid, {
    required String motivo,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/usuarios/$uid/banear'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'motivo': motivo}),
    );
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }
  }

  static Future<void> reactivarUsuario(String uid) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/usuarios/$uid/reactivar'),
    );
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }
  }

  // ===== PRODUCTOS =====
  static Future<void> eliminarProducto(int id) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/productos/$id/eliminar'),
    );
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }
  }
    static Future<void> restaurarProducto(int id) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/productos/$id/restaurar'),
    );
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }
  }

  // ===== SOPORTE =====
  static Future<int> getSoporteNuevosCount() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/soporte/contador'),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['nuevos'] ?? 0;
    }
    throw Exception('Error ${res.statusCode}');
  }

  static Future<List<dynamic>> getSoporteNuevos() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/soporte/nuevos'),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error ${res.statusCode}');
  }

  static Future<List<dynamic>> getSoporteRespondidos() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/soporte/respondidos'),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error ${res.statusCode}');
  }

  static Future<void> responderSoporte(int id, String respuesta) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/soporte/$id/responder'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'respuesta': respuesta}),
    );
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }
  }

  static Future<void> marcarSoporteLeido(int id) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/soporte/$id/leido'),
    );
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode}');
    }
  }

  static Future<void> cerrarSoporte(int id) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/soporte/$id/cerrar'),
    );
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode}');
    }
  }
}