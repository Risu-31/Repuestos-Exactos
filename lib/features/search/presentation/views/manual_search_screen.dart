import 'package:flutter/material.dart';


class ManualSearchScreen extends StatelessWidget {
  const ManualSearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Búsqueda Manual'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Identificar Vehículo',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingrese los parámetros exactos para buscar repuestos compatibles.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Campo VIN
            TextField(
              decoration: InputDecoration(
                labelText: 'Número de VIN (Chasis)',
                hintText: 'Ej. 1HGCM82633A000XXX',
                prefixIcon: const Icon(Icons.qr_code_scanner),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.cardColor,
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: Divider(color: theme.dividerColor)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('O buscar por modelo'),
                ),
                Expanded(child: Divider(color: theme.dividerColor)),
              ],
            ),
            const SizedBox(height: 24),

            // Dropdowns
            _buildDropdown(theme, 'Marca', 'Seleccione Marca', Icons.directions_car_outlined),
            const SizedBox(height: 16),
            _buildDropdown(theme, 'Modelo', 'Seleccione Modelo', Icons.layers_outlined),
            const SizedBox(height: 16),
            _buildDropdown(theme, 'Año', 'Seleccione Año', Icons.calendar_today_outlined),

            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {}, // Simular búsqueda en el futuro
              icon: const Icon(Icons.search),
              label: const Text('Buscar Repuestos Exactos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(ThemeData theme, String label, String hint, IconData icon) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: theme.cardColor,
      ),
      items: const [], // Dropdown vacío para prototipo visual
      onChanged: (value) {},
      hint: Text(hint),
    );
  }
}
