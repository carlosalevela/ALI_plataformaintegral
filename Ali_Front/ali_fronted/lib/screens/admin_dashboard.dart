// admin_dashboard.dart
//
// ✅ ACTUALIZADO 24-Jul-2025 (con estadísticas reales)
//  • Reemplaza listas estáticas por datos del backend (_tec/_car).
//  • Botón refresh recarga estadísticas.
//  • Se conserva el resto de la lógica/UI intacta.
//
// ignore_for_file: depend_on_referenced_packages
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Excel y FileSaver ───────────────────────────────────────────
import 'package:excel/excel.dart' as ex;
import 'package:file_saver/file_saver.dart';

import '../services/api_service.dart';
import 'usuarios_screen.dart';
import 'estadisticas_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // ───────────────────────── data
  final ApiService apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> administradores = [];
  Map<String, List<Map<String, dynamic>>> estudiantesPorGrado = {
    '9': [],
    '10': [],
    '11': [],
  };

  // ───────────────────────── ui-state
  bool _isLoading = true;
  String _activeSection = 'dashboard';
  bool _studentsDropdownOpen = false;
  String _selectedDashboardGrade = '9';
  String _selectedStudentsGrade = '9';
  String _searchTerm = '';

  // ── NUEVO: datos dinámicos para el gráfico
  List<Map<String, dynamic>> _tec = []; // Técnicos (Grado 9)
  List<Map<String, dynamic>> _car = []; // Carreras (10/11)
  bool _loadingStats = false;

  // ───────────────────────── init
  @override
  void initState() {
    super.initState();
    _verificarPermiso();
    _searchController.addListener(() => setState(() => _searchTerm = _searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ═════════════════════════════════ permisos
  Future<void> _verificarPermiso() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('rol') != 'admin') {
      if (mounted) Navigator.pushReplacementNamed(context, '/');
      return;
    }
    await _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final usuarios = await apiService.fetchUsuarios();

      Future<Map<String, dynamic>> _enriquecer(Map<String, dynamic> u) async {
        final usr = Map<String, dynamic>.from(u);
        usr['estado'] = usr['estado'] ?? 'Activo';

        // Helpers de formato
        String _fmt(Map<String, dynamic> t, {required int total}) {
          final estado = t['estado']?.toString() ?? '';
          final resp   = (t['respondidas'] as num?)?.toInt() ?? 0;
          final ult    = (t['ultima_pregunta'] as num?)?.toInt() ?? 0;
          final pct    = (t['progreso_pct'] as num?)?.toDouble() ?? (total > 0 ? (resp / total) * 100 : 0);
          if (estado == 'FINALIZADO') return 'Finalizado';
          if (estado == 'EN_PROGRESO') return 'En progreso: $resp/$total (P$ult) ${pct.toStringAsFixed(0)}%';
          return '—';
        }

        // Grado 9
        if (usr['grado'] == 9) {
          final info = await apiService.progresoUsuarioGrado9(usr['id'], total: 40);
          usr['progreso']            = info['progreso'] ?? '—';
          usr['ultimaRecomendacion'] = info['ultimaRecomendacion'] ?? '—';

          // Fallback por si quieres mantener el detalle
          if (usr['ultimaRecomendacion'] == '—') {
            final tests = await apiService.fetchTestsGrado9PorUsuario(usr['id']);
            if (tests.isNotEmpty) {
              final det = await apiService.fetchResultadoTest9PorId(tests.first['id']);
              usr['ultimaRecomendacion'] = det['resultado'] ?? '—';
              usr['progreso'] = usr['progreso'] == '—' ? _fmt(tests.first, total: 40) : usr['progreso'];
            }
          }
          return usr;
        }

        // Grado 10/11
        if (usr['grado'] == 10 || usr['grado'] == 11) {
          final info = await apiService.progresoUsuarioGrado10y11(usr['id'], total: 40);
          usr['progreso']            = info['progreso'] ?? '—';
          usr['ultimaRecomendacion'] = info['ultimaRecomendacion'] ?? '—';

          if (usr['ultimaRecomendacion'] == '—') {
            final tests = await apiService.fetchTestsGrado10y11PorUsuario(usr['id']);
            if (tests.isNotEmpty) {
              final det = await apiService.fetchResultadoTest10y11PorId(tests.first['id']);
              usr['ultimaRecomendacion'] = det['resultado'] ?? '—';
              usr['progreso'] = usr['progreso'] == '—' ? _fmt(tests.first, total: 40) : usr['progreso'];
            }
          }
          return usr;
        }

        // Otros grados
        usr['progreso']            = '—';
        usr['ultimaRecomendacion'] = '—';
        return usr;
      }

      administradores = usuarios.where((u) => u['rol'] == 'admin').toList();

      final est9  = usuarios.where((u) => u['rol'] == 'estudiante' && u['grado'] == 9).toList();
      final est10 = usuarios.where((u) => u['rol'] == 'estudiante' && u['grado'] == 10).toList();
      final est11 = usuarios.where((u) => u['rol'] == 'estudiante' && u['grado'] == 11).toList();

      estudiantesPorGrado['9']  = await Future.wait(est9 .map(_enriquecer));
      estudiantesPorGrado['10'] = await Future.wait(est10.map(_enriquecer));
      estudiantesPorGrado['11'] = await Future.wait(est11.map(_enriquecer));
    } catch (e) {
      debugPrint('Error al cargar usuarios: $e');
    }
    if (mounted) {
      setState(() => _isLoading = false);
      // 🚀 Cargar estadísticas reales para el gráfico
      _cargarEstadisticas();
    }
  }

  // ═════════════════════════════════ helpers
  List<Map<String, dynamic>> _estudiantesGrado(String k) {
    switch (k) {
      case '9':     return estudiantesPorGrado['9']!;
      case '10':    return estudiantesPorGrado['10']!;
      case '11':    return estudiantesPorGrado['11']!;
      case '10/11': return estudiantesPorGrado['10']! + estudiantesPorGrado['11']!;
      default:      return [];
    }
  }

  void _abrirEstadisticas(Map<String, dynamic> al) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstadisticasUsuarioScreen(
          usuarioId: al['id'],
          nombre:    al['nombre'] ?? al['username'],
          grado:     al['grado'],
        ),
      ),
    );
  }

  Future<void> _editarUsuario(Map<String, dynamic> u) async {
    final n = TextEditingController(text: u['nombre']);
    final e = TextEditingController(text: u['email']);
    final g = TextEditingController(text: u['grado']?.toString());

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: n, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: e, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: g, decoration: const InputDecoration(labelText: 'Grado')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final ok = await apiService.editarUsuario(u['id'], {
                'nombre': n.text.trim(),
                'email' : e.text.trim(),
                'grado' : int.tryParse(g.text.trim()),
              });
              if (ok && mounted) {
                Navigator.pop(context);
                await _cargarUsuarios();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarUsuario(int id) async {
    final conf = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (conf == true) {
      final ok = await apiService.deleteUsuario(id);
      if (ok) await _cargarUsuarios();
    }
  }

  // ═════════════════════════════════ exportar Excel (alias ex)
  Future<void> _exportarExcel(List<Map<String, dynamic>> alumnos) async {
    final ex.Excel wb = ex.Excel.createExcel();
    final ex.Sheet sh = wb['Estudiantes'];

    sh.appendRow([
      'ID', 'Nombre', 'Email', 'Grado', 'Estado', 'Progreso', 'Recomendación'
    ]);

    for (final a in alumnos) {
      sh.appendRow([
        a['id'] ?? '',
        a['nombre'] ?? '',
        a['email'] ?? '',
        a['grado'] ?? '',
        a['estado'] ?? '',
        a['progreso'] ?? '',
        a['ultimaRecomendacion'] ?? '',
      ]);
    }

    final Uint8List bytes = Uint8List.fromList(wb.encode()!);

    await FileSaver.instance.saveFile(
      'estudiantes_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      bytes,
      'xlsx',
      mimeType: MimeType.MICROSOFTEXCEL,
    );
  }

  // activo / inactivo
  Future<void> _toggleEstado(Map<String, dynamic> al) async {
    final nuevo = al['estado'] == 'Activo' ? 'Inactivo' : 'Activo';
    final ok = await apiService.editarUsuario(al['id'], {'estado': nuevo});
    if (ok && mounted) setState(() => al['estado'] = nuevo);
  }

  // ═════════════════════════════════ sidebar
  void _onSidebarTap(String key, {bool drop = false}) {
    setState(() {
      if (key == 'students' && drop) {
        _studentsDropdownOpen = !_studentsDropdownOpen;
        _activeSection = 'students';
      } else {
        _activeSection = key;
        _studentsDropdownOpen = false;
      }
    });
  }

  Widget _buildSidebar() {
    const sidebarBg = Color(0xFF1465BB);
    const activeBg  = Color(0xFF0D4A8A);
    final inactive  = Colors.grey[300];

    Widget item(IconData ic, String label, String key, {bool drop = false}) {
      final act = _activeSection == key;
      return Column(
        children: [
          ListTile(
            leading: Icon(ic, size: 20, color: act ? Colors.white : inactive),
            title:  Text(label, style: TextStyle(color: act ? Colors.white : inactive)),
            tileColor: act ? activeBg : sidebarBg,
            onTap: () => _onSidebarTap(key, drop: drop),
            trailing: drop
                ? Icon(_studentsDropdownOpen ? Icons.expand_less : Icons.expand_more, color: inactive)
                : null,
          ),
          if (key == 'students' && _studentsDropdownOpen)
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.chevron_right, color: Colors.white),
                    title: const Text('Grado 9°', style: TextStyle(color: Colors.white)),
                    onTap: () => setState(() {
                      _selectedStudentsGrade = '9';
                      _activeSection = 'students';
                    }),
                  ),
                  ListTile(
                    leading: const Icon(Icons.chevron_right, color: Colors.white),
                    title: const Text('Grado 10/11', style: TextStyle(color: Colors.white)),
                    onTap: () => setState(() {
                      _selectedStudentsGrade = '10';
                      _activeSection = 'students';
                    }),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return Container(
      width: 250,
      color: sidebarBg,
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text('ALI',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                item(Icons.bar_chart, 'Panel Principal', 'dashboard'),
                item(Icons.person,    'Profesores',      'teachers'),
                item(Icons.school,    'Estudiantes',     'students', drop: true),
                item(Icons.analytics, 'Analíticas',      'analytics'),
              ],
            ),
          ),
          const Divider(color: Colors.white54),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title:  const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pushReplacementNamed(context, '/'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ═════════════════════════════════ header
  Widget _buildHeader() {
    final title = {
      'dashboard': 'Panel Principal',
      'students' : 'Estudiantes',
      'teachers' : 'Profesores',
      'analytics': 'Analíticas',
    }[_activeSection]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          if (_activeSection != 'dashboard')
            SizedBox(
              width: 300,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 20),
                  hintText: 'Buscar...',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          const SizedBox(width: 24),
          const CircleAvatar(child: Icon(Icons.person)),
        ],
      ),
    );
  }

  // ═════════════════════════════════ métricas
  List<Map<String, String>> _metricas(String gradeKey) {
    final est = _estudiantesGrado(gradeKey);
    final tot = est.length;
    final fin = est.where((e) => e['progreso'] == 'Finalizado').length;
    final pen = tot - fin;
    final pct = tot > 0 ? ((fin / tot) * 100).round() : 0;
    return [
      {'title': 'Total Estudiantes',  'value': '$tot', 'subtitle': 'en este grado', 'trend': '+5%'},
      {'title': 'Tests Completados',  'value': '$fin', 'subtitle': 'estudiantes',   'trend': '$pct%'},
      {'title': 'Tests Pendientes',   'value': '$pen', 'subtitle': 'estudiantes',   'trend': '-2%'},
      {'title': 'Tasa de Finalización', 'value': '$pct%', 'subtitle': 'del total', 'trend': '+8%'},
    ];
  }

  // ─────────────── NUEVO: helpers de estadísticas reales
  String _parseTecnico(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Desconocido';
    final s = raw;

    // Formato nuevo: "Técnico sugerido por ALI: Comercio"
    const tag = 'Técnico sugerido por ALI:';
    final i = s.indexOf(tag);
    if (i >= 0) {
      final rest = s.substring(i + tag.length).trim();
      final first = rest.split(RegExp(r'[\n\r]')).first.trim();
      if (first.isNotEmpty) return first;
    }

    // Formatos antiguos (RF/KNN)
    for (final op in ['Industrial','Comercio','Promoción Social','Agropecuaria']) {
      if (s.contains(op)) return op;
    }
    return 'Desconocido';
  }

  Future<void> _cargarEstadisticas() async {
    setState(() => _loadingStats = true);
    try {
      // 9° FINALIZADOS
      final tests9 = await apiService.fetchTestsGrado9(
        estado: 'FINALIZADO', orden: null, limit: 500, offset: 0,
      );
      final Map<String,int> cntTec = {
        'Industrial':0, 'Comercio':0, 'Promoción Social':0, 'Agropecuaria':0,
      };
      for (final t in tests9) {
        final tec = _parseTecnico(t['resultado']?.toString());
        if (cntTec.containsKey(tec)) cntTec[tec] = (cntTec[tec] ?? 0) + 1;
      }
      final tecList = cntTec.entries
          .map((e)=>{'name': e.key, 'count': e.value})
          .toList()
        ..sort((a,b)=> (b['count'] as int).compareTo(a['count'] as int));

      // 10/11 FINALIZADOS
      final tests1011 = await apiService.fetchTestsGrado10y11(
        estado: 'FINALIZADO', orden: null, limit: 1000, offset: 0,
      );
      final Map<String,int> cntCar = {};
      for (final t in tests1011) {
        final car = (t['resultado']?.toString().trim().isEmpty ?? true)
            ? 'Desconocido'
            : t['resultado'].toString().trim();
        cntCar[car] = (cntCar[car] ?? 0) + 1;
      }
      final carList = cntCar.entries
          .map((e)=>{'name': e.key, 'count': e.value})
          .toList()
        ..sort((a,b)=> (b['count'] as int).compareTo(a['count'] as int));

      if (mounted) setState(() { _tec = tecList; _car = carList; });
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  // ═════════════════════════════════ dashboard
  Widget _renderDashboard() {
    final grade   = _selectedDashboardGrade;
    final metrics = _metricas(grade);
    final choices = grade == '9' ? _tec : _car;
    final maxC    = choices.isNotEmpty
        ? choices.map<int>((e) => e['count'] as int).reduce((a, b) => a > b ? a : b)
        : 1;

    final now = DateTime.now();
    final ini = DateTime(now.year, now.month, 1);
    final fin = DateTime(now.year, now.month + 1, 0);
    final rango = '${DateFormat('d MMM', 'es').format(ini)} - '
                  '${DateFormat('d MMM yyyy', 'es').format(fin)}';
    final mesAn = DateFormat('MMMM yyyy', 'es').format(now);

    final calDays = List.generate(5, (i) {
      final d = now.day - 2 + i;
      if (d < 1) return 1 + fin.day + d - 1;
      if (d > fin.day) return d - fin.day;
      return d;
    });

    final progRaw = metrics[1]['trend'] ?? '0%';
    final progVal = (double.tryParse(progRaw.replaceAll(RegExp(r'\D'), '')) ?? 0) / 100;

    final listaEst = _estudiantesGrado(grade);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: ['9', '10/11'].map((g) {
                  final sel = _selectedDashboardGrade == g;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sel ? const Color(0xFF0D4A8A) : Colors.transparent,
                        foregroundColor: sel ? Colors.white : Colors.grey[700],
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        elevation: 0,
                      ),
                      onPressed: () => setState(() => _selectedDashboardGrade = g),
                      child: Text(g == '9' ? 'Grado 9°' : 'Bachillerato'),
                    ),
                  );
                }).toList(),
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(rango, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // métricas
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 3 / 2,
            physics: const NeverScrollableScrollPhysics(),
            children: metrics.map((m) {
              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['title']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(m['value']!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(m['subtitle']!, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                      Text(m['trend']!, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // gráfico + col lateral
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(grade == '9' ? 'Técnicos Elegidos' : 'Carreras Elegidas',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              onPressed: _cargarEstadisticas, // ← recarga reales
                            ),
                          ],
                        ),
                        if (_loadingStats) const LinearProgressIndicator(minHeight: 2),
                        const SizedBox(height: 12),
                        for (final ch in choices)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(width: 140, child: Text(ch['name'], style: const TextStyle(fontSize: 14))),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: (maxC == 0 ? 0 : (ch['count'] as int) / maxC),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text('${ch['count']}'),
                              ],
                            ),
                          ),
                        if (choices.isEmpty && !_loadingStats)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('Sin datos aún', style: TextStyle(color: Colors.grey)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(mesAn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(5, (idx) {
                                final d = [for (int i=-2;i<=2;i++) i][idx] + now.day;
                                final end = DateTime(now.year, now.month + 1, 0).day;
                                final day = d < 1 ? 1 : (d > end ? end : d);
                                final isToday = day == now.day;
                                return ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isToday ? const Color(0xFF0D4A8A) : const Color(0xFFF9FAFB),
                                    foregroundColor: isToday ? Colors.white : Colors.grey[700],
                                    elevation: 0,
                                    minimumSize: const Size(32, 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () {},
                                  child: Text('$day'),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('Progreso de Tests', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                Text('+8.5% del mes pasado', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(value: progVal, minHeight: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // tabla estudiantes
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Estudiantes - ${grade == '9' ? 'Grado 9°' : '10/11'}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _cargarUsuarios()),
                          IconButton(icon: const Icon(Icons.download), tooltip: 'Excel',
                              onPressed: () => _exportarExcel(listaEst)),
                          IconButton(icon: const Icon(Icons.open_in_new),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UsuariosScreen(titulo: 'Estudiantes', usuarios: listaEst),
                                ),
                              )),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Nombre')),
                        DataColumn(label: Text('Estado')),
                        DataColumn(label: Text('Recomendación')),
                        DataColumn(label: Text('Progreso')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: listaEst.map((e) {
                        final prog   = e['progreso'] ?? 'N/A';
                        final estado = e['estado'] ?? 'Activo';
                        final rec    = e['ultimaRecomendacion'] ?? '—';
                        final chipEstado = GestureDetector(
                          onSecondaryTap: () => _toggleEstado(e),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: estado == 'Activo' ? Colors.green[100] : Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(estado,
                                style: TextStyle(color: estado == 'Activo' ? Colors.green : Colors.red)),
                          ),
                        );
                        return DataRow(
                          onSelectChanged: (_) => _abrirEstadisticas(e),
                          cells: [
                            DataCell(Text(e['nombre'] ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis)),
                            DataCell(chipEstado),
                            DataCell(Text(rec)),
                            DataCell(Text(prog)),
                            DataCell(Row(
                              children: [
                                IconButton(icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _editarUsuario(e)),
                                IconButton(icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () => _eliminarUsuario(e['id'])),
                              ],
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════ estudiantes
  Widget _renderStudents() {
    final kGr   = _selectedStudentsGrade == '9' ? '9' : '10';
    final al    = kGr == '9'
        ? estudiantesPorGrado['9']!
        : estudiantesPorGrado['10']! + estudiantesPorGrado['11']!;
    final filt  = al.where((e) {
      final name = (e['nombre'] ?? '').toString().toLowerCase();
      return name.contains(_searchTerm.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estudiantes Inscritos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Excel'),
                    onPressed: () => _exportarExcel(filt),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1465BB),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  for (final g in ['9', '10/11'])
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedStudentsGrade == (g == '9' ? '9' : '10')
                              ? const Color(0xFF0D4A8A)
                              : Colors.transparent,
                          foregroundColor: _selectedStudentsGrade == (g == '9' ? '9' : '10')
                              ? Colors.white
                              : Colors.grey[700],
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                        ),
                        onPressed: () =>
                            setState(() => _selectedStudentsGrade = g == '9' ? '9' : '10'),
                        child: Text(g == '9' ? 'Grado 9°' : 'Grado 10/11'),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Recomendación')),
                  DataColumn(label: Text('Progreso')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: filt.map((al) {
                  final prog   = al['progreso'] ?? 'N/A';
                  final estado = al['estado'] ?? 'Activo';
                  final rec    = al['ultimaRecomendacion'] ?? '—';
                  final chipEstado = GestureDetector(
                    onSecondaryTap: () => _toggleEstado(al),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: estado == 'Activo' ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(estado,
                          style: TextStyle(color: estado == 'Activo' ? Colors.green : Colors.red)),
                    ),
                  );
                  return DataRow(
                    onSelectChanged: (_) => _abrirEstadisticas(al),
                    cells: [
                      DataCell(Text(al['nombre'] ?? '—')),
                      DataCell(Text(al['email'] ?? '—')),
                      DataCell(chipEstado),
                      DataCell(Text(rec)),
                      DataCell(Text(prog)),
                      DataCell(Row(
                        children: [
                          IconButton(icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _editarUsuario(al)),
                          IconButton(icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => _eliminarUsuario(al['id'])),
                        ],
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════ profesores (sin cambios lógicos)
  Widget _renderTeachers() {
    final filt = administradores.where((t) {
      final name = (t['nombre'] ?? '').toString().toLowerCase();
      return name.contains(_searchTerm.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Profesores Registrados',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(icon: const Icon(Icons.person_add),
                  label: const Text('Agregar Profesor'), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: filt.map((p) {
                  return DataRow(cells: [
                    DataCell(Text(p['nombre']?.toString().isNotEmpty == true
                        ? p['nombre'] : p['username'] ?? '—')),
                    DataCell(Text(p['email'] ?? '—')),
                    DataCell(Row(
                      children: [
                        IconButton(icon: const Icon(Icons.edit),   onPressed: () => _editarUsuario(p)),
                        IconButton(icon: const Icon(Icons.delete), onPressed: () => _eliminarUsuario(p['id'])),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════ build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RawKeyboardListener(
              autofocus: true,
              focusNode: FocusNode(),
              onKey: (ev) {
                if (ev is RawKeyDownEvent) {
                  if (ev.logicalKey == LogicalKeyboardKey.arrowDown) {
                    _scrollController.animateTo(
                      _scrollController.offset + 100,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOut,
                    );
                  } else if (ev.logicalKey == LogicalKeyboardKey.arrowUp) {
                    _scrollController.animateTo(
                      _scrollController.offset - 100,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOut,
                    );
                  }
                }
              },
              child: Row(
                children: [
                  _buildSidebar(),
                  Expanded(
                    child: Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: () {
                            switch (_activeSection) {
                              case 'students':
                                return _renderStudents();
                              case 'teachers':
                                return _renderTeachers();
                              case 'analytics':
                                return const Center(child: Text('Sección de Analíticas en desarrollo'));
                              case 'dashboard':
                              default:
                                return _renderDashboard();
                            }
                          }(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
