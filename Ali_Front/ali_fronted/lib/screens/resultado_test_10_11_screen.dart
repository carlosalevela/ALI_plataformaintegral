import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'estudiante_home.dart';

/// Pantalla de resultados para GRADOS 10 y 11
/// —–– Diseño, tamaños y animaciones **idénticos** a `ResultadoTest9Screen`
class ResultadoTest1011Screen extends StatefulWidget {
  final Map<String, String> respuestas;        // respuestas A/B/C/D del test

  const ResultadoTest1011Screen({super.key, required this.respuestas});

  @override
  State<ResultadoTest1011Screen> createState() =>
      _ResultadoTest1011ScreenState();
}

class _ResultadoTest1011ScreenState extends State<ResultadoTest1011Screen>
    with TickerProviderStateMixin {
  // ---------------- LÓGICA ----------------
  late Map<String, double> porcentajes; // A/B/C/D → %
  late String resultado;                // carrera sugerida
  late IconData icono;                  // icono grande
  final Color color = const Color(0xFF1465bb); // tono principal (mismo que grado 9)

  // ---------------- ANIMACIONES ----------------
  late final AnimationController _bounceCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
        ..forward();
  late final Animation<double> _bounceAnim =
      CurvedAnimation(parent: _bounceCtl, curve: Curves.elasticOut);

  late final AnimationController _bgCtl =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))
        ..repeat(reverse: true);

  late final AnimationController _btnCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 280), upperBound: .10);

  @override
  void initState() {
    super.initState();
    _calcularPorcentajes();
    _generarRecomendacion();
  }

  void _calcularPorcentajes() {
    final conteo = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
    for (var r in widget.respuestas.values) {
      if (conteo.containsKey(r)) conteo[r] = conteo[r]! + 1;
    }
    final total = widget.respuestas.length.toDouble();
    porcentajes = {for (var k in conteo.keys) k: (conteo[k]! / total * 100)};
  }

  void _generarRecomendacion() {
    final mayor = porcentajes.entries.reduce((a, b) => a.value > b.value ? a : b);

    switch (mayor.key) {
      case 'A':
        resultado = 'Medicina, Ingeniería o Psicología';
        icono = FontAwesomeIcons.heartPulse;
        break;
      case 'B':
        resultado = 'Derecho, Programación o Docencia';
        icono = FontAwesomeIcons.lightbulb;
        break;
      case 'C':
        resultado = 'Explora nuevas áreas de interés';
        icono = FontAwesomeIcons.faceFrown;
        break;
      case 'D':
        resultado = 'Sigue explorando tus intereses';
        icono = FontAwesomeIcons.circleQuestion;
        break;
      default:
        resultado = 'Explora diferentes opciones';
        icono = FontAwesomeIcons.question;
    }
  }

  // ---------------- LIMPIEZA ----------------
  @override
  void dispose() {
    _bounceCtl.dispose();
    _bgCtl.dispose();
    _btnCtl.dispose();
    super.dispose();
  }

  // ---------------- UI PRINCIPAL ----------------
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final textScale = MediaQuery.textScaleFactorOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Fondo con ondas
          AnimatedBuilder(
            animation: _bgCtl,
            builder: (_, __) => CustomPaint(
              painter: _WavePainter(_bgCtl.value),
              size: MediaQuery.of(context).size,
            ),
          ),

          // Contenido
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerText(
                    text: 'Panel de Recomendación',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .copyWith(fontWeight: FontWeight.w800, color: Colors.grey[900]!),
                  ),
                  const SizedBox(height: 6),
                  Text('Encuentra la carrera perfecta para ti',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 22),

                  // Tarjeta glass principal
                  ScaleTransition(
                    scale: _bounceAnim,
                    child: _GlassCard(
                      gradientColors: const [Color(0x661465bb), Color(0x660f4d8c)],
                      child: Column(
                        children: [
                          Text('Carrera recomendada',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 14),
                          Icon(icono, color: Colors.white, size: 56),
                          const SizedBox(height: 12),
                          Text(resultado,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall!
                                  .copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Grid idéntico al de grado 9 (2 tarjetas)
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 2 : 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isWide ? 1.45 : 1.05,
                    ),
                    children: [
                      _WhiteCard(
                        title: 'Recomendación',
                        child: Center(
                          child: Text('🌟 Próximamente tips personalizados',
                              style: TextStyle(
                                  fontSize: 13 * textScale,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black45)),
                        ),
                      ),
                      _WhiteCard(
                        title: 'Estadísticas del Test',
                        child: _StatsGrid(pct: porcentajes),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),

                  // Botón volver al inicio
                  Center(
                    child: GestureDetector(
                      onTapDown: (_) => _btnCtl.forward(),
                      onTapCancel: () => _btnCtl.reverse(),
                      onTapUp: (_) async {
                        _btnCtl.reverse();
                        final prefs = await SharedPreferences.getInstance();
                        final id = prefs.getInt('user_id');
                        if (id != null) {
                          await prefs.remove('test_grado_1011_respuestas_$id');
                        }
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const EstudianteHome()),
                              (_) => false);
                        }
                      },
                      child: AnimatedBuilder(
                        animation: _btnCtl,
                        builder: (_, child) =>
                            Transform.scale(scale: 1 - _btnCtl.value, child: child),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1465bb), Color(0xFF0f4d8c)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color: const Color(0xFF0f4d8c).withOpacity(.35),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10))
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 20),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const FaIcon(FontAwesomeIcons.houseChimney,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 16),
                            const Text('Volver al inicio',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
//                 W I D G E T S   P R I V A D O S
// (copiados sin cambios del archivo de resultados de grado 9)
// ------------------------------------------------------------------

class _GlassCard extends StatelessWidget {
  final List<Color> gradientColors;
  final Widget child;
  const _GlassCard({required this.gradientColors, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
                color: gradientColors.last.withOpacity(.35),
                blurRadius: 24,
                offset: const Offset(0, 10))
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: child,
      );
}

class _WhiteCard extends StatefulWidget {
  final String title;
  final Widget child;
  const _WhiteCard({required this.title, required this.child});
  @override
  State<_WhiteCard> createState() => _WhiteCardState();
}

class _WhiteCardState extends State<_WhiteCard> {
  double _dy = 0;
  void _setDy(double v) => setState(() => _dy = v);

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => _setDy(-6),
        onExit: (_) => _setDy(0),
        child: GestureDetector(
          onTapDown: (_) => _setDy(-6),
          onTapUp: (_) => _setDy(0),
          onTapCancel: () => _setDy(0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            transform: Matrix4.translationValues(0, _dy, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 14,
                    offset: const Offset(0, 5))
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              widget.child,
            ]),
          ),
        ),
      );
}

class _StatsGrid extends StatelessWidget {
  final Map<String, double> pct;
  const _StatsGrid({required this.pct});

  @override
  Widget build(BuildContext context) {
    final Map<String, Color> col = {
      'Me gusta': const Color(0xFF10B981),
      'No me gusta': Colors.redAccent,
      'Me interesa': const Color(0xFF0ea5e9),
      'No me interesa': Colors.grey,
    };

    return Wrap(
      alignment: WrapAlignment.center,
      runSpacing: 18,
      spacing: 18,
      children: col.keys.map((k) {
        return _CircleStat(
          label: k,
          color: col[k]!,
          value: pct[k] ?? 0,
          icon: k == 'Me gusta'
              ? FontAwesomeIcons.thumbsUp
              : k == 'No me gusta'
                  ? FontAwesomeIcons.thumbsDown
                  : k == 'Me interesa'
                      ? FontAwesomeIcons.solidHeart
                      : FontAwesomeIcons.star,
        );
      }).toList(),
    );
  }
}

class _CircleStat extends StatelessWidget {
  final String label;
  final double value; // 0–100
  final IconData icon;
  final Color color;
  const _CircleStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = value.clamp(0, 100) / 100;
    const sz = 86.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: pct),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutBack,
          builder: (_, v, __) => SizedBox(
            width: sz,
            height: sz,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // halo
                Container(
                  width: sz,
                  height: sz,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        RadialGradient(colors: [color.withOpacity(.15), Colors.white]),
                  ),
                ),
                // arco
                SizedBox(
                  width: sz,
                  height: sz,
                  child: CircularProgressIndicator(
                    value: v,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.withOpacity(.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                // icono
                FaIcon(icon, color: color, size: 22),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('${value.toStringAsFixed(0)}%',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ],
    );
  }
}

class _ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _ShimmerText({required this.text, required this.style});
  @override
  State<_ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<_ShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat();
  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctl,
        builder: (_, __) {
          final gradient = LinearGradient(
            colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
            stops: const [0.2, 0.5, 0.8],
            begin: Alignment(-1 + _ctl.value * 2, 0),
            end: Alignment(-1 + _ctl.value * 2 + 1, 0),
          );
          return ShaderMask(
            shaderCallback: gradient.createShader,
            child: Text(widget.text,
                style: widget.style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          );
        });
}

class _WavePainter extends CustomPainter {
  final double t;
  _WavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;

    // Onda 1
    final path1 = Path()..moveTo(0, h * .25);
    for (double x = 0; x <= size.width; x++) {
      final y =
          h * .25 + math.sin((x / size.width * 2 * math.pi) + t * 2 * math.pi) * 20;
      path1.lineTo(x, y);
    }
    path1
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    final paint1 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x331465bb), Color(0x330f4d8c)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, size.width, h));
    canvas.drawPath(path1, paint1);

    // Onda 2
    final path2 = Path()..moveTo(0, h * .30);
    for (double x = 0; x <= size.width; x++) {
      final y = h * .30 +
          math.sin((x / size.width * 2 * math.pi) + t * 2 * math.pi + math.pi) * 30;
      path2.lineTo(x, y);
    }
    path2
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    final paint2 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x221465bb), Color(0x220f4d8c)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, size.width, h));
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => oldDelegate.t != t;
}
