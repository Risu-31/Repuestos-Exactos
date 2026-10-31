import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:autoscan/features/auth/presentation/controllers/auth_controller.dart';

import '../../domain/repositories/team_repository.dart';
import '../controllers/team_controller.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});
  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  late final TeamController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TeamController(context.read<TeamRepository>());
    if (context.read<AuthController>().session?.isOwner == true) {
      _controller.load();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthController>().session?.isOwner != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Equipo del taller')),
        body: const Center(
          child: Text(
            'Esta sección está disponible para el propietario del taller.',
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Equipo del taller')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Invita a un mecánico',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Comparte una invitación para trabajar como mecánico en tu taller. La persona debe aceptarla con el mismo correo en Google. El enlace vence en 7 días.',
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              key: const Key('invite-email'),
                              controller: _email,
                              enabled: !c.busy,
                              keyboardType: TextInputType.emailAddress,
                              maxLength: 254,
                              decoration: const InputDecoration(
                                labelText: 'Correo de la persona',
                                prefixIcon: Icon(Icons.alternate_email),
                                border: OutlineInputBorder(),
                              ),
                              validator: (s) =>
                                  s == null ||
                                      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                          .hasMatch(s.trim())
                                  ? 'Ingresa un correo válido.'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            const ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.build_outlined),
                              title: Text('Mecánico'),
                              subtitle: Text(
                                'Trabajará con vehículos, diagnósticos y cotizaciones de este taller.',
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              key: const Key('invite-create'),
                              onPressed: c.busy
                                  ? null
                                  : () {
                                      if (_form.currentState?.validate() ??
                                          false) {
                                        c.invite(_email.text);
                                      }
                                    },
                              icon: const Icon(Icons.person_add_alt),
                              label: const Text('Generar invitación'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (c.busy)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: LinearProgressIndicator(),
                    ),
                  if (c.error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        c.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (c.invitationUrl case final String link)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Invitación lista para compartir',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Copia este enlace y envíalo a la persona por correo o por tu medio habitual. Se muestra únicamente al generarlo.',
                            ),
                            const SizedBox(height: 12),
                            SelectableText(link),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .onSurface,
                              ),
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: link),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Enlace copiado.'),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.copy_outlined),
                              label: const Text('Copiar enlace'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Invitaciones recientes',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Actualizar',
                        onPressed: c.busy ? null : c.load,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  if (c.invitations.isEmpty && !c.busy)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('Todavía no has creado invitaciones.'),
                    ),
                  ...c.invitations.map(
                    (i) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i.email,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${i.role == 'mecanico' ? 'Mecánico' : 'Invitación anterior'} · ${i.statusLabel}',
                            ),
                            if (i.status == 'pending')
                              Wrap(
                                spacing: 12,
                                children: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                    onPressed: c.busy
                                        ? null
                                        : () => c.invite(i.email),
                                    child: const Text('Generar nuevo enlace'),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                    onPressed: c.busy
                                        ? null
                                        : () => c.revoke(i.id),
                                    child: const Text('Revocar'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
