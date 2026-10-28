import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/providers.dart';
import 'data/seed.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final container = ProviderContainer();
  // Debug builds start with the prototype's sample library so every screen has content.
  // Release builds always start empty.
  if (kDebugMode) {
    if (await container.read(repositoryProvider).bookCount() == 0) {
      await seedSampleData(container.read(databaseProvider));
    }
  }
  runApp(
    UncontrolledProviderScope(container: container, child: const LibrarioApp()),
  );
}
