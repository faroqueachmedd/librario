import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_screen.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    title: 'Activity',
    note: 'Activity feed arrives in the organization milestone.',
  );
}
