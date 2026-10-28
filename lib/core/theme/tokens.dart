import 'package:flutter/material.dart';

/// Design tokens ported from the prototype's tailwind.config.js and index.css.
/// Monotone, Notion-style: ink on warm paper, hairline borders, muted status colors.
class Tokens {
  static const paper = Color(0xFFF8F6F1);
  static const paper2 = Color(0xFFF0EDE6);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF37352F);
  static const inkDark = Color(0xFF201F1D);
  static const muted = Color(0xFF787774);
  static const line = Color(0xFFE7E3DA);
  static const marker = Color(0xFFEAE6DC);
  static const markerSoft = Color(0xFFF4F1EA);
  static const amber = Color(0xFF9A6E32);
  static const amberSoft = Color(0xFFF8F2E8);
  static const danger = Color(0xFFA84E44);
  static const dangerSoft = Color(0xFFF9ECEA);

  static const gutter = 20.0;

  static const cardShadow = [
    BoxShadow(color: Color(0x17373530), spreadRadius: 1, blurRadius: 0),
  ];
  static const coverShadow = [
    BoxShadow(color: Color(0x380F0F0F), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(
      color: Color(0x470F0F0F),
      blurRadius: 12,
      spreadRadius: -6,
      offset: Offset(0, 6),
    ),
  ];
}

/// Type system: Figtree SemiBold for body emphasis, Bricolage Grotesque ExtraBold for
/// display captions, JetBrains Mono Medium caps for small labels.
class Fonts {
  static const body = 'Figtree';
  static const display = 'Bricolage Grotesque';
  static const mono = 'JetBrains Mono';

  static TextStyle bodyStyle({
    double size = 16,
    bool bold = false,
    Color color = Tokens.ink,
  }) => TextStyle(
    fontFamily: body,
    fontSize: size,
    color: color,
    fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
    fontVariations: [FontVariation.weight(bold ? 600 : 400)],
  );

  static TextStyle displayStyle({double size = 28, Color color = Tokens.ink}) =>
      TextStyle(
        fontFamily: display,
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.025 * size,
        height: 1.05,
        fontVariations: [FontVariation.weight(800)],
      );

  /// Small uppercase label.
  static TextStyle labelStyle({double size = 11, Color color = Tokens.muted}) =>
      TextStyle(
        fontFamily: mono,
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.08 * size,
        fontVariations: [FontVariation.weight(500)],
      );
}
