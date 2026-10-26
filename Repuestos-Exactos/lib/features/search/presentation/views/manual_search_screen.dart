import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:autoscan/features/search/presentation/controllers/catalog_search_controller.dart';
import 'package:autoscan/features/search/presentation/widgets/dtc_search_field.dart';
import 'package:autoscan/features/search/presentation/widgets/search_vehicle_filters.dart';
import 'package:autoscan/features/search/presentation/widgets/part_result_card.dart';

class ManualSearchScreen extends StatelessWidget {
  const ManualSearchScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CatalogSearchController>();
    final theme = Theme.of(context);
    final accent = theme.brightness == Brightness.dark
        ? theme.colorScheme.secondary
        : theme.primaryColor;
    return Scaffold(
      appBar: AppBar(title: const Text('Búsqueda de repuestos')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: CustomScrollView(
            key: const Key('search-list'),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverList.list(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(4, 0, 4, 16),
                      child: Text(
                        'Encuentra alternativas del catálogo a partir de una falla registrada.',
                      ),
                    ),
                    const DtcSearchField(),
                    const SizedBox(height: 12),
                    const SearchVehicleFilters(),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      key: const Key('search-parts-submit'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed:
                          state.loadingParts ||
                              state.loadingModels ||
                              state.loadingVin
                          ? null
                          : state.searchParts,
                      icon: state.loadingParts
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.search),
                      label: Text(
                        state.loadingParts
                            ? 'Buscando repuestos…'
                            : 'Buscar repuestos',
                      ),
                    ),
                    if (state.partsError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(state.partsError!),
                            TextButton(
                              onPressed: state.searchParts,
                              style: TextButton.styleFrom(
                                foregroundColor: accent,
                              ),
                              child: const Text('Reintentar búsqueda'),
                            ),
                          ],
                        ),
                      ),
                    if (state.searched) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Resultados para ${state.selectedCode?.code}',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.modelId == null
                            ? 'Catálogo general: la compatibilidad con tu vehículo aún no está filtrada.'
                            : 'Compatibilidad filtrada por modelo y año.',
                      ),
                      const SizedBox(height: 16),
                      if (state.parts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(Icons.search_off_outlined, size: 40),
                              SizedBox(height: 12),
                              Text(
                                'Sin repuestos disponibles para estos filtros.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: state.parts.length,
                  itemBuilder: (_, index) =>
                      PartResultCard(part: state.parts[index]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                sliver: SliverList.list(
                  children: [
                    if (state.pageError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(state.pageError!),
                      ),
                    if (state.hasMore)
                      Center(
                        child: OutlinedButton.icon(
                          key: const Key('search-load-more'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accent,
                          ),
                          onPressed: state.loadingMore ? null : state.loadMore,
                          icon: state.loadingMore
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more),
                          label: Text(
                            state.loadingMore
                                ? 'Cargando…'
                                : state.pageError == null
                                ? 'Cargar más'
                                : 'Reintentar carga',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
