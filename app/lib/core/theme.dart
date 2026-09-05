import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff7d570e),
      surfaceTint: Color(0xff7d570e),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffffdead),
      onPrimaryContainer: Color(0xff604100),
      secondary: Color(0xff6e5b40),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xfff9dfbb),
      onSecondaryContainer: Color(0xff55442a),
      tertiary: Color(0xff745b0c),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffffdf91),
      onTertiaryContainer: Color(0xff594400),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffff8f3),
      onSurface: Color(0xff201b13),
      onSurfaceVariant: Color(0xff4e4539),
      outline: Color(0xff807567),
      outlineVariant: Color(0xffd2c4b4),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff362f27),
      inversePrimary: Color(0xfff1be6d),
      primaryFixed: Color(0xffffdead),
      onPrimaryFixed: Color(0xff281900),
      primaryFixedDim: Color(0xfff1be6d),
      onPrimaryFixedVariant: Color(0xff604100),
      secondaryFixed: Color(0xfff9dfbb),
      onSecondaryFixed: Color(0xff261904),
      secondaryFixedDim: Color(0xffdbc3a1),
      onSecondaryFixedVariant: Color(0xff55442a),
      tertiaryFixed: Color(0xffffdf91),
      onTertiaryFixed: Color(0xff241a00),
      tertiaryFixedDim: Color(0xffe4c36c),
      onTertiaryFixedVariant: Color(0xff594400),
      surfaceDim: Color(0xffe4d8cc),
      surfaceBright: Color(0xfffff8f3),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffef2e5),
      surfaceContainer: Color(0xfff8ecdf),
      surfaceContainerHigh: Color(0xfff2e6da),
      surfaceContainerHighest: Color(0xffece1d4),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff4b3100),
      surfaceTint: Color(0xff7d570e),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff8e661d),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff43341b),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff7e6a4d),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff443400),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff846a1c),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff8f3),
      onSurface: Color(0xff151009),
      onSurfaceVariant: Color(0xff3d3529),
      outline: Color(0xff5b5144),
      outlineVariant: Color(0xff766b5e),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff362f27),
      inversePrimary: Color(0xfff1be6d),
      primaryFixed: Color(0xff8e661d),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff724e02),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff7e6a4d),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff645237),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff846a1c),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff6a5200),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffd0c5b9),
      surfaceBright: Color(0xfffff8f3),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffef2e5),
      surfaceContainer: Color(0xfff2e6da),
      surfaceContainerHigh: Color(0xffe7dbce),
      surfaceContainerHighest: Color(0xffdbd0c3),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff3d2800),
      surfaceTint: Color(0xff7d570e),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff634300),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff382a12),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff57462c),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff382a00),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff5b4600),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff8f3),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff332b20),
      outlineVariant: Color(0xff51483b),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff362f27),
      inversePrimary: Color(0xfff1be6d),
      primaryFixed: Color(0xff634300),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff462e00),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff57462c),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff3f3018),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff5b4600),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff403100),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc2b7ab),
      surfaceBright: Color(0xfffff8f3),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffbefe2),
      surfaceContainer: Color(0xffece1d4),
      surfaceContainerHigh: Color(0xffded3c6),
      surfaceContainerHighest: Color(0xffd0c5b9),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfff1be6d),
      surfaceTint: Color(0xfff1be6d),
      onPrimary: Color(0xff432c00),
      primaryContainer: Color(0xff604100),
      onPrimaryContainer: Color(0xffffdead),
      secondary: Color(0xffdbc3a1),
      onSecondary: Color(0xff3d2e16),
      secondaryContainer: Color(0xff55442a),
      onSecondaryContainer: Color(0xfff9dfbb),
      tertiary: Color(0xffe4c36c),
      onTertiary: Color(0xff3d2e00),
      tertiaryContainer: Color(0xff594400),
      onTertiaryContainer: Color(0xffffdf91),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff18130b),
      onSurface: Color(0xffece1d4),
      onSurfaceVariant: Color(0xffd2c4b4),
      outline: Color(0xff9b8f80),
      outlineVariant: Color(0xff4e4539),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffece1d4),
      inversePrimary: Color(0xff7d570e),
      primaryFixed: Color(0xffffdead),
      onPrimaryFixed: Color(0xff281900),
      primaryFixedDim: Color(0xfff1be6d),
      onPrimaryFixedVariant: Color(0xff604100),
      secondaryFixed: Color(0xfff9dfbb),
      onSecondaryFixed: Color(0xff261904),
      secondaryFixedDim: Color(0xffdbc3a1),
      onSecondaryFixedVariant: Color(0xff55442a),
      tertiaryFixed: Color(0xffffdf91),
      onTertiaryFixed: Color(0xff241a00),
      tertiaryFixedDim: Color(0xffe4c36c),
      onTertiaryFixedVariant: Color(0xff594400),
      surfaceDim: Color(0xff18130b),
      surfaceBright: Color(0xff3f382f),
      surfaceContainerLowest: Color(0xff120d07),
      surfaceContainerLow: Color(0xff201b13),
      surfaceContainer: Color(0xff241f17),
      surfaceContainerHigh: Color(0xff2f2921),
      surfaceContainerHighest: Color(0xff3a342b),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffd699),
      surfaceTint: Color(0xfff1be6d),
      onPrimary: Color(0xff352200),
      primaryContainer: Color(0xffb5893e),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xfff2d9b5),
      onSecondary: Color(0xff31230c),
      secondaryContainer: Color(0xffa38d6e),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xfffcd980),
      onTertiary: Color(0xff302400),
      tertiaryContainer: Color(0xffab8d3d),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff18130b),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffe9dac9),
      outline: Color(0xffbdb0a0),
      outlineVariant: Color(0xff9a8f80),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffece1d4),
      inversePrimary: Color(0xff624200),
      primaryFixed: Color(0xffffdead),
      onPrimaryFixed: Color(0xff1a0f00),
      primaryFixedDim: Color(0xfff1be6d),
      onPrimaryFixedVariant: Color(0xff4b3100),
      secondaryFixed: Color(0xfff9dfbb),
      onSecondaryFixed: Color(0xff1a0f00),
      secondaryFixedDim: Color(0xffdbc3a1),
      onSecondaryFixedVariant: Color(0xff43341b),
      tertiaryFixed: Color(0xffffdf91),
      onTertiaryFixed: Color(0xff181000),
      tertiaryFixedDim: Color(0xffe4c36c),
      onTertiaryFixedVariant: Color(0xff443400),
      surfaceDim: Color(0xff18130b),
      surfaceBright: Color(0xff4a433a),
      surfaceContainerLowest: Color(0xff0b0703),
      surfaceContainerLow: Color(0xff221d15),
      surfaceContainer: Color(0xff2d271f),
      surfaceContainerHigh: Color(0xff383229),
      surfaceContainerHighest: Color(0xff433d34),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffedd8),
      surfaceTint: Color(0xfff1be6d),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffecba6a),
      onPrimaryContainer: Color(0xff130900),
      secondary: Color(0xffffedd8),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffd7bf9d),
      onSecondaryContainer: Color(0xff130900),
      tertiary: Color(0xffffeecc),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffe0bf69),
      onTertiaryContainer: Color(0xff100a00),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff18130b),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xfffdeedc),
      outlineVariant: Color(0xffcec1b0),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffece1d4),
      inversePrimary: Color(0xff624200),
      primaryFixed: Color(0xffffdead),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xfff1be6d),
      onPrimaryFixedVariant: Color(0xff1a0f00),
      secondaryFixed: Color(0xfff9dfbb),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffdbc3a1),
      onSecondaryFixedVariant: Color(0xff1a0f00),
      tertiaryFixed: Color(0xffffdf91),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffe4c36c),
      onTertiaryFixedVariant: Color(0xff181000),
      surfaceDim: Color(0xff18130b),
      surfaceBright: Color(0xff564f45),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff241f17),
      surfaceContainer: Color(0xff362f27),
      surfaceContainerHigh: Color(0xff413a32),
      surfaceContainerHighest: Color(0xff4d463c),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: textTheme.apply(
       bodyColor: colorScheme.onSurface,
       displayColor: colorScheme.onSurface,
     ),
     scaffoldBackgroundColor: colorScheme.surface,
     canvasColor: colorScheme.surface,
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
