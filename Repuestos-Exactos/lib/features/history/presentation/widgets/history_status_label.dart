import 'package:autoscan/features/history/domain/entities/history_status.dart';

String historyStatusLabel(HistoryStatus status) => switch (status) {
  HistoryStatus.pendiente => 'Pendiente',
  HistoryStatus.cotizado => 'Cotizado',
  HistoryStatus.completado => 'Completado',
  HistoryStatus.cancelado => 'Cancelado',
};
