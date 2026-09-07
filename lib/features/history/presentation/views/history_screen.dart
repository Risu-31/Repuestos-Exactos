import 'package:flutter/material.dart';


class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Datos simulados (Mocks)
    final historyData = [
      {'date': 'Hoy, 10:45 AM', 'vehicle': 'Toyota Hilux 2021', 'code': 'P0171', 'status': 'Cotizado'},
      {'date': 'Ayer, 16:30 PM', 'vehicle': 'Ford Ranger 2019', 'code': 'P0300', 'status': 'Pendiente'},
      {'date': '05 Sept, 09:15 AM', 'vehicle': 'Chevrolet Spark 2018', 'code': 'P0420', 'status': 'Completado'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Diagnósticos'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: historyData.length,
        itemBuilder: (context, index) {
          final item = historyData[index];
          final isCompleted = item['status'] == 'Completado';
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.withOpacity(0.1) : theme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle_outline : Icons.history,
                  color: isCompleted ? Colors.green : theme.primaryColor,
                ),
              ),
              title: Text(
                item['vehicle']!,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: theme.textTheme.bodyMedium?.color),
                      const SizedBox(width: 4),
                      Text(item['date']!),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Falla detectada: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(item['code']!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {}, // Futuro: Ver detalles del reporte
            ),
          );
        },
      ),
    );
  }
}
