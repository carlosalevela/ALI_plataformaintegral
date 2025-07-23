
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'usuarios_screen.dart';
import 'estadisticas_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ---------------- Datos ----------------
  List<Map<String, dynamic>> administradores = [];
  Map<String, List<Map<String, dynamic>>> estudiantesPorGrado = {
    '9': [],
    '10': [],
    '11': [],
  };

  // ---------------- UI State ----------------
  bool _isLoading = true;
  String _activeSection = 'dashboard'; // dashboard | students | teachers | analytics
  bool _studentsDropdownOpen = false;
  String _selectedDashboardGrade = '9'; // 9 | 10/11
  String _selectedStudentsGrade = '9'; // 9 | 10
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _verifyPermission();
    _searchController.addListener(() => setState(() => _searchTerm = _searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------- Permisos ----------------
  Future<void> _verifyPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final rol = prefs.getString('rol');
    if (rol != 'admin') {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
      return;
    }
    await _loadUsuarios();
  }

  Future<void> _loadUsuarios() async {
    try {
      final usuarios = await apiService.fetchUsuarios();
      setState(() {
        administradores = usuarios.where((u) => u['rol'] == 'admin').toList();
        estudiantesPorGrado = {
          '9': usuarios.where((u) => u['rol'] == 'estudiante' && u['grado'] == 9).toList(),
          '10': usuarios.where((u) => u['rol'] == 'estudiante' && u['grado'] == 10).toList(),
          '11': usuarios.where((u) => u['rol'] == 'estudiante' && u['grado'] == 11).toList(),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error al cargar usuarios: $e');
    }
  }

  // ---------------- Helpers ----------------
  List<Map<String, dynamic>> _studentsForGrade(String gradeKey) {
    switch (gradeKey) {
      case '9':
        return estudiantesPorGrado['9']!;
      case '10':
        return estudiantesPorGrado['10']!;
      case '11':
        return estudiantesPorGrado['11']!;
      case '10/11':
        return estudiantesPorGrado['10']! + estudiantesPorGrado['11']!;
      default:
        return [];
    }
  }

  void _openStats(Map<String, dynamic> student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstadisticasUsuarioScreen(
          usuarioId: student['id'],
          nombre: student['nombre'] ?? student['username'],
          grado: student['grado'],
        ),
      ),
    );
  }

  Future<void> _editUser(Map<String, dynamic> usuario) async {
    final nombreCtrl = TextEditingController(text: usuario['nombre']);
    final emailCtrl = TextEditingController(text: usuario['email']);
    final gradoCtrl = TextEditingController(text: usuario['grado']?.toString());

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar Usuario"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: gradoCtrl, decoration: const InputDecoration(labelText: 'Grado')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final success = await apiService.editarUsuario(usuario['id'], {
                'nombre': nombreCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'grado': int.tryParse(gradoCtrl.text.trim()),
              });
              if (success && mounted) {
                Navigator.pop(context);
                await _loadUsuarios();
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(int id) async {
    final confirmado = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Eliminar?"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Eliminar")),
        ],
      ),
    );

    if (confirmado == true) {
      final success = await apiService.deleteUsuario(id);
      if (success) await _loadUsuarios();
    }
  }

  // ---------------- Sidebar ----------------
  void _onSidebarItemTap(String key, {bool hasDropdown = false}) {
    setState(() {
      if (key == 'students' && hasDropdown) {
        _studentsDropdownOpen = !_studentsDropdownOpen;
        _activeSection = 'students';
      } else {
        _activeSection = key;
        _studentsDropdownOpen = false;
      }
    });
  }

  Widget _buildSidebar() {
    const sidebarBg = Color(0xFF1465BB); // nuevo color
    const activeBg = Color(0xFF0D4A8A); // tono más oscuro
    final inactive = Colors.grey[300];

    Widget item(IconData icon, String label, String key, {bool hasDropdown = false}) {
      final active = _activeSection == key;
      return Column(
        children: [
          ListTile(
            leading: Icon(icon, size: 20, color: active ? Colors.white : inactive),
            title: Text(label, style: TextStyle(color: active ? Colors.white : inactive)),
            tileColor: active ? activeBg : sidebarBg,
            onTap: () => _onSidebarItemTap(key, hasDropdown: hasDropdown),
            trailing: hasDropdown
                ? Icon(_studentsDropdownOpen ? Icons.expand_less : Icons.expand_more, color: inactive)
                : null,
          ),
          if (key == 'students' && _studentsDropdownOpen)
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
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
          const Text('ALI', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                item(Icons.bar_chart, 'Panel Principal', 'dashboard'),
                item(Icons.person, 'Profesores', 'teachers'),
                item(Icons.school, 'Estudiantes', 'students', hasDropdown: true),
                item(Icons.analytics, 'Analíticas', 'analytics'),
              ],
            ),
          ),
          const Divider(color: Colors.white54),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pushReplacementNamed(context, '/'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ---------------- Header ----------------
  Widget _buildHeader() {
    final sectionTitle = {
      'dashboard': 'Panel Principal',
      'students': 'Estudiantes',
      'teachers': 'Profesores',
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
          Expanded(child: Text(sectionTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
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

  // ---------------- Métricas ----------------
  List<Map<String, String>> _getDashboardMetrics(String grade) {
    final students = _studentsForGrade(grade);
    final total = students.length;
    final completed = students.where((s) => s['progreso'] == 'Finalizado').length;
    final pending = total - completed;
    final completionPct = total > 0 ? ((completed / total) * 100).round() : 0;

    return [
      {'title': 'Total Estudiantes', 'value': '$total', 'subtitle': 'en este grado', 'trend': '+5%'},
      {'title': 'Tests Completados', 'value': '$completed', 'subtitle': 'estudiantes', 'trend': '$completionPct%'},
      {'title': 'Tests Pendientes', 'value': '$pending', 'subtitle': 'estudiantes', 'trend': '-2%'},
      {'title': 'Tasa de Finalización', 'value': '$completionPct%', 'subtitle': 'del total', 'trend': '+8%'},
    ];
  }

  // Ejemplo de datos de técnicos
  final List<Map<String, dynamic>> _technicalChoices = const [
    {'name': 'Industrial', 'count': 28},
    {'name': 'Comercio', 'count': 22},
    {'name': 'Promoción Social', 'count': 18},
    {'name': 'Agropecuaria', 'count': 12},
  ];

  // ---------------- Dashboard ----------------
  Widget _renderDashboard() {
    final grade = _selectedDashboardGrade;
    final metrics = _getDashboardMetrics(grade);
    final maxCount = _technicalChoices.map((c) => c['count'] as int).reduce((a, b) => a > b ? a : b);

    // Fechas dinámicas
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final dateRangeText =
        '${DateFormat("d MMM yyyy", 'es').format(startOfMonth)} - ${DateFormat("d MMM yyyy", 'es').format(endOfMonth)}';
    final monthYearTitle = DateFormat('MMMM yyyy', 'es').format(now);

    // 5 días centrados en hoy
    final List<int> calendarDays = List.generate(5, (i) {
      final d = now.day - 2 + i;
      if (d < 1) return 1 + endOfMonth.day + d - 1;
      if (d > endOfMonth.day) return d - endOfMonth.day;
      return d;
    });

    // progreso linea
    final trendRaw = metrics[1]['trend'] ?? '0%';
    final digits = trendRaw.replaceAll(RegExp(r'[^0-9]'), '');
    final progress = (double.tryParse(digits) ?? 0) / 100;

    final studentsList = _studentsForGrade(grade);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ---------- Selector de grado + fecha ----------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  for (var g in ['9', '10/11'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedDashboardGrade == g ? const Color(0xFF0D4A8A) : Colors.transparent,
                          foregroundColor: _selectedDashboardGrade == g ? Colors.white : Colors.grey[700],
                          side: BorderSide(color: Colors.grey.shade300),
                          elevation: 0,
                        ),
                        onPressed: () => setState(() => _selectedDashboardGrade = g),
                        child: Text(g == '9' ? 'Grado 9°' : 'Bachillerato'),
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(dateRangeText, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ---------- Métricas ----------
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

          // ---------- Gráficos + columna derecha ----------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------- Tecnicos / Carreras -----------
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
                            Text(
                              grade == '9' ? 'Técnicos Elegidos' : 'Carreras Elegidas',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () {}),
                          ],
                        ),
                        const SizedBox(height: 12),
                        for (var choice in _technicalChoices)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(width: 100, child: Text(choice['name'], style: const TextStyle(fontSize: 14))),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: (choice['count'] as int) / maxCount,
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text('${choice['count']}'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // ----------- Columna derecha -----------
              Expanded(
                child: Column(
                  children: [
                    // --- Calendario ---
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(monthYearTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: calendarDays.map((d) {
                                final isToday = d == now.day;
                                return ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isToday ? const Color(0xFF0D4A8A) : const Color(0xFFF9FAFB),
                                    foregroundColor: isToday ? Colors.white : Colors.grey[700],
                                    elevation: 0,
                                    minimumSize: const Size(32, 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () {},
                                  child: Text('$d'),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Barra de progreso ---
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
                            LinearProgressIndicator(value: progress, minHeight: 8),
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

          // ---------- Tabla de estudiantes ----------
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
                          IconButton(icon: const Icon(Icons.refresh), onPressed: () async => _loadUsuarios()),
                          IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UsuariosScreen(titulo: 'Estudiantes', usuarios: studentsList),
                              ),
                            ),
                          ),
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
                      rows: studentsList.map((student) {
                        final prog = student['progreso'] ?? 'N/A';
                        final lastRec = student['ultimaRecomendacion'] ?? 'N/N';
                        return DataRow(
                          onSelectChanged: (_) => _openStats(student),
                          cells: [
                            DataCell(Text(student['nombre'] ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis)),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: prog == 'Finalizado' ? Colors.green[100] : Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(prog,
                                  style: TextStyle(
                                      color: prog == 'Finalizado' ? Colors.green : Colors.orange)),
                            )),
                            DataCell(Text(lastRec)),
                            DataCell(Text(prog)),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _editUser(student),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () => _deleteUser(student['id']),
                                  ),
                                ],
                              ),
                            ),
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

  // ---------------- Estudiantes ----------------
  Widget _renderStudents() {
    final gradeKey = _selectedStudentsGrade == '9' ? '9' : '10';
    final students = gradeKey == '9' ? estudiantesPorGrado['9']! : estudiantesPorGrado['10']! + estudiantesPorGrado['11']!;
    final filtered = students.where((s) {
      final name = (s['nombre'] ?? '').toString().toLowerCase();
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
              const Text('Estudiantes Inscritos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  for (var g in ['9', '10/11'])
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedStudentsGrade == (g == '9' ? '9' : '10')
                              ? const Color(0xFF0D4A8A)
                              : Colors.transparent,
                          foregroundColor:
                              _selectedStudentsGrade == (g == '9' ? '9' : '10') ? Colors.white : Colors.grey[700],
                          elevation: 0,
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        onPressed: () => setState(() => _selectedStudentsGrade = g == '9' ? '9' : '10'),
                        child: Text(g == '9' ? 'Grado 9°' : 'Grado 10/11'),
                      ),
                    )
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
                rows: filtered.map((student) {
                  final prog = student['progreso'] ?? 'N/A';
                  final lastRec = student['ultimaRecomendacion'] ?? 'N/N';
                  return DataRow(
                    onSelectChanged: (_) => _openStats(student),
                    cells: [
                      DataCell(Text(student['nombre'] ?? '—')),
                      DataCell(Text(student['email'] ?? '—')),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: prog == 'Finalizado' ? Colors.green[100] : Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(prog,
                            style: TextStyle(color: prog == 'Finalizado' ? Colors.green : Colors.orange)),
                      )),
                      DataCell(Text(lastRec)),
                      DataCell(Text(prog)),
                      DataCell(
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editUser(student)),
                            IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: () => _deleteUser(student['id'])),
                          ],
                        ),
                      ),
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

  // ---------------- Profesores ----------------
  Widget _renderTeachers() {
    final filtered = administradores.where((t) {
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
              const Text('Profesores Registrados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(icon: const Icon(Icons.person_add), label: const Text('Agregar Profesor'), onPressed: () {}),
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
                rows: filtered.map((t) {
                  return DataRow(cells: [
                    DataCell(Text(t['nombre']?.toString().isNotEmpty == true ? t['nombre'] : t['username'] ?? '—')),
                    DataCell(Text(t['email'] ?? '—')),
                    DataCell(Row(
                      children: [
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _editUser(t)),
                        IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteUser(t['id'])),
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

  // ---------------- build ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RawKeyboardListener(
              autofocus: true,
              focusNode: FocusNode(),
              onKey: (event) {
                if (event is RawKeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    _scrollController.animateTo(
                      _scrollController.offset + 100,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOut,
                    );
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
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
                          child: Builder(
                            builder: (_) {
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
                            },
                          ),
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
