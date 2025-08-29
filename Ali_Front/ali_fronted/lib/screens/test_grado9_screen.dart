import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'resultado_test9_screen.dart';
import 'estudiante_home.dart';

class TestGrado9Page extends StatefulWidget {
  const TestGrado9Page({Key? key}) : super(key: key);

  @override
  State<TestGrado9Page> createState() => _TestGrado9PageState();
}

class _TestGrado9PageState extends State<TestGrado9Page>
    with TickerProviderStateMixin {
  // ----------- NUEVA PALETA (más suave)
  static const Color azulFondoSuave = Color(0xFF8DB9E4); // fondo base
  static const Color azulSeleccion   = Color(0xFFA7D8F5); // selección opción
  static const Color azulAcento      = Color(0xFF4FC3F7); // acento / barras

  // ---------------------- 40 preguntas completas
  final List<String> preguntas = [
    '¿Te gustaría programar aplicaciones o páginas web?',
    '¿Disfrutas resolver problemas técnicos con software o computadoras?',
    '¿Te interesa aprender a escribir código para automatizar tareas?',
    '¿Te emociona la idea de crear soluciones tecnológicas para la vida diaria?',
    '¿Te gustaría armar circuitos con sensores, luces o motores?',
    '¿Disfrutas entender cómo funcionan los sistemas automáticos?',
    '¿Te interesa diseñar mecanismos con movimiento y precisión?',
    '¿Te gustaría trabajar en la creación de robots?',
    '¿Te llama la atención instalar o reparar sistemas eléctricos?',
    '¿Te gustaría conocer los riesgos eléctricos en una vivienda o empresa?',
    '¿Te interesa trabajar en instalaciones eléctricas para proyectos grandes?',
    '¿Disfrutas seguir planos técnicos para conectar cables y dispositivos?',
    '¿Te gustaría crear tu propio negocio y vender productos o servicios?',
    '¿Te interesa saber cómo funciona una empresa desde adentro?',
    '¿Disfrutas liderar actividades en grupo o tomar decisiones?',
    '¿Te gusta organizar tareas y trabajar en equipo?',
    '¿Disfrutas diseñar logotipos, afiches o material publicitario?',
    '¿Te interesa usar herramientas digitales para crear contenido visual?',
    '¿Te gustaría trabajar en la producción de videos o animaciones?',
    '¿Te llama la atención expresar ideas a través del diseño?',
    '¿Te interesa llevar el control de ingresos y gastos de una empresa?',
    '¿Disfrutas trabajar con números y cálculos detallados?',
    '¿Te gustaría registrar movimientos financieros en hojas de cálculo?',
    '¿Te gusta seguir normas claras al momento de manejar documentos?',
    '¿Te interesa ayudar a las personas a desarrollar sus capacidades?',
    '¿Disfrutas acompañar procesos de selección o entrevistas laborales?',
    '¿Te gustaría liderar actividades de formación o capacitación?',
    '¿Te interesa promover el bienestar dentro de una empresa?',
    '¿Disfrutas jugar y cuidar niños pequeños?',
    '¿Te gustaría apoyar el desarrollo emocional y cognitivo en la niñez?',
    '¿Te interesa diseñar actividades didácticas para niños?',
    '¿Sientes vocación por enseñar y acompañar a la infancia?',
    '¿Te gustaría ayudar a prevenir accidentes en el trabajo?',
    '¿Te interesa conocer las normas de seguridad en las empresas?',
    '¿Te gustaría asesorar sobre salud y prevención de riesgos laborales?',
    '¿Disfrutas identificar posibles peligros en los espacios de trabajo?',
    '¿Te gustaría trabajar con plantas, cultivos o animales?',
    '¿Disfrutas cuidar el medio ambiente y los recursos naturales?',
    '¿Te interesa aprender sobre técnicas de producción agrícola?',
    '¿Te llama la atención contribuir a la alimentación de la comunidad?',
  ];

  final Map<String, String> opciones = {
    'A': 'Me gusta',
    'B': 'Me interesa',
    'C': 'No me gusta',
    'D': 'No me interesa',
  };

  final Map<String, String> respuestas = {};
  int preguntaActual = 0;
  bool mostrarModal = false;

  @override
  void initState() {
    super.initState();
    _cargarProgreso();
  }

  // ---------- PERSISTENCIA
  Future<void> _cargarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('grado9_pregunta_actual') ?? 0;
    final savedResp = prefs.getString('grado9_respuestas');
    if (savedResp != null) {
      final Map<String, dynamic> respDecoded = jsonDecode(savedResp);
      setState(() {
        preguntaActual = savedIndex;
        respuestas.addAll(respDecoded.map((k, v) => MapEntry(k, v.toString())));
      });
    }
  }

  Future<void> _guardarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('grado9_pregunta_actual', preguntaActual);
    await prefs.setString('grado9_respuestas', jsonEncode(respuestas));
  }

  // ---------- NAVEGACIÓN
  void siguientePregunta() {
    if (preguntaActual < preguntas.length - 1) {
      setState(() => preguntaActual++);
      _guardarProgreso();
    } else {
      setState(() => mostrarModal = true);
    }
  }

  void anteriorPregunta() {
    if (preguntaActual > 0) {
      setState(() => preguntaActual--);
      _guardarProgreso();
    }
  }

  Future<void> enviarTest() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userId = prefs.getInt('user_id');
    if (token == null || userId == null) return;

    final url =
        Uri.parse('http://127.0.0.1:8000/Alipsicoorientadora/tests-grado9/');
    final respuestasFinales = {
      for (var i = 0; i < preguntas.length; i++)
        'pregunta_${i + 1}': respuestas['pregunta_$i'] ?? ''
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'usuario': userId,
        'respuestas': respuestasFinales,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      await prefs.remove('grado9_pregunta_actual');
      await prefs.remove('grado9_respuestas');

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final resultado = data['resultado'].toString();

      final contador = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
      respuestas.values.forEach((v) {
        if (contador.containsKey(v)) contador[v] = contador[v]! + 1;
      });
      final total = respuestas.length;

      final porcentajes = {
        'Me gusta': (contador['A']! * 100 / total),
        'Me interesa': (contador['B']! * 100 / total),
        'No me gusta': (contador['C']! * 100 / total),
        'No me interesa': (contador['D']! * 100 / total),
      };

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultadoTest9Screen(
            resultado: resultado,
            porcentajes: porcentajes,
            icono: Icons.lightbulb,
            color: azulFondoSuave,
          ),
        ),
      );
    }
  }

  // #################################### UI
  @override
  Widget build(BuildContext context) {
    final pregunta = preguntas[preguntaActual];
    final respuestaSeleccionada = respuestas['pregunta_$preguntaActual'] ?? '';
    final progreso = respuestas.length / preguntas.length;

    if (mostrarModal) {
      Future.microtask(() {
        setState(() => mostrarModal = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('¿Enviar respuestas?'),
            content: const Text(
                'Una vez enviadas no podrás modificarlas. ¿Estás seguro?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  enviarTest();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: azulFondoSuave,
                    shape: const StadiumBorder()),
                child: const Text('Enviar'),
              ),
            ],
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: azulFondoSuave,
      body: Stack(
        children: [
          const Positioned.fill(child: _AnimatedBackground()),
          // -------- Overlay degradado animado ------------
          const Positioned.fill(child: _GradientOverlay()),
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const EstudianteHome()),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 500),
                  scale: 1.0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.90),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        )
                      ],
                      border: Border.all(
                          color: Colors.white.withOpacity(0.35), width: 1.3),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // PROGRESO
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: progreso,
                            backgroundColor: azulSeleccion.withOpacity(.25),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                azulAcento),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${(progreso * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                                color: azulAcento,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Pregunta ${preguntaActual + 1} de ${preguntas.length}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          pregunta,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 30),

                        // OPCIONES
                        ...opciones.entries.map((opcion) {
                          final estaSeleccionado =
                              respuestaSeleccionada == opcion.key;
                          return GestureDetector(
                            onTap: () {
                              setState(() => respuestas[
                                      'pregunta_$preguntaActual'] =
                                  opcion.key);
                              _guardarProgreso();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOut,
                              margin:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                color: estaSeleccionado
                                    ? azulSeleccion
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                    color: estaSeleccionado
                                        ? azulAcento
                                        : azulSeleccion.withOpacity(0.3),
                                    width: 2),
                                boxShadow: [
                                  if (estaSeleccionado)
                                    BoxShadow(
                                      color: azulSeleccion.withOpacity(.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: estaSeleccionado
                                        ? Colors.white
                                        : azulSeleccion,
                                    child: Text(
                                      opcion.key,
                                      style: TextStyle(
                                          color: estaSeleccionado
                                              ? azulSeleccion
                                              : Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      opcion.value,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: estaSeleccionado
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: estaSeleccionado
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 26),

                        // BOTONES
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (preguntaActual > 0)
                              _BotonRounded(
                                texto: 'Anterior',
                                color: Colors.grey.shade500,
                                onTap: anteriorPregunta,
                              ),
                            _BotonRounded(
                              texto: preguntaActual == preguntas.length - 1
                                  ? 'Finalizar'
                                  : 'Siguiente',
                              color: azulAcento,
                              enabled: respuestaSeleccionada.isNotEmpty,
                              onTap: siguientePregunta,
                            ),
                          ],
                        )
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

// BOTÓN ANIMADO
class _BotonRounded extends StatefulWidget {
  final String texto;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;
  const _BotonRounded(
      {required this.texto,
      required this.color,
      required this.onTap,
      this.enabled = true});

  @override
  State<_BotonRounded> createState() => _BotonRoundedState();
}

class _BotonRoundedState extends State<_BotonRounded>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 90),
        lowerBound: 0.0,
        upperBound: 0.05);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = 1 - _ctrl.value;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      onTap: widget.enabled ? widget.onTap : null,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.45,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(widget.texto,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

// FONDO ANIMADO (ondas + íconos)
class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with TickerProviderStateMixin {
  late final AnimationController _ctrlOndas =
      AnimationController(vsync: this, duration: const Duration(seconds: 12))
        ..repeat(reverse: true);
  late final Animation<double> _shift =
      Tween<double>(begin: -40, end: 40).animate(
          CurvedAnimation(parent: _ctrlOndas, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrlOndas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrlOndas,
      builder: (_, __) => Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter:
                  _WavePainter(offset: _shift.value, color: Colors.white24),
            ),
          ),
          Positioned.fill(
            top: 60,
            child: CustomPaint(
              painter: _WavePainter(
                  offset: _shift.value * .6, color: Colors.white30),
            ),
          ),
          const _IconFloat(top: 100, left: 40, icon: Icons.menu_book),
          const _IconFloat(bottom: 120, right: 60, icon: Icons.computer),
          const _IconFloat(top: 220, right: 20, icon: Icons.school),
          const _IconFloat(bottom: 40, left: 30, icon: Icons.pedal_bike),
        ],
      ),
    );
  }
}

class _IconFloat extends StatelessWidget {
  final double? top, left, right, bottom;
  final IconData icon;
  const _IconFloat(
      {this.top, this.left, this.right, this.bottom, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Icon(icon, size: 48, color: Colors.white.withOpacity(0.08)),
    );
  }
}

// ---------- OVERLAY DEGRADADO (sutil animación de opacidad)
class _GradientOverlay extends StatefulWidget {
  const _GradientOverlay();
  @override
  State<_GradientOverlay> createState() => _GradientOverlayState();
}

class _GradientOverlayState extends State<_GradientOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))
        ..repeat(reverse: true);
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.05 + 0.1 * _ctrl.value),
              Colors.white.withOpacity(0.12 + 0.05 * _ctrl.value),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

// PINTOR DE ONDAS
class _WavePainter extends CustomPainter {
  final double offset;
  final Color color;
  _WavePainter({required this.offset, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height * 0.7 + offset)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.6 + offset,
          size.width * 0.5, size.height * 0.7 + offset)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.8 + offset,
          size.width, size.height * 0.7 + offset)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.offset != offset;
}
