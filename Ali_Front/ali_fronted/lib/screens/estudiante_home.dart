import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EstudianteHome extends StatefulWidget {
  const EstudianteHome({super.key});

  @override
  State<EstudianteHome> createState() => _EstudianteHomeState();
}

class _EstudianteHomeState extends State<EstudianteHome> {
  String nombre = '';
  String grado = '';
  String edad = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nombre = prefs.getString('nombre') ?? 'Estudiante';
      grado = prefs.getString('grado') ?? 'N/A';
      edad = prefs.getString('edad') ?? 'N/A';
    });
  }

  String _tipoTest(String grado) {
    final g = int.tryParse(grado) ?? 0;
    if (g == 10) return 'Test Técnico';
    if (g == 11) return 'Test Tecnológico';
    if (g == 9) return 'Test Grado 9';
    return 'Test Vocacional';
  }

  @override
  Widget build(BuildContext context) {
    final tipoTest = _tipoTest(grado);

    return Scaffold(
      backgroundColor: const Color(0xFFEAF4F4),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Encabezado
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  child: Image.asset(
                    'assets/illustration_home.png',
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¡Hola, $nombre!',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('🎓 Grado: $grado',
                          style: const TextStyle(color: Colors.white)),
                      Text('🎂 Edad: $edad años',
                          style: const TextStyle(color: Colors.white)),
                      Text('🧪 $tipoTest',
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Tarjetas en 2x2
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: MediaQuery.of(context).size.width > 800 ? 2 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.8,
                    children: [
                      _cardItem(
                        icon: Icons.sentiment_satisfied_alt,
                        color: Colors.lightBlueAccent,
                        title: '¿Qué es un Test Vocacional?',
                        description:
                            'Es una herramienta que permite conocer tus intereses, fortalezas y preferencias para ayudarte a elegir una carrera o formación técnica.',
                      ),
                      _cardItem(
                        icon: Icons.settings,
                        color: Colors.teal,
                        title: 'Metodología RIASEC',
                        description:
                            'Usamos el modelo RIASEC: Realista, Investigativa, Artística, Social, Emprendedora y Convencional.',
                      ),
                      _cardItem(
                        icon: Icons.compare_arrows,
                        color: Colors.indigo,
                        title: '¿Cómo funciona?',
                        description:
                            'Respondes 40 preguntas simples según tu interés. El sistema analiza tus respuestas y recomienda una modalidad.',
                      ),
                      _cardItem(
                        icon: Icons.check_circle,
                        color: Colors.deepPurple,
                        title: 'Beneficios del Test',
                        description:
                            '• Identificar tus gustos\n• Elegir con seguridad\n• Recibir orientación\n• Evitar decisiones erradas',
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // Botón Iniciar Test
            if (grado == '9')
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/test_grado9'),
                icon: const Icon(Icons.play_circle_fill),
                label: const Text('Iniciar Test Grado 9'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8DB9E4),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

            const SizedBox(height: 20),

            // Botón Cerrar Sesión
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _cardItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 22,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(description, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
