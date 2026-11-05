import 'package:flutter/material.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_environment.dart';
import 'package:url_launcher/link.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_offer.dart';

class MarketplaceOfferCard extends StatelessWidget {
  const MarketplaceOfferCard({
    super.key,
    required this.offer,
    required this.saving,
    required this.saved,
    required this.onSave,
  });
  final MarketplaceOffer offer;
  final bool saving, saved;
  final VoidCallback onSave;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), date = offer.queriedAt.toLocal();
    final catalog = offer.kind == 'catalog_product';
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${offer.provider.label}${offer.environment == MarketplaceEnvironment.sandbox ? ' · Sandbox' : ''} · ${catalog ? 'Catálogo técnico' : 'Publicación'} · ${offer.externalId}',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Text(offer.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              catalog
                  ? 'Sin precio disponible'
                  : '${offer.currency} ${offer.price}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              catalog
                  ? 'Referencia de catálogo ${offer.catalogStatus == 'inactive' ? 'inactiva' : 'activa'}. No confirma una publicación disponible, precio ni stock.'
                  : offer.environment == MarketplaceEnvironment.sandbox
                  ? 'Precio de prueba. No es una cotización comercial.'
                  : 'Precio publicado, sin margen del taller. Envío e impuestos por confirmar.',
            ),
            const SizedBox(height: 6),
            Text(
              'Consultado el ${date.day}/${date.month}/${date.year} a las ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}.',
            ),
            const SizedBox(height: 8),
            const Text('Compatibilidad pendiente de revisión técnica.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (offer.url != null)
                  Link(
                    uri: Uri.parse(offer.url!),
                    target: LinkTarget.blank,
                    builder: (context, follow) => TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface,
                      ),
                      onPressed: follow,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Ver publicación'),
                    ),
                  ),
                FilledButton.tonalIcon(
                  onPressed: saving || saved ? null : onSave,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          saved
                              ? Icons.bookmark_added_outlined
                              : Icons.bookmark_add_outlined,
                        ),
                  label: Text(
                    saved
                        ? 'Guardada'
                        : saving
                        ? 'Guardando…'
                        : 'Guardar alternativa',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
