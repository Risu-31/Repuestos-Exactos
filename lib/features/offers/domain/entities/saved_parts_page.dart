import 'package:autoscan/features/offers/domain/entities/saved_part.dart';

class SavedPartsPage {
  const SavedPartsPage(this.items, this.nextOffset);
  final List<SavedPart> items;
  final int? nextOffset;
}
