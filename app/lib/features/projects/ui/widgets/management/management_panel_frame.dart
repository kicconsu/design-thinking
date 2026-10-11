import 'package:flutter/material.dart';

/// Marco común de los paneles del contenedor de gestión: fondo opaco (para
/// tapar lo que hay debajo mientras se desliza), título, pestañas opcionales,
/// contenido que se desplaza y un botón fijo abajo.
class ManagementPanelFrame extends StatelessWidget {
  const ManagementPanelFrame({
    super.key,
    required this.title,
    this.onBack,
    this.tabs,
    required this.body,
    this.bottom,
  });

  final String title;
  final VoidCallback? onBack;

  /// Selector de pestañas que va bajo el título.
  final Widget? tabs;
  final Widget body;

  /// Botón (o barra) fijo en la parte inferior.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ColoredBox(
      color: cs.primaryContainer,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: onBack == null
                      ? null
                      : IconButton(
                          tooltip: 'Volver',
                          icon: const Icon(Icons.arrow_back),
                          onPressed: onBack,
                        ),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          if (tabs != null)
            Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 0), child: tabs),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: body,
            ),
          ),
          if (bottom != null)
            Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), child: bottom),
        ],
      ),
    );
  }
}

/// Botón de acción a todo el ancho con las esquinas cuadradas del diseño.
class PanelButton extends StatelessWidget {
  const PanelButton({super.key, required this.label, required this.onPressed, this.busy = false});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(label),
    );
  }
}
