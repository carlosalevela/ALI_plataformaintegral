import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'resultado_test9_screen.dart';
import 'estudiante_home.dart';
import 'dart:math' as math;
import 'dart:convert';

class TestGrado9Screen extends StatefulWidget {
  const TestGrado9Screen({Key? key}) : super(key: key);

  @override
  State<TestGrado9Screen> createState() => _TestGrado9ScreenState();
}

class _TestGrado9ScreenState extends State<TestGrado9Screen> with TickerProviderStateMixin {
  final List<String> preguntas = [ // <-- Aquí irían tus 40 preguntas
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

  Color azulFondo = const Color(0xFF8db9e4);
  Color azulSeleccion = const Color(0xFF59bde9);

  @override
  void initState() {
    super.initState();
    _cargarProgreso();
  }

  Future<void> _guardarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('grado9_pregunta_actual', preguntaActual);
    await prefs.setString('grado9_respuestas', jsonEncode(respuestas));
  }

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
      _guardarProgreso();
    }
  }

  void enviarTest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('grado9_pregunta_actual');
    await prefs.remove('grado9_respuestas');

    final resultado = "Modalidad sugerida: Técnico en Programación";
    final porcentajes = {
      'Me gusta': 30.0,
      'Me interesa': 40.0,
      'No me gusta': 20.0,
      'No me interesa': 10.0,
    };

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultadoTest9Screen(
          resultado: resultado,
          porcentajes: porcentajes,
          icono: Icons.computer,
          color: azulFondo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pregunta = preguntas[preguntaActual];
    final respuestaSeleccionada = respuestas['pregunta_$preguntaActual'] ?? '';
    double progreso = respuestas.length / preguntas.length;

    return Scaffold(
      backgroundColor: azulFondo,
      body: Stack(
        children: [
          Positioned.fill(child: AnimatedBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
            child: SingleChildScrollView(
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LinearProgressIndicator(
                        value: progreso,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(azulFondo),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${(progreso * 100).toStringAsFixed(0)}%',
                          style: TextStyle(color: azulFondo, fontWeight: FontWeight.bold),
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
                            child: Text(
                              preguntaActual == preguntas.length - 1 ? 'Finalizar' : 'Siguiente',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (mostrarModal)
            Center(
              child: AlertDialog(
                title: const Text('¿Enviar respuestas?'),
                content: const Text('Una vez enviadas no podrás modificarlas. ¿Estás seguro?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        mostrarModal = false;
                      });
                    },
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: enviarTest,
                    style: ElevatedButton.styleFrom(backgroundColor: azulFondo),
                    child: const Text('Enviar'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class AnimatedBackground extends StatefulWidget {
  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
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
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: 100 + _animation1.value,
              left: 40,
              child: Icon(Icons.menu_book, size: 48, color: Colors.white.withOpacity(0.2)),
            ),
            Positioned(
              bottom: 120 + _animation2.value,
              right: 60,
              child: Icon(Icons.computer, size: 48, color: Colors.white.withOpacity(0.2)),
            ),
            Positioned(
              top: 220 + _animation2.value,
              right: 20,
              child: Icon(Icons.school, size: 48, color: Colors.white.withOpacity(0.15)),
            ),
            Positioned(
              bottom: 40 + _animation1.value,
              left: 30,
              child: Icon(Icons.pedal_bike, size: 48, color: Colors.white.withOpacity(0.1)),
            ),
          ],
        );
      },
    );
  }
}

