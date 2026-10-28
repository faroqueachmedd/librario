import 'package:drift/drift.dart';

import '../domain/dates.dart';
import 'database.dart';

/// Development-only sample library, ported from the prototype's sample.ts.
/// Never call this from a release build.
Future<void> seedSampleData(AppDatabase db, {DateTime? now}) async {
  final n = now ?? DateTime.now();
  final t = today(n);
  DateTime ago(int days, [int hour = 10]) =>
      DateTime(n.year, n.month, n.day - days, hour);

  const categories = [
    'Finance',
    'Investing',
    'Economics',
    'Business',
    'Startups',
    'Technology',
    'Software Engineering',
    'Product',
  ];
  const tags = [
    'Investing',
    'Strategy',
    'Engineering',
    'Leadership',
    'Ideas',
    'Family',
  ];

  // (id, title, authors, isbn, publisher, year, categories, cover, addedDaysAgo, status, startedDays, finishedDays, page, pages)
  final books =
      <
        (
          String,
          String,
          List<String>,
          String,
          String,
          String,
          List<String>,
          int,
          int,
          ReadingStatus,
          int?,
          int?,
          int?,
          int,
        )
      >[
        (
          'b1',
          'The Psychology of Money',
          ['Morgan Housel'],
          '9780857197689',
          'Harriman House',
          '2020',
          ['Finance', 'Investing'],
          0,
          48,
          ReadingStatus.finished,
          -60,
          -34,
          null,
          256,
        ),
        (
          'b2',
          'The Intelligent Investor',
          ['Benjamin Graham'],
          '9780060555665',
          'Harper Business',
          '2006',
          ['Investing', 'Finance'],
          1,
          40,
          ReadingStatus.reading,
          -12,
          null,
          212,
          640,
        ),
        (
          'b3',
          'Zero to One',
          ['Peter Thiel', 'Blake Masters'],
          '9780804139298',
          'Crown Business',
          '2014',
          ['Startups', 'Business'],
          2,
          38,
          ReadingStatus.finished,
          -90,
          -55,
          null,
          224,
        ),
        (
          'b4',
          'The Lean Startup',
          ['Eric Ries'],
          '9780307887894',
          'Crown Business',
          '2011',
          ['Startups', 'Product'],
          3,
          21,
          ReadingStatus.reading,
          -5,
          null,
          46,
          336,
        ),
        (
          'b5',
          'The Pragmatic Programmer',
          ['David Thomas', 'Andrew Hunt'],
          '9780135957059',
          'Addison-Wesley',
          '2019',
          ['Software Engineering', 'Technology'],
          4,
          14,
          ReadingStatus.reading,
          -9,
          null,
          219,
          352,
        ),
        (
          'b6',
          "The Innovator's Dilemma",
          ['Clayton M. Christensen'],
          '9780062060242',
          'Harper Business',
          '2011',
          ['Business', 'Technology'],
          5,
          9,
          ReadingStatus.finished,
          -30,
          -8,
          null,
          288,
        ),
        (
          'b7',
          'Designing Data-Intensive Applications',
          ['Martin Kleppmann'],
          '9781449373320',
          "O'Reilly Media",
          '2017',
          ['Software Engineering', 'Technology'],
          6,
          4,
          ReadingStatus.dnf,
          -70,
          null,
          212,
          616,
        ),
        (
          'b8',
          'A Random Walk Down Wall Street',
          ['Burton G. Malkiel'],
          '9781324002185',
          'W. W. Norton',
          '2019',
          ['Investing', 'Economics'],
          7,
          1,
          ReadingStatus.notStarted,
          null,
          null,
          null,
          432,
        ),
      ];
  final copies = <(String, String, String, String, String)>[
    ('c1', 'b1', 'Hardback', 'Like new', 'Home office'),
    ('c2', 'b1', 'Paperback', 'Good', 'Living room'),
    ('c3', 'b2', 'Paperback', 'Worn spine', 'Bedside'),
    ('c4', 'b3', 'Paperback', 'Good', 'Living room'),
    ('c5', 'b4', 'Paperback', 'Good', 'Home office'),
    ('c6', 'b5', 'Hardback', 'Like new', 'Home office'),
    ('c7', 'b6', 'Paperback', 'Good', 'Living room'),
    ('c8', 'b7', 'Desk copy', 'Good', 'Living room'),
    ('c9', 'b7', 'Work copy', 'Fair', 'Home office'),
    ('c10', 'b8', 'Paperback', 'Pencil marks', 'Shelf by the window'),
  ];

  await db.transaction(() async {
    for (final c in categories) {
      await db.into(db.categories).insert(CategoriesCompanion.insert(name: c));
    }
    for (final g in tags) {
      await db.into(db.tags).insert(TagsCompanion.insert(name: g));
    }
    for (final b in books) {
      await db
          .into(db.books)
          .insert(
            BooksCompanion.insert(
              id: b.$1,
              title: b.$2,
              authors: Value(b.$3),
              isbn: Value(b.$4),
              publisher: Value(b.$5),
              year: Value(b.$6),
              cover: Value(b.$8),
              addedAt: ago(b.$9),
              status: Value(b.$10),
              startedAt: Value(b.$11 == null ? null : addDays(t, b.$11!)),
              finishedAt: Value(b.$12 == null ? null : addDays(t, b.$12!)),
              currentPage: Value(b.$13),
              pageCount: Value(b.$14),
            ),
          );
      for (final c in b.$7) {
        await db
            .into(db.bookCategories)
            .insert(BookCategoriesCompanion.insert(bookId: b.$1, category: c));
      }
    }
    for (final c in copies) {
      await db
          .into(db.copies)
          .insert(
            CopiesCompanion.insert(
              id: c.$1,
              bookId: c.$2,
              label: c.$3,
              condition: Value(c.$4),
              location: Value(c.$5),
            ),
          );
    }
    Future<void> loan(
      String id,
      String copy,
      String who,
      int lent, {
      int? due,
      int? returned,
      String? note,
    }) => db
        .into(db.loans)
        .insert(
          LoansCompanion.insert(
            id: id,
            copyId: copy,
            borrower: who,
            lentAt: addDays(t, lent),
            dueAt: Value(due == null ? null : addDays(t, due)),
            returnedAt: Value(returned == null ? null : addDays(t, returned)),
            note: Value(note),
          ),
        );
    await loan(
      'l1',
      'c2',
      'Sam',
      -16,
      due: 5,
      note: 'Asked after our chat about index funds.',
    );
    await loan('l2', 'c4', 'Priya', -40, due: -12);
    await loan('l3', 'c5', 'Dan', -3);
    await loan('l4', 'c7', 'Lena', -6, due: 20);
    await loan(
      'l5',
      'c6',
      'Omar',
      -52,
      due: -30,
      returned: -28,
      note: 'Returned with a bookmark in chapter 3.',
    );

    Future<void> event(
      String id,
      ActivityKind kind,
      String bookId,
      String message,
      String detail,
      int daysAgo, [
      int hour = 10,
    ]) => db
        .into(db.activityEvents)
        .insert(
          ActivityEventsCompanion.insert(
            id: id,
            kind: kind,
            message: message,
            bookId: Value(bookId),
            detail: Value(detail),
            at: ago(daysAgo, hour),
          ),
        );
    await event(
      'a1',
      ActivityKind.bookAdded,
      'b8',
      'Book added',
      'A Random Walk Down Wall Street',
      1,
      19,
    );
    await event(
      'a2',
      ActivityKind.loan,
      'b4',
      'Lent to Dan',
      'The Lean Startup, paperback',
      3,
    );
    await event(
      'a3',
      ActivityKind.status,
      'b6',
      'Finished reading',
      "The Innovator's Dilemma",
      8,
    );
  });
}
