import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:autoscan/core/theme/theme_provider.dart';
import 'package:autoscan/features/auth/presentation/controllers/auth_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final themeProvider = context.watch<ThemeProvider>();
    final session = auth.session;
    final workshop = auth.workshop;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Tu cuenta', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(session?.name ?? ''),
              subtitle: Text(session?.roleLabel ?? ''),
            ),
          ),
          const SizedBox(height: 24),
          Text('Tu taller', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          if (auth.loadingWorkshop)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 16),
                    Text('Cargando información…'),
                  ],
                ),
              ),
            ),
          if (auth.workshopError case final String message)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: auth.refreshWorkshop,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          if (workshop != null && !auth.loadingWorkshop)
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.storefront_outlined),
                    title: Text(workshop.name),
                    subtitle: const Text('Taller de tu sesión'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Moneda'),
                    trailing: Text(workshop.currency),
                  ),
                  ListTile(
                    title: const Text('Margen de cotización'),
                    trailing: Text(
                      '${workshop.marginPercent.toStringAsFixed(2)} %',
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Text('Preferencias', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              title: const Text('Modo oscuro'),
              subtitle: const Text(
                'Apariencia de esta sesión en el dispositivo',
              ),
              secondary: Icon(
                themeProvider.isDarkMode
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
              ),
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            key: const Key('logout-button'),
            onPressed: auth.busy ? null : auth.logout,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
