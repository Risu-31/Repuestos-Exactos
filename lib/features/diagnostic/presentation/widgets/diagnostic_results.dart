import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_fault.dart';
import 'package:flutter/material.dart';

class DiagnosticResults extends StatelessWidget {
  const DiagnosticResults({
    super.key,
    required this.observations,
    required this.services,
    this.onFindParts,
  });
  final List<DiagnosticFault> observations;
  final Map<String, String> services;
  final void Function(String)? onFindParts;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final codes = observations.map((o) => o.code).toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${codes.length} código(s) · ${observations.length} observación(es)',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'La lectura OBD2 orienta la revisión del técnico; no identifica por sí sola la pieza defectuosa.',
        ),
        if (services.values.any(
          (s) => s == 'no_data' || s == 'unsupported' || s == 'partial',
        ))
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Algunos servicios no respondieron o no están soportados. Consulta el alcance de la lectura.',
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: services.entries
              .map(
                (s) => Chip(
                  label: Text(
                    '${s.key}: ${{'ok': 'leído', 'empty': 'sin códigos', 'no_data': 'sin respuesta', 'unsupported': 'no soportado'}[s.value] ?? s.value}',
                  ),
                ),
              )
              .toList(),
        ),
        if (observations.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'No se encontraron códigos en los servicios leídos. Esto no descarta fallas mecánicas.',
            ),
          ),
        for (final item in observations)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.code, style: theme.textTheme.titleLarge),
                  Text(
                    item.description ??
                        (onFindParts == null
                            ? 'Código leído. Guarda para consultar el catálogo.'
                            : 'Código no catalogado: requiere revisión técnica.'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ECU: ${item.ecu ?? 'No registrada'} · ${{'stored': 'Almacenado', 'pending': 'Pendiente', 'permanent': 'Permanente'}[item.kind] ?? 'Registro previo'}',
                  ),
                  if (onFindParts != null && item.description != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: theme.brightness == Brightness.dark
                            ? theme.colorScheme.secondary
                            : theme.primaryColor,
                      ),
                      onPressed: () => onFindParts!(item.code),
                      icon: const Icon(Icons.search),
                      label: const Text('Buscar alternativas para esta falla'),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
