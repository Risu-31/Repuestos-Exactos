import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:autoscan/features/history/domain/entities/history_status.dart';
import 'package:autoscan/features/history/presentation/controllers/history_controller.dart';
import 'package:autoscan/features/history/presentation/widgets/history_entry_card.dart';
import 'package:autoscan/features/history/presentation/widgets/history_status_label.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HistoryController>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de diagnósticos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar historial',
            onPressed: controller.loading ? null : controller.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diagnósticos de tu taller',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Consulta las atenciones registradas y su estado.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: const Text('Todos'),
                              selected: controller.status == null,
                              onSelected: (_) => controller.filter(null),
                            ),
                          ),
                          for (final status in HistoryStatus.values)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(historyStatusLabel(status)),
                                selected: controller.status == status,
                                onSelected: (_) => controller.filter(status),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: ListView(
                    key: const Key('history-list'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    children: [
                      if (controller.loading)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (controller.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Icon(Icons.cloud_off_outlined, size: 40),
                              const SizedBox(height: 16),
                              Text(
                                controller.errorMessage!,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: controller.refresh,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      else if (controller.items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Icon(Icons.history_outlined, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Sin diagnósticos',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                controller.status == null
                                    ? 'Las atenciones de tu taller aparecerán aquí.'
                                    : 'No hay diagnósticos con este estado.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else ...[
                        for (final item in controller.items)
                          HistoryEntryCard(entry: item),
                        if (controller.pageError != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              controller.pageError!,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (controller.hasMore)
                          Center(
                            child: OutlinedButton.icon(
                              key: const Key('history-load-more'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    theme.brightness == Brightness.dark
                                    ? theme.colorScheme.secondary
                                    : theme.primaryColor,
                              ),
                              onPressed: controller.loadingMore
                                  ? null
                                  : controller.loadMore,
                              icon: controller.loadingMore
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.expand_more),
                              label: Text(
                                controller.loadingMore
                                    ? 'Cargando…'
                                    : controller.pageError == null
                                    ? 'Cargar más'
                                    : 'Reintentar carga',
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
