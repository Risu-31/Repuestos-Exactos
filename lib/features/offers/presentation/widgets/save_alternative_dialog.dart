import 'package:flutter/material.dart';

class SaveAlternativeDialog extends StatefulWidget {
  const SaveAlternativeDialog({super.key});
  @override
  State<SaveAlternativeDialog> createState() => _SaveAlternativeDialogState();
}

class _SaveAlternativeDialogState extends State<SaveAlternativeDialog> {
  final _note = TextEditingController();
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Guardar alternativa'),
    scrollable: true,
    content: SizedBox(
      width: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guarda esta referencia para revisarla después. Confirma la pieza y su compatibilidad antes de recomendarla al cliente.',
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('saved-part-note'),
            controller: _note,
            maxLength: 1000,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Nota del técnico (opcional)',
              hintText: 'Qué revisar y por qué elegiste esta alternativa',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esta acción no realiza una compra ni emite una cotización.',
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const Key('confirm-save-alternative'),
        onPressed: () => Navigator.pop(context, _note.text.trim()),
        child: const Text('Guardar referencia'),
      ),
    ],
  );
}
