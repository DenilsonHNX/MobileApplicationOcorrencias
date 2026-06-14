import 'package:flutter_test/flutter_test.dart';
import 'package:ocorrencias_app/main.dart';

void main() {
  testWidgets('App inicia sem erros', (WidgetTester tester) async {
    await tester.pumpWidget(const OcorrenciasApp());
    expect(find.byType(OcorrenciasApp), findsOneWidget);
  });
}
