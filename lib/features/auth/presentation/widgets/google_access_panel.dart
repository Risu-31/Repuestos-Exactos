import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/repositories/google_auth_repository.dart';
import '../controllers/auth_controller.dart';
import '../controllers/google_auth_controller.dart';
import 'google_button.dart';

class GoogleAccessPanel extends StatefulWidget {
  const GoogleAccessPanel({super.key, this.invitation, this.controller});
  final GoogleAuthController? controller;
  final String? invitation;
  @override
  State<GoogleAccessPanel> createState() => _GoogleAccessPanelState();
}

class _GoogleAccessPanelState extends State<GoogleAccessPanel> {
  GoogleAuthController? _controller;
  final _workshop = TextEditingController();
  final _password = TextEditingController();
  final _invitation = TextEditingController();
  @override
  void initState() {
    super.initState();
    _invitation.text = widget.invitation ?? '';
    if (widget.controller != null) {
      _controller = widget.controller;
      return;
    }
    final repository = context.read<GoogleAuthRepository?>();
    if (repository != null) {
      _controller = GoogleAuthController(
        repository,
        context.read<AuthController>(),
      )..prepare();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller?.dispose();
    _workshop.dispose();
    _password.dispose();
    _invitation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final pending = c.pending;
        final colors = Theme.of(context).colorScheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('o continúa con Google'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            if (c.busy) const LinearProgressIndicator(),
            if (!c.busy && !c.configured && c.error == null)
              const Text(
                'El ingreso con Google estará disponible próximamente. Usa tu correo y contraseña.',
              ),
            if (c.nonce != null && c.clientId != null)
              Center(
                child: GoogleButton(
                  key: ValueKey(c.nonce),
                  clientId: c.clientId!,
                  nonce: c.nonce!,
                  onCredential: c.authenticate,
                  onError: c.sdkError,
                ),
              ),
            if (pending != null) ...[
              Text(
                'Hola, ${pending.name}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(pending.email ?? ''),
              const SizedBox(height: 16),
              if (pending.requiresLink) ...[
                const Text(
                  'Ya tienes una cuenta. Confirma tu contraseña actual para vincularla con Google y conservar tu taller y permisos.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  enabled: !c.busy,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña actual',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: c.busy
                      ? null
                      : () async {
                          await c.complete('link', password: _password.text);
                          _password.clear();
                        },
                  child: const Text('Vincular mi cuenta'),
                ),
              ] else if (!pending.canRegister) ...[
                const Text(
                  'Para registrar un taller o aceptar una invitación, continúa con una cuenta Gmail o Google Workspace.',
                ),
              ] else ...[
                const Text(
                  'Si eres propietario, registra tu taller. Si eres mecánico, acepta la invitación de su propietario para incorporarte.',
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('google-workshop-name'),
                  controller: _workshop,
                  enabled: !c.busy,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de tu nuevo taller',
                    prefixIcon: Icon(Icons.storefront_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                ElevatedButton.icon(
                  key: const Key('google-register-workshop'),
                  onPressed: c.busy
                      ? null
                      : () => c.complete(
                          'register',
                          workshopName: _workshop.text.trim(),
                        ),
                  icon: const Icon(Icons.add_business_outlined),
                  label: const Text('Crear mi taller'),
                ),
                const SizedBox(height: 20),
                const Text('Soy mecánico: tengo una invitación'),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('google-invitation'),
                  controller: _invitation,
                  enabled: !c.busy,
                  decoration: const InputDecoration(
                    labelText: 'Código o enlace de invitación',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: c.busy
                      ? null
                      : () {
                          final value = _invitation.text.trim();
                          final uri = Uri.tryParse(value);
                          String token = value;
                          if (uri != null && uri.hasFragment) {
                            token =
                                Uri.tryParse(uri.fragment)
                                    ?.queryParameters['invitation'] ??
                                value;
                          }
                          c.complete('accept', invitationToken: token);
                        },
                  icon: const Icon(Icons.group_add_outlined),
                  label: const Text('Aceptar invitación'),
                ),
              ],
            ],
            if (c.error != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    c.error!,
                    style: TextStyle(color: colors.onErrorContainer),
                  ),
                ),
              ),
            ],
            if (!c.busy && (pending != null || c.error != null))
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: c.prepare,
                child: const Text('Volver a intentar con Google'),
              ),
          ],
        );
      },
    );
  }
}
