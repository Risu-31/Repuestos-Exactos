import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_vehicle.dart';
import 'package:autoscan/features/diagnostic/domain/repositories/diagnostic_sessions_repository.dart';
import 'package:autoscan/features/search/domain/repositories/search_repository.dart';
import 'package:autoscan/features/diagnostic/presentation/controllers/vehicle_registration_controller.dart';
import 'package:autoscan/features/diagnostic/presentation/widgets/vehicle_registration_dialog.dart';
import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_fault.dart';

import 'dart:async';

import 'package:autoscan/features/diagnostic/presentation/widgets/vin_reading_card.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:autoscan/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autoscan/features/diagnostic/presentation/controllers/diagnostic_controller.dart';
import 'package:autoscan/features/diagnostic/presentation/widgets/diagnostic_results.dart';

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});
  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(context.read<DiagnosticController>().reset());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DiagnosticController>();
    final owner =
        context.watch<AuthController>().session?.role == 'propietario';
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Escáner OBD2')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'vLinker MC · Bluetooth clásico',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Empareja el adaptador con Windows, conéctalo al vehículo y pon el contacto. Después selecciona el mismo adaptador en el navegador. Esta lectura no borra fallas.',
              ),
              const SizedBox(height: 16),
              if (!state.supported)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Web Serial no está disponible. Usa Chrome de escritorio en localhost o HTTPS.',
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                ),
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      state.error!,
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey('scan-vehicle-${state.vehicle?.id}'),
                initialValue: state.vehicle?.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Vehículo del taller',
                  helperText: 'Opcional antes de leer; requerido para guardar.',
                ),
                items: state.vehicles
                    .map(
                      (v) => DropdownMenuItem(
                        value: v.id,
                        child: Text(v.label, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: state.vehicleLocked || state.loading
                    ? null
                    : state.selectVehicle,
              ),
              if (!state.vehicleLocked && !state.loading)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? colors.secondary
                          : colors.primary,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar vehículo'),
                    onPressed: () async {
                      final repository = context
                          .read<DiagnosticSessionsRepository>();
                      final catalog = context.read<SearchRepository>();
                      final added = await showDialog<DiagnosticVehicle>(
                        context: context,
                        builder: (_) => ChangeNotifierProvider(
                          create: (_) => VehicleRegistrationController(
                            catalog,
                            repository,
                            vin: state.scan?.vin,
                          )..load(),
                          child: const VehicleRegistrationDialog(),
                        ),
                      );
                      if (added != null && mounted) state.addVehicle(added);
                    },
                  ),
                ),
              if (!state.loading && state.vehicles.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No hay vehículos visibles. Registra o habilita el vehículo en tu taller antes de guardar un diagnóstico.',
                  ),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey('scan-device-${state.device?.id}'),
                initialValue: state.device?.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Adaptador registrado',
                ),
                items: state.devices
                    .map(
                      (d) => DropdownMenuItem(
                        value: d.id,
                        child: Text(d.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: state.locked || state.loading
                    ? null
                    : state.selectDevice,
              ),
              if (owner && !state.locked)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? colors.secondary
                          : colors.primary,
                    ),
                    onPressed: state.loading ? null : state.registerDevice,
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar vLinker MC en el taller'),
                  ),
                ),
              if (!owner && !state.loading && state.devices.isEmpty)
                const Text(
                  'El propietario debe registrar el adaptador en el taller.',
                ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: state.mileage,
                enabled: !state.vehicleLocked && !state.loading,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kilometraje actual',
                ),
                onChanged: (v) => state.mileage = v,
              ),
              const SizedBox(height: 20),
              if (!state.connected && state.scan == null)
                FilledButton.icon(
                  style: FilledButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: state.supported && !state.busy && !state.loading
                      ? state.connect
                      : null,
                  icon: const Icon(Icons.bluetooth_connected),
                  label: const Text('Conectar vLinker MC'),
                ),
              if (state.connected && state.scan == null)
                FilledButton.icon(
                  style: FilledButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: state.busy ? null : state.read,
                  icon: const Icon(Icons.car_repair),
                  label: const Text('Leer fallas del vehículo'),
                ),
              if (state.busy)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 12),
              Text(state.progress),
              if (state.busy || state.connected || state.scan != null)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? colors.secondary
                        : colors.primary,
                  ),
                  onPressed: state.saving ? null : state.reset,
                  child: Text(
                    state.busy
                        ? 'Cancelar lectura'
                        : 'Desconectar / nuevo escaneo',
                  ),
                ),
              if (state.scan != null) ...[
                const SizedBox(height: 20),
                VinReadingCard(
                  vin: state.scan!.vin,
                  status: state.scan!.vinStatus,
                ),
                if (state.vinNotice != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(state.vinNotice!),
                  ),
                if (state.scan!.vin != null && state.vehicle?.vin == null)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Al guardar, el VIN leído quedará asociado al vehículo seleccionado. Comprueba que sea el mismo auto.',
                    ),
                  ),
                DiagnosticResults(
                  observations:
                      state.saved?.observations ??
                      state.scan!.observations
                          .map(
                            (o) => DiagnosticFault(
                              code: o.code,
                              ecu: o.ecu,
                              kind: o.kind,
                            ),
                          )
                          .toList(),
                  services: state.scan!.services,
                  onFindParts: state.saved == null
                      ? null
                      : (code) => context.push(
                          '/diagnostic-parts/${state.saved!.id}?code=$code',
                        ),
                ),
                const SizedBox(height: 16),
                if (state.saved == null)
                  FilledButton.icon(
                    onPressed: state.saving ? null : state.save,
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      state.saving ? 'Guardando…' : 'Guardar diagnóstico',
                    ),
                  ),
                if (state.saved != null)
                  OutlinedButton.icon(
                    onPressed: () => context.go('/history'),
                    icon: const Icon(Icons.history),
                    label: const Text('Ver historial del taller'),
                  ),
              ],
              if (state.error != null && state.scan == null)
                TextButton(
                  onPressed: state.loading || state.busy ? null : state.load,
                  child: const Text('Actualizar vehículos y adaptadores'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
