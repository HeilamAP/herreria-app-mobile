import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_engine_service.dart';
import '../../services/auth_service.dart';
import 'ui.dart';

class ResumenEquipoScreen extends StatelessWidget {
  const ResumenEquipoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<AppEngineService>();
    final equipo = context.read<AuthService>().currentUser?.equipoId ?? 'equipo1';
    final dia = fechaKey(hoy());
    final r = engine.resumen(equipo, dia, dia);

    Widget fila(IconData icono, String texto, String valor, {Color color = EC.texto}) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: EC.bordeFuerte)),
          child: Row(children: [
            Icon(icono, size: 28, color: EC.textoSuave),
            const SizedBox(width: 12),
            Expanded(child: Text(texto, style: const TextStyle(fontSize: 21, color: EC.texto))),
            Text(valor, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
          ]),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text('Resumen de hoy', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: EC.texto)),
        Text(diaTexto(hoy()), style: const TextStyle(fontSize: 18, color: EC.textoSuave)),
        const SizedBox(height: 16),
        fila(Icons.payments_outlined, 'Efectivo', dinero(r.efectivo)),
        fila(Icons.account_balance_outlined, 'Transferencia', dinero(r.transferencia)),
        fila(Icons.receipt_long_outlined, 'Gastos', r.gastos > 0 ? '−${dinero(r.gastos)}' : dinero(0), color: EC.peligroTexto),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: EC.superficie, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Lo que quedó hoy', style: TextStyle(fontSize: 20, color: EC.textoSuave)),
            Text(dinero(r.efectivo + r.transferencia - r.gastos),
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: EC.texto)),
          ]),
        ),
        if (r.ventas > 0) ...[
          const SizedBox(height: 10),
          Text('De lo cobrado, ${dinero(r.ventas)} fueron ventas.', style: const TextStyle(fontSize: 17, color: EC.textoSuave)),
        ],
      ],
    );
  }
}
