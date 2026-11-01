import 'package:flutter/material.dart';

class VinReadingCard extends StatelessWidget {
  const VinReadingCard({super.key, required this.vin, this.status});
  final String? vin;
  final String? status;
  @override
  Widget build(BuildContext context) {
    final message = vin != null
        ? status == null
              ? 'VIN registrado del vehículo'
              : 'VIN leído desde el vehículo'
        : 'VIN no disponible. Puedes registrar las fallas seleccionando el vehículo manualmente.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fingerprint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            if (vin != null) ...[
              const SizedBox(height: 8),
              SelectableText(vin!),
            ],
            if (status == 'invalid_or_incomplete') ...[
              const SizedBox(height: 8),
              const Text(
                'La identificación quedó incompleta o no fue válida. Las fallas leídas se conservan.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
