import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:autoscan/features/diagnostic/presentation/controllers/vehicle_registration_controller.dart';

class VehicleRegistrationDialog extends StatelessWidget {
  const VehicleRegistrationDialog({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<VehicleRegistrationController>();
    return AlertDialog(
      scrollable: true,
      title: const Text('Registrar vehículo'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (s.busy) const LinearProgressIndicator(),
            if (s.vin != null) ...[
              SelectableText('VIN leído: ${s.vin}'),
              const SizedBox(height: 12),
              const Text('Confirma marca, modelo y año antes de registrar.'),
              const SizedBox(height: 12),
            ],
            if (s.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(s.error!),
              ),
            DropdownButtonFormField<String>(
              initialValue: s.brand,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Marca'),
              items: s.brands
                  .map(
                    (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                  )
                  .toList(),
              onChanged: s.busy ? null : s.selectBrand,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('new-model-${s.brand}'),
              initialValue: s.model,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Modelo'),
              items: s.models
                  .map(
                    (m) => DropdownMenuItem(value: m.id, child: Text(m.name)),
                  )
                  .toList(),
              onChanged: s.busy ? null : s.selectModel,
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: !s.busy,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Año'),
              onChanged: (v) => s.year = v,
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: !s.busy,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Patente',
                hintText: 'AB1234 o BBBB12',
              ),
              onChanged: (v) => s.plate = v,
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: !s.busy,
              decoration: const InputDecoration(
                labelText: 'Motor',
                hintText: 'Por ejemplo: 1.6 gasolina',
              ),
              onChanged: (v) => s.engine = v,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: s.busy ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(foregroundColor: Colors.white),
          onPressed: s.busy
              ? null
              : () async {
                  final result = await s.save();
                  if (context.mounted && result != null) {
                    Navigator.pop(context, result);
                  }
                },
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}
