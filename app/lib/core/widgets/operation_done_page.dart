import 'package:flutter/material.dart';

/// Pantalla genérica reutilizable para confirmar la finalización exitosa
/// de cualquier operación en la aplicación.
class OperationDonePage extends StatelessWidget {
  final String? title;
  final String? text;
  final Widget? image;
  final double circleRadius;
  final Color? circleBackgroundColor;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final IconData? buttonIcon;
  final Widget? actionButton;
  final PreferredSizeWidget? appBar;
  final bool showAppBar;
  final String? appBarTitle;

  const OperationDonePage({
    super.key,
    this.title,
    this.text,
    this.image,
    this.circleRadius = 64,
    this.circleBackgroundColor,
    this.buttonText,
    this.onButtonPressed,
    this.buttonIcon,
    this.actionButton,
    this.appBar,
    this.showAppBar = true,
    this.appBarTitle = 'Imker',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final bool hasTitle = title != null && title!.trim().isNotEmpty;
    final bool hasText = text != null && text!.trim().isNotEmpty;

    final circle = Center(
      child: CircleAvatar(
        radius: circleRadius,
        backgroundColor: circleBackgroundColor ?? cs.tertiaryContainer,
        child: image,
      ),
    );

    final List<Widget> contentWidgets = [];

    if (hasTitle && hasText) {
      // Si tiene título y texto/subtítulo: título arriba a la izquierda,
      // círculo en el centro, y texto centrado abajo.
      contentWidgets.addAll([
        Text(
          title!,
          style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        circle,
        const SizedBox(height: 32),
        Text(
          text!,
          textAlign: TextAlign.center,
          style: tt.bodyLarge,
        ),
      ]);
    } else if (hasTitle && !hasText) {
      // Si solo tiene título: círculo en el centro y título centrado debajo.
      contentWidgets.addAll([
        circle,
        const SizedBox(height: 32),
        Text(
          title!,
          textAlign: TextAlign.center,
          style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ]);
    } else if (!hasTitle && hasText) {
      // Si solo tiene texto: círculo en el centro y texto centrado abajo.
      contentWidgets.addAll([
        circle,
        const SizedBox(height: 32),
        Text(
          text!,
          textAlign: TextAlign.center,
          style: tt.bodyLarge,
        ),
      ]);
    } else {
      contentWidgets.add(circle);
    }

    PreferredSizeWidget? resolvedAppBar;
    if (showAppBar) {
      resolvedAppBar = appBar ??
          AppBar(
            backgroundColor: cs.tertiaryContainer,
            title: Text(appBarTitle ?? 'Imker'),
            centerTitle: true,
            elevation: 0,
          );
    }

    return Scaffold(
      backgroundColor: cs.primaryContainer,
      appBar: resolvedAppBar,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: (hasTitle && hasText)
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              ...contentWidgets,
              const Spacer(),
              if (actionButton != null)
                actionButton!
              else if (buttonText != null)
                _buildDefaultButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultButton(BuildContext context) {
    final buttonStyle = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
    );

    if (buttonIcon != null) {
      return FilledButton.icon(
        style: buttonStyle,
        onPressed: onButtonPressed,
        icon: Icon(buttonIcon),
        label: Text(buttonText!),
      );
    }

    return FilledButton(
      style: buttonStyle,
      onPressed: onButtonPressed,
      child: Text(buttonText!),
    );
  }
}
