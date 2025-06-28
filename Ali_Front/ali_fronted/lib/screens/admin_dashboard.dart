import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'estadisticas_screen.dart';

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

  void _mostrarDialogoEdicion(Map<String, dynamic> usuario) {
    final nombreCtrl = TextEditingController(text: usuario['nombre']);
    final emailCtrl = TextEditingController(text: usuario['email']);
    final gradoCtrl = TextEditingController(text: usuario['grado']?.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFf5f9ff),
        title: const Text(
          "Editar Usuario",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2a3f5f)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: gradoCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Grado',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.cancel, color: Colors.redAccent),
            label: const Text("Cancelar", style: TextStyle(color: Colors.redAccent)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("Guardar"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF59bde9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarUsuario(int id) async {
    final confirmado = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.all(0),
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF8db9e4),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          ),
          child: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "Confirmar eliminación",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "¿Estás seguro de eliminar este usuario?\n\nEsta acción no se puede deshacer.",
            style: TextStyle(fontSize: 15),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.cancel, color: Colors.grey),
            label: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever),
            label: const Text("Eliminar"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EstadisticasUsuarioScreen(
                usuarioId: usuario['id'],
                nombre: usuario['nombre'] ?? usuario['username'],
                grado: usuario['grado'],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (usuario['nombre'] != null)
                Text(
                  usuario['nombre'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              Text('Email: ${usuario['email']}', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    onPressed: () => _mostrarDialogoEdicion(usuario),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF59bde9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    label: const Text("Editar"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever, size: 16),
                    onPressed: () => _eliminarUsuario(usuario['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    label: const Text("Eliminar"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccion(String titulo, List<Map<String, dynamic>> usuarios) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3a506b),
            ),
          ),
          const SizedBox(height: 12),
          ...usuarios.map((u) => _buildUsuarioCard(u)).toList(),
        ],
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
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildSeccion("👑 Administradores", administradores),
                    _buildSeccion("📘 Estudiantes - Grado 9", estudiantesPorGrado['9']!),
                    _buildSeccion("📗 Estudiantes - Grado 10", estudiantesPorGrado['10']!),
                    _buildSeccion("📙 Estudiantes - Grado 11", estudiantesPorGrado['11']!),
                  ],
                ),
              ),
            ),
    );
  }
}
