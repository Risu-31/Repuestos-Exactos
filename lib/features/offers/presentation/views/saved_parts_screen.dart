import 'package:flutter/material.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_environment.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/link.dart';
import 'package:autoscan/features/offers/presentation/controllers/saved_parts_controller.dart';

class SavedPartsScreen extends StatelessWidget {
  const SavedPartsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<SavedPartsController>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alternativas guardadas'),
        leading: IconButton(
          tooltip: 'Volver al historial',
          onPressed: () => context.go('/history'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar alternativas',
            onPressed: state.loading ? null : state.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: RefreshIndicator(
            onRefresh: state.refresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Text(
                  'Selecciones de tu taller',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Referencias elegidas por el equipo. Los precios y la disponibilidad deben consultarse nuevamente al cotizar.',
                ),
                const SizedBox(height: 20),
                if (state.loading)
                  const Center(child: CircularProgressIndicator())
                else if (state.error != null) ...[
                  Text(state.error!),
                  TextButton(
                    onPressed: state.refresh,
                    child: const Text('Reintentar'),
                  ),
                ] else if (state.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.bookmarks_outlined, size: 40),
                        SizedBox(height: 12),
                        Text(
                          'Aún no hay alternativas guardadas. Búscalas en Mercado Libre o eBay desde Búsqueda.',
                        ),
                      ],
                    ),
                  )
                else
                  for (final item in state.items)
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.code} · ${item.component}',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${item.provider.label}${item.environment == MarketplaceEnvironment.sandbox ? ' · Sandbox' : ''} · ${item.externalId}',
                            ),
                            if (item.environment ==
                                MarketplaceEnvironment.sandbox)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Referencia de prueba. No usar para una cotización comercial.',
                                ),
                              ),
                            if (item.vehicle != null) Text(item.vehicle!),
                            const SizedBox(height: 6),
                            Text(
                              'Guardó ${item.author} · ${item.createdAt.toLocal().day}/${item.createdAt.toLocal().month}/${item.createdAt.toLocal().year}',
                            ),
                            if (item.note.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(item.note),
                              ),
                            const SizedBox(height: 8),
                            if (item.kind == 'catalog_product')
                              const Text(
                                'Referencia técnica de catálogo, sin precio ni disponibilidad confirmada.',
                              ),
                            const Text(
                              'Compatibilidad pendiente de revisión técnica.',
                            ),
                            if (item.url != null)
                              Link(
                                uri: Uri.parse(item.url!),
                                target: LinkTarget.blank,
                                builder: (context, follow) => TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        theme.colorScheme.onSurface,
                                  ),
                                  onPressed: follow,
                                  icon: const Icon(Icons.open_in_new, size: 18),
                                  label: const Text(
                                    'Consultar publicación actual',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                if (state.pageError != null) Text(state.pageError!),
                if (state.nextOffset != null)
                  OutlinedButton(
                    onPressed: state.loadingMore ? null : state.loadMore,
                    child: Text(state.loadingMore ? 'Cargando…' : 'Cargar más'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
