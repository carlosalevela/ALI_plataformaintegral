import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Pantalla única para Test de Grado 10 y 11 (estilo TestGrado9Page)
class TestGrado1011Screen extends StatefulWidget {
  const TestGrado1011Screen({Key? key}) : super(key: key);

  @override
  _TestGrado1011ScreenState createState() => _TestGrado1011ScreenState();
}

class _TestGrado1011ScreenState extends State<TestGrado1011Screen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _respuestas = {};
  int? _userId;

  late final AnimationController _controller;
  late final List<Animation<double>> _animations;

  final Map<String, String> opciones = {
    'A': 'Me gusta',
    'B': 'Me interesa',
    'C': 'No me gusta',
    'D': 'No me interesa',
  };

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
    '¿Te atrae el pensamiento crítico y la búsqueda de evidencias?'
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _animations = List.generate(
      preguntas.length,
      (i) => CurvedAnimation(
        parent: _controller,
        curve: Interval(
          i / preguntas.length,
          (i + 1) / preguntas.length,
          curve: Curves.easeOut,
        ),
      ),
    );
    _cargarProgreso();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cargarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');
    final saved = prefs.getString('test_grado_10_11_respuestas_$_userId');
    if (saved != null) {
      setState(() => _respuestas.addAll(Map<String, String>.from(jsonDecode(saved))));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔄 Progreso restaurado.')),
      );
    }
  }

  Future<void> _guardarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    if (_userId != null) {
      await prefs.setString('test_grado_10_11_respuestas_$_userId', jsonEncode(_respuestas));
    }
  }

  Future<void> enviarTest() async {
    if (_respuestas.length < preguntas.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor responde todas las preguntas.')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final url = Uri.parse('http://127.0.0.1:8000/Alipsicoorientadora/tests-grado10-11/');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'usuario': _userId, 'respuestas': _respuestas}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      await prefs.remove('test_grado_10_11_respuestas_$_userId');

      // Mostrar resultado del modelo
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Resultado del Test'),
          content: Text('Recomendación: ${data['resultado']}'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar'))
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al enviar el test.')),
      );
    }
  }

  IconData _getIcon(String key) {
    switch (key) {
      case 'A':
        return Icons.thumb_up;
      case 'B':
        return Icons.favorite;
      case 'C':
        return Icons.thumb_down;
      case 'D':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(backgroundColor: primary, elevation: 0, title: const Text('Test Grado 10 y 11 - RIASEC')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            itemCount: preguntas.length,
            itemBuilder: (context, index) {
              final keyPreg = 'pregunta_${index + 1}';
              final anim = _animations[index];
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, .2), end: Offset.zero).animate(anim),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(left: BorderSide(color: primary, width: 4)),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0,3))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${index + 1}. ${preguntas[index]}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                        const SizedBox(height: 10),
                        ...opciones.entries.map((e) {
                          final sel = _respuestas[keyPreg] == e.key;
                          return RadioListTile<String>(
                            activeColor: primary,
                            title: Row(children: [Icon(_getIcon(e.key), color: sel ? primary : Colors.grey.shade600), const SizedBox(width: 6), Text(e.value, style: TextStyle(fontSize: 15, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? primary : Colors.grey.shade700))]),
                            value: e.key,
                            groupValue: _respuestas[keyPreg],
                            onChanged: (v) {
                              setState(() => _respuestas[keyPreg] = v!);
                              _guardarProgreso();
                            },
                          );
                        }).toList(),
                      ]),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        onPressed: enviarTest,
        child: const Icon(Icons.send, size: 28),
      ),
    );
  }
}
