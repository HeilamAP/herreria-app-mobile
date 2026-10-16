import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/trabajo.dart';
import '../services/app_engine_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class TrabajosScreen extends StatefulWidget {
  const TrabajosScreen({super.key});

  @override
  State<TrabajosScreen> createState() => _TrabajosScreenState();
}

class _TrabajosScreenState extends State<TrabajosScreen> {
  String _searchQuery = '';
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<AppEngineService>(context);
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;

    final userTeam = user?.isAdmin == true ? 'todos' : (user?.equipoId ?? 'equipo1');
    final teamTrabajos = engine.getTrabajosFiltered(userTeam);

    final filtered = teamTrabajos.where((t) {
      final query = _searchQuery.toLowerCase();
      return t.cliente.toLowerCase().contains(query) ||
          t.descripcion.toLowerCase().contains(query);
    }).toList();

    final totalMonto = filtered.fold<double>(0, (sum, t) => sum + t.monto);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context, null),
        backgroundColor: AppTheme.accentTeal,
        foregroundColor: const Color(0xFF0F172A),
        icon: const Icon(Icons.handyman),
        label: const Text('Nuevo Trabajo', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F4C5C), Color(0xFF1E293B)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accentTeal.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trabajos de Herrería / Instalaciones',
                        style: GoogleFonts.outfit(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Filtrado: ${currencyFormat.format(totalMonto)}',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentTeal,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.door_front_door_outlined, color: AppTheme.accentTeal, size: 36),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Search Bar
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Buscar por cliente, dirección o trabajo...',
                prefixIcon: Icon(Icons.search, color: AppTheme.accentTeal),
              ),
            ),
            const SizedBox(height: 16),

            // Trabajos List
            if (filtered.isEmpty)
              Card(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      const Icon(Icons.engineering_outlined, size: 48, color: Color(0xFF64748B)),
                      const SizedBox(height: 12),
                      Text(
                        'No hay trabajos registrados para este equipo.',
                        style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final t = filtered[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  t.cliente,
                                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                currencyFormat.format(t.monto),
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentTeal,
                                ),
                              ),
                            ],
                          ),
                          if (t.descripcion.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(t.descripcion, style: const TextStyle(color: Colors.white70)),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Fecha: ${t.fecha} • (${t.equipoId.toUpperCase()})', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18, color: AppTheme.primaryCyan),
                                    onPressed: () => _showAddEditDialog(context, t),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerRed),
                                    onPressed: () => _confirmDelete(context, t.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, Trabajo? existing) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final engine = Provider.of<AppEngineService>(context, listen: false);
    final currentUser = auth.currentUser;

    final isEdit = existing != null;
    final clienteCtrl = TextEditingController(text: existing?.cliente ?? '');
    final descCtrl = TextEditingController(text: existing?.descripcion ?? '');
    final fechaCtrl = TextEditingController(text: existing?.fecha ?? '');
    final montoCtrl = TextEditingController(text: existing != null ? existing.monto.toString() : '');
    String selectedEquipo = existing?.equipoId ?? (currentUser?.equipoId == 'todos' ? 'equipo1' : (currentUser?.equipoId ?? 'equipo1'));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Editar Trabajo' : 'Nuevo Trabajo', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: clienteCtrl,
                      decoration: const InputDecoration(labelText: 'Cliente *'),
                    ),
                    if (currentUser?.isAdmin == true) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedEquipo,
                        decoration: const InputDecoration(labelText: 'Asignar a Equipo'),
                        items: const [
                          DropdownMenuItem(value: 'equipo1', child: Text('Equipo 1 (Jose Ay)')),
                          DropdownMenuItem(value: 'equipo2', child: Text('Equipo 2 (Nefy Dzul)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedEquipo = val);
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: fechaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Fecha (Opcional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Descripción del Trabajo'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: montoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Monto del Trabajo (\$) *'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentTeal, foregroundColor: const Color(0xFF0F172A)),
                  onPressed: () {
                    if (clienteCtrl.text.trim().isEmpty || montoCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor completa los campos obligatorios.')),
                      );
                      return;
                    }

                    final fechaFinal = fechaCtrl.text.trim().isEmpty
                        ? DateFormat('yyyy-MM-dd').format(DateTime.now())
                        : fechaCtrl.text.trim();

                    final t = Trabajo(
                      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      fecha: fechaFinal,
                      cliente: clienteCtrl.text.trim(),
                      direccion: '',
                      descripcion: descCtrl.text.trim(),
                      empleadoIds: existing?.empleadoIds ?? const [],
                      monto: double.tryParse(montoCtrl.text) ?? 0.0,
                      equipoId: selectedEquipo,
                    );

                    engine.saveTrabajo(t);
                    Navigator.pop(ctx);
                  },
                  child: Text(isEdit ? 'Guardar Cambios' : 'Crear Trabajo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Trabajo?'),
        content: const Text('Esta acción eliminará el trabajo permanentemente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () {
              Provider.of<AppEngineService>(context, listen: false).deleteTrabajo(id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
