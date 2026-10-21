import 'package:flutter/material.dart';

/// Botón de la interfaz de Imker: esquinas rectas, borde negro y el mismo
/// relleno que «Leer más» de las tarjetas.
ButtonStyle squareButtonStyle(ColorScheme cs) => FilledButton.styleFrom(
  backgroundColor: cs.inversePrimary,
  foregroundColor: cs.onSurface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.zero,
    side: BorderSide(color: Colors.black),
  ),
);

/// Hojas inferiores rectas con un borde arriba, como la barra de navegación.
ShapeBorder squareSheetShape(ColorScheme cs) => RoundedRectangleBorder(
  borderRadius: BorderRadius.zero,
  side: BorderSide(color: cs.onTertiaryContainer),
);

const squareInputBorder = OutlineInputBorder(borderRadius: BorderRadius.zero);
