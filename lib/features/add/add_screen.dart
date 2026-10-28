import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_screen.dart';

class AddScreen extends StatelessWidget {
  const AddScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    title: 'Add',
    note: 'Scan, search and manual entry arrive in the adding-books milestone.',
  );
}
