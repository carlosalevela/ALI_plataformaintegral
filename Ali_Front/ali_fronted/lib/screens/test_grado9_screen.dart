import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TestGrado9Page extends StatefulWidget {
  @override
  _TestGrado9PageState createState() => _TestGrado9PageState();
}

class _TestGrado9PageState extends State<TestGrado9Page> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _respuestas = {};
  int? _userId;

  final Map<String, String> opciones = {
    'A': 'Me gusta',
    'B': 'Me interesa',
    'C': 'No me gusta',
    'D': 'No me interesa',
  };

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

  @override
  void initState() {
    super.initState();
    _cargarProgreso();
  }

  void _cargarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');
    final saved = prefs.getString('test_grado9_respuestas_$_userId');
    if (saved != null) {
      setState(() {
        _respuestas.addAll(Map<String, String>.from(jsonDecode(saved)));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔄 Se restauró tu progreso anterior.')),
      );
    }
  }

  Future<void> _guardarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    if (_userId != null) {
      await prefs.setString(
        'test_grado9_respuestas_$_userId',
        jsonEncode(_respuestas),
      );
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

    final url = Uri.parse('http://127.0.0.1:8000/Alipsicoorientadora/tests-grado9/');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'usuario': _userId,
        'respuestas': _respuestas
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await prefs.remove('test_grado9_respuestas_$_userId');

      final total = _respuestas.length;
      final contador = {'A': 0, 'B': 0, 'C': 0, 'D': 0};

      _respuestas.values.forEach((v) {
        if (contador.containsKey(v)) contador[v] = contador[v]! + 1;
      });

      final resultado = data['resultado'].toString();
      IconData icono;
      Color color;

      if (resultado.toLowerCase().contains('tecnológico')) {
        icono = Icons.memory;
        color = Colors.blueGrey;
      } else if (resultado.toLowerCase().contains('técnico')) {
        icono = Icons.engineering;
        color = Colors.indigo;
      } else if (resultado.toLowerCase().contains('artístico')) {
        icono = Icons.palette;
        color = Colors.deepPurple;
      } else if (resultado.toLowerCase().contains('empresarial')) {
        icono = Icons.business_center;
        color = Colors.teal;
      } else {
        icono = Icons.lightbulb;
        color = Colors.blueGrey;
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('🎯 Resultado del Test'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  border: Border.all(color: color, width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(icono, color: color, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '💼 Modalidad sugerida:\n$resultado',
                        style: TextStyle(
                          fontSize: 16,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Me gusta: ${(contador['A']! * 100 / total).toStringAsFixed(1)}%'),
              Text('Me interesa: ${(contador['B']! * 100 / total).toStringAsFixed(1)}%'),
              Text('No me gusta: ${(contador['C']! * 100 / total).toStringAsFixed(1)}%'),
              Text('No me interesa: ${(contador['D']! * 100 / total).toStringAsFixed(1)}%'),
              const SizedBox(height: 16),
              const Text('🎉 ¡Gracias por completar el test!', style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            )
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
      case 'A': return Icons.thumb_up;
      case 'B': return Icons.favorite;
      case 'C': return Icons.thumb_down;
      case 'D': return Icons.block;
      default: return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Grado 9 - RIASEC')),
      body: Form(
        key: _formKey,
        child: ListView.builder(
          itemCount: preguntas.length,
          itemBuilder: (context, index) {
            final preguntaKey = 'pregunta_${index + 1}';
            return Card(
              margin: const EdgeInsets.all(8),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${index + 1}. ${preguntas[index]}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    ...opciones.entries.map((entry) => RadioListTile<String>(
                          title: Row(
                            children: [
                              Icon(_getIcon(entry.key), color: Colors.grey.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(entry.value,
                                  style: const TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                          value: entry.key,
                          groupValue: _respuestas[preguntaKey],
                          onChanged: (value) {
                            setState(() {
                              _respuestas[preguntaKey] = value!;
                            });
                            _guardarProgreso();
                          },
                        ))
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.send),
        onPressed: enviarTest,
      ),
    );
  }
}
