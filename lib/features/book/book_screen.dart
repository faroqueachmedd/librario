import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/book_cover.dart';
import '../../core/widgets/kit.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../domain/selectors.dart';

class BookScreen extends ConsumerWidget {
  const BookScreen({super.key, required this.bookId});
  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksProvider).value ?? const <Book>[];
    final book = books.where((b) => b.id == bookId).firstOrNull;
    final copies = (ref.watch(copiesProvider).value ?? const <Copy>[])
        .where((c) => c.bookId == bookId)
        .toList();
    final loans = ref.watch(loansProvider).value ?? const <Loan>[];

    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: book == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                Tokens.gutter,
                0,
                Tokens.gutter,
                32,
              ),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    coverOf(book, size: CoverSize.lg),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatusPill(statusLabel[book.status]!),
                          const SizedBox(height: 10),
                          Text(book.title, style: Fonts.displayStyle(size: 24)),
                          const SizedBox(height: 6),
                          Text(
                            authorLine(book),
                            style: Fonts.bodyStyle(
                              size: 15,
                              color: Tokens.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Eyebrow('Copies'),
                const SizedBox(height: 8),
                for (final c in copies)
                  Builder(
                    builder: (_) {
                      final out = loans
                          .where(
                            (l) => l.copyId == c.id && l.returnedAt == null,
                          )
                          .firstOrNull;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.label,
                                      style: Fonts.bodyStyle(
                                        size: 15.5,
                                        bold: true,
                                      ),
                                    ),
                                    if (c.location != null)
                                      Text(
                                        c.location!,
                                        style: Fonts.bodyStyle(
                                          size: 14,
                                          color: Tokens.muted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (out != null)
                                StatusPill(
                                  'With ${out.borrower}',
                                  tone: loanState(out) == LoanState.overdue
                                      ? PillTone.danger
                                      : PillTone.amber,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}
