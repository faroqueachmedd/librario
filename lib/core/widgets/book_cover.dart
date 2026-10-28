import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum CoverSize {
  xxs(28, 40, 3, 0.3),
  xs(40, 56, 4, 0.42),
  sm(56, 80, 5, 0.58),
  md(96, 144, 6, 1),
  lg(144, 216, 8, 1.5);

  const CoverSize(this.w, this.h, this.radius, this.scale);
  final double w, h, radius, scale;
}

class _Style {
  const _Style(
    this.colors,
    this.fg,
    this.accent,
    this.layout, {
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });
  final List<Color> colors;
  final Color fg, accent;
  final String layout;
  final Alignment begin, end;
}

const _styles = <_Style>[
  _Style(
    [Color(0xFFF6F0E4), Color(0xFFE9DFCB)],
    Color(0xFF2A2420),
    Color(0xFFB98A3E),
    'classic',
  ),
  _Style(
    [Color(0xFF2B3A63), Color(0xFF121A33)],
    Color(0xFFEDE6D3),
    Color(0xFF9FB7E8),
    'night',
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
  _Style(
    [Color(0xFFE7EDF3), Color(0xFFC7D3DF), Color(0xFF8B9CAE)],
    Color(0xFF1F2A3A),
    Color(0xFF4E6A8E),
    'mist',
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
  _Style(
    [Color(0xFFF7D84A), Color(0xFFEFC22B)],
    Color(0xFF141414),
    Color(0xFF141414),
    'bold',
  ),
  _Style(
    [Color(0xFFECE8E1), Color(0xFFD9D3C8)],
    Color(0xFF1B1B1B),
    Color(0xFF1B1B1B),
    'classic',
  ),
  _Style(
    [Color(0xFFF4E7DF), Color(0xFFE7D2C6)],
    Color(0xFF5A2F2A),
    Color(0xFFB4533F),
    'classic',
  ),
  _Style(
    [Color(0xFFDDE6EF), Color(0xFF9DB1C6)],
    Color(0xFF18263A),
    Color(0xFF18263A),
    'mist',
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
  _Style(
    [Color(0xFFEFEDE6), Color(0xFFD8D2C3)],
    Color(0xFF2B2B2B),
    Color(0xFF7C6A4A),
    'classic',
  ),
];

/// Typeset placeholder jacket, with the real cover (photo or cached file) painted over it
/// when one exists. Mirrors the prototype's `Cover` component.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.title,
    required this.author,
    required this.style,
    this.size = CoverSize.md,
    this.imagePath,
    this.width,
  });

  final String title;
  final String author;
  final int style;
  final CoverSize size;
  final String? imagePath;

  /// Overrides the size's width and keeps a 2:3 ratio (for grid cells).
  final double? width;

  @override
  Widget build(BuildContext context) {
    final c = _styles[style % _styles.length];
    final k = size.scale;
    final w = width ?? size.w;
    final h = width != null ? width! * 1.5 : size.h;
    final radius = BorderRadius.circular(size.radius);
    final titleSize =
        (title.length > 26
            ? 11.5
            : title.length > 14
            ? 14.0
            : 17.0) *
        k;

    return Semantics(
      label: '$title cover',
      excludeSemantics: true,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: Tokens.coverShadow,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: c.colors,
                    begin: c.begin,
                    end: c.end,
                  ),
                ),
              ),
              if (size != CoverSize.xxs)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.09,
                    vertical: h * 0.07,
                  ),
                  child: Column(
                    crossAxisAlignment: c.layout == 'bold'
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      Text(
                        c.layout == 'bold' ? title.toUpperCase() : title,
                        maxLines: 5,
                        overflow: TextOverflow.clip,
                        textAlign: c.layout == 'bold'
                            ? TextAlign.start
                            : TextAlign.center,
                        style: TextStyle(
                          fontFamily: Fonts.display,
                          fontSize: c.layout == 'bold' ? 18 * k : titleSize,
                          height: c.layout == 'bold' ? 0.9 : 1.05,
                          color: c.layout == 'classic' ? c.accent : c.fg,
                          fontWeight: c.layout == 'bold'
                              ? FontWeight.w800
                              : FontWeight.w500,
                          fontVariations: [
                            FontVariation.weight(
                              c.layout == 'bold' ? 800 : 500,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (size.index >= CoverSize.md.index)
                        Text(
                          author.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: Fonts.mono,
                            fontSize: 6.5 * k,
                            letterSpacing: 1.4 * k,
                            color: c.fg,
                          ),
                        ),
                    ],
                  ),
                ),
              if (imagePath != null)
                Image.file(
                  File(imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              // spine crease and sheen
              Positioned(
                left: w * 0.04,
                top: 0,
                bottom: 0,
                width: 2,
                child: const ColoredBox(color: Color(0x1A000000)),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1, -0.2),
                    end: Alignment(1, 0.2),
                    colors: [
                      Color(0x40FFFFFF),
                      Color(0x00FFFFFF),
                      Color(0x0F000000),
                    ],
                    stops: [0, 0.3, 1],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience: a cover built from a database [Book].
BookCover coverOf(
  dynamic book, {
  CoverSize size = CoverSize.md,
  double? width,
}) => BookCover(
  title: book.title as String,
  author: (book.authors as List<String>).isEmpty
      ? 'Unknown'
      : (book.authors as List<String>).first,
  style: book.cover as int,
  imagePath: book.photoPath as String?,
  size: size,
  width: width,
);
