import 'package:flutter/material.dart';
import 'package:autoscan/features/history/domain/entities/history_entry.dart';
import 'package:autoscan/features/history/domain/entities/history_status.dart';
import 'package:autoscan/features/history/presentation/widgets/history_status_label.dart';

class HistoryEntryCard extends StatelessWidget {
  const HistoryEntryCard({super.key, required this.entry});
  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = entry.startedAt.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    final dateLabel =
        '${two(date.day)}/${two(date.month)}/${date.year} · ${two(date.hour)}:${two(date.minute)}';
    final vehicle = entry.vehicleId == null
        ? 'Vehículo no disponible'
        : [
            entry.brand,
            entry.model,
            entry.year?.toString(),
          ].whereType<String>().join(' ');
    final tone = switch (entry.status) {
      HistoryStatus.pendiente => const Color(0xFFB7791F),
      HistoryStatus.cotizado => const Color(0xFF4086BB),
      HistoryStatus.completado => const Color(0xFF2A9279),
      HistoryStatus.cancelado => const Color(0xFFB7697C),
    };
    final statusForeground = theme.brightness == Brightness.dark
        ? Color.lerp(tone, Colors.white, 0.4)!
        : Color.lerp(tone, Colors.black, 0.25)!;
    return Card(
      key: ValueKey(entry.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  vehicle.isEmpty ? 'Vehículo' : vehicle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    historyStatusLabel(entry.status),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: statusForeground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (entry.plate != null) ...[
              const SizedBox(height: 6),
              Text('Patente: ${entry.plate}'),
            ],
            const SizedBox(height: 12),
            Text(dateLabel, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              '${entry.faultCount} ${entry.faultCount == 1 ? 'falla registrada' : 'fallas registradas'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${entry.userName} · ${entry.method == 'manual' ? 'Ingreso manual' : 'OBD Bluetooth'}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
