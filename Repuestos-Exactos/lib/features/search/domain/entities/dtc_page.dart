import 'package:autoscan/features/search/domain/entities/dtc_option.dart';

class DtcPage {
  const DtcPage({required this.items, required this.hasMore});
  final List<DtcOption> items;
  final bool hasMore;
}
