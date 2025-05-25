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

      // Guardar tokens y datos del usuario
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

  // Decodificar token JWT para extraer datos (como el rol)
  Map<String, dynamic> _decodeJWT(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};

    final payload = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(payload));
    return jsonDecode(decoded);
  }

  // Enviar respuestas al test de grado 9
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
        'respuestas': respuestas
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

  /// Enviar respuestas al test de grado 10 y 11
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

}
