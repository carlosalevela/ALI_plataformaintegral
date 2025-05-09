import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EstudianteHome extends StatefulWidget {
  const EstudianteHome({super.key});

  @override
  State<EstudianteHome> createState() => _EstudianteHomeState();
}

class _EstudianteHomeState extends State<EstudianteHome> with SingleTickerProviderStateMixin {
  String nombre = '';
  String grado = '';
  String edad = '';
  bool expanded = false;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _queEsKey = GlobalKey();
  final GlobalKey _metodologiaKey = GlobalKey();
  final GlobalKey _comoFuncionaKey = GlobalKey();
  final GlobalKey _beneficiosKey = GlobalKey();

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

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
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
    final testTipo = _tipoTest(grado);

    return Scaffold(
      backgroundColor: const Color(0xFFEAF4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF263238),
        elevation: 4,
        title: const Text('Test de Interés Vocacional', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => _scrollToSection(_queEsKey),
            child: const Text('¿Qué es?', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => _scrollToSection(_metodologiaKey),
            child: const Text('Metodología', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => _scrollToSection(_comoFuncionaKey),
            child: const Text('¿Cómo funciona?', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => _scrollToSection(_beneficiosKey),
            child: const Text('Beneficios', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              onTap: () => setState(() => expanded = !expanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color.fromARGB(255, 104, 255, 237), Color(0xFF004D40)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.white,
                          child: Icon(FontAwesomeIcons.userGraduate, color: Colors.teal, size: 30),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '¡Hola, $nombre!',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🎓 Grado: $grado    🎂 Edad: $edad años',
                              style: const TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 10),
                          Text('🧪 $testTipo',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  AnimatedSection(
                    key: _queEsKey,
                    icon: Icons.help_outline,
                    title: '¿Qué es un Test Vocacional?',
                    content: 'Es una herramienta que permite conocer tus intereses, fortalezas y preferencias para ayudarte a elegir una carrera o formación técnica. Su objetivo es brindarte claridad para tomar decisiones académicas y profesionales.',
                  ),
                  AnimatedSection(
                    key: _metodologiaKey,
                    icon: Icons.extension,
                    title: 'Metodología RIASEC',
                    content: 'Usamos el modelo RIASEC, que clasifica las preferencias en 6 áreas: Realista, Investigativa, Artística, Social, Emprendedora y Convencional. A través de tus respuestas, se identifica tu perfil predominante.',
                  ),
                  AnimatedSection(
                    key: _comoFuncionaKey,
                    icon: Icons.auto_mode,
                    title: '¿Cómo funciona?',
                    content: 'Respondes 40 preguntas simples según tu interés (me gusta, me interesa, no me gusta, no me interesa). Al final, el sistema analiza tus patrones y sugiere una modalidad formativa alineada a tu perfil.',
                  ),
                  AnimatedSection(
                    key: _beneficiosKey,
                    icon: Icons.check_circle_outline,
                    title: 'Beneficios del Test',
                    content: '• Identificar tus gustos e intereses\n• Elegir con mayor seguridad tu futuro técnico o tecnológico\n• Recibir orientación personalizada\n• Evitar decisiones erradas por desinformación',
                  ),
                  const SizedBox(height: 20),
                  if (grado == '9')
                    Center(
                      child: AnimatedScale(
                        scale: 1.0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutBack,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/test_grado9');
                          },
                          icon: const Icon(Icons.play_circle_fill),
                          label: const Text('Iniciar Test Grado 9'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 201, 175, 247),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Center(
                    child: AnimatedScale(
                      scale: 1.0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutBack,
                      child: TextButton.icon(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                        icon: const Icon(FontAwesomeIcons.rightFromBracket, color: Colors.white, size: 18),
                        label: const Text('Cerrar sesión'),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[900],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedSection extends StatefulWidget {
  final String title;
  final String content;
  final IconData icon;

  const AnimatedSection({super.key, required this.title, required this.content, required this.icon});

  @override
  State<AnimatedSection> createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<AnimatedSection> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _offsetAnimation = Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 30),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(widget.icon, size: 32, color: Colors.teal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.content, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
