import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'estudiante_home.dart';

class ResultadoTest9Screen extends StatefulWidget {
  final String resultado;
  final Map<String, double> porcentajes;
  final IconData icono;
  final Color color;

  /// ✨ Opcionales (no rompen tu lógica)
  final String? explicacion;           // breve párrafo
  final List<String>? razones;         // bullets “¿Por qué creemos…?”
  final VoidCallback? onVerMas;        // acción del botón “Ver más…”

  const ResultadoTest9Screen({
    super.key,
    required this.resultado,
    required this.porcentajes,
    required this.icono,
    required this.color,
    this.explicacion,
    this.razones,
    this.onVerMas,
  });

  @override
  State<ResultadoTest9Screen> createState() => _ResultadoTest9ScreenState();
}

class _ResultadoTest9ScreenState extends State<ResultadoTest9Screen>
    with TickerProviderStateMixin {
  // --------------------- controladores de animación ---------------------
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
  void dispose() {
    _bounceCtl.dispose();
    _bgCtl.dispose();
    _btnCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final textScale = MediaQuery.textScaleFactorOf(context);

    // Defaults suaves si no te pasan explicación/razones
    final explicacion = widget.explicacion ??
        'Vemos que tienes afinidad por actividades prácticas y contextos reales. '
        'Este técnico encaja con tus intereses y fortalezas, y puede abrirte buenas oportunidades.';
    final razones = widget.razones ??
        [
          'Conexión con tus gustos e intereses declarados en el test.',
          'Actividades prácticas y de aprendizaje aplicado.',
          'Oportunidades laborales estables y variadas.',
        ];

    // Barras que reflejan tu captura (“Me gusta” y “No me interesa”)
    final mg = (widget.porcentajes['Me gusta'] ?? 0).clamp(0, 100);
    final nmi = (widget.porcentajes['No me interesa'] ?? 0).clamp(0, 100);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ------------------  FONDO CON ONDAS  ------------------
          AnimatedBuilder(
            animation: _bgCtl,
            builder: (_, __) => CustomPaint(
              painter: _WavePainter(_bgCtl.value),
              size: MediaQuery.of(context).size,
            ),
          ),

          // ------------------  CONTENIDO  ------------------
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
                  Text('Encuentra la carrera técnica perfecta para ti',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 22),

                  // ------------------  TARJETA GLASS (hero) ------------------
                  ScaleTransition(
                    scale: _bounceAnim,
                    child: _GlassCard(
                      gradientColors: const [Color(0x661465bb), Color(0x660f4d8c)],
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text('Tu Carrera Técnica Sugerida',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium!
                                      .copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icono grande
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(.18),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(widget.icono, color: Colors.white, size: 40),
                                ),
                                const SizedBox(width: 14),
                                // Título + explicación
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.resultado,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall!
                                            .copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              height: 1.1,
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        explicacion,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.white.withOpacity(.95),
                                              height: 1.35,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ¿Por qué creemos que es para ti?
                            Text(
                              '¿Por qué creemos que es para ti?',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            ...razones.map((r) => _BulletRow(text: r)).toList(),
                            const SizedBox(height: 14),

                            // Botón “Ver más”
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _OutlinePillButton(
                                label: 'Ver más sobre ${widget.resultado}',
                                icon: FontAwesomeIcons.magnifyingGlass,
                                onTap: widget.onVerMas,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // ------------------  SECCIÓN ANALYSIS ------------------
                  Text('El Análisis de tu Test',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700, color: Colors.grey[900])),
                  const SizedBox(height: 14),

                  // Grid 2 columnas (o 1 en móvil)
                  LayoutBuilder(
                    builder: (ctx, cns) => GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 2 : 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isWide ? 1.75 : 1.10,
                      ),
                      children: [
                        // Próximos pasos
                        _WhiteCard(
                          title: 'Próximos Pasos',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _NextStepRow(
                                icon: FontAwesomeIcons.bookOpenReader,
                                text: 'Investiga el plan de estudios.',
                              ),
                              const SizedBox(height: 10),
                              _NextStepRow(
                                icon: FontAwesomeIcons.video,
                                text: 'Mira un video de “Un día de vida” de este técnico.',
                              ),
                              const SizedBox(height: 10),
                              _NextStepRow(
                                icon: FontAwesomeIcons.locationDot,
                                text: 'Explora instituciones cercanas que lo ofrezcan.',
                              ),
                              const SizedBox(height: 18),
                              // Botón rehacer test (reusa tu lógica)
                              Center(
                                child: GestureDetector(
                                  onTapDown: (_) => _btnCtl.forward(),
                                  onTapCancel: () => _btnCtl.reverse(),
                                  onTapUp: (_) async {
                                    _btnCtl.reverse();
                                    final prefs = await SharedPreferences.getInstance();
                                    final id = prefs.getInt('user_id');
                                    if (id != null) {
                                      await prefs.remove('test_grado9_respuestas_$id');
                                    }
                                    if (mounted) {
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (_) => const EstudianteHome()),
                                        (_) => false,
                                      );
                                    }
                                  },
                                  child: AnimatedBuilder(
                                    animation: _btnCtl,
                                    builder: (_, child) =>
                                        Transform.scale(scale: 1 - _btnCtl.value, child: child),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(40),
                                        color: const Color(0xFF0f4d8c),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.refresh, color: Colors.white, size: 18),
                                          SizedBox(width: 10),
                                          Text('No me convence. Realizar de nuevo',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Resumen de intereses (barras)
                        _WhiteCard(
                          title: 'Tu Resumen de Intereses',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _BarStat(
                                label: 'Me gusta',
                                value: mg / 100,
                                valueText: '${mg.toStringAsFixed(0)}%',
                              ),
                              const SizedBox(height: 12),
                              _BarStat(
                                label: 'No me interesa',
                                value: nmi / 100,
                                valueText: '${nmi.toStringAsFixed(0)}%',
                                muted: true,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Aunque algunas áreas no te interesaron, el ${mg.toStringAsFixed(0)}% indica una fuerte conexión con ${widget.resultado.toLowerCase()}.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.black54, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ------------------  BOTÓN “Volver al inicio” (se mantiene)
                  Center(
                    child: GestureDetector(
                      onTapDown: (_) => _btnCtl.forward(),
                      onTapCancel: () => _btnCtl.reverse(),
                      onTapUp: (_) async {
                        _btnCtl.reverse();
                        final prefs = await SharedPreferences.getInstance();
                        final id = prefs.getInt('user_id');
                        if (id != null) {
                          await prefs.remove('test_grado9_respuestas_$id');
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
                          child: Row(mainAxisSize: MainAxisSize.min, children: const [
                            FaIcon(FontAwesomeIcons.houseChimney, color: Colors.white, size: 20),
                            SizedBox(width: 16),
                            Text('Volver al inicio',
                                style: TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
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

// --------------------------------------------------------------------------
//                              WIDGETS PRIVADOS
// --------------------------------------------------------------------------

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

class _BulletRow extends StatelessWidget {
  final String text;
  const _BulletRow({required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white, height: 1.35),
              ),
            ),
          ],
        ),
      );
}

class _OutlinePillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _OutlinePillButton({required this.label, required this.icon, this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(.75), width: 1.2),
            color: Colors.white.withOpacity(.08),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
            ],
          ),
        ),
      );
}

class _NextStepRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _NextStepRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1465bb)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.black87))),
        ],
      );
}

class _BarStat extends StatelessWidget {
  final String label;
  final double value;      // 0..1
  final String valueText;  // “80%”
  final bool muted;
  const _BarStat({
    required this.label,
    required this.value,
    required this.valueText,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final track = muted ? Colors.black12 : const Color(0xFFe6f0fb);
    final fill = muted ? Colors.grey : const Color(0xFF1465bb);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(valueText,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 14,
            child: Stack(
              children: [
                Container(color: track),
                FractionallySizedBox(
                  widthFactor: value.clamp(0, 1),
                  child: Container(color: fill),
                ),
              ],
            ),
          ),
        ),
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
      ).createShader(Rect.fromLTWH(0, 0, size.width, h));
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
      ).createShader(Rect.fromLTWH(0, 0, size.width, h));
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => oldDelegate.t != t;
}
