import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portones_movil/screens/encargado/horario_dia.dart';
import 'package:portones_movil/screens/encargado/ui.dart';
import 'package:portones_movil/main.dart';
import 'package:portones_movil/models/visita_agenda.dart';
import 'package:portones_movil/services/app_engine_service.dart';
import 'package:portones_movil/services/seguridad.dart';
import 'package:portones_movil/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('La entrada muestra a los encargados', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await tester.runAsync(storage.init);
    await tester.pumpWidget(PortonesApp(storageService: storage));
    expect(find.text('AY OY'), findsOneWidget);
    expect(find.text('¿Quién eres?'), findsOneWidget);
    expect(find.text('Jose Ay'), findsOneWidget);
    expect(find.text('Nefy Dzul'), findsOneWidget);
  });

  test('Las contraseñas se guardan cifradas y se verifican', () {
    final guardado = Seguridad.cifrar('1234');
    expect(guardado, isNot(contains('1234')));
    expect(Seguridad.verificar('1234', guardado), isTrue);
    expect(Seguridad.verificar('4321', guardado), isFalse);
  });

  test('La agenda única junta los trabajos de los dos equipos', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final engine = AppEngineService(storage: storage);
    VisitaAgenda cita(String id, String equipo, String hora) => VisitaAgenda(
          id: id, cliente: id, fecha: '2030-01-07', hora: hora, tipo: 'Instalación',
          direccion: '', telefono: '', notas: '', estado: 'pendiente', equipoId: equipo,
        );
    engine.saveVisitaAgenda(cita('de_nefy', 'equipo2', '10:00'));
    engine.saveVisitaAgenda(cita('de_jose', 'equipo1', '09:00'));

    final todos = engine.trabajosDelDia('todos', '2030-01-07');
    expect(todos.map((t) => t.id), ['de_jose', 'de_nefy']);
    expect(engine.pendientesEn('todos', '2030-01-07'), 2);
    expect(engine.trabajosDelDia('equipo2', '2030-01-07').map((t) => t.id), ['de_nefy']);
  });

  test('La duración se guarda y los trabajos viejos duran 1 hora', () {
    final viejo = VisitaAgenda.fromJson({'id': 'a', 'hora': '10:00'});
    expect(viejo.duracionMin, 60);
    expect(viejo.finMinutos, 11 * 60);
    final nuevo = VisitaAgenda.fromJson({...viejo.toJson(), 'duracionMin': 150});
    expect(VisitaAgenda.fromJson(nuevo.toJson()).duracionMin, 150);
    expect(duracionTexto(30), '30 min');
    expect(duracionTexto(90), '1 hora y media');
    expect(duracionTexto(150), '2 horas y media');
    expect(duracionTexto(600), 'Todo el día');
  });

  testWidgets('El horario muestra trabajos encimados y fuera de horario', (tester) async {
    VisitaAgenda cita(String id, String equipo, String hora, int dur) => VisitaAgenda(
          id: id, cliente: 'Cliente $id', fecha: '2030-01-07', hora: hora, tipo: 'Instalación',
          direccion: '', telefono: '', notas: '', estado: 'pendiente', equipoId: equipo, duracionMin: dur,
        );
    VisitaAgenda? tocado;
    String? huecoEquipo;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: HorarioDia(
            trabajos: [
              cita('a', 'equipo1', '09:00', 120),
              cita('b', 'equipo1', '10:00', 60), // se encima con "a"
              cita('c', 'equipo2', '07:00', 60), // antes de las 8
            ],
            equipos: const ['equipo1', 'equipo2'],
            equipoPropio: 'equipo1',
            esHoy: false,
            onTrabajo: (t) => tocado = t,
            onHueco: (e, m) => huecoEquipo = e,
          ),
        ),
      ),
    ));
    expect(find.text('Antes de las 8 am'), findsOneWidget);
    expect(find.text('Cliente a'), findsOneWidget);
    expect(find.text('Cliente b'), findsOneWidget);
    await tester.tap(find.text('Cliente b'));
    expect(tocado?.id, 'b');
    await tester.tapAt(tester.getTopRight(find.byType(HorarioDia)) + const Offset(-20, 300));
    expect(huecoEquipo, 'equipo2');
  });

  test('El detalle del Resumen separa efectivo y transferencia', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final engine = AppEngineService(storage: storage);
    VisitaAgenda cobro(String id, String metodo, String estado, String hora) => VisitaAgenda(
          id: id, cliente: id, fecha: '2030-01-07', hora: hora, tipo: 'Instalación', direccion: '',
          telefono: '', notas: '', estado: estado, equipoId: 'equipo1', monto: 500, metodoPago: metodo,
        );
    engine.saveVisitaAgenda(cobro('efe_tarde', 'efectivo', 'completado', '15:00'));
    engine.saveVisitaAgenda(cobro('efe_manana', 'efectivo', 'completado', '09:00'));
    engine.saveVisitaAgenda(cobro('trans', 'transferencia', 'completado', '10:00'));
    engine.saveVisitaAgenda(cobro('pendiente', 'efectivo', 'pendiente', '11:00'));

    expect(engine.cobrosDelDia('equipo1', '2030-01-07', 'efectivo').map((t) => t.id), ['efe_manana', 'efe_tarde']);
    expect(engine.cobrosDelDia('equipo1', '2030-01-07', 'transferencia').map((t) => t.id), ['trans']);
    expect(engine.cobrosDelDia('equipo2', '2030-01-07', 'efectivo'), isEmpty);
  });

  test('La hora se lee en formato nuevo y viejo', () {
    expect(VisitaAgenda.minutosDeHora('14:30'), 14 * 60 + 30);
    expect(VisitaAgenda.minutosDeHora('02:30 PM'), 14 * 60 + 30);
    expect(VisitaAgenda.minutosDeHora('12:15 AM'), 15);
    expect(VisitaAgenda.horaDeMinutos(16 * 60 + 15), '16:15');
  });
}
