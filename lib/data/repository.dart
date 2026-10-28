import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/dates.dart';
import 'database.dart';

const _uuid = Uuid();
String _id() => _uuid.v4();
String _norm(String s) => s.trim().toLowerCase();

const _statusText = {
  ReadingStatus.notStarted: 'Marked not started',
  ReadingStatus.reading: 'Started reading',
  ReadingStatus.finished: 'Finished reading',
  ReadingStatus.dnf: 'Marked did not finish',
};

/// All writes go through here. Each mutation writes its activity event in the same
/// transaction, so screens never touch the database or log activity themselves.
class LibraryRepository {
  LibraryRepository(this.db, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _now;

  Future<void> _log(
    ActivityKind kind,
    String message, {
    String? bookId,
    String? detail,
    String? entryId,
  }) {
    return db
        .into(db.activityEvents)
        .insert(
          ActivityEventsCompanion.insert(
            id: _id(),
            kind: kind,
            message: message,
            bookId: Value(bookId),
            detail: Value(detail),
            entryId: Value(entryId),
            at: _now(),
          ),
        );
  }

  // ---- Reads (streams, so lists update live) ----

  Stream<List<Book>> watchBooks() => (db.select(
    db.books,
  )..orderBy([(b) => OrderingTerm.desc(b.addedAt)])).watch();
  Stream<List<Copy>> watchCopies() => db.select(db.copies).watch();
  Stream<List<Loan>> watchLoans() => db.select(db.loans).watch();
  Stream<List<Entry>> watchEntries() => (db.select(
    db.entries,
  )..orderBy([(e) => OrderingTerm.desc(e.createdAt)])).watch();
  Stream<List<Review>> watchReviews() => db.select(db.reviews).watch();
  Stream<List<ActivityEvent>> watchActivity() => (db.select(
    db.activityEvents,
  )..orderBy([(a) => OrderingTerm.desc(a.at)])).watch();
  Stream<List<String>> watchCategories() =>
      (db.select(db.categories)..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .watch()
          .map((r) => [for (final c in r) c.name]);
  Stream<List<String>> watchTags() =>
      (db.select(db.tags)..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch()
          .map((r) => [for (final t in r) t.name]);
  Stream<List<BookCategory>> watchBookCategories() =>
      db.select(db.bookCategories).watch();
  Stream<List<EntryTag>> watchEntryTags() => db.select(db.entryTags).watch();

  // ---- Books ----

  Future<int> bookCount() => db.books.count().getSingle();

  Future<String> addBook({
    required String title,
    List<String> authors = const [],
    String? isbn,
    String? publisher,
    String? year,
    String? edition,
    String? generalNotes,
    List<String> categories = const [],
    int? pageCount,
    String? photoPath,
    String copyLabel = 'Copy 1',
  }) {
    return db.transaction(() async {
      final id = _id();
      final count = await bookCount();
      await db
          .into(db.books)
          .insert(
            BooksCompanion.insert(
              id: id,
              title: title.trim(),
              authors: Value(authors),
              isbn: Value(isbn),
              publisher: Value(publisher),
              year: Value(year),
              edition: Value(edition),
              generalNotes: Value(generalNotes),
              cover: Value(count % 8),
              photoPath: Value(photoPath),
              pageCount: Value(pageCount),
              addedAt: _now(),
            ),
          );
      for (final c in categories) {
        await db
            .into(db.bookCategories)
            .insert(
              BookCategoriesCompanion.insert(bookId: id, category: c),
              mode: InsertMode.insertOrIgnore,
            );
      }
      await db
          .into(db.copies)
          .insert(
            CopiesCompanion.insert(
              id: _id(),
              bookId: id,
              label: copyLabel.isEmpty ? 'Copy 1' : copyLabel,
            ),
          );
      await _log(
        ActivityKind.bookAdded,
        'Book added',
        bookId: id,
        detail: title,
      );
      return id;
    });
  }

  /// Returns the existing book with this ISBN, for the duplicate check when adding.
  Future<Book?> findByIsbn(String isbn) {
    final clean = isbn.replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();
    return (db.select(
      db.books,
    )..where((b) => b.isbn.equals(clean))).getSingleOrNull();
  }

  Future<void> updateBook(
    String id,
    BooksCompanion patch, {
    List<String>? categories,
  }) {
    return db.transaction(() async {
      final book = await (db.select(
        db.books,
      )..where((b) => b.id.equals(id))).getSingle();
      if (patch.toColumns(true).isNotEmpty) {
        await (db.update(db.books)..where((b) => b.id.equals(id))).write(patch);
      }
      if (categories != null) {
        await (db.delete(
          db.bookCategories,
        )..where((c) => c.bookId.equals(id))).go();
        for (final c in categories) {
          await db
              .into(db.bookCategories)
              .insert(
                BookCategoriesCompanion.insert(bookId: id, category: c),
                mode: InsertMode.insertOrIgnore,
              );
        }
      }
      await _log(
        ActivityKind.library,
        'Details edited',
        bookId: id,
        detail: patch.title.present ? patch.title.value : book.title,
      );
    });
  }

  Future<void> setStatus(String bookId, ReadingStatus status, {int? page}) {
    return db.transaction(() async {
      final book = await (db.select(
        db.books,
      )..where((b) => b.id.equals(bookId))).getSingle();
      final changed = book.status != status;
      await (db.update(db.books)..where((b) => b.id.equals(bookId))).write(
        BooksCompanion(
          status: Value(status),
          currentPage: Value(page ?? book.currentPage),
          startedAt: Value(
            status == ReadingStatus.reading && book.startedAt == null
                ? today(_now())
                : book.startedAt,
          ),
          finishedAt: Value(
            status == ReadingStatus.finished
                ? (book.finishedAt ?? today(_now()))
                : book.finishedAt,
          ),
        ),
      );
      await _log(
        ActivityKind.status,
        changed ? _statusText[status]! : 'Progress updated',
        bookId: bookId,
        detail: page != null ? '${book.title}, page $page' : book.title,
      );
    });
  }

  // ---- Copies and lending ----

  Future<void> addCopy(String bookId, String label, {String? location}) {
    return db.transaction(() async {
      final book = await (db.select(
        db.books,
      )..where((b) => b.id.equals(bookId))).getSingle();
      await db
          .into(db.copies)
          .insert(
            CopiesCompanion.insert(
              id: _id(),
              bookId: bookId,
              label: label,
              location: Value(
                (location == null || location.isEmpty) ? null : location,
              ),
            ),
          );
      await _log(
        ActivityKind.copyAdded,
        'Copy added',
        bookId: bookId,
        detail: '${book.title}, ${label.toLowerCase()}',
      );
    });
  }

  /// Lends a copy. Returns null (and changes nothing) if the copy is already out.
  Future<String?> lend(
    String copyId,
    String borrower, {
    String? dueAt,
    String? note,
  }) {
    return db.transaction(() async {
      final open = await (db.select(
        db.loans,
      )..where((l) => l.copyId.equals(copyId) & l.returnedAt.isNull())).get();
      if (open.isNotEmpty) return null;
      final copy = await (db.select(
        db.copies,
      )..where((c) => c.id.equals(copyId))).getSingle();
      final book = await (db.select(
        db.books,
      )..where((b) => b.id.equals(copy.bookId))).getSingle();
      final id = _id();
      final name = borrower.trim();
      await db
          .into(db.loans)
          .insert(
            LoansCompanion.insert(
              id: id,
              copyId: copyId,
              borrower: name,
              lentAt: today(_now()),
              dueAt: Value((dueAt == null || dueAt.isEmpty) ? null : dueAt),
              note: Value((note == null || note.isEmpty) ? null : note),
            ),
          );
      await _log(
        ActivityKind.loan,
        'Lent to $name',
        bookId: book.id,
        detail: '${book.title}, ${copy.label.toLowerCase()}',
      );
      return id;
    });
  }

  Future<void> returnLoan(String loanId) {
    return db.transaction(() async {
      final loan = await (db.select(
        db.loans,
      )..where((l) => l.id.equals(loanId))).getSingleOrNull();
      if (loan == null || loan.returnedAt != null) return;
      final copy = await (db.select(
        db.copies,
      )..where((c) => c.id.equals(loan.copyId))).getSingle();
      final book = await (db.select(
        db.books,
      )..where((b) => b.id.equals(copy.bookId))).getSingle();
      await (db.update(db.loans)..where((l) => l.id.equals(loanId))).write(
        LoansCompanion(returnedAt: Value(today(_now()))),
      );
      await _log(
        ActivityKind.returned,
        'Returned by ${loan.borrower}',
        bookId: book.id,
        detail: '${book.title}, ${copy.label.toLowerCase()}',
      );
    });
  }

  // ---- Journal and reviews ----

  /// Creates or updates an entry (pass [id] to update). Returns its id.
  Future<String> saveEntry({
    String? id,
    required String bookId,
    required EntryType type,
    required String content,
    String? reflection,
    int? page,
    String? chapter,
    List<String> tags = const [],
  }) {
    return db.transaction(() async {
      final book = await (db.select(
        db.books,
      )..where((b) => b.id.equals(bookId))).getSingle();
      final entryId = id ?? _id();
      final existing = id == null
          ? null
          : await (db.select(
              db.entries,
            )..where((e) => e.id.equals(id))).getSingleOrNull();
      await db
          .into(db.entries)
          .insertOnConflictUpdate(
            EntriesCompanion.insert(
              id: entryId,
              bookId: bookId,
              type: type,
              content: content,
              reflection: Value(reflection),
              page: Value(page),
              chapter: Value(chapter),
              createdAt: existing?.createdAt ?? _now(),
            ),
          );
      await (db.delete(
        db.entryTags,
      )..where((t) => t.entryId.equals(entryId))).go();
      for (final t in tags) {
        await db
            .into(db.tags)
            .insert(
              TagsCompanion.insert(name: t),
              mode: InsertMode.insertOrIgnore,
            );
        await db
            .into(db.entryTags)
            .insert(
              EntryTagsCompanion.insert(entryId: entryId, tag: t),
              mode: InsertMode.insertOrIgnore,
            );
      }
      final label = switch (type) {
        EntryType.quote => 'Quote',
        EntryType.insight => 'Insight',
        EntryType.thought => 'Thought',
        EntryType.note => 'Note',
      };
      await _log(
        type == EntryType.quote ? ActivityKind.quote : ActivityKind.entry,
        existing != null
            ? '$label updated'
            : type == EntryType.quote
            ? 'Quote captured'
            : '$label added',
        bookId: bookId,
        entryId: entryId,
        detail: '${book.title}${page != null ? ', p. $page' : ''}',
      );
      return entryId;
    });
  }

  Future<void> deleteEntry(String id) =>
      (db.delete(db.entries)..where((e) => e.id.equals(id))).go();

  Future<void> saveReview({
    required String bookId,
    int? rating,
    String text = '',
    List<String> takeaways = const [],
    String? finishedAt,
  }) {
    return db.transaction(() async {
      final book = await (db.select(
        db.books,
      )..where((b) => b.id.equals(bookId))).getSingle();
      final exists =
          await (db.select(
            db.reviews,
          )..where((r) => r.bookId.equals(bookId))).getSingleOrNull() !=
          null;
      await db
          .into(db.reviews)
          .insertOnConflictUpdate(
            ReviewsCompanion.insert(
              bookId: bookId,
              rating: Value(rating),
              body: Value(text),
              takeaways: Value(takeaways),
              finishedAt: Value(finishedAt),
              updatedAt: _now(),
            ),
          );
      await _log(
        ActivityKind.review,
        exists ? 'Review updated' : 'Review saved',
        bookId: bookId,
        detail:
            '${book.title}${rating != null ? ', $rating star${rating > 1 ? 's' : ''}' : ''}',
      );
    });
  }

  // ---- Categories and tags (renames and deletes cascade in one transaction) ----

  Future<bool> addCategory(String name) => db.transaction(() async {
    final n = name.trim();
    if (n.isEmpty || await _hasName(await _categoryNames(), n)) return false;
    await db.into(db.categories).insert(CategoriesCompanion.insert(name: n));
    await _log(ActivityKind.library, 'Category created', detail: n);
    return true;
  });

  Future<bool> renameCategory(String from, String to) =>
      db.transaction(() async {
        final n = to.trim();
        final names = (await _categoryNames()).where((c) => c != from).toList();
        if (n.isEmpty || await _hasName(names, n)) return false;
        await (db.update(db.categories)..where((c) => c.name.equals(from)))
            .write(CategoriesCompanion(name: Value(n)));
        await (db.update(db.bookCategories)
              ..where((c) => c.category.equals(from)))
            .write(BookCategoriesCompanion(category: Value(n)));
        return true;
      });

  Future<void> deleteCategory(String name) => db.transaction(() async {
    await (db.delete(
      db.bookCategories,
    )..where((c) => c.category.equals(name))).go();
    await (db.delete(db.categories)..where((c) => c.name.equals(name))).go();
  });

  Future<bool> addTag(String name) => db.transaction(() async {
    final n = name.trim();
    if (n.isEmpty || await _hasName(await _tagNames(), n)) return false;
    await db.into(db.tags).insert(TagsCompanion.insert(name: n));
    return true;
  });

  Future<bool> renameTag(String from, String to) => db.transaction(() async {
    final n = to.trim();
    final names = (await _tagNames()).where((t) => t != from).toList();
    if (n.isEmpty || await _hasName(names, n)) return false;
    await (db.update(
      db.tags,
    )..where((t) => t.name.equals(from))).write(TagsCompanion(name: Value(n)));
    await (db.update(db.entryTags)..where((t) => t.tag.equals(from))).write(
      EntryTagsCompanion(tag: Value(n)),
    );
    return true;
  });

  Future<void> deleteTag(String name) => db.transaction(() async {
    await (db.delete(db.entryTags)..where((t) => t.tag.equals(name))).go();
    await (db.delete(db.tags)..where((t) => t.name.equals(name))).go();
  });

  Future<List<String>> _categoryNames() async => [
    for (final c in await db.select(db.categories).get()) c.name,
  ];
  Future<List<String>> _tagNames() async => [
    for (final t in await db.select(db.tags).get()) t.name,
  ];
  Future<bool> _hasName(List<String> names, String candidate) async =>
      names.any((x) => _norm(x) == _norm(candidate));
}
