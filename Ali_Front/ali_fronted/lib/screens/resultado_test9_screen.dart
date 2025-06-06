import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'estudiante_home.dart';

class ResultadoTest9Screen extends StatelessWidget {
  final String resultado;
  final Map<String, double> porcentajes; // A, B, C, D
  final IconData icono;
  final Color color;

  const ResultadoTest9Screen({
    Key? key,
    required this.resultado,
    required this.porcentajes,
    required this.icono,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Resultado del Test Grado 9'),
        backgroundColor: color,
        elevation: 0,
      ),
      body: Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.all(24),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono, color: color, size: 50),
                const SizedBox(height: 12),
                Text(
                  'Modalidad sugerida:',
                  style: TextStyle(
                    fontSize: 18,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  resultado,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ...porcentajes.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      '${entry.key}: ${entry.value.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '¡Gracias por completar el test!',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Borra progreso guardado antes de volver
                    final prefs = await SharedPreferences.getInstance();
                    final userId = prefs.getInt('user_id');
                    if (userId != null) {
                      await prefs.remove('test_grado9_respuestas_$userId');
                    }
                    // Navega al Home de estudiantes y elimina rutas anteriores
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => EstudianteHome()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver al inicio'),
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
