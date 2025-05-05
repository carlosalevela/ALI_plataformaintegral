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
    final saved = prefs.getString('test_grado9_respuestas');
    if (saved != null) {
      setState(() {
        _respuestas.addAll(Map<String, String>.from(jsonDecode(saved)));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🔄 Se restauró tu progreso anterior.')),
      );
    }
  }

  Future<void> _guardarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('test_grado9_respuestas', jsonEncode(_respuestas));
  }

  Future<void> enviarTest() async {
    if (_respuestas.length < 40) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor responde todas las preguntas.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userId = prefs.getInt('user_id');

    final url = Uri.parse('http://127.0.0.1:8000/Alipsicoorientadora/tests-grado9/');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'usuario': userId,
        'respuestas': _respuestas
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await prefs.remove('test_grado9_respuestas'); // limpiar progreso
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Resultado'),
          content: Text('Modalidad sugerida: ${data['resultado']}'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
        ),
      );
    } else {
      print('Error: ${response.statusCode}');
      print('Body: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar el test.')),
      );
    }
  }

  Color _getColor(String key) {
    switch (key) {
      case 'A': return Colors.green.shade300;
      case 'B': return Colors.blue.shade300;
      case 'C': return Colors.orange.shade300;
      case 'D': return Colors.red.shade300;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Grado 9 - RIASEC')),
      body: Form(
        key: _formKey,
        child: ListView.builder(
          itemCount: preguntas.length,
          itemBuilder: (context, index) {
            final preguntaKey = 'pregunta_${index + 1}';
            return Card(
              margin: EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${index + 1}. ${preguntas[index]}',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...opciones.entries.map((entry) => Container(
                          decoration: BoxDecoration(
                            color: _getColor(entry.key),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: RadioListTile<String>(
                            title: Text('${entry.key} - ${entry.value}',
                                style: TextStyle(color: Colors.black)),
                            value: entry.key,
                            groupValue: _respuestas[preguntaKey],
                            onChanged: (value) {
                              setState(() {
                                _respuestas[preguntaKey] = value!;
                              });
                              _guardarProgreso(); // guardar al cambiar
                            },
                          ),
                        ))
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.send),
        onPressed: enviarTest,
      ),
    );
  }
}
