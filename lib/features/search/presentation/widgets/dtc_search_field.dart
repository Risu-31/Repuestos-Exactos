import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:autoscan/features/search/presentation/controllers/catalog_search_controller.dart';

class DtcSearchField extends StatefulWidget {
  const DtcSearchField({super.key});
  @override
  State<DtcSearchField> createState() => _DtcSearchFieldState();
}

class _DtcSearchFieldState extends State<DtcSearchField> {
  final _query = TextEditingController();
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CatalogSearchController>();
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Código de falla',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Busca un DTC completo o un prefijo y selecciona una coincidencia.',
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('search-dtc-query'),
              controller: _query,
              maxLength: 5,
              textCapitalization: TextCapitalization.characters,
              onChanged: state.changeCodeQuery,
              onSubmitted: (_) => state.searchCodes(),
              decoration: InputDecoration(
                labelText: 'Código DTC',
                hintText: 'Ej. P0300 o P03',
                border: const OutlineInputBorder(),
                counterText: '',
                suffixIcon: IconButton(
                  tooltip: 'Buscar códigos',
                  key: const Key('search-dtc-submit'),
                  onPressed: state.loadingCodes ? null : state.searchCodes,
                  icon: state.loadingCodes
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ),
            ),
            if (state.codeError != null) ...[
              const SizedBox(height: 12),
              Text(state.codeError!, semanticsLabel: state.codeError),
            ],
            if (state.codes.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey('dtc-${state.selectedCode?.code}'),
                initialValue: state.selectedCode?.code,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Seleccionar falla',
                  border: OutlineInputBorder(),
                ),
                items: state.codes
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.code,
                        child: Text(
                          '${item.code} · ${item.description}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: state.selectCode,
              ),
              if (state.selectedCode != null) ...[
                const SizedBox(height: 10),
                Text(state.selectedCode!.description),
              ],
            ],
            if (state.codesHaveMore && state.codes.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Hay más coincidencias. Escribe un prefijo más específico.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
