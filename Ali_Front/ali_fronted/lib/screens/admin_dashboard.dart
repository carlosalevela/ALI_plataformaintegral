import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'usuarios_screen.dart'; // Asegúrate de crear este archivo también

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> administradores = [];
  Map<String, List<Map<String, dynamic>>> estudiantesPorGrado = {
    '9': [],
    '10': [],
    '11': [],
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verificarPermiso();
  }

  void _verificarPermiso() async {
    final prefs = await SharedPreferences.getInstance();
    final rol = prefs.getString('rol');

    if (rol != 'admin') {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    } else {
      _loadUsuarios();
    }
  }

  void _loadUsuarios() async {
    try {
      final usuarios = await apiService.fetchUsuarios();
      setState(() {
        administradores = usuarios.where((u) => u['rol'] == 'admin').toList();
        estudiantesPorGrado = {
          '9': usuarios.where((u) => u['rol'] == 'estudiante' && u['grado'] == 9).toList(),
          '10': usuarios.where((u) => u['rol'] == 'estudiante' && u['grado'] == 10).toList(),
          '11': usuarios.where((u) => u['rol'] == 'estudiante' && u['grado'] == 11).toList(),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error al cargar usuarios: $e');
    }
  }

  Widget _buildCard(String titulo, IconData icono, List<Map<String, dynamic>> data, Color color) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UsuariosScreen(titulo: titulo, usuarios: List.from(data)),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8db9e4),
        title: const Text('Panel del Administrador', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFf0f4fa),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(20),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildCard("👑 Administradores", Icons.admin_panel_settings, administradores, Colors.teal),
                _buildCard("📘 Estudiantes Grado 9", Icons.school, estudiantesPorGrado['9']!, Colors.blue),
                _buildCard("📗 Estudiantes Grado 10", Icons.school, estudiantesPorGrado['10']!, Colors.green),
                _buildCard("📙 Estudiantes Grado 11", Icons.school, estudiantesPorGrado['11']!, Colors.orange),
              ],
            ),
    );
  }
}
