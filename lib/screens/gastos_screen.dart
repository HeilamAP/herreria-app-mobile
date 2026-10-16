import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/gasto.dart';
import '../services/app_engine_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<AppEngineService>(context);
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;

    final userTeam = user?.isAdmin == true ? 'todos' : (user?.equipoId ?? 'equipo1');
    final filtered = engine.getGastosFiltered(userTeam);

    final totalGastos = filtered.fold<double>(0, (sum, g) => sum + g.monto);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context, null),
        backgroundColor: AppTheme.dangerRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva compra', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  colors: [Color(0xFF7F1D1D), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registro de Gastos',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              user?.isAdmin == true ? 'Visualizando Todos los equipos' : 'Equipo: ${user?.nombre}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFFFCA5A5)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.receipt_sharp, color: AppTheme.dangerRed, size: 28),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Monto total de Gastos:', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                            Text(
                              currencyFormat.format(totalGastos),
                              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Gastos Registrados:', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                            Text(
                              '${filtered.length}',
                              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.dangerRed),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Gastos List
            if (filtered.isEmpty)
              Card(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Text(
                        'No se encontraron Gastos Registrados',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8)),
                        textAlign: TextAlign.center,
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
                  final g = filtered[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.dangerRed.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.receipt_long,
                          color: AppTheme.dangerRed,
                        ),
                      ),
                      title: Text(
                        g.descripcion,
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Fecha: ${g.fecha} • (${g.equipoId.toUpperCase()})',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(g.monto),
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.dangerRed,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: AppTheme.primaryCyan),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _showAddEditDialog(context, g),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerRed),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _confirmDelete(context, g.id),
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

  void _showAddEditDialog(BuildContext context, Gasto? existing) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final currentUser = auth.currentUser;

    final isEdit = existing != null;
    final descCtrl = TextEditingController(text: existing?.descripcion ?? '');
    final fechaCtrl = TextEditingController(
      text: existing?.fecha ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final montoCtrl = TextEditingController(text: existing != null ? existing.monto.toString() : '');
    String selectedEquipo = existing?.equipoId ?? (currentUser?.equipoId == 'todos' ? 'equipo1' : (currentUser?.equipoId ?? 'equipo1'));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> selectDate() async {
              DateTime initial = DateTime.tryParse(fechaCtrl.text.trim()) ?? DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
                helpText: 'SELECCIONAR FECHA DEL GASTO',
                cancelText: 'CANCELAR',
                confirmText: 'ACEPTAR',
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppTheme.dangerRed,
                        onPrimary: Colors.white,
                        surface: Color(0xFF1E293B),
                        onSurface: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setDialogState(() {
                  fechaCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                });
              }
            }

            return AlertDialog(
              title: Text(isEdit ? 'Editar Gasto' : 'Nuevo Gasto', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Descripción del Gasto *'),
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
                      readOnly: true,
                      onTap: selectDate,
                      decoration: InputDecoration(
                        labelText: 'Fecha del Gasto * (Requerida)',
                        hintText: 'Toca para abrir calendario',
                        prefixIcon: const Icon(Icons.calendar_month, color: AppTheme.dangerRed),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.edit_calendar, color: AppTheme.dangerRed),
                          onPressed: selectDate,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: montoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Monto (\$) *'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
                  onPressed: () {
                    if (descCtrl.text.trim().isEmpty || montoCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor completa los campos obligatorios.')),
                      );
                      return;
                    }

                    if (fechaCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('La fecha es obligatoria para registrar el gasto.'),
                          backgroundColor: AppTheme.dangerRed,
                        ),
                      );
                      return;
                    }

                    final g = Gasto(
                      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      fecha: fechaCtrl.text.trim(),
                      descripcion: descCtrl.text.trim(),
                      categoria: '',
                      monto: double.tryParse(montoCtrl.text) ?? 0.0,
                      equipoId: selectedEquipo,
                    );

                    Provider.of<AppEngineService>(context, listen: false).saveGasto(g);
                    Navigator.pop(ctx);
                  },
                  child: Text(isEdit ? 'Guardar Cambios' : 'Crear Gasto', style: const TextStyle(color: Colors.white)),
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
        title: const Text('¿Eliminar Gasto?'),
        content: const Text('Esta acción eliminará el gasto permanentemente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () {
              Provider.of<AppEngineService>(context, listen: false).deleteGasto(id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
