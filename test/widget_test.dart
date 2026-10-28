import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portones_movil/models/gasto.dart';
import 'package:portones_movil/models/direccion.dart';
import 'package:portones_movil/models/marca.dart';
import 'package:portones_movil/screens/encargado/evidencia.dart';
import 'package:portones_movil/services/sello_foto.dart';
import 'package:portones_movil/services/ubicacion.dart';
import 'package:image/image.dart' as img;
import 'package:portones_movil/screens/encargado/agendar_screen.dart';
import 'package:portones_movil/screens/encargado/cobrar_screen.dart';
import 'package:portones_movil/screens/encargado/gastos_screen.dart';
import 'package:portones_movil/screens/encargado/fotos_screen.dart';
import 'package:portones_movil/screens/encargado/horario_dia.dart';
import 'package:portones_movil/services/foto_store.dart';
import 'package:portones_movil/screens/encargado/resumen_screen.dart';
import 'package:portones_movil/screens/encargado/trabajos_screen.dart';
import 'package:portones_movil/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:portones_movil/screens/encargado/ui.dart';
import 'package:portones_movil/main.dart';
import 'package:portones_movil/models/visita_agenda.dart';
import 'package:portones_movil/services/app_engine_service.dart';
import 'package:portones_movil/services/seguridad.dart';
import 'package:portones_movil/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Sin GPS ni mapa de verdad en las pruebas.
  setUp(() => ubicador = UbicadorFijo());

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

  testWidgets('El Resumen despliega el detalle debajo del renglón tocado', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await tester.runAsync(storage.init);
    final auth = AuthService(storage: storage);
    final engine = AppEngineService(storage: storage);
    auth.crearPinYEntrar(storage.data.usuarios.firstWhere((u) => u.equipoId == 'equipo1'), '1234');
    engine.saveVisitaAgenda(VisitaAgenda(
      id: 'v1', cliente: 'Ana Pech', fecha: fechaKey(hoy()), hora: '10:00', tipo: 'Venta', direccion: '',
      telefono: '', notas: '', estado: 'completado', equipoId: 'equipo1', monto: 900, metodoPago: 'efectivo',
    ));

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<AppEngineService>.value(value: engine),
      ],
      child: const MaterialApp(home: Scaffold(body: ResumenEquipoScreen())),
    ));

    expect(find.text('Ana Pech'), findsNothing);
    await tester.tap(find.text('Efectivo'));
    await tester.pumpAndSettle();
    expect(find.text('Ana Pech'), findsOneWidget);
    expect(find.text('Toca un cobro para ver sus opciones.'), findsOneWidget);

    await tester.tap(find.text('Transferencia'));
    await tester.pumpAndSettle();
    expect(find.text('No hay cobros por transferencia hoy'), findsOneWidget);

    await tester.tap(find.text('Efectivo'));
    await tester.pumpAndSettle();
    expect(find.text('Ana Pech'), findsNothing);
  });

  testWidgets('En el Resumen, "Lo que quedó" negativo sale en rojo', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await tester.runAsync(storage.init);
    final auth = AuthService(storage: storage);
    final engine = AppEngineService(storage: storage);
    auth.crearPinYEntrar(storage.data.usuarios.firstWhere((u) => u.equipoId == 'equipo1'), '1234');
    engine.saveVisitaAgenda(VisitaAgenda(
      id: 'v1', cliente: 'Ana Pech', fecha: fechaKey(hoy()), hora: '10:00', tipo: 'Venta', direccion: '',
      telefono: '', notas: '', estado: 'completado', equipoId: 'equipo1', monto: 900, metodoPago: 'efectivo',
    ));
    engine.addGasto(Gasto(id: 'g1', fecha: fechaKey(hoy()), descripcion: 'Material', monto: 1200));

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<AppEngineService>.value(value: engine),
      ],
      child: const MaterialApp(home: Scaffold(body: ResumenEquipoScreen())),
    ));

    final quedo = tester.widget<Text>(find.text('−\$300'));
    expect(quedo.style?.color, EC.peligroTexto);

    // Con ganancia, el monto vuelve al color normal.
    engine.saveVisitaAgenda(VisitaAgenda(
      id: 'v2', cliente: 'Luis Kú', fecha: fechaKey(hoy()), hora: '12:00', tipo: 'Venta', direccion: '',
      telefono: '', notas: '', estado: 'completado', equipoId: 'equipo1', monto: 1000, metodoPago: 'efectivo',
    ));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text('\$700')).style?.color, EC.texto);
  });

  testWidgets('Un cobro ya hecho solo lo cambia o lo borra el administrador', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await tester.runAsync(storage.init);
    final auth = AuthService(storage: storage);
    final engine = AppEngineService(storage: storage);
    final t = VisitaAgenda(
      id: 'c1', cliente: 'Ana Pech', fecha: fechaKey(hoy()), hora: '10:00', tipo: 'Instalación', direccion: '',
      telefono: '', notas: '', estado: 'completado', equipoId: 'equipo1', monto: 900, metodoPago: 'efectivo',
    );
    engine.saveVisitaAgenda(t);
    Future<void> abrirOpciones() => tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthService>.value(value: auth),
            ChangeNotifierProvider<AppEngineService>.value(value: engine),
          ],
          child: MaterialApp(key: UniqueKey(), home: OpcionesTrabajoScreen(trabajo: t)),
        ));

    auth.crearPinYEntrar(storage.data.usuarios.firstWhere((u) => u.equipoId == 'equipo1'), '1234');
    await abrirOpciones();
    expect(find.text('Cambiar el cobro'), findsNothing);
    expect(find.text('Borrar este trabajo'), findsNothing);
    expect(find.textContaining('pídeselo al administrador'), findsOneWidget);
    expect(find.text('Cambiar los datos'), findsOneWidget); // los datos del cliente sí se pueden corregir

    auth.logout();
    expect(auth.login('heilamay', 'admin123', onError: (_) {}), isTrue);
    await abrirOpciones();
    expect(find.text('Cambiar el cobro'), findsOneWidget);
    expect(find.text('Borrar este trabajo'), findsOneWidget);
    expect(find.textContaining('pídeselo al administrador'), findsNothing);
  });

  testWidgets('El administrador anota gastos de cualquier equipo y sin límite', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await tester.runAsync(storage.init);
    final auth = AuthService(storage: storage);
    final engine = AppEngineService(storage: storage);
    expect(auth.login('heilamay', 'admin123', onError: (_) {}), isTrue);
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<AppEngineService>.value(value: engine),
      ],
      child: const MaterialApp(home: NuevoGastoScreen(equipoId: 'equipo2')),
    ));

    await tester.tap(find.text('Material'));
    await tester.pumpAndSettle();
    expect(find.text('Hasta \$15,000 por gasto.'), findsNothing);
    for (final d in ['2', '0', '0', '0', '0']) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.tap(find.text('Guardar gasto'));
    await tester.pumpAndSettle();
    expect(find.text('Guardado'), findsOneWidget);
    final g = engine.data.gastos.single;
    expect((g.monto, g.equipoId), (20000, 'equipo2'));
  });

  test('La semana del Resumen va de domingo a sábado', () {
    // El 20 de octubre de 2026 es martes: su semana es del domingo 18 al sábado 24.
    expect(domingoDe(DateTime(2026, 10, 20)), DateTime(2026, 10, 18));
    expect(domingoDe(DateTime(2026, 10, 18)), DateTime(2026, 10, 18)); // domingo
    expect(domingoDe(DateTime(2026, 10, 24)), DateTime(2026, 10, 18)); // sábado
    expect(domingoDe(DateTime(2026, 10, 25)), DateTime(2026, 10, 25)); // siguiente domingo
    expect(semanaTexto(DateTime(2026, 10, 18)), 'Del 18 al 24 de octubre');
    expect(semanaTexto(DateTime(2026, 10, 25)), 'Del 25 al 31 de octubre');
    expect(semanaTexto(DateTime(2026, 11, 29)), 'Del 29 de noviembre al 5 de diciembre');
  });

  testWidgets('El Resumen de la semana suma y agrupa los días de domingo a sábado', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await tester.runAsync(storage.init);
    final auth = AuthService(storage: storage);
    final engine = AppEngineService(storage: storage);
    auth.crearPinYEntrar(storage.data.usuarios.firstWhere((u) => u.equipoId == 'equipo1'), '1234');
    // Otro día de esta semana que no sea hoy.
    final otroDia = hoy().weekday == DateTime.sunday ? hoy().add(const Duration(days: 1)) : domingoDe(hoy());
    VisitaAgenda cobro(String id, String cliente, DateTime dia, double monto) => VisitaAgenda(
          id: id, cliente: cliente, fecha: fechaKey(dia), hora: '10:00', tipo: 'Instalación', direccion: '',
          telefono: '', notas: '', estado: 'completado', equipoId: 'equipo1', monto: monto, metodoPago: 'efectivo',
        );
    engine.saveVisitaAgenda(cobro('hoy', 'Ana Pech', hoy(), 900));
    engine.saveVisitaAgenda(cobro('otro', 'Luis Cauich', otroDia, 1500));
    engine.saveVisitaAgenda(cobro('pasada', 'Semana pasada', hoy().subtract(const Duration(days: 7)), 5000));

    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<AppEngineService>.value(value: engine),
      ],
      child: const MaterialApp(home: Scaffold(body: ResumenEquipoScreen())),
    ));

    expect(find.text('\$900'), findsWidgets); // hoy solo cuenta la de hoy
    await tester.tap(find.text('Semana'));
    await tester.pumpAndSettle();
    expect(find.text('Resumen de la semana'), findsOneWidget);
    expect(find.text('\$2,400'), findsWidgets); // 900 + 1500, sin la semana pasada

    await tester.tap(find.text('Efectivo'));
    await tester.pumpAndSettle();
    expect(find.text('Ana Pech'), findsOneWidget);
    expect(find.text('Luis Cauich'), findsOneWidget);
    expect(find.text('Semana pasada'), findsNothing);
    expect(find.textContaining('Hoy, '), findsOneWidget); // encabezado del día

    await tester.tap(find.byTooltip('Anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Semana pasada'), findsOneWidget);
    expect(find.text('Ana Pech'), findsNothing);
  });

  group('Corregir lo ya guardado actualiza el mismo registro', () {
    late StorageService storage;
    late AppEngineService engine;

    Future<void> abrir(WidgetTester tester, Widget pantalla) async {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
      await tester.runAsync(storage.init);
      engine = AppEngineService(storage: storage);
      tester.view.physicalSize = const Size(420, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    Future<void> mostrar(WidgetTester tester, Widget pantalla) => tester.pumpWidget(
          ChangeNotifierProvider<AppEngineService>.value(value: engine, child: MaterialApp(home: pantalla)),
        );

    testWidgets('Trabajo: se toca un dato en "¿Está bien así?" y se corrige', (tester) async {
      await abrir(tester, const SizedBox());
      final t = VisitaAgenda(
        id: 't1', cliente: 'Luis Cauih', fecha: fechaKey(hoy()), hora: '10:00', tipo: 'Instalación',
        direccion: 'Calle 42', telefono: '', notas: '', estado: 'pendiente', equipoId: 'equipo1',
      );
      engine.saveVisitaAgenda(t);
      final total = engine.data.agenda.length; // incluye citas de ejemplo del modo de prueba
      await mostrar(tester, AgendarScreen(equipoId: 'equipo1', existente: t, empezarEnConfirmar: true));

      expect(find.text('¿Está bien así?'), findsOneWidget);
      await tester.tap(find.text('Luis Cauih'));
      await tester.pumpAndSettle();
      expect(find.text('Corrigiendo'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Luis Cauich');
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(find.text('¿Está bien así?'), findsOneWidget); // regresa al resumen, no al paso 2
      expect(find.text('Luis Cauich'), findsOneWidget);
      expect(find.text('Calle 42'), findsOneWidget); // lo demás se conserva
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(find.text('Me equivoqué, corregir'), findsOneWidget);
      expect(engine.data.agenda.where((a) => a.id == 't1').single.cliente, 'Luis Cauich');
      expect(engine.data.agenda.length, total); // no se creó otro
    });

    testWidgets('Dirección: se corrige por partes y la línea se vuelve a armar', (tester) async {
      await abrir(tester, const SizedBox());
      final t = VisitaAgenda(
        id: 't2', cliente: 'Carlos Mendoza', fecha: fechaKey(hoy()), hora: '09:00', tipo: 'Instalación',
        direccion: '', telefono: '', notas: 'Llevar soldadora', estado: 'pendiente', equipoId: 'equipo1',
        partes: PartesDireccion(calle: '60', numero: '450', cruce1: '53', cruce2: '55', colonia: 'Centro', referencias: 'Portón negro'),
      )..direccion = 'Calle 60 #450 x 53 y 55, Col. Centro, Mérida';
      engine.saveVisitaAgenda(t);
      await mostrar(tester, AgendarScreen(equipoId: 'equipo1', existente: t, empezarEnConfirmar: true));

      expect(find.text('Calle 60 #450 x 53 y 55, Col. Centro, Mérida'), findsOneWidget);
      expect(find.text('Portón negro'), findsOneWidget);
      expect(find.text('Llevar soldadora'), findsOneWidget); // las notas tienen su propio renglón

      await tester.tap(find.text('Calle 60 #450 x 53 y 55, Col. Centro, Mérida'));
      await tester.pumpAndSettle();
      expect(find.text('¿Dónde es?'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Centro'), 'García Ginerés');
      await tester.tap(find.text('Otro'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Kanasín'), 'Kanasín');
      await tester.enterText(find.widgetWithText(TextField, '60'), '');
      await tester.ensureVisible(find.text('Siguiente'));
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Escribe la calle'), findsOneWidget); // la calle es obligatoria
      await tester.enterText(find.byType(TextField).first, '60');
      await tester.ensureVisible(find.text('Siguiente'));
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(find.text('¿Está bien así?'), findsOneWidget);
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      final guardado = engine.data.agenda.firstWhere((a) => a.id == 't2');
      expect(guardado.direccion, 'Calle 60 #450 x 53 y 55, Col. García Ginerés, Kanasín');
      expect(guardado.referencias, 'Portón negro');
    });

    testWidgets('Venta rápida: se reabre con cliente, monto y forma de pago', (tester) async {
      await abrir(tester, const SizedBox());
      final v = VisitaAgenda(
        id: 'v1', cliente: 'Ana Pech', fecha: fechaKey(hoy()), hora: '12:00', tipo: 'Venta', direccion: '',
        telefono: '', notas: 'Control', estado: 'completado', equipoId: 'equipo1', monto: 900, metodoPago: 'efectivo',
      );
      engine.saveVisitaAgenda(v);
      final total = engine.data.agenda.length;
      await mostrar(tester, CobrarScreen(equipoId: 'equipo1', trabajo: v, corregirVenta: true));

      expect(find.text('Corrigiendo venta · 1 de 3'), findsOneWidget);
      expect(find.text('Ana Pech'), findsWidgets);
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('\$900'), findsOneWidget);
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transferencia'));
      await tester.pumpAndSettle();

      expect(find.text('Venta corregida'), findsOneWidget);
      expect(engine.data.agenda.length, total); // no se creó otra venta
      final guardada = engine.data.agenda.firstWhere((a) => a.id == 'v1');
      expect(guardada.metodoPago, 'transferencia');
      expect(guardada.hora, '12:00');
    });

    testWidgets('Gasto: abre en el monto con la categoría ya elegida', (tester) async {
      await abrir(tester, const SizedBox());
      final g = Gasto(id: 'g1', fecha: fechaKey(hoy()), descripcion: 'Gasolina', categoria: 'Gasolina', monto: 300);
      engine.addGasto(g);
      await mostrar(tester, NuevoGastoScreen(equipoId: 'equipo1', existente: g));

      expect(find.text('¿Cuánto gastaste en gasolina?'), findsOneWidget);
      expect(find.text('\$300'), findsOneWidget);
      await tester.tap(find.text('0'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar gasto'));
      await tester.pumpAndSettle();

      expect(find.text('Gasto corregido'), findsOneWidget);
      expect(engine.data.gastos.single.id, 'g1');
      expect(engine.data.gastos.single.monto, 3000);
    });

    testWidgets('Gasto: un encargado no puede anotar más de \$15,000', (tester) async {
      await abrir(tester, const SizedBox());
      final g = Gasto(id: 'g1', fecha: fechaKey(hoy()), descripcion: 'Material', categoria: 'Material', monto: 15000);
      engine.addGasto(g);
      await mostrar(tester, NuevoGastoScreen(equipoId: 'equipo1', existente: g));
      expect(find.text('Hasta \$15,000 por gasto.'), findsOneWidget);

      await tester.tap(find.text('0')); // $150,000
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar gasto'));
      await tester.pumpAndSettle();
      expect(find.textContaining('El límite es \$15,000 por gasto'), findsOneWidget);
      expect(engine.data.gastos.single.monto, 15000); // no se guardó

      await mostrar(tester, NuevoGastoScreen(equipoId: 'equipo1', existente: g, key: UniqueKey()));
      await tester.tap(find.text('Guardar gasto')); // justo $15,000 sí se puede
      await tester.pumpAndSettle();
      expect(find.text('Gasto corregido'), findsOneWidget);
    });
  });

  group('Notas y fotos de los trabajos', () {
    // Imagen PNG de 1x1 píxel, para no depender de la cámara.
    final png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');
    late StorageService storage;
    late AppEngineService engine;
    late FotoStoreMemoria memoria;

    Future<void> preparar(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
      await tester.runAsync(storage.init);
      engine = AppEngineService(storage: storage);
      memoria = FotoStoreMemoria();
      fotoStore = memoria;
      tester.view.physicalSize = const Size(420, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    Future<void> mostrar(WidgetTester tester, Widget pantalla) => tester.pumpWidget(
          ChangeNotifierProvider<AppEngineService>.value(value: engine, child: MaterialApp(home: pantalla)),
        );

    VisitaAgenda trabajo({List<String>? fotos, String estado = 'completado'}) => VisitaAgenda(
          id: 'tf', cliente: 'Carlos Mendoza', fecha: fechaKey(hoy()), hora: '09:00', tipo: 'Instalación',
          direccion: '', telefono: '', notas: 'Llevar soldadora', estado: estado, equipoId: 'equipo1', monto: 4500,
          fotos: fotos,
        );

    test('La nota final y las fotos se guardan y los trabajos viejos no tienen', () {
      final viejo = VisitaAgenda.fromJson({'id': 'x'});
      expect(viejo.notaFinal, '');
      expect(viejo.fotos, isEmpty);
      final t = VisitaAgenda.fromJson({'id': 'y', 'notaFinal': 'Falta pintar', 'fotos': ['f1', 'f2']});
      final otra = VisitaAgenda.fromJson(t.toJson());
      expect(otra.notaFinal, 'Falta pintar');
      expect(otra.fotos, ['f1', 'f2']);
      expect(otra.notas, ''); // la nota de cuando se agenda es aparte
    });

    testWidgets('Se escribe la nota y se quita una foto', (tester) async {
      await preparar(tester);
      final id = await tester.runAsync(() => guardarFoto(png));
      engine.saveVisitaAgenda(trabajo(fotos: [id!]));
      await mostrar(tester, const FotosNotaScreen(trabajoId: 'tf'));
      await tester.pumpAndSettle();

      expect(find.text('1 de 10 fotos'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Falta pintar el riel');
      await tester.tap(find.byTooltip('Quitar foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sí, quitar'));
      await tester.pumpAndSettle();
      expect(find.text('Todavía no hay fotos'), findsOneWidget);
      expect(engine.visitaPorId('tf')!.fotos, isEmpty);
      expect(memoria.fotos, isEmpty); // también se borra del teléfono

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(engine.visitaPorId('tf')!.notaFinal, 'Falta pintar el riel');
      expect(engine.visitaPorId('tf')!.notas, 'Llevar soldadora');
    });

    testWidgets('Al cobrar se pregunta por fotos; al corregir el cobro, no', (tester) async {
      await preparar(tester);
      final t = trabajo(estado: 'pendiente');
      engine.saveVisitaAgenda(t);
      await mostrar(tester, CobrarScreen(equipoId: 'equipo1', trabajo: t));
      await tester.pumpAndSettle();

      for (final tecla in ['5', '0', '0']) {
        await tester.tap(find.text(tecla));
        await tester.pump();
      }
      expect(find.text('\$500'), findsOneWidget);
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Efectivo'));
      await tester.pumpAndSettle();
      expect(find.text('¿Quieres agregar fotos o una nota?'), findsOneWidget);

      await tester.tap(find.text('Terminar sin nada'));
      await tester.pumpAndSettle();
      expect(find.text('Cobrado'), findsOneWidget);
      expect(engine.visitaPorId('tf')!.monto, 500);

      await tester.tap(find.text('Me equivoqué, corregir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transferencia'));
      await tester.pumpAndSettle();
      expect(find.text('¿Quieres agregar fotos o una nota?'), findsNothing);
      expect(find.text('Cobro cambiado'), findsOneWidget);
    });

    testWidgets('La tarjeta muestra la nota y las miniaturas', (tester) async {
      await preparar(tester);
      final ids = <String>[];
      for (var i = 0; i < 6; i++) {
        ids.add((await tester.runAsync(() => guardarFoto(png)))!);
      }
      final t = trabajo(fotos: ids)..notaFinal = 'Quedó bien';
      await mostrar(tester, Scaffold(body: NotasYFotosResumen(trabajo: t, onAbrir: () {})));
      await tester.pumpAndSettle();
      expect(find.text('Quedó bien'), findsOneWidget);
      expect(find.byType(FotoMiniatura), findsNWidgets(3));
      expect(find.text('+3'), findsOneWidget);
    });
  });

  testWidgets('Un gasto registrado se puede corregir desde la pestaña Gastos', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await tester.runAsync(storage.init);
    final auth = AuthService(storage: storage);
    final engine = AppEngineService(storage: storage);
    auth.crearPinYEntrar(storage.data.usuarios.firstWhere((u) => u.equipoId == 'equipo1'), '1234');
    engine.addGasto(Gasto(id: 'g1', fecha: fechaKey(hoy()), descripcion: 'Gasolina', categoria: 'Gasolina', monto: 300));
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<AppEngineService>.value(value: engine),
      ],
      child: const MaterialApp(home: Scaffold(body: GastosEquipoScreen())),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gasolina'));
    await tester.pumpAndSettle();
    expect(find.text('Corregir este gasto'), findsOneWidget);
    expect(find.text('Borrar este gasto'), findsOneWidget);

    await tester.tap(find.text('Corregir este gasto'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cuánto gastaste en gasolina?'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    expect(find.text('\$30'), findsOneWidget); // el monto guardado viene escrito: 300 → borrar un dígito → 30
    await tester.tap(find.text('5'));
    await tester.pump();
    expect(find.text('\$305'), findsOneWidget);
    await tester.tap(find.text('Guardar gasto'));
    await tester.pumpAndSettle();

    expect(find.text('Gasto corregido'), findsOneWidget);
    expect(engine.data.gastos.single.id, 'g1');
    expect(engine.data.gastos.single.monto, 305);
  });

  group('Modo oscuro', () {
    tearDown(() => EC.usarOscuro(false));

    Color colorDe(WidgetTester tester, String texto) => tester.widget<Text>(find.text(texto)).style!.color!;

    testWidgets('La app abre en claro la primera vez', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await tester.runAsync(storage.init);
      await tester.pumpWidget(PortonesApp(storageService: storage));
      expect(storage.aspecto, 'claro');
      expect(EC.oscuro, isFalse);
      expect(colorDe(tester, '¿Quién eres?'), Paleta.clara.texto);
    });

    testWidgets('Si se eligió oscuro, se recuerda al abrir', (tester) async {
      SharedPreferences.setMockInitialValues({'ayoy_datos_v2_aspecto': 'oscuro'});
      final storage = StorageService();
      await tester.runAsync(storage.init);
      await tester.pumpWidget(PortonesApp(storageService: storage));
      expect(EC.oscuro, isTrue);
      expect(colorDe(tester, '¿Quién eres?'), Paleta.oscura.texto);
      final fondo = tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor ??
          Theme.of(tester.element(find.byType(Scaffold).first)).scaffoldBackgroundColor;
      expect(fondo, Paleta.oscura.fondo);
    });

    testWidgets('La luna abre "Aspecto de la app" y cambia a oscuro', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await tester.runAsync(storage.init);
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(PortonesApp(storageService: storage));
      // Entrar como Jose (crea su PIN).
      await tester.tap(find.text('Jose Ay'));
      await tester.pumpAndSettle();
      for (var vez = 0; vez < 2; vez++) {
        for (final n in ['1', '2', '3', '4']) {
          await tester.tap(find.text(n));
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.pumpAndSettle();
      }
      expect(find.text('Hola, Jose'), findsOneWidget);

      await tester.tap(find.byTooltip('Aspecto de la app'));
      await tester.pumpAndSettle();
      expect(find.text('Aspecto de la app'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Como el celular'), findsNothing); // solo claro u oscuro
      await tester.tap(find.text('Oscuro'));
      await tester.pumpAndSettle();

      expect(EC.oscuro, isTrue);
      expect(storage.aspecto, 'oscuro');
      expect(find.text('Hola, Jose'), findsOneWidget); // sigue con la sesión abierta
      expect(colorDe(tester, 'Hola, Jose'), Paleta.oscura.texto);
    });

    testWidgets('El ajuste del teléfono no cambia el modo; un valor viejo "sistema" queda en claro', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      SharedPreferences.setMockInitialValues({'ayoy_datos_v2_aspecto': 'sistema'});
      final storage = StorageService();
      await tester.runAsync(storage.init);
      await tester.pumpWidget(PortonesApp(storageService: storage));
      expect(EC.oscuro, isFalse);
    });
  });

  testWidgets('Trabajos muestra una sola semana, de domingo a sábado', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await tester.runAsync(storage.init);
    final auth = AuthService(storage: storage);
    final engine = AppEngineService(storage: storage);
    auth.crearPinYEntrar(storage.data.usuarios.firstWhere((u) => u.equipoId == 'equipo1'), '1234');
    tester.view.physicalSize = const Size(380, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<AppEngineService>.value(value: engine),
      ],
      child: const MaterialApp(home: Scaffold(body: TrabajosDiaScreen())),
    ));
    await tester.pumpAndSettle();

    final domingo = domingoDe(hoy());
    expect(find.text('Esta semana'), findsOneWidget);
    // Los 7 días: el número de cada uno, y "Hoy" en lugar del nombre del día de hoy.
    for (var i = 0; i < 7; i++) {
      expect(find.text('${domingo.add(Duration(days: i)).day}'), findsWidgets);
    }
    expect(find.text('Hoy'), findsOneWidget);
    final sabadoSiguienteSemana = domingo.add(const Duration(days: 13));
    expect(find.text(diasCortos[sabadoSiguienteSemana.weekday - 1]), findsOneWidget); // solo un "Sáb"

    await tester.tap(find.byTooltip('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text(semanaTexto(domingo.add(const Duration(days: 7)))), findsOneWidget);
    expect(find.text('Hoy'), findsNothing);
    await tester.tap(find.text('Volver a hoy'));
    await tester.pumpAndSettle();
    expect(find.text('Esta semana'), findsOneWidget);
  });

  test('La hora se lee en formato nuevo y viejo', () {
    expect(VisitaAgenda.minutosDeHora('14:30'), 14 * 60 + 30);
    expect(VisitaAgenda.minutosDeHora('02:30 PM'), 14 * 60 + 30);
    expect(VisitaAgenda.minutosDeHora('12:15 AM'), 15);
    expect(VisitaAgenda.horaDeMinutos(16 * 60 + 15), '16:15');
  });

  test('La dirección por partes se arma en una línea', () {
    expect(PartesDireccion(calle: '60', numero: '450', cruce1: '53', cruce2: '55', colonia: 'Centro').linea,
        'Calle 60 #450 x 53 y 55, Col. Centro, Mérida');
    expect(PartesDireccion(calle: '21').linea, 'Calle 21, Mérida');
    expect(PartesDireccion(calle: 'Av. Itzaes', numero: '12', colonia: 'Col. Jardines', municipio: 'Umán').linea,
        'Av. Itzaes #12, Col. Jardines, Umán');
    expect(PartesDireccion(calle: '20', cruce2: '22').linea, 'Calle 20 x 22, Mérida');
    final copia = VisitaAgenda.fromJson(VisitaAgenda(
      id: 'x', cliente: 'A', fecha: '2030-01-01', tipo: 'Otro', direccion: '', telefono: '', notas: '', estado: 'pendiente',
      partes: PartesDireccion(calle: '60', referencias: 'Portón negro'),
    ).toJson());
    expect(copia.partes?.calle, '60');
    expect(copia.referencias, 'Portón negro');
  });

  test('El teléfono solo acepta 10 números y se separa al escribir', () {
    expect(formatoTelefono('9991234567'), '999 123 4567');
    expect(formatoTelefono('999-123-45.67#*'), '999 123 4567');
    expect(formatoTelefono('99912345678901'), '999 123 4567'); // números de más se ignoran
    expect(formatoTelefono('9991'), '999 1');
    expect(formatoTelefono('+()'), '');

    final f = FormatoTelefono();
    TextEditingValue escribir(String texto) =>
        f.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length)));
    expect(escribir('999123').text, '999 123');
    expect(escribir('999123').selection.end, 7);
    expect(escribir('999 123 45678').text, '999 123 4567');
    expect(escribir('abc').text, '');
  });

  group('Evidencia: hora y lugar', () {
    // Calle 60 x 61, Centro de Mérida, y un punto a ~3 km.
    const domLat = 20.96712, domLng = -89.62374;
    Marca marca({double lat = domLat, double lng = domLng, bool falsa = false}) =>
        Marca(hora: DateTime(2026, 10, 28, 10, 42), lat: lat, lng: lng, precisionM: 8, falsa: falsa);
    VisitaAgenda trabajo() => VisitaAgenda(
          id: 'e1', cliente: 'Carlos Mendoza', fecha: fechaKey(hoy()), hora: '09:00', tipo: 'Instalación',
          direccion: 'Calle 60 #450 x 53 y 55, Col. Centro, Mérida', telefono: '', notas: '', estado: 'pendiente',
          partes: PartesDireccion(calle: '60', numero: '450', cruce1: '53', cruce2: '55', colonia: 'Centro'),
        );

    test('Distancias y "en el domicilio"', () {
      expect(distanciaM(domLat, domLng, domLat, domLng), 0);
      expect(distanciaM(domLat, domLng, domLat + 0.027, domLng), closeTo(3000, 30)); // ~3 km al norte
      final t = trabajo();
      expect(enDomicilio(t, marca()), isFalse); // todavía no se sabe dónde queda la dirección
      t
        ..domLat = domLat
        ..domLng = domLng
        ..domDireccion = t.direccion;
      expect(enDomicilio(t, marca(lat: domLat + 0.001)), isTrue); // ~110 m
      expect(enDomicilio(t, marca(lat: domLat + 0.027)), isFalse);
      expect(enDomicilio(t, marca(falsa: true)), isFalse); // ubicación falsa no cuenta
      t.direccion = 'Otra dirección';
      expect(t.domicilioUbicado, isFalse); // si cambia la dirección, hay que volver a ubicarla
    });

    test('Al mapa se le pregunta sin cruzamientos', () {
      expect(consultaMapa(trabajo()), 'Calle 60 450, Centro, Mérida, Yucatán, México');
      final viejo = trabajo()
        ..partes = null
        ..direccion = 'Calle 21 #300 x 20 y 22, Mérida';
      expect(consultaMapa(viejo), 'Calle 21 300, Mérida, Yucatán, México');
    });

    test('Las marcas se guardan y se leen', () {
      final t = trabajo()
        ..llegada = marca()
        ..salida = marca(falsa: true)
        ..marcasFotos['f1'] = marca(lat: 21.0);
      final copia = VisitaAgenda.fromJson(jsonDecode(jsonEncode(t.toJson())));
      expect(copia.llegada?.lat, domLat);
      expect(copia.salida?.falsa, isTrue);
      expect(copia.marcasFotos['f1']?.lat, 21.0);
      expect(copia.llegada?.hora, DateTime(2026, 10, 28, 10, 42));
    });

    test('El sello dice dirección, fecha y trabajo, sin coordenadas', () {
      final lineas = lineasSello(trabajo(), DateTime(2026, 10, 28, 10, 42));
      expect(lineas, [
        'Calle 60 #450 x 53 y 55, Col. Centro, Mérida',
        'Mié 28 oct 2026 · 10:42 a.m.',
        'Instalación · Carlos Mendoza · Equipo 1',
      ]);
      expect(fechaHoraSello(DateTime(2026, 10, 25, 0, 5)), 'Dom 25 oct 2026 · 12:05 a.m.');
    });

    testWidgets('El sello queda pegado en la foto', (tester) async {
      final original = img.encodeJpg(img.Image(width: 400, height: 300)..clear(img.ColorRgb8(255, 255, 255)));
      final sellada = await tester.runAsync(() => sellarFoto(original, lineas: ['Calle 60', 'Mié 28 oct'], etiqueta: 'En el domicilio'));
      final foto = img.decodeJpg(sellada!)!;
      expect((foto.width, foto.height), (400, 300));
      expect(foto.getPixel(5, 5).r, greaterThan(240)); // arriba sigue blanco
      expect(foto.getPixel(5, 295).r, lessThan(140)); // abajo, la franja oscura del sello
    });

    testWidgets('"Llegué" guarda hora y lugar, y ubica la dirección', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await tester.runAsync(storage.init);
      final engine = AppEngineService(storage: storage);
      engine.saveVisitaAgenda(trabajo());
      ubicador = UbicadorFijo(marca: marca(), domicilio: (domLat, domLng));
      await tester.pumpWidget(ChangeNotifierProvider<AppEngineService>.value(
        value: engine,
        child: MaterialApp(home: Scaffold(body: BotonLlegue(trabajo: engine.visitaPorId('e1')!))),
      ));

      await tester.tap(find.text('Llegué'));
      await tester.pumpAndSettle();
      expect(find.text('Llegaste a las 10:42 mañana'), findsOneWidget);
      final t = engine.visitaPorId('e1')!;
      expect(t.llegada?.lat, domLat);
      expect(t.domicilioUbicado, isTrue);
    });

    testWidgets('El administrador ve la evidencia y los avisos', (tester) async {
      final t = trabajo()
        ..domLat = domLat
        ..domLng = domLng
        ..domDireccion = 'Calle 60 #450 x 53 y 55, Col. Centro, Mérida'
        ..llegada = marca()
        ..salida = Marca(hora: DateTime(2026, 10, 28, 12, 12), lat: domLat, lng: domLng)
        ..fotos = ['f1']
        ..marcasFotos['f1'] = marca(lat: domLat + 0.027);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: EvidenciaTrabajo(trabajo: t)))));
      expect(find.text('Llegaron 10:42 mañana · Cobraron 12:12 tarde'), findsOneWidget);
      expect(find.text('1 h 30 min en el trabajo'), findsOneWidget);
      expect(find.text('Una foto se marcó a 3.0 km del domicilio'), findsOneWidget);
      expect(find.text('2 de 3 marcas en el domicilio'), findsOneWidget);

      t.llegada = marca(falsa: true);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: EvidenciaTrabajo(trabajo: t, key: UniqueKey())))));
      expect(find.text('Se usó una app para falsear la ubicación'), findsOneWidget);
    });
  });
}
