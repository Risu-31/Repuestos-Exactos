import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:autoscan/core/theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sección Perfil
          Text('Perfil del Mecánico', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: const Text('Carlos Mendoza'),
              subtitle: const Text('Taller Mecánico Central'),
              trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: (){}),
            ),
          ),
          const SizedBox(height: 24),

          // Sección Preferencias
          Text('Preferencias de Aplicación', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Modo Oscuro (Premium)'),
                  subtitle: const Text('Optimizado para entornos de taller y bajo consumo'),
                  secondary: Icon(themeProvider.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Conexión OBD2 por defecto'),
                  subtitle: const Text('Bluetooth LE'),
                  leading: const Icon(Icons.bluetooth),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sección Soporte
          Text('Soporte y Ayuda', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Manual de Usuario'),
                  leading: const Icon(Icons.menu_book_outlined),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Contactar Soporte'),
                  leading: const Icon(Icons.help_outline),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
