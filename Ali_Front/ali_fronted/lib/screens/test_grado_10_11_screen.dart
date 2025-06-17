import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'resultado_test_10_11_screen.dart';
import 'estudiante_home.dart';
import 'dart:math' as math;

class TestGrado1011Screen extends StatefulWidget {
  const TestGrado1011Screen({Key? key}) : super(key: key);

  @override
  State<TestGrado1011Screen> createState() => _TestGrado1011ScreenState();
}

class _TestGrado1011ScreenState extends State<TestGrado1011Screen> with TickerProviderStateMixin {
  final List<String> preguntas = [
    '¿Te gustaría aprender cómo funciona el cuerpo humano para ayudar a otros?',
    '¿Disfrutas cuidar a personas enfermas o vulnerables?',
    '¿Te interesa la biología y la investigación médica?',
    '¿Te llama la atención trabajar en hospitales o clínicas?',
    '¿Te interesan los sistemas mecánicos, eléctricos o industriales?',
    '¿Disfrutas resolver problemas técnicos de manera lógica?',
    '¿Te gustaría diseñar estructuras, objetos o soluciones para el mundo real?',
    '¿Te apasionan las matemáticas y su aplicación práctica?',
    '¿Te gustaría liderar una empresa o equipo de trabajo?',
    '¿Te interesa aprender cómo funcionan las organizaciones?',
    '¿Te atrae el mundo de los negocios, ventas y estrategias?',
    '¿Disfrutas planificar y tomar decisiones importantes?',
    '¿Te interesa entender cómo piensan y sienten las personas?',
    '¿Te gustaría ayudar a otros a resolver sus conflictos emocionales?',
    '¿Disfrutas escuchar y comprender a quienes te rodean?',
    '¿Te atrae analizar el comportamiento humano en diferentes contextos?',
    '¿Te gustaría defender los derechos de las personas?',
    '¿Te interesa la justicia, las leyes y su aplicación?',
    '¿Disfrutas debatir y argumentar con lógica?',
    '¿Te atrae la idea de trabajar en juzgados o asesorías legales?',
    '¿Te gustaría enseñar y compartir tus conocimientos con otros?',
    '¿Te interesa guiar procesos de aprendizaje en niños o jóvenes?',
    '¿Disfrutas explicar ideas de manera clara y creativa?',
    '¿Sientes vocación por la formación de nuevas generaciones?',
    '¿Te gustaría crear programas, aplicaciones o videojuegos?',
    '¿Te interesa la inteligencia artificial o el desarrollo web?',
    '¿Disfrutas resolver problemas de lógica a través del código?',
    '¿Te atrae la idea de trabajar en tecnología e innovación?',
    '¿Te interesa el manejo del dinero y las finanzas personales o empresariales?',
    '¿Disfrutas organizar información numérica o contable?',
    '¿Te gustaría trabajar en bancos, oficinas o asesorías financieras?',
    '¿Te sientes cómodo/a siguiendo normas y procedimientos exactos?',
    '¿Te gusta expresarte a través de imágenes, colores y formas?',
    '¿Te gustaría crear campañas visuales o publicitarias?',
    '¿Disfrutas usar programas de diseño como Photoshop o Illustrator?',
    '¿Te interesa el mundo del arte digital y la creatividad visual?',
    '¿Te interesa investigar fenómenos de la naturaleza como el clima o los ecosistemas?',
    '¿Disfrutas hacer experimentos científicos en laboratorio o campo?',
    '¿Te gustaría trabajar como biólogo, físico o químico?',
    '¿Te atrae el pensamiento crítico y la búsqueda de evidencias?',
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

  Color azulFondo = const Color(0xFF8db9e4);
  Color azulSeleccion = const Color(0xFF59bde9);

  @override
  void initState() {
    super.initState();
    _cargarProgreso();
  }

  Future<void> _cargarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      preguntaActual = prefs.getInt('pregunta_actual_1011') ?? 0;
      for (int i = 0; i < preguntas.length; i++) {
        final respuesta = prefs.getString('respuesta_$i');
        if (respuesta != null) {
          respuestas['pregunta_$i'] = respuesta;
        }
      }
    });
  }

  Future<void> _guardarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pregunta_actual_1011', preguntaActual);
    for (int i = 0; i < respuestas.length; i++) {
      final respuesta = respuestas['pregunta_$i'];
      if (respuesta != null) {
        await prefs.setString('respuesta_$i', respuesta);
      }
    }
  }

  Future<void> _borrarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pregunta_actual_1011');
    for (int i = 0; i < preguntas.length; i++) {
      await prefs.remove('respuesta_$i');
    }
  }

  void siguientePregunta() {
    if (preguntaActual < preguntas.length - 1) {
      setState(() {
        preguntaActual++;
      });
      _guardarProgreso();
    } else {
      setState(() {
        mostrarModal = true;
      });
    }
  }

  void anteriorPregunta() {
    if (preguntaActual > 0) {
      setState(() {
        preguntaActual--;
      });
    }
  }

  void enviarTest() async {
    await _borrarProgreso();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultadoTest1011Screen(
          respuestas: respuestas,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pregunta = preguntas[preguntaActual];
    final respuestaSeleccionada = respuestas['pregunta_$preguntaActual'] ?? '';
    double progreso = respuestas.length / preguntas.length;

    if (mostrarModal) {
      Future.microtask(() {
        setState(() => mostrarModal = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('¿Enviar respuestas?'),
            content: const Text('Una vez enviadas no podrás modificarlas. ¿Estás seguro?'),
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
                style: ElevatedButton.styleFrom(backgroundColor: azulFondo),
                child: const Text('Enviar'),
              ),
            ],
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: azulFondo,
      body: Stack(
        children: [
          const Positioned.fill(child: _AnimatedBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const EstudianteHome()),
                    );
                  },
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 600),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LinearProgressIndicator(
                          value: progreso,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(azulFondo),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${(progreso * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: azulFondo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Pregunta ${preguntaActual + 1} de ${preguntas.length}',
                          style: TextStyle(
                            color: azulFondo,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          pregunta,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 30),
                        ...opciones.entries.map((opcion) {
                          final estaSeleccionado = respuestaSeleccionada == opcion.key;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                respuestas['pregunta_$preguntaActual'] = opcion.key;
                              });
                              _guardarProgreso();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: estaSeleccionado ? azulSeleccion : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: estaSeleccionado ? azulSeleccion : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: estaSeleccionado ? Colors.white : azulFondo,
                                    child: Text(
                                      opcion.key,
                                      style: TextStyle(
                                        color: estaSeleccionado ? azulSeleccion : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      opcion.value,
                                      style: TextStyle(
                                        color: estaSeleccionado ? Colors.white : Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (preguntaActual > 0)
                              ElevatedButton(
                                onPressed: anteriorPregunta,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  shape: const StadiumBorder(),
                                ),
                                child: const Text('Anterior'),
                              ),
                            ElevatedButton(
                              onPressed: respuestaSeleccionada.isNotEmpty ? siguientePregunta : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: azulFondo,
                                shape: const StadiumBorder(),
                              ),
                              child: Text(preguntaActual == preguntas.length - 1 ? 'Finalizar' : 'Siguiente'),
                            ),
                          ],
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

class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation1;
  late final Animation<double> _animation2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 10), vsync: this)..repeat(reverse: true);
    _animation1 = Tween<double>(begin: 0, end: 20).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _animation2 = Tween<double>(begin: 0, end: -20).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Stack(
          children: [
            Positioned(top: 100 + _animation1.value, left: 40, child: Icon(Icons.menu_book, size: 48, color: Colors.white.withOpacity(0.2))),
            Positioned(bottom: 120 + _animation2.value, right: 60, child: Icon(Icons.computer, size: 48, color: Colors.white.withOpacity(0.2))),
            Positioned(top: 220 + _animation2.value, right: 20, child: Icon(Icons.school, size: 48, color: Colors.white.withOpacity(0.15))),
            Positioned(bottom: 40 + _animation1.value, left: 30, child: Icon(Icons.pedal_bike, size: 48, color: Colors.white.withOpacity(0.1))),
          ],
        );
      },
    );
  }
}
