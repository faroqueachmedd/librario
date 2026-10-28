import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/book_cover.dart';
import '../../core/widgets/kit.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../domain/selectors.dart';

class _StatusFilter extends Notifier<ReadingStatus?> {
  @override
  ReadingStatus? build() => null;
  void set(ReadingStatus? s) => state = s;
}

class _Query extends Notifier<String> {
  @override
  String build() => '';
  void set(String q) => state = q;
}

final _statusFilter = NotifierProvider<_StatusFilter, ReadingStatus?>(
  _StatusFilter.new,
);
final _query = NotifierProvider<_Query, String>(_Query.new);

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(booksProvider).value ?? const <Book>[];
    final status = ref.watch(_statusFilter);
    final q = ref.watch(_query).trim().toLowerCase();
    final books = [
      for (final b in all)
        if ((status == null || b.status == status) &&
            (q.isEmpty ||
                b.title.toLowerCase().contains(q) ||
                b.authors.any((a) => a.toLowerCase().contains(q))))
          b,
    ];

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ScreenTitle('Library', eyebrow: '${all.length} titles'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
              child: TextField(
                onChanged: (v) => ref.read(_query.notifier).set(v),
                style: Fonts.bodyStyle(size: 16),
                decoration: InputDecoration(
                  hintText: 'Search title or author',
                  prefixIcon: const Icon(Icons.search, color: Tokens.muted),
                  filled: true,
                  fillColor: Tokens.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Tokens.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Tokens.ink),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: Tokens.gutter,
                  vertical: 10,
                ),
                children: [
                  AppChip(
                    'All',
                    selected: status == null,
                    onTap: () => ref.read(_statusFilter.notifier).set(null),
                  ),
                  for (final s in ReadingStatus.values) ...[
                    const SizedBox(width: 8),
                    AppChip(
                      statusLabel[s]!,
                      selected: status == s,
                      onTap: () => ref.read(_statusFilter.notifier).set(s),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.gutter,
              8,
              Tokens.gutter,
              24,
            ),
            sliver: SliverLayoutBuilder(
              builder: (context, c) {
                const gap = 14.0;
                final w = (c.crossAxisExtent - gap * 2) / 3;
                return SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: gap,
                    mainAxisSpacing: 18,
                    childAspectRatio: w / (w * 1.5 + 44),
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, i) {
                    final b = books[i];
                    return GestureDetector(
                      onTap: () => context.go('/library/book/${b.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          coverOf(b, width: w),
                          const SizedBox(height: 8),
                          Text(
                            b.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Fonts.bodyStyle(size: 13, bold: true),
                          ),
                          Text(
                            authorLine(b),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Fonts.bodyStyle(
                              size: 12,
                              color: Tokens.muted,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
