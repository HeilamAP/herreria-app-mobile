import 'package:flutter_test/flutter_test.dart';
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

  test('La hora se lee en formato nuevo y viejo', () {
    expect(VisitaAgenda.minutosDeHora('14:30'), 14 * 60 + 30);
    expect(VisitaAgenda.minutosDeHora('02:30 PM'), 14 * 60 + 30);
    expect(VisitaAgenda.minutosDeHora('12:15 AM'), 15);
    expect(VisitaAgenda.horaDeMinutos(16 * 60 + 15), '16:15');
  });
}
