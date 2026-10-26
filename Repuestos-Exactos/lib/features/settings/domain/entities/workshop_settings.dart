class WorkshopSettings {
  const WorkshopSettings({
    required this.id,
    required this.name,
    required this.currency,
    required this.theme,
    required this.marginPercent,
    required this.retentionYears,
  });
  final String id;
  final String name;
  final String currency;
  final String theme;
  final double marginPercent;
  final int retentionYears;
}
