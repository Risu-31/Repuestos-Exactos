import 'package:flutter/material.dart';

class GoogleButton extends StatelessWidget {
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
  Widget build(BuildContext context) =>
      const Text('Para continuar con Google, abre la aplicación web.');
}
