import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class RespaldosScreen extends StatefulWidget {
  const RespaldosScreen({super.key});

  @override
  State<RespaldosScreen> createState() => _RespaldosScreenState();
}

class _RespaldosScreenState extends State<RespaldosScreen> {
  int _selectedYear = DateTime.now().year < 2026 ? 2026 : DateTime.now().year;
  int _selectedMonth = (DateTime.now().year <= 2026 && DateTime.now().month < 10) ? 10 : DateTime.now().month;

  final List<String> _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);

    // Calculate available months based on selected year (starting from October 2026)
    final startMonth = _selectedYear == 2026 ? 10 : 1;
    if (_selectedYear == 2026 && _selectedMonth < 10) {
      _selectedMonth = 10;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                  colors: [Color(0xFF0F766E), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accentTeal.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.backup_outlined, color: AppTheme.accentTeal, size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Respaldos y Reportes',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Genera y exporta tu reporte mensual de datos en formato CSV (Excel)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Reporte Mensual CSV (Excel)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.table_chart_outlined, color: AppTheme.primaryCyan),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Reporte Mensual en CSV (Excel)',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Genera un archivo CSV compatible con Microsoft Excel con el desglose de ventas, gastos, trabajos, agenda y nómina del mes.',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedMonth < startMonth ? startMonth : _selectedMonth,
                            decoration: const InputDecoration(labelText: 'Mes'),
                            items: List.generate(13 - startMonth, (index) {
                              final m = startMonth + index;
                              return DropdownMenuItem(
                                value: m,
                                child: Text(_meses[m - 1]),
                              );
                            }),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedMonth = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedYear,
                            decoration: const InputDecoration(labelText: 'Año'),
                            items: [2026, 2027, 2028, 2029, 2030].map((y) {
                              return DropdownMenuItem(value: y, child: Text('$y'));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedYear = val;
                                  if (_selectedYear == 2026 && _selectedMonth < 10) {
                                    _selectedMonth = 10;
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _exportCsv(storage),
                            icon: const Icon(Icons.file_download),
                            label: const Text('Copiar / Compartir CSV'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportCsv(StorageService storage) {
    final csvData = storage.exportMonthlyCsv(_selectedYear, _selectedMonth);
    Clipboard.setData(ClipboardData(text: csvData));
    SharePlus.instance.share(
      ShareParams(
        text: csvData,
        subject: 'Resumen Mensual $_selectedYear-$_selectedMonth.csv',
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡CSV copiado al portapapeles y listo para compartir!'),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
