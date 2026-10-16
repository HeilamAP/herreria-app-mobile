import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_engine_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  String _adminTeamFilter = 'todos'; // todos | equipo1 | equipo2

  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<AppEngineService>(context);
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;

    final effectiveTeamId = user?.isAdmin == true ? _adminTeamFilter : (user?.equipoId ?? 'equipo1');

    final totalVentasMonto = engine.getTotalVentasMonto(equipoId: effectiveTeamId);
    final totalVentasCant = engine.getTotalVentasCantidad(equipoId: effectiveTeamId);
    final totalTrabajosMonto = engine.getTotalTrabajosRealizadosMonto(equipoId: effectiveTeamId);
    final totalTrabajosCant = engine.getTrabajosRealizadosCantidad(equipoId: effectiveTeamId);
    final totalGastos = engine.getTotalGastos(equipoId: effectiveTeamId);
    final gananciaNeta = engine.getGananciaNeta(equipoId: effectiveTeamId);
    final visitasPendientes = engine.getVisitasPendientes(equipoId: effectiveTeamId);

    final cantEfectivo = engine.getTrabajosPagadosEfectivoCantidad(equipoId: effectiveTeamId);
    final montoEfectivo = engine.getTrabajosPagadosEfectivoMonto(equipoId: effectiveTeamId);
    final cantTransferencia = engine.getTrabajosPagadosTransferenciaCantidad(equipoId: effectiveTeamId);
    final montoTransferencia = engine.getTrabajosPagadosTransferenciaMonto(equipoId: effectiveTeamId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Welcome Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.2),
                      child: const Icon(Icons.shield_outlined, color: AppTheme.primaryCyan, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Hola, ${user?.nombre ?? "Usuario"}!',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.isAdmin == true
                                ? 'Administrador General - Ay Oy Herrería en General'
                                : 'Acceso exclusivo: ${user?.nombre ?? "Equipo"}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Admin Team Filter selector and Payroll Summary
                if (user?.isAdmin == true) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF334155)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildAdminTeamChip('Todos los Equipos', 'todos'),
                              const SizedBox(width: 8),
                              _buildAdminTeamChip('Equipo 1', 'equipo1'),
                              const SizedBox(width: 8),
                              _buildAdminTeamChip('Equipo 2', 'equipo2'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4C1D95).withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.infoPurple),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.badge_outlined, color: AppTheme.infoPurple, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Gasto Total en Pago a Trabajadores:',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currencyFormat.format(engine.getTotalNominaGastada(equipoId: effectiveTeamId)),
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.infoPurple),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4 Main KPI Cards: Total Ventas, Citas y Agenda, Total Gastos, Saldo Ganancias
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isWide ? 1.5 : 1.15,
                children: [
                  _buildKpiCard(
                    title: 'Total de Ventas',
                    value: currencyFormat.format(totalVentasMonto),
                    subtitle: '$totalVentasCant ventas registradas',
                    icon: Icons.point_of_sale,
                    color: AppTheme.primaryCyan,
                    bgGradient: [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                  ),
                  _buildKpiCard(
                    title: 'Trabajos realizados',
                    value: currencyFormat.format(totalTrabajosMonto),
                    subtitle: '$totalTrabajosCant completados • $visitasPendientes pendientes',
                    icon: Icons.task_alt,
                    color: AppTheme.warningAmber,
                    bgGradient: [const Color(0xFF78350F), const Color(0xFF451A03)],
                  ),
                  _buildKpiCard(
                    title: 'Total de Gastos',
                    value: currencyFormat.format(totalGastos),
                    subtitle: 'Egresos e insumos del equipo',
                    icon: Icons.trending_down,
                    color: AppTheme.dangerRed,
                    bgGradient: [const Color(0xFFB91C1C), const Color(0xFF7F1D1D)],
                  ),
                  _buildKpiCard(
                    title: 'Saldo de Ganancias',
                    value: currencyFormat.format(gananciaNeta),
                    subtitle: 'Ganancia neta disponible',
                    icon: Icons.account_balance_wallet,
                    color: AppTheme.successGreen,
                    bgGradient: [const Color(0xFF047857), const Color(0xFF064E3B)],
                  ),
                ],
              );
            },
          ),

          // Resumen de Métodos de Pago: Efectivo vs Transferencia
          const SizedBox(height: 24),
          _buildPaymentSummarySection(
            cantEfectivo: cantEfectivo,
            montoEfectivo: montoEfectivo,
            cantTransferencia: cantTransferencia,
            montoTransferencia: montoTransferencia,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPaymentSummarySection({
    required int cantEfectivo,
    required double montoEfectivo,
    required int cantTransferencia,
    required double montoTransferencia,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.payments_rounded, color: AppTheme.primaryCyan, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cobros de Trabajos Realizados',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Resumen de cobro en Efectivo vs Transferencia',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Tarjeta Efectivo
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF064E3B), Color(0xFF0F172A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.12),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'EFECTIVO',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF34D399),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Icon(Icons.attach_money_rounded, color: Color(0xFF34D399), size: 18),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$cantEfectivo ${cantEfectivo == 1 ? "trabajo" : "trabajos"}',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        currencyFormat.format(montoEfectivo),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF34D399),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cobrado en mano',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Tarjeta Transferencia
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0C4A6E), Color(0xFF0F172A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'TRANSFERENCIA',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF38BDF8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Icon(Icons.account_balance_rounded, color: Color(0xFF38BDF8), size: 18),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$cantTransferencia ${cantTransferencia == 1 ? "trabajo" : "trabajos"}',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        currencyFormat.format(montoTransferencia),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF38BDF8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'En cuenta bancaria',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminTeamChip(String label, String value) {
    final isSelected = _adminTeamFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _adminTeamFilter = value;
          });
        }
      },
      selectedColor: AppTheme.accentTeal,
      backgroundColor: const Color(0xFF0F172A),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0F172A) : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 11,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.accentTeal : const Color(0xFF334155),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required List<Color> bgGradient,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bgGradient,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
