import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'estudiante_home.dart';

class ResultadoTest1011Screen extends StatefulWidget {
  final Map<String, String> respuestas;
  final String resultado;

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
  late Color color;

  final List<Color> pieColors = [
    const Color(0xFF32D6A0), // A - Me gusta
    const Color(0xFF5C8DF6), // B - Me interesa
    const Color(0xFFF57D7C), // C - No me gusta
    const Color(0xFFEFC368), // D - No me interesa
  ];

  final Map<String, String> pieLabels = {
    'A': 'Me gusta',
    'B': 'Me interesa',
    'C': 'No me gusta',
    'D': 'No me interesa',
  };

  @override
  void initState() {
    super.initState();
    calcularPorcentajes();
    configurarIconoYColor(widget.resultado);
  }

  void calcularPorcentajes() {
    Map<String, int> conteo = {'A': 0, 'B': 0, 'C': 0, 'D': 0};

    for (var respuesta in widget.respuestas.values) {
      if (conteo.containsKey(respuesta)) {
        conteo[respuesta] = conteo[respuesta]! + 1;
      }
    }

    final total = widget.respuestas.length.toDouble();
    porcentajes = {
      for (var key in conteo.keys)
        key: (conteo[key]! / total * 100).toDouble(),
    };
  }

  void configurarIconoYColor(String resultado) {
    final carrera = resultado.toLowerCase();

    if (carrera.contains('medicina')) {
      icono = FontAwesomeIcons.userDoctor;
      color = Colors.teal;
    } else if (carrera.contains('ingeniería') || carrera.contains('ingenieria')) {
      icono = FontAwesomeIcons.gears;
      color = Colors.blueGrey;
    } else if (carrera.contains('psicología') || carrera.contains('psicologia')) {
      icono = FontAwesomeIcons.brain;
      color = Colors.deepPurple;
    } else if (carrera.contains('derecho')) {
      icono = FontAwesomeIcons.scaleBalanced;
      color = Colors.brown;
    } else if (carrera.contains('educación') || carrera.contains('educacion')) {
      icono = FontAwesomeIcons.bookOpen;
      color = Colors.indigo;
    } else if (carrera.contains('sistemas') || carrera.contains('software')) {
      icono = FontAwesomeIcons.laptopCode;
      color = Colors.blue;
    } else if (carrera.contains('administración') || carrera.contains('administracion')) {
      icono = FontAwesomeIcons.chartColumn;
      color = Colors.green;
    } else if (carrera.contains('contaduría') || carrera.contains('contaduria')) {
      icono = FontAwesomeIcons.calculator;
      color = Colors.cyan;
    } else if (carrera.contains('diseño') || carrera.contains('diseno')) {
      icono = FontAwesomeIcons.penNib;
      color = Colors.pink;
    } else if (carrera.contains('naturales')) {
      icono = FontAwesomeIcons.leaf;
      color = Colors.lightGreen;
    } else {
      icono = FontAwesomeIcons.question;
      color = Colors.grey;
    }
  }

  String decodeUTF8(String texto) {
    return utf8.decode(texto.runes.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color.withOpacity(0.1),
      appBar: AppBar(
        backgroundColor: color,
        title: const Text('Resultado del Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icono, size: 60, color: color),
            const SizedBox(height: 16),
            Text(
              'Carrera recomendada',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              decodeUTF8(widget.resultado), // ✅ Aquí se soluciona la codificación
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: porcentajes.entries.map((entry) {
                    final index = ['A', 'B', 'C', 'D'].indexOf(entry.key);
                    return PieChartSectionData(
                      color: pieColors[index],
                      value: entry.value,
                      title: '${entry.value.toStringAsFixed(1)}%',
                      radius: 60,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: porcentajes.length,
                itemBuilder: (context, index) {
                  final key = ['A', 'B', 'C', 'D'][index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: pieColors[index],
                      child: Text(key, style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(pieLabels[key]!),
                    trailing: Text('${porcentajes[key]!.toStringAsFixed(1)}%'),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.home),
              label: const Text('Volver al inicio'),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const EstudianteHome()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
