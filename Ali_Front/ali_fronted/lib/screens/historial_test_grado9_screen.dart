import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'detalle_resultado_test9_screen.dart';

class HistorialTestGrado9Screen extends StatefulWidget {
  const HistorialTestGrado9Screen({super.key});

  @override
  State<HistorialTestGrado9Screen> createState() => _HistorialTestGrado9ScreenState();
}

class _HistorialTestGrado9ScreenState extends State<HistorialTestGrado9Screen> {
  final ApiService api = ApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  String _filtro = 'Todos';

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await api.listarMisTestsGrado9();
      setState(() => _items = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String _extraerTecnico(String? resultado) {
    if (resultado == null) return '—';
    // Formato backend: "Técnico sugerido por ALI: X\n\nExplicación: ..."
    final idx = resultado.indexOf(':');
    if (idx != -1) {
      final linea = resultado.split('\n').first;
      final partes = linea.split(':');
      if (partes.length >= 2) return partes[1].trim();
    }
    return '—';
  }

  DateTime? _parseFecha(String? iso) {
    if (iso == null) return null;
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }

  List<String> get _tecnicosDisponibles {
    final set = <String>{};
    for (final it in _items) {
      set.add(_extraerTecnico(it['resultado'] as String?));
    }
    final list = set.where((e) => e != '—').toList()..sort();
    return ['Todos', ...list];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial (Grado 9)'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 32),
                      Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: FilledButton.icon(
                          onPressed: _cargar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      )
                    ],
                  )
                : _buildList(context),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final filtrados = _filtro == 'Todos'
        ? _items
        : _items.where((e) => _extraerTecnico(e['resultado'] as String?) == _filtro).toList();

    return Column(
      children: [
        // Filtro por técnico sugerido (chips)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: _tecnicosDisponibles.map((tec) {
              final selected = _filtro == tec;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(tec),
                  selected: selected,
                  onSelected: (_) => setState(() => _filtro = tec),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 0),
        Expanded(
          child: filtrados.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('Aún no hay intentos guardados.'),
                  ),
                )
              : ListView.separated(
                  itemCount: filtrados.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (ctx, i) {
                    final it = filtrados[i];
                    final id = it['id'] as int?;
                    final resultado = it['resultado'] as String?;
                    final tecnico = _extraerTecnico(resultado);
                    final fechaIso = it['fecha_realizacion'] as String?;
                    final fecha = _parseFecha(fechaIso);
                    final hace = fecha != null
                        ? timeago.format(fecha, locale: 'es')
                        : (fechaIso ?? '—');

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text((i + 1).toString()),
                      ),
                      title: Text(
                        'Técnico: $tecnico',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('Intento #$id • $hace'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (op) async {
                          if (op == 'ver' && id != null) {
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetalleResultadoTest9Screen(testId: id),
                              ),
                            );
                          } else if (op == 'copiar') {
                            await Clipboard.setData(ClipboardData(text: resultado ?? ''));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Resultado copiado')),
                            );
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'ver', child: Text('Ver detalle')),
                          const PopupMenuItem(value: 'copiar', child: Text('Copiar resultado')),
                        ],
                      ),
                      onTap: id == null
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetalleResultadoTest9Screen(testId: id),
                                ),
                              ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
