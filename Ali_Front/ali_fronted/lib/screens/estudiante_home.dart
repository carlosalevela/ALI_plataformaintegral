// estudiante_home.dart
import 'dart:ui' show ImageFilter;              // blur para botón glass
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _blue     = Color(0xFF1976D2);
const _blueDark = Color(0xFF0D47A1);
const _bubbleBG = Color(0xFFF1F8FF);

class EstudianteHome extends StatefulWidget {
  const EstudianteHome({super.key});

  @override
  State<EstudianteHome> createState() => _EstudianteHomeState();
}

class _EstudianteHomeState extends State<EstudianteHome>
    with SingleTickerProviderStateMixin {
  String nombre = '';
  String grado  = '';
  String edad   = '';

  late final AnimationController _zoom =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      nombre = p.getString('nombre') ?? 'Estudiante';
      grado  = p.getString('grado')  ?? 'N/A';
      edad   = p.getString('edad')   ?? 'N/A';
    });
  }

  String _tipoTest(String g) {
    final n = int.tryParse(g) ?? 0;
    if (n == 9)  return 'Test para Recomendación de un Técnico';
    if (n >= 10) return 'Test para Recomendación de una Carrera';
    return 'Test Vocacional';
  }

  // ---------------------------- UI ----------------------------
  @override
  Widget build(BuildContext context) {
    final tipoTest = _tipoTest(grado);
    final wide     = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFE0F2FF),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // mini botón (glass)
                Row(
                  children: [
                    const Spacer(),

                    // ACTUALIZADO: botón "Historial" (glass) según grado
                    TinyGlassButton(
                      icon: Icons.history_edu_rounded,
                      tooltip: 'Historial',
                      onTap: () {
                        final n = int.tryParse(grado) ?? 0;
                        if (n == 9) {
                          Navigator.pushNamed(context, '/historial-test9');
                        } else if (n >= 10) {
                          Navigator.pushNamed(context, '/historial-test-10-11');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Configura tu grado para ver el historial.'),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 12),

                    // existente: logout
                    TinyGlassButton(
                      icon: Icons.logout,
                      tooltip: 'Cerrar sesión',
                      onTap: () => Navigator.pushReplacementNamed(context, '/'),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),

                // header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _HeaderSection(
                    nombre: nombre,
                    edad: edad,
                    grado: grado,
                    tipoTest: tipoTest,
                    controller: _zoom,
                    wide: wide,
                  ),
                ),

                const SizedBox(height: 28),

                // botón principal (fancy)
                FancyPrimaryButton(
                  text: (grado == '9')
                      ? 'Iniciar Test Grado 9'
                      : 'Iniciar Test Grado $grado',
                  onTap: () {
                    final ruta = (grado == '9')
                        ? '/test_grado9'
                        : '/test_grado_10_11';
                    Navigator.pushNamed(context, ruta);
                  },
                ),

                const SizedBox(height: 40),
                _InfoCards(wide: wide),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
//                       HEADER SECTION
// ============================================================
class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.nombre,
    required this.edad,
    required this.grado,
    required this.tipoTest,
    required this.controller,
    required this.wide,
  });

  final String nombre, edad, grado, tipoTest;
  final AnimationController controller;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final greetSize = wide ? 40.0 : 28.0;
    final imgSize   = wide ? 260.0 : 180.0;

    // avatar
    Widget avatar = ClipOval(
      child: Container(
        width: imgSize,
        height: imgSize,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB3E5FC), Color(0xFF81D4FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.04)
              .animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut)),
          child: Image.asset('assets/nino_home.png', fit: BoxFit.contain),
        ),
      ),
    );

    // texto + chips
    Widget textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¡Hola, ${nombre.toLowerCase()}!',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: greetSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
              shadows: const [
                Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
              ],
            )),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(Icons.cake,  'Edad: $edad'),
            _chip(Icons.grade, 'Grado: $grado'),
            _chip(Icons.star,  tipoTest),
          ],
        ),
      ],
    );

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB3E5FC), Color(0xFF81D4FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        child: wide
            ? Row(children: [
                Expanded(child: textBlock),
                const SizedBox(width: 16),
                avatar,
              ])
            : Column(children: [
                avatar,
                const SizedBox(height: 24),
                textBlock,
              ]),
      ),
    );
  }

  Widget _chip(IconData ic, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: _bubbleBG, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ic, size: 16, color: _blueDark),
            const SizedBox(width: 6),
            Flexible(
              child: Text(text,
                  softWrap: true,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
            ),
          ],
        ),
      );
}

// ============================================================
//                     INFO CARDS GRID
// ============================================================
class _InfoCards extends StatelessWidget {
  const _InfoCards({required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: wide ? 2 : 1,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 1.65,
          children: [
            _card(Icons.question_answer, '¿Qué es un Test Vocacional?',
                'Herramienta para descubrir tus intereses, fortalezas y preferencias y orientar tu futuro académico.'),
            _card(Icons.settings_suggest_rounded, 'Metodología RIASEC',
                'Modelo RIASEC: Realista, Investigativa, Artística, Social, Emprendedora y Convencional.'),
            _card(Icons.compare_arrows_rounded, '¿Cómo funciona?',
                'Respondes 40 preguntas. Analizamos tus respuestas y te recomendamos una modalidad.'),
            _card(Icons.emoji_events, 'Beneficios',
                '• Identificas tus gustos\n• Tomas decisiones seguras\n• Recibes orientación\n• Evitas equivocaciones'),
          ],
        ),
      );

  Widget _card(IconData ic, String title, String desc) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 14, offset: Offset(0, 6))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(backgroundColor: _blue, radius: 26, child: Icon(ic, color: Colors.white, size: 28)),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(desc,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13.5, height: 1.35)),
          ],
        ),
      );
}

// ============================================================
//      FANCY PRIMARY BUTTON (gradiente animado azul-turquesa)
// ============================================================
class FancyPrimaryButton extends StatefulWidget {
  const FancyPrimaryButton({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  State<FancyPrimaryButton> createState() => _FancyPrimaryButtonState();
}

class _FancyPrimaryButtonState extends State<FancyPrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              // Paleta inspirada en el header (celeste-turquesa)
              final palette = [
                const Color(0xFF00B4DB), // turquesa vivo
                const Color(0xFF2196F3), // azul medio
                const Color(0xFF64B5F6), // celeste claro
                const Color(0xFF00B4DB),
              ];
              final t = (_ctrl.value * (palette.length - 1)).floor();
              final gradient = LinearGradient(
                colors: List.generate(
                    palette.length, (i) => palette[(i + t) % palette.length]),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 6))
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow, color: Colors.white, size: 26),
                    const SizedBox(width: 10),
                    Text(widget.text,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              );
            },
          ),
        ),
      );
}

// ============================================================
//          TINY GLASS BUTTON (vidrio azulado, ícono oscuro)
// ============================================================
class TinyGlassButton extends StatefulWidget {
  const TinyGlassButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  State<TinyGlassButton> createState() => _TinyGlassButtonState();
}

class _TinyGlassButtonState extends State<TinyGlassButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Tooltip(
            message: widget.tooltip ?? '',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: _hover
                      ? [const Color(0x662196F3), const Color(0x5500B4DB)]
                      : [const Color(0x442196F3), const Color(0x3300B4DB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  if (_hover)
                    const BoxShadow(
                        color: Color(0x552196F3),
                        blurRadius: 12,
                        spreadRadius: 1)
                ],
                border: Border.all(color: Colors.white38, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Icon(widget.icon,
                      size: 22,
                      color: _hover
                          ? Colors.white
                          : const Color(0xFF0D47A1) /* azul oscuro */),
                ),
              ),
            ),
          ),
        ),
      );
}
