import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_offer.dart';
import 'package:autoscan/features/offers/domain/entities/saved_part.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_provider.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_environment.dart';

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

MarketplaceProvider offerProvider(Map<String, dynamic> data) =>
    switch (data['provider']) {
      'mercadolibre' => MarketplaceProvider.mercadolibre,
      'ebay' => MarketplaceProvider.ebay,
      _ => throw const AppFailure('Proveedor desconocido.'),
    };
MarketplaceEnvironment offerEnvironment(Map<String, dynamic> data) {
  final provider = offerProvider(data);
  final raw =
      data['environment'] ??
      (provider == MarketplaceProvider.mercadolibre ? 'production' : null);
  if (raw == 'production') return MarketplaceEnvironment.production;
  if (raw == 'sandbox' && provider == MarketplaceProvider.ebay) {
    return MarketplaceEnvironment.sandbox;
  }
  throw const AppFailure('El entorno del proveedor no es válido.');
}

String offerExternalId(Map<String, dynamic> data) {
  final id = offerString(data, 'external_id');
  final pattern = offerProvider(data) == MarketplaceProvider.ebay
      ? r'^v1\|[0-9]{1,20}\|[0-9]{1,20}$'
      : r'^MLC[0-9]{5,20}$';
  if (!RegExp(pattern).hasMatch(id)) {
    throw const AppFailure('La referencia recibida no es válida.');
  }
  return id;
}

String offerUrl(Map<String, dynamic> data) {
  final raw = offerString(data, 'url');
  final uri = Uri.tryParse(raw);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.userInfo.isNotEmpty ||
      (uri.hasPort && uri.port != 443) ||
      raw.length > 2000) {
    throw const AppFailure('El enlace del proveedor no es válido.');
  }
  final provider = offerProvider(data), environment = offerEnvironment(data);
  final sandbox =
      uri.host == 'sandbox.ebay.com' || uri.host.endsWith('.sandbox.ebay.com');
  final allowed = provider == MarketplaceProvider.mercadolibre
      ? uri.host == 'mercadolibre.cl' || uri.host.endsWith('.mercadolibre.cl')
      : !uri.hasFragment &&
            uri.path.startsWith('/itm/') &&
            uri.path.length > 5 &&
            (environment == MarketplaceEnvironment.sandbox
                ? sandbox
                : !sandbox &&
                      (uri.host == 'ebay.com' ||
                          uri.host.endsWith('.ebay.com')));
  if (!allowed) throw const AppFailure('El enlace del proveedor no es válido.');
  return raw;
}

DateTime offerDate(Map<String, dynamic> data, String key) {
  final date = DateTime.tryParse(offerString(data, key));
  if (date == null) {
    throw const AppFailure('El servicio devolvió una fecha inválida.');
  }
  return date;
}

void _validateKind(Map<String, dynamic> data) {
  final provider = offerProvider(data);
  if (!{'listing', 'catalog_product'}.contains(data['kind']) ||
      (provider == MarketplaceProvider.ebay && data['kind'] != 'listing')) {
    throw const AppFailure('El servicio devolvió una oferta inválida.');
  }
}

MarketplaceOffer parseOffer(Object? value) {
  final data = offerObject(value);
  _validateKind(data);
  if (data['compatibility'] != 'unverified') {
    throw const AppFailure('El servicio devolvió una oferta inválida.');
  }
  final kind = offerString(data, 'kind');
  String? price, currency, url;
  if (kind == 'listing') {
    price = offerString(data, 'price');
    currency = offerString(data, 'currency');
    url = offerUrl(data);
    if (!RegExp(r'^[0-9]{1,15}(?:\.[0-9]{1,4})?$').hasMatch(price) ||
        !RegExp(r'^[A-Z]{3}$').hasMatch(currency)) {
      throw const AppFailure('El precio recibido no es válido.');
    }
  } else if (data['price'] != null ||
      data['currency'] != null ||
      data['url'] != null ||
      !{'active', 'inactive'}.contains(data['catalog_status'])) {
    throw const AppFailure('El catálogo recibido no es válido.');
  }
  return MarketplaceOffer(
    token: offerString(data, 'offer_token'),
    externalId: offerExternalId(data),
    title: offerString(data, 'title'),
    kind: kind,
    catalogStatus: kind == 'catalog_product'
        ? offerString(data, 'catalog_status')
        : null,
    price: price,
    currency: currency,
    url: url,
    queriedAt: offerDate(data, 'queried_at'),
    provider: offerProvider(data),
    environment: offerEnvironment(data),
  );
}

SavedPart parseSavedPart(Object? value) {
  final data = offerObject(value);
  _validateKind(data);
  if (data['kind'] == 'catalog_product' && data['url'] != null) {
    throw const AppFailure('El catálogo recibido no es válido.');
  }
  final vehicle = [
    data['brand'],
    data['model'],
    data['year'],
  ].where((v) => v != null).join(' ');
  return SavedPart(
    id: offerString(data, 'id'),
    externalId: offerExternalId(data),
    url: data['kind'] == 'listing' ? offerUrl(data) : null,
    kind: offerString(data, 'kind'),
    code: offerString(data, 'dtc'),
    component: offerString(data, 'component_name'),
    author: offerString(data, 'author'),
    note: offerString(data, 'note'),
    createdAt: offerDate(data, 'created_at'),
    vehicle: vehicle.isEmpty ? null : vehicle,
    provider: offerProvider(data),
    environment: offerEnvironment(data),
  );
}
