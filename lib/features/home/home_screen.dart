import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/book_cover.dart';
import '../../core/widgets/kit.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../domain/dates.dart';
import '../../domain/selectors.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksProvider).value ?? const <Book>[];
    final copies = ref.watch(copiesProvider).value ?? const <Copy>[];
    final loans = ref.watch(loansProvider).value ?? const <Loan>[];
    final s = stats(loans, copies, books);
    final reading = books
        .where((b) => b.status == ReadingStatus.reading)
        .toList();
    final due = activeLoans(loans, copies, books)
        .where(
          (l) => l.state == LoanState.overdue || l.state == LoanState.dueSoon,
        )
        .toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ScreenTitle(greeting(), eyebrow: longDate()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
            child: Row(
              children: [
                for (final (label, n) in [
                  ('Titles', s.titles),
                  ('Reading', s.reading),
                  ('Lent', s.lent),
                  ('Overdue', s.overdue),
                ]) ...[
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$n',
                            style: Fonts.displayStyle(
                              size: 26,
                              color: label == 'Overdue' && n > 0
                                  ? Tokens.danger
                                  : Tokens.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Eyebrow(label),
                        ],
                      ),
                    ),
                  ),
                  if (label != 'Overdue') const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          if (reading.isNotEmpty) ...[
            const _Section('Currently reading'),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
                itemCount: reading.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  final b = reading[i];
                  final pct = (b.pageCount ?? 0) > 0
                      ? (b.currentPage ?? 0) / b.pageCount!
                      : 0.0;
                  return GestureDetector(
                    onTap: () => context.go('/home/book/${b.id}'),
                    child: SizedBox(
                      width: 96,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          coverOf(b),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: pct.clamp(0, 1),
                              minHeight: 3,
                              backgroundColor: Tokens.line,
                              color: Tokens.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (due.isNotEmpty) ...[
            const _Section('Due soon'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
              child: Column(
                children: [
                  for (final l in due)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        onTap: () => context.go('/home/book/${l.book.id}'),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            coverOf(l.book, size: CoverSize.xs),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.book.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Fonts.bodyStyle(
                                      size: 15.5,
                                      bold: true,
                                    ),
                                  ),
                                  Text(
                                    'With ${l.loan.borrower}',
                                    style: Fonts.bodyStyle(
                                      size: 14,
                                      color: Tokens.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusPill(
                              dueText(l.loan),
                              tone: l.state == LoanState.overdue
                                  ? PillTone.danger
                                  : PillTone.amber,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Tokens.gutter, 28, Tokens.gutter, 12),
    child: Text(title, style: Fonts.displayStyle(size: 20)),
  );
}
