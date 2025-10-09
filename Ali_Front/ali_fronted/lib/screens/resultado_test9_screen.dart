import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'estudiante_home.dart';

class ResultadoTest9Screen extends StatefulWidget {
  final String resultado;                   // p.ej. "Industrial" o ya con el prefijo
  final Map<String, double> porcentajes;
  final IconData icono;                     // fallback si no reconocemos el técnico
  final Color color;

  // Opcional: explicación que va en el diálogo
  final String? explicacion;

  const ResultadoTest9Screen({
    super.key,
    required this.resultado,
    required this.porcentajes,
    required this.icono,
    required this.color,
    this.explicacion,
  });

  @override
  State<ResultadoTest9Screen> createState() => _ResultadoTest9ScreenState();
}

class _ResultadoTest9ScreenState extends State<ResultadoTest9Screen>
    with TickerProviderStateMixin {
  // Animaciones
  late final AnimationController _bounceCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  late final Animation<double> _bounceAnim =
      CurvedAnimation(parent: _bounceCtl, curve: Curves.elasticOut);

  late final AnimationController _bgCtl =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);

  late final AnimationController _btnCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 280), upperBound: .10);

  // ---------------- helpers ----------------

  // Evita "Técnico sugerido por ALI: Técnico sugerido por ALI: X"
  String _tituloNormalizado(String raw) {
    const prefijo = 'Técnico sugerido por ALI:';
    final s = raw.trim();
    if (s.toLowerCase().startsWith(prefijo.toLowerCase())) return s;
    return '$prefijo $s';
  }

  // Mapea el técnico a un icono de FontAwesome.
  // Soporta nombres con o sin acentos y mayúsculas.
  IconData _iconForResultado(String raw) {
    final s = raw.toLowerCase();

    // Si viene prefijado, nos quedamos con la cola del título
    const prefijo = 'técnico sugerido por ali:';
    final nombre = s.startsWith(prefijo)
        ? s.substring(prefijo.length).trim()
        : s;

    // Normalizamos diacríticos básicos
    String n = nombre
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');

    // {1: "Industrial", 2: "Comercio", 3: "Promoción Social", 4: "Agropecuaria"}
    if (n.contains('industrial')) return FontAwesomeIcons.gears;             // ⚙️
    if (n.contains('comercio')) return FontAwesomeIcons.cartShopping;        // 🛒
    if (n.contains('promocion social')) return FontAwesomeIcons.handHoldingHeart; // 🤝❤️
    if (n.contains('agropecuaria')) return FontAwesomeIcons.wheatAwn;        // 🌾
    // Fallback al icono que recibiste (por compatibilidad)
    return widget.icono;
  }

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
    final String explicacion = (widget.explicacion ?? '').trim();

    final tituloNormalizado = _tituloNormalizado(widget.resultado);
    final iconoTecnico = _iconForResultado(widget.resultado);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Fondo decorativo
          AnimatedBuilder(
            animation: _bgCtl,
            builder: (_, __) => CustomPaint(
              painter: _WavePainter(_bgCtl.value),
              size: MediaQuery.of(context).size,
            ),
          ),

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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 18),

                  // ------------------ HERO ------------------
                  ScaleTransition(
                    scale: _bounceAnim,
                    child: _GlassCard(
                      gradientColors: const [Color(0x661465bb), Color(0x660f4d8c)],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.18),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(iconoTecnico, color: Colors.white, size: 34),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  tituloNormalizado,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        height: 1.15,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _OutlinePillButton(
                              label: 'Técnico sugerido',
                              icon: FontAwesomeIcons.circleInfo,
                              onTap: () => _openTecnicoDialogCentered(
                                icono: iconoTecnico,
                                color: widget.color,
                                titulo: tituloNormalizado,
                                explicacion: explicacion,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ------------------ ANÁLISIS ------------------
                  Text('El Análisis de tu Test',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700, color: Colors.grey[900])),
                  const SizedBox(height: 12),

                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 2 : 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isWide ? 1.75 : 1.10,
                    ),
                    children: [
                      _WhiteCard(
                        title: 'Próximos Pasos',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _NextStepRow(
                              icon: FontAwesomeIcons.bookOpenReader,
                              text: 'Investiga el plan de estudios.',
                            ),
                            SizedBox(height: 10),
                            _NextStepRow(
                              icon: FontAwesomeIcons.video,
                              text: 'Mira un video de “Un día de vida” de este técnico.',
                            ),
                            SizedBox(height: 10),
                            _NextStepRow(
                              icon: FontAwesomeIcons.locationDot,
                              text: 'Explora instituciones cercanas que lo ofrezcan.',
                            ),
                          ],
                        ),
                      ),

                      // --------- TARJETA CON DONAS ---------
                      _WhiteCard(
                        title: 'Tu Resumen de Intereses',
                        child: _InterestsDonuts(pct: widget.porcentajes),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Volver al inicio
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
                        builder: (_, child) => Transform.scale(scale: 1 - _btnCtl.value, child: child),
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
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 20),
                          child: Row(mainAxisSize: MainAxisSize.min, children: const [
                            FaIcon(FontAwesomeIcons.houseChimney, color: Colors.white, size: 20),
                            SizedBox(width: 16),
                            Text('Volver al inicio',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------- DIÁLOGO CENTRADO: SOLO EXPLICACIÓN + ENTENDIDO ---------------
  void _openTecnicoDialogCentered({
    required IconData icono,
    required Color color,
    required String titulo,
    required String explicacion,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (ctx) {
        final double maxW = MediaQuery.of(ctx).size.width;
        final double dialogW =
            (maxW < 420.0 ? (maxW - 24.0) : (maxW < 920.0 ? 560.0 : 720.0)).clamp(320.0, 720.0);

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          backgroundColor: Colors.transparent,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: dialogW),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Material(
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 18, 8, 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withOpacity(.95), const Color(0xFF0f4d8c)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icono, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Técnico sugerido',
                                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                                  SizedBox(height: 4),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      // Título
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            titulo,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                      // Contenido: SOLO explicación si viene
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (explicacion.isNotEmpty) ...[
                                Text(explicacion, style: const TextStyle(height: 1.45)),
                                const SizedBox(height: 16),
                              ],
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => Navigator.pop(ctx),
                                      icon: const Icon(Icons.check_circle_outline),
                                      label: const Text('Entendido'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF0f4d8c),
                                        side: const BorderSide(color: Color(0xFF0f4d8c)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/* ============================= WIDGETS PRIVADOS ============================= */

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
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withOpacity(.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
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
                BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 14, offset: const Offset(0, 5))
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              widget.child,
            ]),
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(.75), width: 1.2),
            color: Colors.white.withOpacity(.08),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 8),
              Text(label,
                  style:
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
            ],
          ),
        ),
      );
}

class _ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _ShimmerText({required this.text, required this.style});
  @override
  State<_ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<_ShimmerText> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
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
            child: Text(widget.text, style: widget.style, maxLines: 1, overflow: TextOverflow.ellipsis),
          );
        },
      );
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
      final y = h * .25 + math.sin((x / size.width * 2 * math.pi) + t * 2 * math.pi) * 20;
      path1.lineTo(x, y);
    }
    path1..lineTo(size.width, 0)..lineTo(0, 0)..close();

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
      final y =
          h * .30 + math.sin((x / size.width * 2 * math.pi) + t * 2 * math.pi + math.pi) * 30;
      path2.lineTo(x, y);
    }
    path2..lineTo(size.width, 0)..lineTo(0, 0)..close();

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

/* ===================== DONAS PARA “RESUMEN DE INTERESES” ===================== */

class _InterestsDonuts extends StatelessWidget {
  final Map<String, double> pct;
  const _InterestsDonuts({required this.pct});

  @override
  Widget build(BuildContext context) {
    final double mg  = ((pct['Me gusta'] ?? 0).clamp(0, 100)).toDouble();
    final double nmg = ((pct['No me gusta'] ?? 0).clamp(0, 100)).toDouble();
    final double mi  = ((pct['Me interesa'] ?? 0).clamp(0, 100)).toDouble();
    final double nmi = ((pct['No me interesa'] ?? 0).clamp(0, 100)).toDouble();

    const azul = Color(0xFF1465bb);
    const rojo = Color(0xFFE11D48);
    const cian = Color(0xFF0ea5e9);
    const gris = Color(0xFF9CA3AF);

    return LayoutBuilder(
      builder: (ctx, c) {
        final isWide = c.maxWidth >= 560;
        return Wrap(
          spacing: 22,
          runSpacing: 22,
          alignment: isWide ? WrapAlignment.spaceBetween : WrapAlignment.start,
          children: [
            _DonutCard(
              title: 'Afinidad',
              centerLabel: 'Afinidad',
              segments: [
                _DonutSegment('Me gusta', mg, azul),
                _DonutSegment('No me gusta', nmg, rojo),
              ],
            ),
            _DonutCard(
              title: 'Interés',
              centerLabel: 'Interés',
              segments: [
                _DonutSegment('Me interesa', mi, cian),
                _DonutSegment('No me interesa', nmi, gris),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DonutCard extends StatelessWidget {
  final String title;
  final String centerLabel;
  final List<_DonutSegment> segments;
  const _DonutCard({
    required this.title,
    required this.centerLabel,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (s, e) => s + e.value);
    final showEmpty = total <= 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              _AnimatedDonut(
                size: 132,
                thickness: 16,
                segments: showEmpty
                    ? [_DonutSegment('Sin datos', 1, const Color(0xFFE5E7EB))]
                    : segments,
                centerBuilder: (ctx) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(centerLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            )),
                    const SizedBox(height: 2),
                    Text(
                      showEmpty ? '0%' : '${(segments.first.value).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: segments.map((s) {
                    final pct = total == 0 ? 0 : (s.value / total * 100);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          _LegendDot(color: s.color),
                          const SizedBox(width: 8),
                          Expanded(child: Text(s.label, style: const TextStyle(color: Color(0xFF111827)))),
                          Text('${pct.toStringAsFixed(0)}%',
                              style: const TextStyle(color: Color(0xFF6B7280))),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _DonutSegment {
  final String label;
  final double value;
  final Color color;
  const _DonutSegment(this.label, this.value, this.color);
}

class _AnimatedDonut extends StatelessWidget {
  final double size;
  final double thickness;
  final List<_DonutSegment> segments;
  final WidgetBuilder? centerBuilder;
  const _AnimatedDonut({
    required this.size,
    required this.thickness,
    required this.segments,
    this.centerBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _DonutPainter(segments: segments, progress: t, thickness: thickness),
          child: Center(child: centerBuilder?.call(context)),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSegment> segments;
  final double progress; // 0..1
  final double thickness;

  _DonutPainter({required this.segments, required this.progress, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final total = segments.fold<double>(0, (s, e) => s + (e.value <= 0 ? 0 : e.value));
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = const Color(0xFFE5E7EB);

    // Anillo base
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - thickness / 2),
      -math.pi / 2,
      math.pi * 2,
      false,
      bg,
    );

    if (total <= 0) return;

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    double start = -math.pi / 2;
    for (final s in segments) {
      if (s.value <= 0) continue;
      final sweep = (s.value / total) * math.pi * 2 * progress;
      stroke.color = s.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - thickness / 2),
        start,
        sweep,
        false,
        stroke,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress || old.segments != segments || old.thickness != thickness;
}

/* ============================== NEXT STEP ROW ============================== */

class _NextStepRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _NextStepRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1465bb)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black87, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
