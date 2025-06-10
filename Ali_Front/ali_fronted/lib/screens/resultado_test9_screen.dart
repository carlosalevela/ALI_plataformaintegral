import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'estudiante_home.dart';
import 'dart:math' as math;

class ResultadoTest9Screen extends StatefulWidget {
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
  State<ResultadoTest9Screen> createState() => _ResultadoTest9ScreenState();
}

class _ResultadoTest9ScreenState extends State<ResultadoTest9Screen>
    with TickerProviderStateMixin {
  late AnimationController _appearController;
  late AnimationController _btnController;
  late Animation<double> _appearAnim;
  late Animation<double> _chart3dAnim;
  late Animation<double> _btnScaleAnim;
  bool _isBtnPressed = false;

  final List<Color> _pieColors = [
    Color(0xFF32D6A0),
    Color(0xFF5C8DF6),
    Color(0xFFF57D7C),
    Color(0xFFEFC368),
  ];

  final List<String> _pieLabels = [
    'Me gusta',
    'Me interesa',
    'No me gusta',
    'No me interesa'
  ];

  final List<String> _pieEmojis = [
    '😍',
    '🤩',
    '😕',
    '😐',
  ];

  @override
  void initState() {
    super.initState();
    _appearController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..forward();

    _btnController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      lowerBound: 0.0,
      upperBound: 0.12,
    );

    _appearAnim = CurvedAnimation(parent: _appearController, curve: Curves.elasticOut);
    _chart3dAnim = Tween<double>(begin: -math.pi / 2, end: 0)
        .animate(CurvedAnimation(parent: _appearController, curve: Curves.easeOutBack));
    _btnScaleAnim = Tween<double>(begin: 1.0, end: 0.90).animate(CurvedAnimation(
      parent: _btnController,
      curve: Curves.easeInOutBack,
    ));
  }

  @override
  void dispose() {
    _appearController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  List<PieChartSectionData> _buildPieSections() {
    final values = widget.porcentajes.values.toList();
    return List.generate(_pieLabels.length, (i) {
      return PieChartSectionData(
        color: _pieColors[i % _pieColors.length].withOpacity(0.93),
        value: values[i],
        title: '',
        radius: 62 + (values[i] > 0 ? 12 : 0),
        badgeWidget: _buildBadge(_pieLabels[i], _pieColors[i], _pieEmojis[i], values[i]),
        badgePositionPercentageOffset: 1.23,
        showTitle: false,
      );
    });
  }

  Widget _buildBadge(String label, Color color, String emoji, double value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 23, height: 1)),
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.93),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.17),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            '${value.toStringAsFixed(1)}%',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildBar(int i, double value) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 2),
        child: Row(
          children: [
            Text(_pieEmojis[i], style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 7),
            SizedBox(
              width: 95,
              child: Text(
                _pieLabels[i],
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: animValue / 100,
                  color: _pieColors[i],
                  backgroundColor: _pieColors[i].withOpacity(0.15),
                  minHeight: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('${value.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBackground(BuildContext context) {
    // Fondo premium: shapes difusas, blur, degradados.
    return Stack(
      children: [
        // Degradado principal.
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFDCF3FF),
                Color(0xFFF4E9FF),
                Color(0xFFEAFBFB),
              ],
            ),
          ),
        ),
        // Shapes borrosos y gradientes "premium"
        Positioned(
          left: -90,
          top: -30,
          child: _blurShape(180, 180, Colors.blue.withOpacity(0.18)),
        ),
        Positioned(
          right: -60,
          top: 70,
          child: _blurShape(140, 140, Colors.orange.withOpacity(0.15)),
        ),
        Positioned(
          left: 24,
          bottom: 60,
          child: _blurShape(80, 80, Colors.green.withOpacity(0.11)),
        ),
        Positioned(
          right: 28,
          bottom: 34,
          child: _blurShape(54, 54, Colors.purple.withOpacity(0.12)),
        ),
        // Shape decorativa extra (onda sutil)
        Positioned(
          left: -110,
          bottom: -20,
          child: Transform.rotate(
            angle: 0.13,
            child: Container(
              width: 280,
              height: 85,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blueAccent.withOpacity(0.10),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _blurShape(double w, double h, Color color) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        // "Blur" visual:
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: w * 0.8,
            spreadRadius: w * 0.17,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildPremiumBackground(context),
          Center(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _appearAnim,
                child: ScaleTransition(
                  scale: _appearAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Card premium bien centrada, con sombra y glass.
                        Container(
                          width: 390,
                          constraints: const BoxConstraints(maxWidth: 480),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(38),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.80),
                                Colors.white.withOpacity(0.97),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.color.withOpacity(0.14),
                                blurRadius: 42,
                                spreadRadius: 14,
                              )
                            ],
                            border: Border.all(
                              color: widget.color.withOpacity(0.18),
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30.0, vertical: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(widget.icono,
                                  color: widget.color, size: 60, shadows: [
                                    Shadow(
                                      color: widget.color.withOpacity(0.17),
                                      blurRadius: 10)
                                  ]),
                                const SizedBox(height: 10),
                                Text(
                                  'Modalidad sugerida:',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: widget.color,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 900),
                                  child: Text(
                                    widget.resultado,
                                    key: ValueKey(widget.resultado),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: widget.color,
                                      fontFamily: 'Roboto',
                                      letterSpacing: 0.3,
                                      shadows: [
                                        Shadow(
                                          color: widget.color.withOpacity(0.12),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 34),
                                // Pie chart perfectamente centrado
                                Center(
                                  child: AnimatedBuilder(
                                    animation: _chart3dAnim,
                                    builder: (context, child) {
                                      return Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..setEntry(3, 2, 0.001)
                                          ..rotateX(_chart3dAnim.value),
                                        child: child,
                                      );
                                    },
                                    child: SizedBox(
                                      width: 245,
                                      height: 245,
                                      child: PieChart(
                                        PieChartData(
                                          sections: _buildPieSections(),
                                          sectionsSpace: 3,
                                          centerSpaceRadius: 56,
                                          borderData: FlBorderData(show: false),
                                        ),
                                        swapAnimationDuration: const Duration(milliseconds: 1100),
                                        swapAnimationCurve: Curves.elasticOut,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Column(
                                  children: List.generate(
                                      4,
                                      (i) => _buildBar(
                                          i,
                                          widget.porcentajes.values
                                              .toList()[i])),
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      '¡Gracias por completar el test!',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 17,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('🎉', style: TextStyle(fontSize: 25)),
                                  ],
                                ),
                                const SizedBox(height: 30),
                                Center(
                                  child: GestureDetector(
                                    onTapDown: (_) {
                                      _btnController.forward();
                                      setState(() => _isBtnPressed = true);
                                    },
                                    onTapUp: (_) async {
                                      _btnController.reverse();
                                      setState(() => _isBtnPressed = false);
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      final userId = prefs.getInt('user_id');
                                      if (userId != null) {
                                        await prefs.remove(
                                            'test_grado9_respuestas_$userId');
                                      }
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                EstudianteHome()),
                                        (Route<dynamic> route) => false,
                                      );
                                    },
                                    onTapCancel: () {
                                      _btnController.reverse();
                                      setState(() => _isBtnPressed = false);
                                    },
                                    child: AnimatedBuilder(
                                      animation: _btnScaleAnim,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _btnScaleAnim.value,
                                          child: child,
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              widget.color.withOpacity(0.96),
                                              widget.color.withOpacity(0.76),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(28),
                                          boxShadow: [
                                            BoxShadow(
                                              color: widget.color.withOpacity(0.18),
                                              blurRadius: 16,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 38, vertical: 16),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            FaIcon(FontAwesomeIcons.arrowLeftLong,
                                                color: Colors.white, size: 22),
                                            SizedBox(width: 12),
                                            Text(
                                              'Volver al inicio',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  letterSpacing: 0.2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
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
          ),
        ],
      ),
    );
  }
}
