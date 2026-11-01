import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:autoscan/features/offers/domain/repositories/offers_repository.dart';
import 'package:autoscan/features/offers/presentation/controllers/offers_controller.dart';
import 'package:autoscan/features/offers/presentation/widgets/marketplace_offer_card.dart';
import 'package:autoscan/features/offers/presentation/widgets/save_alternative_dialog.dart';

class MarketplaceSearchPanel extends StatelessWidget {
  const MarketplaceSearchPanel({
    super.key,
    required this.repository,
    required this.code,
    this.model,
    this.year,
    this.vehicleId,
  });
  final OffersRepository repository;
  final String code;
  final String? model, vehicleId;
  final int? year;
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => OffersController(
      repository,
      code: code,
      model: model,
      year: year,
      vehicleId: vehicleId,
    )..initialize(),
    child: Consumer<OffersController>(
      builder: (context, state, _) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Repuestos en Mercado Libre',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Una falla puede tener distintas causas. Elige el componente que deseas cotizar después de revisar el vehículo.',
                    ),
                    const SizedBox(height: 16),
                    if (state.loadingComponents)
                      const LinearProgressIndicator()
                    else if (state.components.isNotEmpty)
                      DropdownButtonFormField<String>(
                        key: ValueKey('component-$code'),
                        initialValue: state.selectedComponent,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Componente a revisar',
                        ),
                        items: state.components
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: state.select,
                      )
                    else if (state.error == null)
                      const Text(
                        'Esta falla aún no tiene componentes asociados.',
                      ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const Key('search-marketplace'),
                      style: FilledButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                          state.selectedComponent == null || state.loading
                          ? null
                          : state.search,
                      icon: state.loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.travel_explore),
                      label: Text(
                        state.loading
                            ? 'Buscando ofertas…'
                            : 'Buscar en Mercado Libre',
                      ),
                    ),
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          state.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (!state.loadingComponents &&
                        state.components.isEmpty &&
                        state.error != null)
                      TextButton(
                        onPressed: state.initialize,
                        child: const Text('Reintentar componentes'),
                      ),
                    if (state.message != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(state.message!),
                      ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .secondary,
                      ),
                      onPressed: () => context.go('/saved-parts'),
                      icon: const Icon(Icons.bookmarks_outlined),
                      label: const Text('Ver alternativas guardadas'),
                    ),
                  ],
                ),
              ),
            ),
            if (state.searched && state.offers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Mercado Libre no devolvió ofertas para este componente y vehículo.',
                ),
              ),
            if (state.offers.any((offer) => offer.kind == 'catalog_product'))
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'La búsqueda de publicaciones está restringida. Estos resultados son referencias técnicas de catálogo, sin precio ni disponibilidad confirmada.',
                ),
              ),
            for (final offer in state.offers)
              MarketplaceOfferCard(
                offer: offer,
                saving: state.saving.contains(offer.token),
                saved: state.saved.contains(offer.token),
                onSave: () async {
                  final note = await showDialog<String>(
                    context: context,
                    builder: (_) => const SaveAlternativeDialog(),
                  );
                  if (note != null && context.mounted) {
                    await state.save(offer, note);
                  }
                },
              ),
          ],
        ),
      ),
    ),
  );
}
