import 'package:flutter_test/flutter_test.dart';
import 'package:portones_movil/main.dart';
import 'package:portones_movil/services/storage_service.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    final storage = StorageService();
    await tester.pumpWidget(PortonesApp(storageService: storage));
    expect(find.text('AY OY'), findsAtLeastNWidgets(1));
    expect(find.text('Herrería Artística en General'), findsAtLeastNWidgets(1));
  });
}
