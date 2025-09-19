import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000/Alipsicoorientadora/usuarios";

  // Función de inicio de sesión
  Future<Map<String, dynamic>> login(String username, String password, String email) async {
    final url = Uri.parse('$baseUrl/login/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final decoded = _decodeJWT(data['access']);
      final rol = decoded['rol'];
      final nombre = decoded['nombre'];
      final grado = decoded['grado'].toString();
      final edad = decoded['edad'].toString();
      final userId = decoded['user_id'];

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access']);
      await prefs.setString('refresh_token', data['refresh']);
      await prefs.setString('rol', rol);
      await prefs.setString('nombre', nombre);
      await prefs.setString('grado', grado);
      await prefs.setString('edad', edad);
      await prefs.setInt('user_id', userId);

      return {'success': true, 'role': rol};
    } else {
      return {'success': false, 'message': 'Credenciales incorrectas'};
    }
  }

  // Función de registro
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final url = Uri.parse('$baseUrl/registro/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 201) {
      return {'success': true};
    } else {
      return {'success': false, 'message': jsonDecode(response.body)};
    }
  }

  // Obtener todos los usuarios (solo para admin)
  Future<List<Map<String, dynamic>>> fetchUsuarios() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final url = Uri.parse('$baseUrl/usuarios/');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Error al obtener usuarios');
    }
  }

  // 🔍 Buscar usuarios (nombre, email o username)
  Future<List<Map<String, dynamic>>> buscarUsuarios({
    String nombre = '',
    String email = '',
    String username = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final queryParameters = {
      if (nombre.isNotEmpty) 'nombre': nombre,
      if (email.isNotEmpty) 'email': email,
      if (username.isNotEmpty) 'username': username,
    };

    final uri = Uri.http(
      '127.0.0.1:8000',
      '/Alipsicoorientadora/usuarios/usuarios/',
      queryParameters,
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Error al buscar usuarios: ${response.statusCode}');
    }
  }

  // Eliminar un usuario
  Future<bool> deleteUsuario(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final url = Uri.parse('$baseUrl/usuarios/$id/');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  // Editar un usuario
  Future<bool> editarUsuario(int id, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final url = Uri.parse('$baseUrl/usuarios/$id/');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 200;
  }

  // Decodificar token JWT
  Map<String, dynamic> _decodeJWT(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    final payload = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(payload));
    return jsonDecode(decoded);
  }

  // Enviar test grado 9
  Future<Map<String, dynamic>> enviarTestGrado9(Map<String, dynamic> respuestas) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userId = prefs.getInt('user_id');

    final url = Uri.parse('http://127.0.0.1:8000/Alipsicoorientadora/tests-grado9/');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'usuario': userId,
        'respuestas': respuestas,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {'success': true, 'resultado': data};
    } else {
      return {
        'success': false,
        'message': 'Error en el test: ${response.body}'
      };
    }
  }

  // Enviar test grado 10/11
  Future<Map<String, dynamic>> enviarTestGrado10y11(Map<String, String> respuestas) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userId = prefs.getInt('user_id');

    final url = Uri.parse('http://127.0.0.1:8000/Alipsicoorientadora/tests-grado10-11/');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'usuario': userId,
        'respuestas': respuestas,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {'success': true, 'resultado': data};
    } else {
      return {
        'success': false,
        'message': 'Error en el test: ${response.statusCode} ${response.body}',
      };
    }
  }

  // Obtener resultado test grado 9 por ID
  Future<Map<String, dynamic>> fetchResultadoTest9PorId(int testId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final url = Uri.parse('http://127.0.0.1:8000/Alipsicoorientadora/tests-grado9/resultado/$testId/');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener resultado test: ${response.statusCode}');
    }
  }

  // Obtener tests grado 9 por usuario
  Future<List<dynamic>> fetchTestsGrado9PorUsuario(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final url = Uri.parse('http://127.0.0.1:8000/Alipsicoorientadora/tests-grado9/usuario/$userId/');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener tests de usuario: ${response.statusCode}');
    }
  }

  // Obtener tests grado 10/11 por usuario
  Future<List<dynamic>> fetchTestsGrado10y11PorUsuario(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final url = Uri.parse('http://127.0.0.1:8000/Alipsicoorientadora/tests-grado10-11/usuario/$userId/');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener tests de usuario 10/11: ${response.statusCode}');
    }
  }

  // Obtener resultado test 10/11 por ID
  Future<Map<String, dynamic>> fetchResultadoTest10y11PorId(int testId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final url = Uri.parse('http://127.0.0.1:8000/Alipsicoorientadora/tests-grado10-11/resultado/$testId/');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener resultado test 10/11: ${response.statusCode}');
    }
  }

    // ➜ Agrega esto dentro de tu clase ApiService

Future<List<Map<String, dynamic>>> listarMisTestsGrado9() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  final url = Uri.parse('http://127.0.0.1:8000/Alipsicoorientadora/tests-grado9/'); // GET list
  final resp = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (resp.statusCode == 200) {
    final List data = jsonDecode(resp.body);
    // Esperado: [{id, resultado, fecha_realizacion, ...}, ...]
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('No se pudo cargar el historial (${resp.statusCode})');
  }
}

Future<Map<String, dynamic>> obtenerResultadoTest9PorId(int testId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  final url = Uri.parse('http://127.0.0.1:8000/Alipsicoorientadora/tests-grado9/resultado/$testId/');
  final resp = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (resp.statusCode == 200) {
    final data = jsonDecode(resp.body);
    return {'success': true, 'data': data};
  } else {
    return {
      'success': false,
      'error': 'No se pudo obtener el resultado ($testId): ${resp.statusCode}'
    };
  }
}
  Future<List<Map<String, dynamic>>> listarMisTestsGrado10y11() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  final url = Uri.parse('http://127.0.0.1:8000/Alipsicoorientadora/tests-grado10-11/');
  final resp = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (resp.statusCode == 200) {
    final List data = jsonDecode(resp.body);
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('No se pudo cargar el historial 10/11 (${resp.statusCode})');
  }
}

Future<Map<String, dynamic>> obtenerResultadoTest1011PorId(int testId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  final url = Uri.parse('http://127.0.0.1:8000/Alipsicoorientadora/tests-grado10-11/resultado/$testId/');
  final resp = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (resp.statusCode == 200) {
    final data = jsonDecode(resp.body);
    return {'success': true, 'data': data};
  } else {
    return {
      'success': false,
      'error': 'No se pudo obtener el resultado ($testId): ${resp.statusCode}'
    };
  }
}
    // ===============================
// PROGRESO: feeds y helpers (ADD)
// ===============================

// Lista general (admin) de tests 9° con filtros (?estado=&orden=&limit=&offset=)
Future<List<Map<String, dynamic>>> fetchTestsGrado9({
  String? estado,      // EN_PROGRESO | FINALIZADO
  String? orden,       // actividad (usa fecha_ultima_actividad)
  int? limit,          // si tu back usa LimitOffsetPagination
  int? offset,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  final q = <String, String>{};
  if (estado != null && estado.isNotEmpty) q['estado'] = estado;
  if (orden  != null && orden.isNotEmpty)  q['orden']  = orden;
  if (limit  != null) q['limit']  = '$limit';
  if (offset != null) q['offset'] = '$offset';

  final uri = Uri.http('127.0.0.1:8000', '/Alipsicoorientadora/tests-grado9/', q);
  final resp = await http.get(uri, headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  });

  if (resp.statusCode == 200) {
    final data = jsonDecode(resp.body);
    return (data as List).cast<Map<String, dynamic>>();
  } else {
    throw Exception('Error al listar tests 9° (${resp.statusCode})');
  }
}

// Lista general (admin) de tests 10/11 con filtros (?estado=&orden=&limit=&offset=)
Future<List<Map<String, dynamic>>> fetchTestsGrado10y11({
  String? estado,      // EN_PROGRESO | FINALIZADO
  String? orden,       // actividad
  int? limit,
  int? offset,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  final q = <String, String>{};
  if (estado != null && estado.isNotEmpty) q['estado'] = estado;
  if (orden  != null && orden.isNotEmpty)  q['orden']  = orden;
  if (limit  != null) q['limit']  = '$limit';
  if (offset != null) q['offset'] = '$offset';

  final uri = Uri.http('127.0.0.1:8000', '/Alipsicoorientadora/tests-grado10-11/', q);
  final resp = await http.get(uri, headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  });

  if (resp.statusCode == 200) {
    final data = jsonDecode(resp.body);
    return (data as List).cast<Map<String, dynamic>>();
  } else {
    throw Exception('Error al listar tests 10/11 (${resp.statusCode})');
  }
}

// Formatea una línea de progreso legible para la UI
String _formatProgreso(Map<String, dynamic> t, {required int total}) {
  final estado = t['estado']?.toString() ?? '';
  final resp   = (t['respondidas'] as num?)?.toInt() ?? 0;
  final ult    = (t['ultima_pregunta'] as num?)?.toInt() ?? 0;
  final pct    = (t['progreso_pct'] as num?)?.toDouble() ?? (total > 0 ? (resp / total) * 100 : 0);

  if (estado == 'FINALIZADO') return 'Finalizado';
  if (estado == 'EN_PROGRESO') return 'En progreso: $resp/$total (P$ult) ${pct.toStringAsFixed(0)}%';
  return '—';
}

// Devuelve el mejor test para pintar progreso (prefiere EN_PROGRESO reciente; si no, el último finalizado)
Map<String, dynamic>? _pickBestTestForUser(
  List<Map<String, dynamic>> feed,
  int userId,
) {
  final mine = feed.where((t) => t['usuario'] == userId).toList();
  if (mine.isEmpty) return null;

  // Prioriza EN_PROGRESO (asume feed ya viene ordenado si usas orden=actividad)
  final enProg = mine.where((t) => t['estado'] == 'EN_PROGRESO').toList();
  if (enProg.isNotEmpty) return enProg.first;

  // Si no hay en progreso, toma el más reciente por fecha_realizacion
  mine.sort((a, b) => (b['fecha_realizacion'] ?? '').toString().compareTo((a['fecha_realizacion'] ?? '').toString()));
  return mine.first;
}

// ===============================
// ENDPOINTS DE ALTO NIVEL (ADD)
// ===============================

// ➜ Progreso consolidado para un usuario de 9°
//   - Busca en feed EN_PROGRESO (orden actividad) y cae a "por usuario" si no hay en progreso
//   - Retorna { progreso, ultimaRecomendacion, testId }
Future<Map<String, dynamic>> progresoUsuarioGrado9(int userId, {int total = 40}) async {
  try {
    // 1) Feed EN_PROGRESO ordenado por actividad (admin)
    final feedProg = await fetchTestsGrado9(estado: 'EN_PROGRESO', orden: 'actividad', limit: 200, offset: 0);
    Map<String, dynamic>? best = _pickBestTestForUser(feedProg, userId);

    // 2) Si no hay, cae al endpoint por usuario (ya lo tienes)
    if (best == null) {
      final testsUsr = await fetchTestsGrado9PorUsuario(userId);
      if (testsUsr.isNotEmpty) {
        // vienen ya ordenados por -fecha_realizacion desde el back
        best = Map<String, dynamic>.from(testsUsr.first);
      }
    }

    if (best == null) return {'progreso': '—', 'ultimaRecomendacion': '—', 'testId': null};

    final progreso = _formatProgreso(best, total: total);
    final String ultimaRec = (best['resultado'] as String?) ?? '—';

    return {
      'progreso': progreso,
      'ultimaRecomendacion': ultimaRec,
      'testId': best['id'],
    };
  } catch (_) {
    return {'progreso': '—', 'ultimaRecomendacion': '—', 'testId': null};
  }
}

// ➜ Progreso consolidado para un usuario de 10/11
Future<Map<String, dynamic>> progresoUsuarioGrado10y11(int userId, {int total = 40}) async {
  try {
    final feedProg = await fetchTestsGrado10y11(estado: 'EN_PROGRESO', orden: 'actividad', limit: 200, offset: 0);
    Map<String, dynamic>? best = _pickBestTestForUser(feedProg, userId);

    if (best == null) {
      final testsUsr = await fetchTestsGrado10y11PorUsuario(userId);
      if (testsUsr.isNotEmpty) {
        best = Map<String, dynamic>.from(testsUsr.first);
      }
    }

    if (best == null) return {'progreso': '—', 'ultimaRecomendacion': '—', 'testId': null};

    final progreso = _formatProgreso(best, total: total);
    final String ultimaRec = (best['resultado'] as String?) ?? '—';

    return {
      'progreso': progreso,
      'ultimaRecomendacion': ultimaRec,
      'testId': best['id'],
    };
  } catch (_) {
    return {'progreso': '—', 'ultimaRecomendacion': '—', 'testId': null};
  }
}


}
