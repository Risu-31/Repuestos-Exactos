import 'package:autoscan/features/search/domain/entities/part_result.dart';

class PartPage {
  const PartPage({required this.items, this.nextOffset});
  final List<PartResult> items;
  final int? nextOffset;
}
