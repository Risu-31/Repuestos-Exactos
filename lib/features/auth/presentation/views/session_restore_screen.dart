import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:autoscan/features/auth/presentation/controllers/auth_controller.dart';

class SessionRestoreScreen extends StatelessWidget {
  const SessionRestoreScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Repuestos Exactos',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                if (auth.restoring) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Recuperando tu sesión…'),
                ] else ...[
                  Text(
                    auth.restoreError ?? 'Vuelve a ingresar para continuar.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: auth.restoreSession,
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reintentar'),
                  ),
                  TextButton(
                    onPressed: auth.continueToLogin,
                    child: const Text('Ir al inicio de sesión'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
