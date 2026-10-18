import 'support/search_fakes.dart';

import 'package:autoscan/features/history/domain/entities/history_page.dart';

import 'support/history_fakes.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/core/theme/theme_provider.dart';
import 'package:autoscan/main.dart';

import 'support/session_fakes.dart';

void main() {
  testWidgets(
    'login gates navigation, shows real identity and supports logout',
    (tester) async {
      final auth = FakeAuthRepository();
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          child: RepuestosExactosApp(
            authRepository: auth,
            settingsRepository: FakeSettingsRepository(),
            searchRepository: FakeSearchRepository(),
            historyRepository: FakeHistoryRepository()
              ..handler = (_, _) async =>
                  HistoryPage(items: [historyEntry('from-api')]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Hola, Carlos'), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('login-submit')));
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();
      expect(auth.loginCalls, 0);
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'admin@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        'test-password',
      );
      await tester.ensureVisible(find.byKey(const Key('login-submit')));
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Hola, Carla Fuentes'), findsOneWidget);
      expect(find.text('Taller Los Aromos'), findsOneWidget);
      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();
      expect(find.text('Toyota Yaris 2018'), findsOneWidget);
      expect(find.text('2 fallas registradas'), findsOneWidget);
      await tester.tap(find.text('Búsqueda'));
      await tester.pumpAndSettle();
      expect(find.text('Búsqueda de repuestos'), findsOneWidget);
      await tester.tap(find.text('Ajustes'));
      await tester.pumpAndSettle();
      expect(find.text('Carla Fuentes'), findsOneWidget);
      expect(find.text('Taller Los Aromos'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('logout-button')),
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const Key('logout-button')));
      await tester.pumpAndSettle();
      expect(auth.logoutCalls, 1);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Taller Los Aromos'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'login presents service failures without navigating into the app',
    (tester) async {
      final auth = FakeAuthRepository()
        ..loginError = const AppFailure('Correo o contraseña incorrectos.');
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          child: RepuestosExactosApp(
            authRepository: auth,
            settingsRepository: FakeSettingsRepository(),
            searchRepository: FakeSearchRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'admin@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        'test-password',
      );
      await tester.ensureVisible(find.byKey(const Key('login-submit')));
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
