import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:autoscan/features/auth/presentation/controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _visible = false;

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthController>();
    await auth.login(_email.text, _password.text);
    if (mounted && auth.isAuthenticated) {
      _password.clear();
      TextInput.finishAutofillContext(shouldSave: false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.secondary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.build_circle_outlined,
                          color: colors.secondary,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Repuestos Exactos',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tu taller, conectado.',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ingresa para acceder a tu cuenta y a la información de tu taller.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Iniciar sesión',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                key: const Key('login-email'),
                                controller: _email,
                                enabled: !auth.busy,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                autocorrect: false,
                                decoration: const InputDecoration(
                                  labelText: 'Correo electrónico',
                                  prefixIcon: Icon(Icons.alternate_email),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    value == null || !value.trim().contains('@')
                                    ? 'Ingresa tu correo electrónico.'
                                    : null,
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                key: const Key('login-password'),
                                controller: _password,
                                enabled: !auth.busy,
                                obscureText: !_visible,
                                autocorrect: false,
                                enableSuggestions: false,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) {
                                  if (!auth.busy) _submit();
                                },
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    tooltip: _visible
                                        ? 'Ocultar contraseña'
                                        : 'Mostrar contraseña',
                                    onPressed: auth.busy
                                        ? null
                                        : () => setState(
                                            () => _visible = !_visible,
                                          ),
                                    icon: Icon(
                                      _visible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Ingresa tu contraseña.'
                                    : null,
                              ),
                              if (auth.errorMessage
                                  case final String message) ...[
                                const SizedBox(height: 18),
                                Semantics(
                                  liveRegion: true,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colors.errorContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      message,
                                      style: TextStyle(
                                        color: colors.onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              ElevatedButton(
                                key: const Key('login-submit'),
                                onPressed: auth.busy ? null : _submit,
                                child: auth.busy
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Ingresar'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Diagnóstico y cotización para tu equipo de trabajo.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
