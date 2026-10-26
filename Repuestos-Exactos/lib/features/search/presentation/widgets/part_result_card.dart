import 'package:flutter/material.dart';
import 'package:autoscan/features/search/domain/entities/part_result.dart';

class PartResultCard extends StatelessWidget {
  const PartResultCard({super.key, required this.part});
  final PartResult part;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = switch (part.profile) {
      'genuino' => 'Genuino',
      'oem' => 'OEM',
      _ => 'Genérico',
    };
    final risk = switch (part.risk) {
      'bajo' => 'Bajo',
      'medio' => 'Medio',
      _ => 'Alto',
    };
    String group(String value) => value.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match[1]}.',
    );
    final accent = theme.brightness == Brightness.dark
        ? theme.colorScheme.secondary
        : theme.primaryColor;
    return Card(
      key: ValueKey(part.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              part.componentName,
              style: theme.textTheme.labelLarge?.copyWith(color: accent),
            ),
            const SizedBox(height: 8),
            Text(
              part.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text('${part.brand} · $profile'),
            const SizedBox(height: 6),
            Text(
              'Referencia: ${part.manufacturerCode}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            Text(
              '${part.currency} ${group(part.salePrice.toString())}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            const Text('Precio de referencia con margen del taller'),
            const SizedBox(height: 12),
            Text(
              'Durabilidad estimada: ${group(part.durability.toString())} km',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text('Riesgo de catálogo: $risk', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
