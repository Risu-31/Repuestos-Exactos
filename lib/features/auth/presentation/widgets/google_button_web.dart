import 'package:flutter/material.dart';
import 'package:google_identity_services_web/id.dart' as gis;
import 'package:google_identity_services_web/loader.dart';

/// El botón lo dibuja Google; el widget no realiza llamadas a nuestra API.
class GoogleButton extends StatefulWidget {
  const GoogleButton({
    super.key,
    required this.clientId,
    required this.nonce,
    required this.onCredential,
    required this.onError,
  });
  final String clientId;
  final String nonce;
  final void Function(String) onCredential;
  final VoidCallback onError;
  @override
  State<GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<GoogleButton> {
  late final Future<void> _ready;
  @override
  void initState() {
    super.initState();
    _ready = _initialize();
  }

  Future<void> _initialize() async {
    try {
      await loadWebSdk().timeout(const Duration(seconds: 10));
      if (!mounted) return;
      // Un único cliente activo por pantalla. Cada nuevo intento renueva el nonce.
      gis.id.initialize(
        gis.IdConfiguration(
          client_id: widget.clientId,
          nonce: widget.nonce,
          auto_select: false,
          callback: (response) {
            if (!mounted) return;
            final token = response.credential;
            if (token == null || response.error != null) {
              widget.onError();
            } else {
              widget.onCredential(token);
            }
          },
        ),
      );
    } on Object {
      if (mounted) widget.onError();
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _ready,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Text('No pudimos cargar el botón de Google.');
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return const SizedBox(
          height: 44,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return SizedBox(
        height: 44,
        child: HtmlElementView.fromTagName(
          tagName: 'div',
          onElementCreated: (element) {
            gis.id.renderButton(
              element,
              gis.GsiButtonConfiguration(
                type: gis.ButtonType.standard,
                theme: gis.ButtonTheme.outline,
                size: gis.ButtonSize.large,
                text: gis.ButtonText.continue_with,
                shape: gis.ButtonShape.pill,
                width: MediaQuery.sizeOf(context).width < 380 ? 200 : 280,
                locale: 'es',
              ),
            );
          },
        ),
      );
    },
  );
}
