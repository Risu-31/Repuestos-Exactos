import 'package:flutter/material.dart';
import 'package:autoscan/features/diagnostic/presentation/widgets/vin_reading_card.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:autoscan/features/diagnostic/presentation/controllers/diagnostic_detail_controller.dart';
import 'package:autoscan/features/diagnostic/presentation/widgets/diagnostic_results.dart';

class DiagnosticDetailScreen extends StatelessWidget {
  const DiagnosticDetailScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<DiagnosticDetailController>();
    final detail = state.detail;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del diagnóstico'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/history'),
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
                    if (detail != null) ...[
                      Text(
                        detail.label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      if (detail.vin != null) VinReadingCard(vin: detail.vin),
                      DiagnosticResults(
                        observations: detail.observations,
                        services: detail.services,
                        onFindParts: detail.vehicleId == null
                            ? null
                            : (code) => context.push(
                                '/diagnostic-parts/${detail.id}?code=$code',
                              ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
