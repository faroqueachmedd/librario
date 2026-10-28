import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

ThemeData buildAppTheme() {
  final scheme = ColorScheme.light(
    primary: Tokens.ink,
    onPrimary: Colors.white,
    secondary: Tokens.muted,
    surface: Tokens.surface,
    onSurface: Tokens.ink,
    error: Tokens.danger,
    outline: Tokens.line,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Tokens.paper,
    canvasColor: Tokens.paper,
    fontFamily: Fonts.body,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: Tokens.line,
    textTheme: Typography.blackCupertino.apply(
      fontFamily: Fonts.body,
      bodyColor: Tokens.ink,
      displayColor: Tokens.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Tokens.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Tokens.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );
}
