import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/visita_agenda.dart';
import '../services/app_engine_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

bool _isFutureDate(String dateStr) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final parsed = DateTime.tryParse(dateStr.trim());
  if (parsed == null) return false;
  final checkDate = DateTime(parsed.year, parsed.month, parsed.day);
  return checkDate.isAfter(today);
}

Widget _buildPaymentMethodChip({
  required String label,
  required IconData icon,
  required bool isSelected,
  required Color selectedColor,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected ? selectedColor.withValues(alpha: 0.16) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? selectedColor : const Color(0xFF334155),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 15,
            color: isSelected ? selectedColor : const Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? selectedColor : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    ),
  );
}

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _selectedDate = DateTime.now();

  int _parseTimeToMinutes(String timeStr) {
    final s = timeStr.trim().toUpperCase();
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(s);
    if (match != null) {
      int h = int.tryParse(match.group(1)!) ?? 0;
      int m = int.tryParse(match.group(2)!) ?? 0;
      if (s.contains('P.M.') || s.contains('PM')) {
        if (h < 12) h += 12;
      } else if (s.contains('A.M.') || s.contains('AM')) {
        if (h == 12) h = 0;
      }
      return h * 60 + m;
    }
    final matchHourOnly = RegExp(r'^(\d{1,2})').firstMatch(s);
    if (matchHourOnly != null) {
      int h = int.tryParse(matchHourOnly.group(1)!) ?? 0;
      if (s.contains('P.M.') || s.contains('PM')) {
        if (h < 12) h += 12;
      } else if (s.contains('A.M.') || s.contains('AM')) {
        if (h == 12) h = 0;
      }
      return h * 60;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<AppEngineService>(context);
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;

    final userTeam = user?.isAdmin == true ? 'todos' : (user?.equipoId ?? 'equipo1');
    final filteredList = engine.getAgendaFiltered(userTeam);

    final String selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Group filtered appointments by date for lookup in calendar
    final Map<String, List<VisitaAgenda>> appointmentsByDate = {};
    for (var item in filteredList) {
      if (item.fecha.isNotEmpty) {
        appointmentsByDate.putIfAbsent(item.fecha, () => []).add(item);
      }
    }

    final selectedDayAppointments = appointmentsByDate[selectedDateStr] ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CLEAN DISCREET TOP DATE SELECTOR CARD
            _buildDateSelectorCard(),

            // SELECTED DAY WORK HOURS TIMELINE SCHEDULE
            _buildSelectedDayTimelineView(selectedDateStr, selectedDayAppointments, engine),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelectorCard() {
    final monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final dayNames = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
    ];

    final dayName = dayNames[_selectedDate.weekday - 1];
    final monthName = monthNames[_selectedDate.month - 1];
    final formattedDate = '$dayName, ${_selectedDate.day} de $monthName de ${_selectedDate.year}';

    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Tag badge on left, interactive "Calendario" button on right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.warningAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.warningAmber.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: AppTheme.warningAmber,
                            size: 13,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'DÍA SELECCIONADO',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.warningAmber,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'HOY',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successGreen,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Sleek Calendar Picker Trigger Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _selectDateFromPicker(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.warningAmber.withValues(alpha: 0.65),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_calendar_rounded, size: 14, color: AppTheme.warningAmber),
                          const SizedBox(width: 6),
                          Text(
                            'Calendario',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.warningAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Middle: Prominent Full-Width Date (Tapping also opens calendar picker, never squeezed)
            InkWell(
              onTap: () => _selectDateFromPicker(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  formattedDate,
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(color: Color(0xFF334155), height: 1),
            const SizedBox(height: 8),

            // Bottom quick navigation bar inside the card (rock-solid 3-column layout)
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                        });
                      },
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                      label: Text(
                        'Día Anterior',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: isToday
                      ? null
                      : () {
                          setState(() {
                            _selectedDate = DateTime.now();
                          });
                        },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isToday ? Colors.transparent : AppTheme.warningAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? null
                          : Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      isToday ? '• Hoy •' : 'Ir a Hoy',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isToday ? const Color(0xFF64748B) : AppTheme.warningAmber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.add(const Duration(days: 1));
                        });
                      },
                      icon: Text(
                        'Día Siguiente',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      ),
                      label: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateFromPicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      locale: const Locale('es', 'ES'),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.warningAmber,
              onPrimary: Color(0xFF0F172A),
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildSelectedDayTimelineView(String dateStr, List<VisitaAgenda> dayVisits, AppEngineService engine) {
    final isToday = dateStr == DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Generate anchor hourly slots for clean structure (8 AM to 6 PM)
    final hourlyAnchorSlots = [
      '8:00 A.M.', '9:00 A.M.', '10:00 A.M.', '11:00 A.M.',
      '12:00 P.M.', '1:00 P.M.', '2:00 P.M.', '3:00 P.M.',
      '4:00 P.M.', '5:00 P.M.', '6:00 P.M.'
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clean Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday ? 'CITAS DE HOY' : 'CITAS DEL DÍA',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dayVisits.length} Programada${dayVisits.length == 1 ? '' : 's'}',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(
                    context,
                    null,
                    defaultDate: dateStr,
                    defaultHora: '09:00 A.M.',
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nueva Cita', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningAmber,
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Color(0xFF334155), height: 1),
            const SizedBox(height: 14),

            // Timeline Slots: Hourly Anchors with Compact Clean View
            ...hourlyAnchorSlots.map((anchorSlot) {
              final anchorMins = _parseTimeToMinutes(anchorSlot);
              final anchorEndMins = anchorMins + 60;

              // Find all visits falling within this 1-hour block
              final visitsInHour = dayVisits.where((v) {
                final vMins = _parseTimeToMinutes(v.hora);
                if (vMins == -1) return anchorSlot == hourlyAnchorSlots.first;
                return vMins >= anchorMins && vMins < anchorEndMins;
              }).toList();

              // Sort visits chronologically by exact minute
              visitsInHour.sort((a, b) => _parseTimeToMinutes(a.hora).compareTo(_parseTimeToMinutes(b.hora)));

              final hasVisits = visitsInHour.isNotEmpty;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hour Badge
                    Container(
                      width: 70,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      decoration: BoxDecoration(
                        color: hasVisits ? AppTheme.warningAmber : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hasVisits ? AppTheme.warningAmber : const Color(0xFF334155),
                        ),
                      ),
                      child: Text(
                        anchorSlot,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: hasVisits ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Content: Appointment Cards or Minimal 1-line "Horario Libre"
                    Expanded(
                      child: hasVisits
                          ? Column(
                              children: visitsInHour.map((v) => _buildAppointmentCard(v, engine)).toList(),
                            )
                          : InkWell(
                              onTap: () => _showAddEditDialog(
                                context,
                                null,
                                defaultDate: dateStr,
                                defaultHora: anchorSlot,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.6)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Horario Libre',
                                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                    ),
                                    const Row(
                                      children: [
                                        Icon(Icons.add_circle_outline, size: 14, color: AppTheme.warningAmber),
                                        SizedBox(width: 4),
                                        Text(
                                          'Agendar',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.warningAmber,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(VisitaAgenda a, AppEngineService engine) {
    return _ExpandableAppointmentTile(
      visita: a,
      engine: engine,
      onEdit: () => _showAddEditDialog(context, a),
      onDelete: () => _confirmDelete(context, a.id),
      getStatusColor: _getStatusColor,
    );
  }

  Color _getStatusColor(String state) {
    switch (state.toLowerCase()) {
      case 'completado':
        return AppTheme.successGreen;
      case 'cancelado':
        return AppTheme.dangerRed;
      default:
        return AppTheme.warningAmber;
    }
  }

  void _showAddEditDialog(BuildContext context, VisitaAgenda? existing, {String? defaultDate, String? defaultHora}) {
    final engine = Provider.of<AppEngineService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    final currentUser = auth.currentUser;

    final isEdit = existing != null;

    final clienteCtrl = TextEditingController(text: existing?.cliente ?? '');
    final tipoCtrl = TextEditingController(text: existing?.tipo ?? '');
    final fechaCtrl = TextEditingController(
        text: existing?.fecha ?? (defaultDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now())));
    final horaCtrl = TextEditingController(text: existing?.hora ?? (defaultHora ?? '09:00 AM'));
    final telCtrl = TextEditingController(text: existing?.telefono ?? '');
    final montoCtrl = TextEditingController(
        text: existing != null && existing.monto > 0 ? existing.monto.toString() : '');
    String estado = existing?.estado ?? 'pendiente';
    String metodoPago = existing?.metodoPago ?? 'efectivo';
    String selectedEquipo = existing?.equipoId ?? (currentUser?.equipoId == 'todos' ? 'equipo1' : (currentUser?.equipoId ?? 'equipo1'));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isFuture = _isFutureDate(fechaCtrl.text);
            if (isFuture && estado == 'completado') {
              estado = 'pendiente';
            }

            return AlertDialog(
              title: Text(isEdit ? 'Editar Visita' : 'Agendar Visita', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: clienteCtrl,
                      decoration: const InputDecoration(labelText: 'Cliente *'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tipoCtrl,
                      decoration: const InputDecoration(labelText: 'Descripción de Trabajo'),
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
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: fechaCtrl,
                            readOnly: true,
                            onTap: () async {
                              DateTime initial = DateTime.tryParse(fechaCtrl.text) ?? DateTime(2026, 10, 1);
                              if (initial.isBefore(DateTime(2026, 10, 1))) initial = DateTime(2026, 10, 1);
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: initial,
                                firstDate: DateTime(2026, 10, 1),
                                lastDate: DateTime(2035),
                                locale: const Locale('es', 'ES'),
                                initialEntryMode: DatePickerEntryMode.calendarOnly,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: AppTheme.warningAmber,
                                        onPrimary: Color(0xFF0F172A),
                                        surface: Color(0xFF1E293B),
                                        onSurface: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                final formatted = DateFormat('yyyy-MM-dd').format(picked);
                                setDialogState(() {
                                  fechaCtrl.text = formatted;
                                  if (_isFutureDate(formatted) && estado == 'completado') {
                                    estado = 'pendiente';
                                  }
                                });
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Fecha',
                              suffixIcon: Icon(Icons.calendar_month, color: AppTheme.warningAmber, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: horaCtrl,
                            readOnly: true,
                            onTap: () => _selectTimeFromClock(context, horaCtrl, setDialogState),
                            decoration: const InputDecoration(
                              labelText: 'Hora',
                              suffixIcon: Icon(Icons.access_time, color: AppTheme.warningAmber, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: telCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Teléfono de contacto'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: montoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Pago o Monto Cobrado (\$) (Opcional)',
                        prefixIcon: Icon(Icons.attach_money, color: AppTheme.warningAmber, size: 20),
                        hintText: 'Ej. 1500.00',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Subtle aesthetic payment method selector
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.payments_outlined, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 6),
                            Text(
                              'Método de Pago:',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPaymentMethodChip(
                                label: 'Efectivo',
                                icon: Icons.payments_rounded,
                                isSelected: metodoPago == 'efectivo',
                                selectedColor: AppTheme.successGreen,
                                onTap: () => setDialogState(() => metodoPago = 'efectivo'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildPaymentMethodChip(
                                label: 'Transferencia',
                                icon: Icons.account_balance_rounded,
                                isSelected: metodoPago == 'transferencia',
                                selectedColor: AppTheme.primaryCyan,
                                onTap: () => setDialogState(() => metodoPago = 'transferencia'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('estado_${isFuture}_$estado'),
                      initialValue: estado,
                      decoration: InputDecoration(
                        labelText: 'Estado de la Cita',
                        helperText: isFuture
                            ? '⚠️ Fechas futuras no pueden registrarse como "Completado"'
                            : null,
                        helperStyle: const TextStyle(color: AppTheme.warningAmber, fontSize: 11),
                      ),
                      items: [
                        const DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                        if (!isFuture)
                          const DropdownMenuItem(value: 'completado', child: Text('Completado')),
                        const DropdownMenuItem(value: 'cancelado', child: Text('Cancelado')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => estado = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningAmber, foregroundColor: const Color(0xFF0F172A)),
                  onPressed: () {
                    if (clienteCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor ingresa el nombre del cliente.')),
                      );
                      return;
                    }

                    if (_isFutureDate(fechaCtrl.text.trim()) && estado == 'completado') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pueden registrar trabajos completados en fechas futuras.'),
                          backgroundColor: AppTheme.dangerRed,
                        ),
                      );
                      return;
                    }

                    final v = VisitaAgenda(
                      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      cliente: clienteCtrl.text.trim(),
                      tipo: tipoCtrl.text.trim(),
                      fecha: fechaCtrl.text.trim(),
                      hora: horaCtrl.text.trim(),
                      direccion: existing?.direccion ?? '',
                      telefono: telCtrl.text.trim(),
                      notas: existing?.notas ?? '',
                      estado: estado,
                      equipoId: selectedEquipo,
                      monto: double.tryParse(montoCtrl.text.trim()) ?? (existing?.monto ?? 0.0),
                      metodoPago: metodoPago,
                    );

                    if (isEdit) {
                      int index = engine.data.agenda.indexWhere((x) => x.id == v.id);
                      if (index >= 0) engine.data.agenda[index] = v;
                      engine.storage.saveData();
                    } else {
                      engine.addVisitaAgenda(v);
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(isEdit ? 'Guardar Cambios' : 'Agendar'),
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
        title: const Text('¿Eliminar Cita?'),
        content: const Text('Esta acción eliminará la cita de la agenda.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () {
              Provider.of<AppEngineService>(context, listen: false).deleteVisitaAgenda(id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTimeFromClock(
    BuildContext context,
    TextEditingController horaCtrl,
    StateSetter setDialogState,
  ) async {
    TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
    final currentText = horaCtrl.text.trim().toUpperCase();
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(A\.?M\.?|P\.?M\.?)?').firstMatch(currentText);
    if (match != null) {
      int h = int.tryParse(match.group(1)!) ?? 9;
      int m = int.tryParse(match.group(2)!) ?? 0;
      final p = match.group(3) ?? '';
      if (p.contains('P') && h < 12) h += 12;
      if (p.contains('A') && h == 12) h = 0;
      initial = TimeOfDay(hour: h, minute: m);
    }

    final picked = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => _AestheticClockPickerDialog(initialTime: initial),
    );

    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      final formatted = DateFormat('hh:mm a').format(dt).toUpperCase();
      setDialogState(() {
        horaCtrl.text = formatted;
      });
    }
  }
}

class _AestheticClockPickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const _AestheticClockPickerDialog({required this.initialTime});

  @override
  State<_AestheticClockPickerDialog> createState() => _AestheticClockPickerDialogState();
}

class _AestheticClockPickerDialogState extends State<_AestheticClockPickerDialog> {
  late int _selectedHour12;
  late int _selectedMinute;
  late String _selectedPeriod;
  bool _isSelectingHour = true; // true = selecting Hour, false = selecting Minute

  @override
  void initState() {
    super.initState();
    int h = widget.initialTime.hour;
    _selectedPeriod = h >= 12 ? 'P.M.' : 'A.M.';
    _selectedHour12 = h % 12;
    if (_selectedHour12 == 0) _selectedHour12 = 12;
    _selectedMinute = widget.initialTime.minute;
  }

  @override
  Widget build(BuildContext context) {
    final formattedHour = _selectedHour12.toString().padLeft(2, '0');
    final formattedMinute = _selectedMinute.toString().padLeft(2, '0');

    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppTheme.warningAmber.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Title
            Text(
              'SELECCIONAR HORA',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF94A3B8),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 14),

            // Live Time Display Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hour Box
                  InkWell(
                    onTap: () => setState(() => _isSelectingHour = true),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isSelectingHour ? AppTheme.warningAmber.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isSelectingHour ? AppTheme.warningAmber : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        formattedHour,
                        style: GoogleFonts.outfit(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: _isSelectingHour ? AppTheme.warningAmber : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    ' : ',
                    style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.warningAmber),
                  ),
                  // Minute Box
                  InkWell(
                    onTap: () => setState(() => _isSelectingHour = false),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: !_isSelectingHour ? AppTheme.warningAmber.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: !_isSelectingHour ? AppTheme.warningAmber : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        formattedMinute,
                        style: GoogleFonts.outfit(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: !_isSelectingHour ? AppTheme.warningAmber : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Period AM/PM Switch
                  Column(
                    children: ['A.M.', 'P.M.'].map((p) {
                      final isSelected = _selectedPeriod == p;
                      return InkWell(
                        onTap: () => setState(() => _selectedPeriod = p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.warningAmber : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Circular Clock Face
            SizedBox(
              width: 220,
              height: 220,
              child: CustomPaint(
                painter: _ClockDialPainter(
                  isSelectingHour: _isSelectingHour,
                  selectedHour: _selectedHour12,
                  selectedMinute: _selectedMinute,
                ),
                child: Stack(
                  children: _isSelectingHour ? _buildHourNumbers() : _buildMinuteNumbers(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    int h24 = _selectedHour12;
                    if (_selectedPeriod == 'P.M.' && h24 < 12) h24 += 12;
                    if (_selectedPeriod == 'A.M.' && h24 == 12) h24 = 0;
                    Navigator.pop(context, TimeOfDay(hour: h24, minute: _selectedMinute));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningAmber,
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHourNumbers() {
    final widgets = <Widget>[];
    final hours = [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    const radius = 82.0;
    const center = 110.0;

    for (int i = 0; i < 12; i++) {
      final hour = hours[i];
      final angle = (i * 30 - 90) * (math.pi / 180.0);
      final x = center + radius * math.cos(angle) - 17;
      final y = center + radius * math.sin(angle) - 17;
      final isSelected = _selectedHour12 == hour;

      widgets.add(
        Positioned(
          left: x,
          top: y,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedHour12 = hour;
                _isSelectingHour = false; // Auto transition to minutes!
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.warningAmber : const Color(0xFF1E293B),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.warningAmber.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
                border: Border.all(
                  color: isSelected ? AppTheme.warningAmber : const Color(0xFF334155),
                ),
              ),
              child: Center(
                child: Text(
                  '$hour',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildMinuteNumbers() {
    final widgets = <Widget>[];
    final minutes = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];
    const radius = 82.0;
    const center = 110.0;

    for (int i = 0; i < 12; i++) {
      final min = minutes[i];
      final angle = (i * 30 - 90) * (math.pi / 180.0);
      final x = center + radius * math.cos(angle) - 17;
      final y = center + radius * math.sin(angle) - 17;
      final isSelected = _selectedMinute == min;

      widgets.add(
        Positioned(
          left: x,
          top: y,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedMinute = min;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.warningAmber : const Color(0xFF1E293B),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.warningAmber.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
                border: Border.all(
                  color: isSelected ? AppTheme.warningAmber : const Color(0xFF334155),
                ),
              ),
              child: Center(
                child: Text(
                  min.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}

class _ClockDialPainter extends CustomPainter {
  final bool isSelectingHour;
  final int selectedHour;
  final int selectedMinute;

  _ClockDialPainter({
    required this.isSelectingHour,
    required this.selectedHour,
    required this.selectedMinute,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw background ring
    final bgPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, 82, bgPaint);

    // Draw center dot
    final dotPaint = Paint()
      ..color = AppTheme.warningAmber
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, dotPaint);

    // Draw clock hand to selected item
    double val = isSelectingHour ? (selectedHour % 12).toDouble() : (selectedMinute / 5.0);
    double angle = (val * 30 - 90) * (math.pi / 180.0);
    final target = Offset(center.dx + 82 * math.cos(angle), center.dy + 82 * math.sin(angle));

    final handPaint = Paint()
      ..color = AppTheme.warningAmber
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, target, handPaint);
  }

  @override
  bool shouldRepaint(covariant _ClockDialPainter oldDelegate) {
    return oldDelegate.isSelectingHour != isSelectingHour ||
        oldDelegate.selectedHour != selectedHour ||
        oldDelegate.selectedMinute != selectedMinute;
  }
}

class _ExpandableAppointmentTile extends StatefulWidget {
  final VisitaAgenda visita;
  final AppEngineService engine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color Function(String) getStatusColor;

  const _ExpandableAppointmentTile({
    required this.visita,
    required this.engine,
    required this.onEdit,
    required this.onDelete,
    required this.getStatusColor,
  });

  @override
  State<_ExpandableAppointmentTile> createState() => _ExpandableAppointmentTileState();
}

class _ExpandableAppointmentTileState extends State<_ExpandableAppointmentTile> {
  bool _isExpanded = false;
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final a = widget.visita;
    final engine = widget.engine;
    final statusColor = widget.getStatusColor(a.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _isExpanded ? AppTheme.warningAmber.withValues(alpha: 0.5) : const Color(0xFF334155),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clean Header: Client Name, Price chip if available, & Expand Icon
              Row(
                children: [
                  Expanded(
                    child: Text(
                      a.cliente,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (a.monto > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        currencyFormat.format(a.monto),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: _isExpanded ? AppTheme.warningAmber : const Color(0xFF94A3B8),
                    size: 22,
                  ),
                ],
              ),

              // Expanded Details
              if (_isExpanded) ...[
                const SizedBox(height: 10),
                const Divider(color: Color(0xFF334155), height: 1),
                const SizedBox(height: 10),

                // Status and Payment Badges (Clean, balanced top row)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        a.estado.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ),
                    if (a.monto > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: a.metodoPago == 'transferencia'
                              ? AppTheme.primaryCyan.withValues(alpha: 0.15)
                              : AppTheme.successGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: a.metodoPago == 'transferencia'
                                ? AppTheme.primaryCyan.withValues(alpha: 0.5)
                                : AppTheme.successGreen.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              a.metodoPago == 'transferencia'
                                  ? Icons.account_balance_rounded
                                  : Icons.payments_rounded,
                              size: 12,
                              color: a.metodoPago == 'transferencia'
                                  ? AppTheme.primaryCyan
                                  : AppTheme.successGreen,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              a.metodoPago == 'transferencia'
                                  ? 'Transferencia'
                                  : 'Efectivo',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: a.metodoPago == 'transferencia'
                                    ? AppTheme.primaryCyan
                                    : AppTheme.successGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Elegant Description Container (Never overflows or bleeds outside card)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.construction_outlined, size: 14, color: AppTheme.warningAmber),
                          const SizedBox(width: 6),
                          Text(
                            'Descripción del Trabajo:',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        a.tipo.isNotEmpty ? a.tipo : 'Sin descripción registrada.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFFF1F5F9),
                          height: 1.4,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Payment Highlight Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: (a.monto > 0 ? AppTheme.successGreen : AppTheme.warningAmber).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (a.monto > 0 ? AppTheme.successGreen : AppTheme.warningAmber).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            a.monto > 0 ? Icons.payments_outlined : Icons.monetization_on_outlined,
                            size: 15,
                            color: a.monto > 0 ? AppTheme.successGreen : AppTheme.warningAmber,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pago Realizado:',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        a.monto > 0 ? currencyFormat.format(a.monto) : 'Sin registrar',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: a.monto > 0 ? AppTheme.successGreen : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Phone
                if (a.telefono.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          a.telefono,
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],

                // Time and Team
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 13, color: AppTheme.warningAmber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${a.hora} • ${a.fecha} (${a.equipoId.toUpperCase()})',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.warningAmber,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Actions: Safe responsive Wrap
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (a.estado.toLowerCase() != 'completado') ...[
                          Builder(
                            builder: (context) {
                              final isFuture = _isFutureDate(a.fecha);
                              return OutlinedButton.icon(
                                onPressed: isFuture
                                    ? () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'No se puede completar: esta cita es para una fecha futura (${a.fecha}).',
                                            ),
                                            backgroundColor: const Color(0xFF334155),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    : () => _showCompletarDialog(context, a, engine),
                                icon: Icon(
                                  Icons.check_circle_outline,
                                  size: 14,
                                  color: isFuture ? const Color(0xFF64748B) : AppTheme.successGreen,
                                ),
                                label: Text(
                                  'Completar',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isFuture ? const Color(0xFF64748B) : AppTheme.successGreen,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isFuture ? const Color(0xFF64748B) : AppTheme.successGreen,
                                  side: BorderSide(
                                    color: isFuture ? const Color(0xFF475569) : AppTheme.successGreen,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              );
                            },
                          ),
                        ],
                        if (a.estado.toLowerCase() == 'pendiente') ...[
                          const SizedBox(width: 6),
                          OutlinedButton.icon(
                            onPressed: () {
                              engine.updateVisitaEstado(a.id, 'cancelado');
                            },
                            icon: const Icon(Icons.cancel_outlined, size: 14),
                            label: const Text('Cancelar', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.dangerRed,
                              side: const BorderSide(color: AppTheme.dangerRed),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: AppTheme.primaryCyan),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: widget.onEdit,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerRed),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: widget.onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCompletarDialog(BuildContext context, VisitaAgenda a, AppEngineService engine) {
    if (_isFutureDate(a.fecha)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede completar: esta cita es para una fecha futura (${a.fecha}).'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    final montoCtrl = TextEditingController(
      text: a.monto > 0 ? a.monto.toString() : '',
    );
    String metodoPago = a.metodoPago.isNotEmpty ? a.metodoPago : 'efectivo';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Completar Trabajo',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cliente: ${a.cliente}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                    ),
                    if (a.tipo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Trabajo: ${a.tipo}', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      'Registra el pago recibido para sumarlo a "Trabajos realizados" en el inicio:',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: montoCtrl,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monto Cobrado (\$) *',
                        prefixIcon: Icon(Icons.attach_money, color: AppTheme.successGreen),
                        hintText: 'Ej. 1500.00',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Subtle aesthetic payment method selector
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined, size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 6),
                        Text(
                          'Método de Cobro:',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFCBD5E1)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPaymentMethodChip(
                            label: 'Efectivo',
                            icon: Icons.payments_rounded,
                            isSelected: metodoPago == 'efectivo',
                            selectedColor: AppTheme.successGreen,
                            onTap: () => setDialogState(() => metodoPago = 'efectivo'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildPaymentMethodChip(
                            label: 'Transferencia',
                            icon: Icons.account_balance_rounded,
                            isSelected: metodoPago == 'transferencia',
                            selectedColor: AppTheme.primaryCyan,
                            onTap: () => setDialogState(() => metodoPago = 'transferencia'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Volver'),
                ),
                OutlinedButton(
                  onPressed: () {
                    engine.updateVisitaEstadoConMonto(a.id, 'completado', a.monto, metodoPago: metodoPago);
                    Navigator.pop(ctx);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF94A3B8),
                    side: const BorderSide(color: Color(0xFF334155)),
                  ),
                  child: const Text('Sin registrar cobro', style: TextStyle(fontSize: 11)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final parsed = double.tryParse(montoCtrl.text.trim()) ?? 0.0;
                    engine.updateVisitaEstadoConMonto(a.id, 'completado', parsed, metodoPago: metodoPago);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Guardar Pago y Completar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
