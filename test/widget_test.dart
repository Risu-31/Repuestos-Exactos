import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:autoscan/core/theme/theme_provider.dart';
import 'package:autoscan/main.dart';

void main() {
  testWidgets('RepuestosExactosApp smoke test - carga pantalla de inicio', (WidgetTester tester) async {
    // Construir la aplicación envuelta en su ChangeNotifierProvider requerido
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const RepuestosExactosApp(),
      ),
    );

    // Esperar que se asienten las animaciones y el enrutador
    await tester.pumpAndSettle();

    // Verificar que el título de la aplicación se encuentre en pantalla
    expect(find.text('Repuestos Exactos'), findsOneWidget);

    // Verificar datos clave del dashboard del taller
    expect(find.text('Hola, Carlos'), findsOneWidget);
    expect(find.text('Taller Mecánico Central'), findsOneWidget);
  });
}
