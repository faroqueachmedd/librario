import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'kit.dart';

/// Stand-in for screens that arrive in later milestones.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, required this.note});
  final String title;
  final String note;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScreenTitle(title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
          child: AppCard(
            child: Text(
              note,
              style: Fonts.bodyStyle(size: 15, color: Tokens.muted),
            ),
          ),
        ),
      ],
    ),
  );
}
