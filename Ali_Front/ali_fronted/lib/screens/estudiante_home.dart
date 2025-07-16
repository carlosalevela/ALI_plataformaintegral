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
    if (g == 10) return 'Test Para Recomendacion De Una Carrera';
    if (g == 11) return 'Test Para Recomendacion De Una Carrera';
    if (g == 9) return 'Test Para Recomendacion de un Tecnico';
    return 'Test Vocacional';
  }

  @override
  Widget build(BuildContext context) {
    final tipoTest = _tipoTest(grado);
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 800;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/fondo_home.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      _headerVisual(nombre, grado, edad, tipoTest, isWeb),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;
                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: 1.8,
                              children: [
                                _cardItem(
                                  icon: Icons.sentiment_satisfied_alt,
                                  color: Colors.lightBlue,
                                  title: '¿Qué es un Test Vocacional?',
                                  description:
                                      'Es una herramienta que permite conocer tus intereses, fortalezas y preferencias para ayudarte a elegir una carrera o formación técnica.',
                                ),
                                _cardItem(
                                  icon: Icons.settings,
                                  color: Colors.green,
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
                      if (grado == '9') ...[
                        _botonIniciarTest(() =>
                            Navigator.pushNamed(context, '/test_grado9'), 'Iniciar Test Grado 9'),
                      ] else if (grado == '10' || grado == '11') ...[
                        _botonIniciarTest(() =>
                            Navigator.pushNamed(context, '/test_grado_10_11'), 'Iniciar Test Grado $grado'),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
            _botonCerrarSesion(context),
          ],
        ),
      ),
    );
  }

  Widget _headerVisual(String nombre, String grado, String edad, String tipoTest, bool isWeb) {
    final double fontSize = isWeb ? 38 : 26;
    final double imageSize = isWeb ? 240 : 160;

    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Image.asset(
              'assets/nino_home.png',
              height: imageSize,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 24,
            top: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, $nombre!',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PatrickHand',
                    color: Colors.black87,
                    shadows: const [Shadow(color: Colors.white70, blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 12),
                _infoBurbuja('Edad: $edad'),
                _infoBurbuja('Grado: $grado'),
                _infoBurbuja(tipoTest),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBurbuja(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontFamily: 'PatrickHand',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _botonIniciarTest(VoidCallback onPressed, String texto) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF62A8E5),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle_fill, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                texto,
                style: const TextStyle(
                  fontFamily: 'PatrickHand',
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonCerrarSesion(BuildContext context) {
    return Positioned(
      top: 24,
      right: 24,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 1.2),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              children: const [
                Icon(Icons.logout, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    fontFamily: 'PatrickHand',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 26,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
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
