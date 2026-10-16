import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/empleado.dart';
import '../models/pago_semanal.dart';
import '../services/app_engine_service.dart';
import '../theme/app_theme.dart';

class EmpleadosScreen extends StatefulWidget {
  const EmpleadosScreen({super.key});

  @override
  State<EmpleadosScreen> createState() => _EmpleadosScreenState();
}

class _EmpleadosScreenState extends State<EmpleadosScreen> {
  final String _selectedSemana = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<AppEngineService>(context);
    final allEmpleados = engine.data.empleados;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4C1D95), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.infoPurple.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal y Nómina',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.infoPurple.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.infoPurple),
                          ),
                          child: Text(
                            'Gasto Total Pagado: ${currencyFormat.format(engine.getTotalNominaGastada())}',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEmpleadoDialog(context),
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Nuevo empleado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.infoPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Lista de Empleados y Pagos (${allEmpleados.length})',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (allEmpleados.isEmpty)
              Card(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      const Icon(Icons.badge_outlined, size: 48, color: Color(0xFF64748B)),
                      const SizedBox(height: 12),
                      Text(
                        'No hay empleados registrados en el sistema.',
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
                itemCount: allEmpleados.length,
                itemBuilder: (context, index) {
                  final emp = allEmpleados[index];
                  final pago = engine.getPagoSemanal(emp.id, _selectedSemana);
                  final neto = pago.calcularNeto();

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
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppTheme.infoPurple.withValues(alpha: 0.2),
                                      child: const Icon(Icons.person, color: AppTheme.infoPurple),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            emp.nombre,
                                            style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            emp.puesto.isEmpty ? 'Técnico' : emp.puesto,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.dangerRed),
                                onPressed: () => _confirmDeleteEmpleado(context, emp.id),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Color(0xFF334155)),

                          // Payroll Breakdown Row
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _buildNominaMiniItem('Pago Base', currencyFormat.format(pago.pagoBase)),
                              _buildNominaMiniItem('Extras', currencyFormat.format(pago.extraTrabajos)),
                              _buildNominaMiniItem('Préstamo', '-${currencyFormat.format(pago.descuentoPrestamo)}', color: AppTheme.dangerRed),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              Text(
                                'Neto a Pagar: ${currencyFormat.format(neto)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successGreen,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showEditPagoDialog(context, emp, pago),
                                icon: const Icon(Icons.payments, size: 16),
                                label: const Text('Gestionar Pago'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.infoPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
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

  Widget _buildNominaMiniItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color ?? Colors.white)),
      ],
    );
  }

  void _showAddEmpleadoDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final puestoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nuevo Empleado', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre Completo *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: puestoCtrl,
              decoration: const InputDecoration(labelText: 'Puesto / Rol (ej. Instalador)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.infoPurple),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final emp = Empleado(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                nombre: nameCtrl.text.trim(),
                puesto: puestoCtrl.text.trim(),
                equipoId: 'equipo1',
              );
              Provider.of<AppEngineService>(context, listen: false).addEmpleado(emp);
              Navigator.pop(ctx);
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditPagoDialog(BuildContext context, Empleado emp, PagoSemanal currentPago) {
    final engine = Provider.of<AppEngineService>(context, listen: false);

    final baseCtrl = TextEditingController(text: currentPago.pagoBase.toString());
    final extraCtrl = TextEditingController(text: currentPago.extraTrabajos.toString());
    final prestamoCtrl = TextEditingController(text: currentPago.descuentoPrestamo.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double base = double.tryParse(baseCtrl.text) ?? 0.0;
            double extra = double.tryParse(extraCtrl.text) ?? 0.0;
            double prestamo = double.tryParse(prestamoCtrl.text) ?? 0.0;
            double neto = base + extra - prestamo;

            return AlertDialog(
              title: Text('Pago Semanal - ${emp.nombre}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Semana: $_selectedSemana', style: const TextStyle(color: AppTheme.infoPurple, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: baseCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Pago Base (\$)'),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: extraCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Extra Trabajos (\$)'),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: prestamoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Descuento Préstamo (\$)'),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Neto Calculado:'),
                          Text(
                            currencyFormat.format(neto),
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.successGreen, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.infoPurple),
                  onPressed: () {
                    final p = PagoSemanal(
                      id: currentPago.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : currentPago.id,
                      empleadoId: emp.id,
                      semana: _selectedSemana,
                      pagoBase: double.tryParse(baseCtrl.text) ?? 0.0,
                      extraTrabajos: double.tryParse(extraCtrl.text) ?? 0.0,
                      motivoExtra: '',
                      ayudaEspecial: 0.0,
                      motivoAyuda: '',
                      descuentoPrestamo: double.tryParse(prestamoCtrl.text) ?? 0.0,
                      motivoPrestamo: '',
                    );
                    engine.savePagoSemanal(p);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Guardar Pago', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteEmpleado(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Empleado?'),
        content: const Text('Esta acción eliminará al empleado de la lista.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () {
              Provider.of<AppEngineService>(context, listen: false).deleteEmpleado(id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
