import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:autoscan/features/search/presentation/controllers/catalog_search_controller.dart';

class SearchVehicleFilters extends StatefulWidget {
  const SearchVehicleFilters({super.key});
  @override
  State<SearchVehicleFilters> createState() => _SearchVehicleFiltersState();
}

class _SearchVehicleFiltersState extends State<SearchVehicleFilters> {
  final _vin = TextEditingController();
  final _year = TextEditingController();
  @override
  void dispose() {
    _vin.dispose();
    _year.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CatalogSearchController>();
    final theme = Theme.of(context);
    final accent = theme.brightness == Brightness.dark
        ? theme.colorScheme.secondary
        : theme.primaryColor;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '2. Vehículo (opcional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona modelo y año para filtrar la compatibilidad.',
            ),
            if (state.canLookupVehicle) ...[
              const SizedBox(height: 16),
              TextField(
                key: const Key('search-vin'),
                controller: _vin,
                maxLength: 17,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'VIN registrado en tu taller',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                onChanged: (_) {
                  state.changeVin();
                  if (state.modelId == null) _year.clear();
                },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                key: const Key('search-vin-submit'),
                style: TextButton.styleFrom(foregroundColor: accent),
                onPressed:
                    state.loadingVin ||
                        state.loadingBrands ||
                        state.brandError != null
                    ? null
                    : () async {
                        await state.lookupVin(_vin.text);
                        if (mounted) _year.text = state.year?.toString() ?? '';
                      },
                icon: state.loadingVin
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.manage_search),
                label: Text(
                  state.loadingVin
                      ? 'Buscando vehículo…'
                      : 'Identificar por VIN',
                ),
              ),
              if (state.vinMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(state.vinMessage!),
                ),
            ],
            const SizedBox(height: 16),
            if (state.loadingBrands) const LinearProgressIndicator(),
            if (state.brandError != null) ...[
              Text(state.brandError!),
              TextButton(
                onPressed: state.initialize,
                style: TextButton.styleFrom(foregroundColor: accent),
                child: const Text('Reintentar catálogo'),
              ),
            ],
            DropdownButtonFormField<String>(
              key: ValueKey('brand-${state.brandId}'),
              initialValue: state.brandId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Marca',
                border: OutlineInputBorder(),
              ),
              items: state.brands
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name),
                    ),
                  )
                  .toList(),
              onChanged: state.loadingBrands || state.loadingVin
                  ? null
                  : (id) {
                      _year.clear();
                      state.selectBrand(id);
                    },
            ),
            const SizedBox(height: 14),
            if (state.loadingModels) const LinearProgressIndicator(),
            if (state.modelError != null) ...[
              Text(state.modelError!),
              TextButton(
                onPressed: () => state.selectBrand(state.brandId),
                style: TextButton.styleFrom(foregroundColor: accent),
                child: const Text('Reintentar modelos'),
              ),
            ],
            DropdownButtonFormField<String>(
              key: ValueKey('model-${state.modelId}-${state.brandId}'),
              initialValue: state.modelId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Modelo',
                border: OutlineInputBorder(),
              ),
              items: state.models
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name),
                    ),
                  )
                  .toList(),
              onChanged:
                  state.loadingModels ||
                      state.loadingVin ||
                      state.models.isEmpty
                  ? null
                  : (id) {
                      _year.clear();
                      state.selectModel(id);
                    },
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('search-year'),
              controller: _year,
              enabled: state.modelId != null && !state.loadingVin,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(
                labelText: 'Año',
                hintText: '1981–2100',
                border: OutlineInputBorder(),
              ),
              onChanged: state.selectYear,
            ),
            if (state.brandId != null || state.loadingVin) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  _vin.clear();
                  _year.clear();
                  state.selectBrand(null);
                },
                style: TextButton.styleFrom(foregroundColor: accent),
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Limpiar filtro de vehículo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
