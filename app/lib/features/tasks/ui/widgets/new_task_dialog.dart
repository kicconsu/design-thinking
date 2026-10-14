import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Diálogo para crear una tarea. Se cierra con `({title, description})` o con
/// `null` si se cancela.
class NewTaskDialog extends StatefulWidget {
  const NewTaskDialog({super.key});

  @override
  State<NewTaskDialog> createState() => _NewTaskDialogState();
}

class _NewTaskDialogState extends State<NewTaskDialog> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Get.back(result: (title: title, description: _description.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear tarea'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nombre de la tarea',
              errorText: _showError ? 'Escribe un nombre' : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Crear')),
      ],
    );
  }
}
