import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librario/data/database.dart';
import 'package:librario/data/repository.dart';
import 'package:librario/domain/dates.dart';
import 'package:librario/domain/selectors.dart';

void main() {
  late AppDatabase db;
  late LibraryRepository repo;
  final now = DateTime(2026, 10, 28, 12);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LibraryRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  Future<(String, String)> bookWithCopy() async {
    final id = await repo.addBook(
      title: 'Zero to One',
      authors: ['Peter Thiel'],
      isbn: '9780804139298',
    );
    final copy = (await db.select(db.copies).get()).single;
    return (id, copy.id);
  }

  test('addBook creates a copy and an activity event', () async {
    final (id, _) = await bookWithCopy();
    expect((await db.select(db.books).get()).single.id, id);
    expect(await db.select(db.copies).get(), hasLength(1));
    final events = await db.select(db.activityEvents).get();
    expect(events.single.kind, ActivityKind.bookAdded);
  });

  test(
    'lend refuses a copy that is already out, and return logs activity',
    () async {
      final (_, copyId) = await bookWithCopy();
      final loanId = await repo.lend(copyId, ' Sam ', dueAt: '2026-11-05');
      expect(loanId, isNotNull);
      expect(await repo.lend(copyId, 'Priya'), isNull);

      final loans = await db.select(db.loans).get();
      expect(loans.single.borrower, 'Sam');

      await repo.returnLoan(loanId!);
      expect((await db.select(db.loans).get()).single.returnedAt, '2026-10-28');
      // Returning twice does nothing.
      await repo.returnLoan(loanId);
      final kinds = [
        for (final e in await db.select(db.activityEvents).get()) e.kind,
      ];
      expect(kinds.where((k) => k == ActivityKind.returned), hasLength(1));
      expect(kinds.where((k) => k == ActivityKind.loan), hasLength(1));
    },
  );

  test('setStatus stamps started and finished dates once', () async {
    final (id, _) = await bookWithCopy();
    await repo.setStatus(id, ReadingStatus.reading, page: 12);
    var b = (await db.select(db.books).get()).single;
    expect(b.startedAt, '2026-10-28');
    expect(b.currentPage, 12);
    await repo.setStatus(id, ReadingStatus.finished);
    b = (await db.select(db.books).get()).single;
    expect(b.finishedAt, '2026-10-28');
    expect(b.currentPage, 12);
  });

  test(
    'category rename cascades to books and rejects case-insensitive duplicates',
    () async {
      await repo.addCategory('Finance');
      await repo.addCategory('Business');
      final id = await repo.addBook(title: 'Book', categories: ['Finance']);
      expect(await repo.addCategory('finance'), isFalse);
      expect(await repo.renameCategory('Finance', 'business'), isFalse);
      expect(await repo.renameCategory('Finance', 'Money'), isTrue);
      final bc = await db.select(db.bookCategories).get();
      expect(bc.single.bookId, id);
      expect(bc.single.category, 'Money');
      await repo.deleteCategory('Money');
      expect(await db.select(db.bookCategories).get(), isEmpty);
    },
  );

  test('tag rename and delete cascade to entries', () async {
    final (id, _) = await bookWithCopy();
    final entryId = await repo.saveEntry(
      bookId: id,
      type: EntryType.quote,
      content: 'Hello',
      tags: ['Ideas'],
    );
    expect(await repo.renameTag('Ideas', 'Thinking'), isTrue);
    expect((await db.select(db.entryTags).get()).single.tag, 'Thinking');
    await repo.deleteTag('Thinking');
    expect(await db.select(db.entryTags).get(), isEmpty);
    expect(await db.select(db.entries).get(), hasLength(1));
    expect(entryId, isNotEmpty);
  });

  test('saveEntry update keeps createdAt and logs an update', () async {
    final (id, _) = await bookWithCopy();
    final entryId = await repo.saveEntry(
      bookId: id,
      type: EntryType.thought,
      content: 'a',
    );
    final later = LibraryRepository(
      db,
      clock: () => now.add(const Duration(days: 2)),
    );
    await later.saveEntry(
      id: entryId,
      bookId: id,
      type: EntryType.thought,
      content: 'b',
    );
    final e = (await db.select(db.entries).get()).single;
    expect(e.content, 'b');
    expect(e.createdAt, now);
    final texts = [
      for (final a in await db.select(db.activityEvents).get()) a.message,
    ];
    expect(texts, contains('Thought updated'));
  });

  test(
    'deleting a book cascades to copies, loans, entries and review',
    () async {
      final (id, copyId) = await bookWithCopy();
      await repo.lend(copyId, 'Sam');
      await repo.saveEntry(bookId: id, type: EntryType.note, content: 'x');
      await repo.saveReview(bookId: id, rating: 4, text: 'Good');
      await (db.delete(db.books)..where((b) => b.id.equals(id))).go();
      expect(await db.select(db.copies).get(), isEmpty);
      expect(await db.select(db.loans).get(), isEmpty);
      expect(await db.select(db.entries).get(), isEmpty);
      expect(await db.select(db.reviews).get(), isEmpty);
    },
  );

  test('loan selectors', () async {
    final (_, copyId) = await bookWithCopy();
    await repo.lend(copyId, 'Sam', dueAt: '2026-10-20');
    final loans = await db.select(db.loans).get();
    final views = activeLoans(
      loans,
      await db.select(db.copies).get(),
      await db.select(db.books).get(),
      todayYmd: '2026-10-28',
    );
    expect(views.single.state, LoanState.overdue);
    expect(dueText(loans.single, todayYmd: '2026-10-28'), '8 days overdue');
  });

  test('date helpers', () {
    expect(addDays('2026-10-31', 1), '2026-11-01');
    expect(daysBetween('2026-03-01', '2026-03-31'), 30);
    expect(
      groupOf(DateTime(2026, 10, 27, 9), now: now),
      ActivityGroup.yesterday,
    );
  });
}
