import 'package:autoscan/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autoscan/features/team/domain/entities/workshop_invitation.dart';
import 'package:autoscan/features/team/domain/repositories/team_repository.dart';
import 'package:autoscan/features/team/presentation/views/team_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/session_fakes.dart';

class _TeamRepository implements TeamRepository {
  int loads = 0;
  String? invitedEmail;
  @override
  Future<List<WorkshopInvitation>> invitations() async {
    loads++;
    return [];
  }

  @override
  Future<String> invite(String email) async {
    invitedEmail = email;
    return 'http://localhost:8080/#/login?invitation=test';
  }

  @override
  Future<void> revoke(String id) async {}
}

void main() {
  for (final profile in ['propietario', 'mecanico']) {
    testWidgets('equipo respeta perfil $profile en pantalla estrecha', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _TeamRepository();
      final auth = AuthController(
        FakeAuthRepository()..result = testSession(role: profile),
        FakeSettingsRepository(),
      );

      await auth.login('fixture@example.test', 'fixture');
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>.value(value: auth),
            Provider<TeamRepository>.value(value: repository),
          ],
          child: const MaterialApp(home: TeamScreen()),
        ),
      );
      await tester.pumpAndSettle();
      if (profile == 'mecanico') {
        expect(repository.loads, 0);
        expect(find.byKey(const Key('invite-email')), findsNothing);
        expect(
          find.text(
            'Esta sección está disponible para el propietario del taller.',
          ),
          findsOneWidget,
        );
      } else {
        expect(repository.loads, 1);
        expect(find.text('Invita a un mecánico'), findsOneWidget);
        expect(find.byType(DropdownButtonFormField<String>), findsNothing);
        await tester.enterText(
          find.byKey(const Key('invite-email')),
          'tecnico@gmail.com',
        );
        await tester.ensureVisible(find.byKey(const Key('invite-create')));
        await tester.tap(find.byKey(const Key('invite-create')));
        await tester.pumpAndSettle();
        expect(repository.invitedEmail, 'tecnico@gmail.com');
        expect(find.text('Invitación lista para compartir'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      auth.dispose();
    });
  }
}
