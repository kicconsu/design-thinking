import 'package:flutter/material.dart';

/// Muestra un anillo donde se toca la pantalla, para ver en un teléfono o
/// emulador qué está haciendo la prueba.
///
/// Los toques que inyecta `tester.tap` no los dibuja el sistema operativo
/// (la opción «Mostrar toques» de Android solo ve los dedos reales), así que
/// la app los dibuja ella: escucha los eventos del puntero, no los consume.
///
/// Solo se activa con `--dart-define=SHOW_TAPS=true`; sin él, [wrap] devuelve
/// la app tal cual (el CI no cambia).
class TapOverlay extends StatefulWidget {
  const TapOverlay({super.key, required this.child});

  final Widget child;

  static const enabled = bool.fromEnvironment('SHOW_TAPS');

  /// Envuelve [child] solo si se pidió ver los toques.
  static Widget wrap(Widget? child) =>
      enabled ? TapOverlay(child: child ?? const SizedBox.shrink()) : child!;

  @override
  State<TapOverlay> createState() => _TapOverlayState();
}

class _TapOverlayState extends State<TapOverlay> with TickerProviderStateMixin {
  final _marks = <_Mark>[];

  void _onDown(PointerDownEvent event) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    final mark = _Mark(event.position, controller);
    setState(() => _marks.add(mark));
    controller
      ..addListener(() => setState(() {}))
      ..forward().whenComplete(() {
        if (!mounted) return;
        setState(() => _marks.remove(mark));
        controller.dispose();
      });
  }

  @override
  void dispose() {
    for (final mark in _marks) {
      mark.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      child: Stack(
        textDirection: TextDirection.ltr,
        children: [
          Positioned.fill(child: widget.child),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _TapPainter(_marks)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Mark {
  _Mark(this.position, this.controller);

  final Offset position;
  final AnimationController controller;
}

class _TapPainter extends CustomPainter {
  _TapPainter(this.marks);

  final List<_Mark> marks;

  @override
  void paint(Canvas canvas, Size size) {
    for (final mark in marks) {
      final t = mark.controller.value;
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = Colors.redAccent.withValues(alpha: 1 - t);
      final dot = Paint()
        ..color = Colors.redAccent.withValues(alpha: 0.5 * (1 - t));
      canvas.drawCircle(mark.position, 18 + 34 * t, ring);
      canvas.drawCircle(mark.position, 10, dot);
    }
  }

  @override
  bool shouldRepaint(_TapPainter oldDelegate) => true;
}
