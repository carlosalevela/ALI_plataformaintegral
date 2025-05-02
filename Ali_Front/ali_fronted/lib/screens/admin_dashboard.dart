import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

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
    _verificarPermiso(); // 🔒 Verificamos si es admin antes de cargar
  }

  void _verificarPermiso() async {
    final prefs = await SharedPreferences.getInstance();
    final rol = prefs.getString('rol');

    if (rol != 'admin') {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/'); // Redirige si no es admin
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

  void _mostrarDialogoEdicion(Map<String, dynamic> usuario) {
    final nombreCtrl = TextEditingController(text: usuario['nombre']);
    final emailCtrl = TextEditingController(text: usuario['email']);
    final gradoCtrl = TextEditingController(text: usuario['grado']?.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar Usuario"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: gradoCtrl, decoration: const InputDecoration(labelText: 'Grado')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final success = await apiService.editarUsuario(usuario['id'], {
                'nombre': nombreCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'grado': int.tryParse(gradoCtrl.text.trim()),
              });
              if (success) {
                Navigator.pop(context);
                _loadUsuarios();
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarUsuario(int id) async {
    final confirmado = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Eliminar usuario?"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Eliminar")),
        ],
      ),
    );

    if (confirmado == true) {
      final success = await apiService.deleteUsuario(id);
      if (success) _loadUsuarios();
    }
  }

  Widget _buildUsuarioCard(Map<String, dynamic> usuario) {
    return Card(
      child: ListTile(
        title: Text(usuario['nombre'] ?? usuario['username']),
        subtitle: Text('Email: ${usuario['email']}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _mostrarDialogoEdicion(usuario),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _eliminarUsuario(usuario['id']),
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
        title: const Text('Panel del Administrador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('👑 Administradores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...administradores.map(_buildUsuarioCard),
                const Divider(),
                const Text('📘 Estudiantes - Grado 9', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...estudiantesPorGrado['9']!.map(_buildUsuarioCard),
                const Divider(),
                const Text('📗 Estudiantes - Grado 10', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...estudiantesPorGrado['10']!.map(_buildUsuarioCard),
                const Divider(),
                const Text('📙 Estudiantes - Grado 11', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...estudiantesPorGrado['11']!.map(_buildUsuarioCard),
              ],
            ),
    );
  }
}
