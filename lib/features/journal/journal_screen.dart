import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_screen.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    title: 'Journal',
    note: 'Thoughts, insights and quotes arrive in the journal milestone.',
  );
}
