import 'package:flutter/material.dart';

import 'package:autoscan/data/models/diagnostic.dart';

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({Key? key}) : super(key: key);

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  String _status = 'connecting'; // connecting, scanning, completed
  DiagnosticReport? _report;

  @override
  void initState() {
    super.initState();
    _simulateScan();
  }

  Future<void> _simulateScan() async {
    // Simular conexión Bluetooth
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _status = 'scanning');

    // Simular lectura OBD2
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _status = 'completed';
        _report = DiagnosticReport(
          code: 'P0171',
          description: 'Sistema muy pobre (Banco 1)',
          system: 'Inyección de Combustible',
          partOptions: [
            PartOption(
              type: PartType.genuino,
              brand: 'Toyota Original',
              price: 185.00,
              estimatedLife: '80,000 km',
              risk: PartRisk.bajo,
            ),
            PartOption(
              type: PartType.oem,
              brand: 'Denso',
              price: 95.00,
              estimatedLife: '60,000 km',
              risk: PartRisk.bajo,
            ),
            PartOption(
              type: PartType.alternativo,
              brand: 'Generic AutoParts',
              price: 35.00,
              estimatedLife: '15,000 km',
              risk: PartRisk.alto,
            ),
          ],
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner OBD2'),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_status == 'connecting') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Conectando al puerto OBD2...',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Asegúrese de que el motor esté encendido',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_status == 'scanning') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: theme.primaryColor),
            const SizedBox(height: 24),
            Text(
              'Leyendo códigos de falla (DTC)...',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
        ),
      );
    }

    if (_status == 'completed' && _report != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta de Código de Error
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 32),
                      const SizedBox(width: 16),
                      Text(
                        _report!.code,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _report!.description,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text('Sistema: ${_report!.system}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Matriz de Cotización',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Matriz Comparativa
            ..._report!.partOptions.map((opt) => _PartOptionCard(option: opt)).toList(),
          ],
        ),
      );
    }

    return const SizedBox();
  }
}

class _PartOptionCard extends StatelessWidget {
  final PartOption option;

  const _PartOptionCard({required this.option});

  Color _getRiskColor() {
    switch (option.risk) {
      case PartRisk.bajo:
        return Colors.green;
      case PartRisk.medio:
        return Colors.orange;
      case PartRisk.alto:
        return Colors.red;
    }
  }

  String _getTypeString() {
    switch (option.type) {
      case PartType.genuino:
        return 'GENUINO';
      case PartType.oem:
        return 'OEM';
      case PartType.alternativo:
        return 'ALTERNATIVO';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riskColor = _getRiskColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  option.brand,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${option.price.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTypeString(),
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 16, color: theme.textTheme.bodyMedium?.color),
                const SizedBox(width: 4),
                Text(option.estimatedLife),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.gpp_bad_outlined, size: 14, color: riskColor),
                      const SizedBox(width: 4),
                      Text(
                        'Riesgo ${option.risk.name}',
                        style: TextStyle(color: riskColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
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
