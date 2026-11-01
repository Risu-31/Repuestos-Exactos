import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_offer.dart';
import 'package:autoscan/features/offers/domain/entities/saved_part.dart';

Map<String, dynamic> offerObject(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const AppFailure(
      'El servicio devolvió datos de repuestos inválidos.',
    );
  }
  return value;
}

String offerString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is! String) {
    throw const AppFailure(
      'El servicio devolvió datos de repuestos inválidos.',
    );
  }
  return value;
}

String offerUrl(Map<String, dynamic> data) {
  final raw = offerString(data, 'url');
  final uri = Uri.tryParse(raw);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.userInfo.isNotEmpty ||
      (uri.hasPort && uri.port != 443) ||
      !(uri.host == 'mercadolibre.cl' ||
          uri.host.endsWith('.mercadolibre.cl'))) {
    throw const AppFailure('El enlace del proveedor no es válido.');
  }
  return raw;
}

DateTime offerDate(Map<String, dynamic> data, String key) {
  final date = DateTime.tryParse(offerString(data, key));
  if (date == null) {
    throw const AppFailure('El servicio devolvió una fecha inválida.');
  }
  return date;
}

MarketplaceOffer parseOffer(Object? value) {
  final data = offerObject(value);
  final kind = offerString(data, 'kind');
  if (data['provider'] != 'mercadolibre' ||
      data['compatibility'] != 'unverified' ||
      (kind != 'listing' && kind != 'catalog_product')) {
    throw const AppFailure('El servicio devolvió una oferta inválida.');
  }
  String? price, currency, url;
  if (kind == 'listing') {
    price = offerString(data, 'price');
    currency = offerString(data, 'currency');
    url = offerUrl(data);
    if (!RegExp(r'^[0-9]{1,15}(?:\.[0-9]{1,4})?$').hasMatch(price)) {
      throw const AppFailure('El precio recibido no es válido.');
    }
  } else if (data['price'] != null ||
      data['currency'] != null ||
      data['url'] != null ||
      (data['catalog_status'] != 'active' &&
          data['catalog_status'] != 'inactive')) {
    throw const AppFailure('El catálogo recibido no es válido.');
  }
  return MarketplaceOffer(
    token: offerString(data, 'offer_token'),
    externalId: offerString(data, 'external_id'),
    title: offerString(data, 'title'),
    kind: kind,
    catalogStatus: kind == 'catalog_product'
        ? offerString(data, 'catalog_status')
        : null,
    price: price,
    currency: currency,
    url: url,
    queriedAt: offerDate(data, 'queried_at'),
  );
}

SavedPart parseSavedPart(Object? value) {
  final data = offerObject(value);
  if (data['provider'] != 'mercadolibre' ||
      !{'listing', 'catalog_product'}.contains(data['kind'])) {
    throw const AppFailure('Proveedor desconocido.');
  }
  final vehicle = [
    data['brand'],
    data['model'],
    data['year'],
  ].where((v) => v != null).join(' ');
  return SavedPart(
    id: offerString(data, 'id'),
    externalId: offerString(data, 'external_id'),
    url: data['kind'] == 'listing' ? offerUrl(data) : null,
    kind: offerString(data, 'kind'),
    code: offerString(data, 'dtc'),
    component: offerString(data, 'component_name'),
    author: offerString(data, 'author'),
    note: offerString(data, 'note'),
    createdAt: offerDate(data, 'created_at'),
    vehicle: vehicle.isEmpty ? null : vehicle,
  );
}
