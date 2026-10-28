import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepository(ref.watch(databaseProvider)),
);

final booksProvider = StreamProvider<List<Book>>(
  (ref) => ref.watch(repositoryProvider).watchBooks(),
);
final copiesProvider = StreamProvider<List<Copy>>(
  (ref) => ref.watch(repositoryProvider).watchCopies(),
);
final loansProvider = StreamProvider<List<Loan>>(
  (ref) => ref.watch(repositoryProvider).watchLoans(),
);
final entriesProvider = StreamProvider<List<Entry>>(
  (ref) => ref.watch(repositoryProvider).watchEntries(),
);
final reviewsProvider = StreamProvider<List<Review>>(
  (ref) => ref.watch(repositoryProvider).watchReviews(),
);
final activityProvider = StreamProvider<List<ActivityEvent>>(
  (ref) => ref.watch(repositoryProvider).watchActivity(),
);
final categoriesProvider = StreamProvider<List<String>>(
  (ref) => ref.watch(repositoryProvider).watchCategories(),
);
final tagsProvider = StreamProvider<List<String>>(
  (ref) => ref.watch(repositoryProvider).watchTags(),
);
