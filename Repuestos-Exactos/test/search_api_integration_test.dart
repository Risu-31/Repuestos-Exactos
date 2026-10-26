import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:autoscan/core/network/api_client.dart';
import 'package:autoscan/features/auth/data/repositories/api_auth_repository.dart';
import 'package:autoscan/features/search/data/repositories/api_search_repository.dart';

void main() {
  test(
    'Dio consumes the real catalog, compatibility and workshop prices',
    () async {
      final client = ApiClient(baseUrl: Platform.environment['TEST_API_URL']!);
      addTearDown(client.close);
      final auth = ApiAuthRepository(client);
      final search = ApiSearchRepository(client);
      final password = Platform.environment['TEST_DEMO_PASSWORD']!;
      try {
        await auth.login('admin@losaromos.example', password);
        final brands = await search.brands();
        final toyota = brands.firstWhere((item) => item.name == 'Toyota');
        final models = await search.models(toyota.id);
        final yaris = models.firstWhere((item) => item.name == 'Yaris');
        final codes = await search.codes('P03');
        expect(codes.items.any((item) => item.code == 'P0300'), isTrue);
        final compatible = await search.parts(
          'P0300',
          model: yaris.id,
          year: 2018,
        );
        expect(compatible.items, isNotEmpty);
        expect(compatible.items.first.salePrice, isA<BigInt>());
        final first = await search.parts('P0300');
        expect(first.items, isNotEmpty);
        expect(await search.vehicle('AAAAAAAAAAAAAAAAA'), isNull);
        await auth.logout();
        await auth.login('admin@nuble.example', password);
        final second = await search.parts('P0300');
        final otherPrices = {
          for (final item in second.items) item.id: item.salePrice,
        };
        expect(
          first.items.any((item) => otherPrices[item.id] != item.salePrice),
          isTrue,
        );
      } finally {
        await auth.logout();
      }
    },
    skip:
        Platform.environment['TEST_API_URL'] == null ||
        Platform.environment['TEST_DEMO_PASSWORD'] == null,
  );
}
