import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:autoscan/features/diagnostic/presentation/controllers/diagnostic_detail_controller.dart';
import 'package:autoscan/features/offers/domain/repositories/offers_repository.dart';
import 'package:autoscan/features/offers/presentation/widgets/marketplace_search_panel.dart';

class DiagnosticPartsScreen extends StatelessWidget {
  const DiagnosticPartsScreen({super.key, required this.code});
  final String code;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<DiagnosticDetailController>();
    final detail = state.detail;
    final available =
        detail != null &&
        detail.vehicleId != null &&
        detail.modelId != null &&
        detail.year != null &&
        detail.observations.any((o) => o.code == code && o.description != null);
    return Scaffold(
      appBar: AppBar(
        title: Text('Alternativas para $code'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/diagnostic/${state.id}'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: state.loading
              ? const CircularProgressIndicator()
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (state.error != null) ...[
                      Text(state.error!),
                      TextButton(
                        onPressed: state.load,
                        child: const Text('Reintentar'),
                      ),
                    ],
                    if (detail != null && !available)
                      const Text(
                        'La falla no está catalogada o el vehículo no está disponible para tu perfil.',
                      ),
                    if (available) ...[
                      Text(
                        detail.label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      MarketplaceSearchPanel(
                        repository: context.read<OffersRepository>(),
                        code: code,
                        model: detail.modelId,
                        year: detail.year,
                        vehicleId: detail.vehicleId,
                        sessionId: detail.id,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
