import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <- Para Clipboard y SnackBar
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'estudiante_home.dart';

/// ResultadoTest1011Screen
/// - Muestra la carrera y AHORA también una explicación visible y elegante.
/// - Arregla acentos/mojibake ("IngenierÃ­a" -> "Ingeniería").
/// - Mantiene tus porcentajes A/B/C/D y el diseño actual.
class ResultadoTest1011Screen extends StatefulWidget {
  final Map<String, String> respuestas; // A/B/C/D
  final String resultado;               // puede venir crudo (string largo/JSON serializado)

  const ResultadoTest1011Screen({
    Key? key,
    required this.respuestas,
    required this.resultado,
  }) : super(key: key);

  @override
  State<ResultadoTest1011Screen> createState() => _ResultadoTest1011ScreenState();
}

class _ResultadoTest1011ScreenState extends State<ResultadoTest1011Screen>
    with TickerProviderStateMixin {
  late Map<String, double> porcentajes;
  late IconData icono;
  late Color accentColor;

  /// Etiqueta final ya limpia para mostrar (solo carrera)
  late String carreraLabel;

  /// Explicación legible para el estudiante
  late String explicacion;

  @override
  void initState() {
    super.initState();
    _calcularPorcentajes();

    // Carrera sugerida (etiqueta)
    carreraLabel = _extractCareerLabel(widget.resultado).trim();
    if (carreraLabel.isEmpty) {
      carreraLabel = _pretty(widget.resultado).trim();
    }

    // Explicación (texto)
    explicacion = _extractExplanation(widget.resultado).trim();
    if (explicacion.isEmpty) {
      explicacion = 'Pronto verás una explicación personalizada generada por ALI según tus intereses.';
    }

    _configurarIconoYColor(carreraLabel);
  }

  void _calcularPorcentajes() {
    final conteo = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
    for (var r in widget.respuestas.values) {
      if (conteo.containsKey(r)) conteo[r] = conteo[r]! + 1;
    }
    final total = widget.respuestas.isEmpty ? 1.0 : widget.respuestas.length.toDouble();
    porcentajes = {for (var k in conteo.keys) k: (conteo[k]! / total * 100).toDouble()};
  }

  // ---------------- Helpers de texto (acentos/mojibake) ----------------
  String _pretty(String s) {
    if (s.contains(RegExp(r'[ÃÂ]'))) {
      try {
        return utf8.decode(latin1.encode(s), allowMalformed: true);
      } catch (_) {}
    }
    return s;
  }

  String _stripDiacritics(String s) {
    return s
        .replaceAll(RegExp(r'[áàäâãÁÀÄÂÃ]'), 'a')
        .replaceAll(RegExp(r'[éèëêÉÈËÊ]'), 'e')
        .replaceAll(RegExp(r'[íìïîÍÌÏÎ]'), 'i')
        .replaceAll(RegExp(r'[óòöôõÓÒÖÔÕ]'), 'o')
        .replaceAll(RegExp(r'[úùüûÚÙÜÛ]'), 'u')
        .replaceAll(RegExp(r'[ñÑ]'), 'n')
        .replaceAll(RegExp(r'[çÇ]'), 'c');
  }

  String _norm(String s) => _stripDiacritics(_pretty(s).toLowerCase());
  String _decodeUTF8(String s) => _pretty(s);

  bool _looksLikeCareer(String s) {
    final t = s.trim();
    if (t.isEmpty) return false;
    if (t.contains('{') || t.contains('[') || t.contains(':')) return false;
    if (t.length > 60) return false;

    final lettersOnly = RegExp(r'^[\p{L}\s\-\(\)\/&]+$', unicode: true).hasMatch(t);
    if (lettersOnly) return true;

    final norm = _stripDiacritics(t.toLowerCase());
    const keys = [
      'ingenier', 'diseñ', 'disen', 'medic', 'derech', 'psicol', 'admin',
      'contad', 'sistem', 'softw', 'biolog', 'quimic', 'fisic', 'docen',
      'educac', 'natur', 'finanz', 'marketing', 'comunic', 'arquite',
      'enfermer', 'graf'
    ];
    return keys.any((k) => norm.contains(k));
  }

  String _pickFromDecodedJson(dynamic dec) {
    if (dec is String) return _pretty(dec);
    if (dec is Map) {
      for (final k in [
        'carrera','carrera_sugerida','nombre_carrera','resultado','recomendacion',
        'recomendación','tecnico','tecnico_sugerido','sugerencia','label','titulo','nombre'
      ]) {
        final v = dec[k];
        if (v is String && v.trim().isNotEmpty) return _pretty(v);
      }
      String? best;
      void walk(dynamic v) {
        if (v == null) return;
        if (v is String) {
          if (_looksLikeCareer(v)) {
            if (best == null || v.length < best!.length) best = v;
          }
        } else if (v is Map) {
          for (final e in v.values) walk(e);
        } else if (v is List) {
          for (final e in v) walk(e);
        }
      }
      walk(dec);
      return _pretty(best ?? '');
    }
    if (dec is List) {
      for (final e in dec) {
        final s = _pickFromDecodedJson(e);
        if (s.isNotEmpty) return s;
      }
    }
    return '';
  }

  String _extractCareerLabel(String raw) {
    final s = _pretty(raw).trim();
    if (s.isEmpty) return '';

    // Si es JSON serializado
    if ((s.startsWith('{') && s.endsWith('}')) || (s.startsWith('[') && s.endsWith(']'))) {
      try {
        final dec = jsonDecode(s);
        final fromJson = _pickFromDecodedJson(dec);
        if (fromJson.isNotEmpty) return fromJson;
      } catch (_) {}
    }

    // Buscar líneas tipo "Carrera recomendada: XYZ"
    final lines = s.split(RegExp(r'\r?\n')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    for (final line in lines) {
      final norm = _norm(line);
      if (norm.contains('carrera recomendada') ||
          norm.contains('recomendacion') || norm.contains('recomendación') ||
          norm.contains('area sugerida') || norm.contains('área sugerida')) {
        final idx = line.indexOf(':');
        if (idx != -1 && idx + 1 < line.length) {
          final candidate = line.substring(idx + 1).trim();
          if (_looksLikeCareer(candidate)) return candidate;
        }
      }
    }

    // Primera línea que parezca carrera
    for (final line in lines) {
      if (_looksLikeCareer(line)) return line;
    }

    return s.length <= 60 ? s : s.substring(0, 60);
  }

  /// ----------- NUEVO: extrae la explicación legible del resultado -----------
  String _extractExplanation(String raw) {
    final s = _pretty(raw).trim();
    if (s.isEmpty) return '';

    // JSON: busca campos comunes
    if ((s.startsWith('{') && s.endsWith('}')) || (s.startsWith('[') && s.endsWith(']'))) {
      try {
        final dec = jsonDecode(s);

        String findInMap(Map m) {
          for (final k in [
            'explicacion','explicación','justificacion','justificación',
            'detalle','motivo','razon','razón','explanation','why','mensaje'
          ]) {
            final v = m[k];
            if (v is String && v.trim().isNotEmpty) return _pretty(v);
          }
          // Algunas APIs anidan la explicación en 'resultado' u 'output'
          for (final k in ['resultado','output','data','response']) {
            final v = m[k];
            if (v is Map) {
              final got = findInMap(v);
              if (got.isNotEmpty) return got;
            }
          }
          // Si viene como lista
          for (final v in m.values) {
            if (v is List) {
              for (final e in v) {
                if (e is Map) {
                  final got = findInMap(e);
                  if (got.isNotEmpty) return got;
                } else if (e is String && e.trim().length > 20) {
                  // primer párrafo decente
                  return _pretty(e.trim());
                }
              }
            }
          }
          return '';
        }

        if (dec is Map) {
          final got = findInMap(dec);
          if (got.isNotEmpty) return got;
        } else if (dec is List) {
          for (final e in dec) {
            if (e is Map) {
              final got = findInMap(e);
              if (got.isNotEmpty) return got;
            } else if (e is String && e.trim().length > 20) {
              return _pretty(e.trim());
            }
          }
        }
      } catch (_) {}
    }

    // Texto plano: intenta "Explicación: ...", toma el resto del párrafo
    final lines = s.split(RegExp(r'\r?\n'));
    final joined = lines.join('\n');
    final expIdx = _norm(joined).indexOf('explicacion');
    if (expIdx != -1) {
      final after = joined.substring(expIdx);
      final colon = after.indexOf(':');
      if (colon != -1 && colon + 1 < after.length) {
        final text = after.substring(colon + 1).trim();
        if (text.isNotEmpty) return _pretty(text);
      }
    }

    // Fallback: quita la primera línea si parece la carrera y usa el resto
    if (lines.isNotEmpty && _looksLikeCareer(lines.first)) {
      final rest = lines.skip(1).join(' ').trim();
      if (rest.length > 15) return _pretty(rest);
    }

    // Último recurso: si todo el string luce como párrafo explicativo
    if (!_looksLikeCareer(s) && s.length > 20) return _pretty(s);
    return '';
  }

  void _configurarIconoYColor(String resultadoEtiqueta) {
    final carrera = _norm(resultadoEtiqueta);
    if (carrera.contains('medicina')) {
      icono = FontAwesomeIcons.userDoctor; accentColor = Colors.teal;
    } else if (carrera.contains('ingenieria')) {
      icono = FontAwesomeIcons.gears; accentColor = Colors.blueGrey;
    } else if (carrera.contains('psicologia')) {
      icono = FontAwesomeIcons.brain; accentColor = Colors.deepPurple;
    } else if (carrera.contains('derecho')) {
      icono = FontAwesomeIcons.scaleBalanced; accentColor = Colors.brown;
    } else if (carrera.contains('educacion')) {
      icono = FontAwesomeIcons.bookOpen; accentColor = Colors.indigo;
    } else if (carrera.contains('sistemas') || carrera.contains('software')) {
      icono = FontAwesomeIcons.laptopCode; accentColor = Colors.blue;
    } else if (carrera.contains('administracion')) {
      icono = FontAwesomeIcons.chartColumn; accentColor = Colors.green;
    } else if (carrera.contains('contaduria')) {
      icono = FontAwesomeIcons.calculator; accentColor = Colors.cyan;
    } else if (carrera.contains('diseno') || carrera.contains('diseño') || carrera.contains('graf')) {
      icono = FontAwesomeIcons.penNib; accentColor = Colors.pink;
    } else if (carrera.contains('naturales')) {
      icono = FontAwesomeIcons.leaf; accentColor = Colors.lightGreen;
    } else {
      icono = FontAwesomeIcons.question; accentColor = Colors.grey;
    }
  }

  // ---------------- Animaciones ----------------
  late final AnimationController _bounceCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  late final Animation<double> _bounceAnim =
      CurvedAnimation(parent: _bounceCtl, curve: Curves.elasticOut);

  late final AnimationController _bgCtl =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);

  late final AnimationController _btnCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 280), upperBound: .10);

  @override
  void dispose() {
    _bounceCtl.dispose();
    _bgCtl.dispose();
    _btnCtl.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final textScale = MediaQuery.textScaleFactorOf(context);

    final Map<String, double> pctLegible = {
      'Me gusta': porcentajes['A'] ?? 0,
      'Me interesa': porcentajes['B'] ?? 0,
      'No me gusta': porcentajes['C'] ?? 0,
      'No me interesa': porcentajes['D'] ?? 0,
    };

    const primary1 = Color(0xFF1465bb);
    const primary2 = Color(0xFF0f4d8c);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
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
                    style: Theme.of(context).textTheme.headlineSmall!
                        .copyWith(fontWeight: FontWeight.w800, color: Colors.grey[900]!),
                  ),
                  const SizedBox(height: 6),
                  Text('Encuentra la carrera perfecta para ti',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 22),

                  // Glass principal: SOLO etiqueta de carrera
                  ScaleTransition(
                    scale: _bounceAnim,
                    child: _GlassCard(
                      gradientColors: const [Color(0x661465bb), Color(0x660f4d8c)],
                      child: Column(
                        children: [
                          Text('Carrera recomendada',
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 14),
                          Icon(icono, color: Colors.white, size: 56),
                          const SizedBox(height: 12),
                          Text(_decodeUTF8(carreraLabel),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall!
                                  .copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Grid (mantiene tu estructura)
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 2 : 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      // Un poco más alto para que la explicación no se corte
                      childAspectRatio: isWide ? 1.35 : 1.02,
                    ),
                    children: [
                      _WhiteCard(
                        title: 'Recomendación',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(width: 9, height: 9,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: primary1)),
                              const SizedBox(width: 8),
                              Text('🌟 Próximamente tips personalizados',
                                  style: TextStyle(fontSize: 13 * textScale, fontStyle: FontStyle.italic, color: Colors.black45)),
                            ]),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10, runSpacing: 10,
                              children: [
                                const _ChipTag(text: 'Área sugerida', color: primary1),
                                _ChipTag(text: _decodeUTF8(carreraLabel), color: accentColor),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // -------- BLOQUE EXPLICACIÓN (nuevo) ----------
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1465bb).withOpacity(.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF1465bb).withOpacity(.20)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const FaIcon(FontAwesomeIcons.solidLightbulb, size: 16, color: primary1),
                                      const SizedBox(width: 8),
                                      Text('Explicación',
                                          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                            color: const Color(0xFF0f4d8c), fontWeight: FontWeight.w800)),
                                      const Spacer(),
                                      TextButton.icon(
                                        onPressed: () async {
                                          await Clipboard.setData(ClipboardData(text: _decodeUTF8(explicacion)));
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Explicación copiada')),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.copy, size: 16),
                                        label: const Text('Copiar'),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _ExpandableText(
                                    text: _decodeUTF8(explicacion),
                                    maxLines: 4,
                                    textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      height: 1.35, color: Colors.black87),
                                    moreLabel: 'Ver más',
                                    lessLabel: 'Ver menos',
                                  ),
                                ],
                              ),
                            ),
                            // -------- FIN EXPLICACIÓN ----------
                          ],
                        ),
                      ),
                      _WhiteCard(
                        title: 'Estadísticas del Test',
                        child: _StatsGrid(pct: pctLegible),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),

                  // Botón volver
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
                              colors: [primary1, primary2],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [BoxShadow(color: primary2.withOpacity(.35), blurRadius: 22, offset: Offset(0, 10))],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 20),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(FontAwesomeIcons.houseChimney, color: Colors.white, size: 20),
                              SizedBox(width: 16),
                              Text('Volver al inicio',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
                            ],
                          ),
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

// ---------------- Widgets privados ----------------

class _GlassCard extends StatelessWidget {
  final List<Color> gradientColors;
  final Widget child;
  const _GlassCard({required this.gradientColors, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: gradientColors.last.withOpacity(.35), blurRadius: 24, offset: const Offset(0, 10))],
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 14, offset: Offset(0, 5))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                widget.child,
              ],
            ),
          ),
        ),
      );
}

class _ChipTag extends StatelessWidget {
  final String text;
  final Color color;
  const _ChipTag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(.35)),
        ),
        child: Text(
          text,
          style: TextStyle(color: color.darken(0.1), fontWeight: FontWeight.w600, fontSize: 12),
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
      'Me interesa': const Color(0xFF0ea5e9),
      'No me gusta': Colors.redAccent,
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
          value: (pct[k] ?? 0).clamp(0, 100),
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
  const _CircleStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value.clamp(0, 100)) / 100;
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
                Container(
                  width: sz,
                  height: sz,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [color.withOpacity(.15), Colors.white]),
                  ),
                ),
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
                FaIcon(icon, color: color, size: 22),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('${value.toStringAsFixed(0)}%',
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        const Text('', style: TextStyle(fontSize: 10, color: Colors.transparent)), // separador mínimo
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
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
            child: Text(
              widget.text,
              style: widget.style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
      ).createShader(Rect.fromLTRB(0, 0, size.width, h));
    canvas.drawPath(path1, paint1);

    final path2 = Path()..moveTo(0, h * .30);
    for (double x = 0; x <= size.width; x++) {
      final y = h * .30 + math.sin((x / size.width * 2 * math.pi) + t * 2 * math.pi + math.pi) * 30;
      path2.lineTo(x, y);
    }
    path2..lineTo(size.width, 0)..lineTo(0, 0)..close();

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

// ---------------- Texto expandible ----------------
class _ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? textStyle;
  final String moreLabel;
  final String lessLabel;
  const _ExpandableText({
    required this.text,
    this.maxLines = 4,
    this.textStyle,
    this.moreLabel = 'Ver más',
    this.lessLabel = 'Ver menos',
  });

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = widget.textStyle ?? Theme.of(context).textTheme.bodyMedium!;
    final text = widget.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: Text(text, style: style, maxLines: widget.maxLines, overflow: TextOverflow.ellipsis),
          secondChild: Text(text, style: style),
          crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => expanded = !expanded),
          child: Text(
            expanded ? widget.lessLabel : widget.moreLabel,
            style: style.copyWith(
              color: const Color(0xFF1465bb),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- Extensión útil ----------------
extension _ColorX on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final f = 1 - amount;
    return Color.fromARGB(
      alpha,
      (red * f).round(),
      (green * f).round(),
      (blue * f).round(),
    );
  }
}
