import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

enum ReadingStatus { notStarted, reading, finished, dnf }

enum EntryType { thought, insight, quote, note }

enum ActivityKind {
  bookAdded,
  copyAdded,
  entry,
  quote,
  review,
  status,
  loan,
  returned,
  library,
}

/// Stores a list of strings as a JSON array in one text column.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();
  @override
  List<String> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List).cast<String>();
  @override
  String toSql(List<String> value) => jsonEncode(value);
}

class Books extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get authors => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get isbn => text().nullable()();
  TextColumn get publisher => text().nullable()();
  TextColumn get year => text().nullable()();
  TextColumn get edition => text().nullable()();
  TextColumn get generalNotes => text().nullable()();
  IntColumn get cover => integer().withDefault(const Constant(0))();

  /// Path of the user's own cover photo or the cached Open Library cover.
  TextColumn get photoPath => text().nullable()();
  DateTimeColumn get addedAt => dateTime()();
  TextColumn get status => textEnum<ReadingStatus>().withDefault(
    Constant(ReadingStatus.notStarted.name),
  )();

  /// Dates are stored as local `YYYY-MM-DD` strings, as in the prototype.
  TextColumn get startedAt => text().nullable()();
  TextColumn get finishedAt => text().nullable()();
  IntColumn get currentPage => integer().nullable()();
  IntColumn get pageCount => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get name => text()();
  @override
  Set<Column> get primaryKey => {name};
}

class BookCategories extends Table {
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get category => text()();
  @override
  Set<Column> get primaryKey => {bookId, category};
}

class Tags extends Table {
  TextColumn get name => text()();
  @override
  Set<Column> get primaryKey => {name};
}

class Copies extends Table {
  TextColumn get id => text()();
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get label => text()();
  TextColumn get condition => text().nullable()();
  TextColumn get location => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class Loans extends Table {
  TextColumn get id => text()();
  TextColumn get copyId =>
      text().references(Copies, #id, onDelete: KeyAction.cascade)();
  TextColumn get borrower => text()();
  TextColumn get lentAt => text()();
  TextColumn get dueAt => text().nullable()();
  TextColumn get returnedAt => text().nullable()();
  TextColumn get note => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class Entries extends Table {
  TextColumn get id => text()();
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => textEnum<EntryType>()();
  TextColumn get content => text()();
  TextColumn get reflection => text().nullable()();
  IntColumn get page => integer().nullable()();
  TextColumn get chapter => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class EntryTags extends Table {
  TextColumn get entryId =>
      text().references(Entries, #id, onDelete: KeyAction.cascade)();
  TextColumn get tag => text()();
  @override
  Set<Column> get primaryKey => {entryId, tag};
}

class Reviews extends Table {
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();
  IntColumn get rating => integer().nullable()();
  TextColumn get body => text().withDefault(const Constant(''))();
  TextColumn get takeaways => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get finishedAt => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {bookId};
}

@DataClassName('ActivityEvent')
class ActivityEvents extends Table {
  TextColumn get id => text()();
  TextColumn get kind => textEnum<ActivityKind>()();
  TextColumn get bookId => text().nullable()();
  TextColumn get message => text()();
  TextColumn get detail => text().nullable()();
  DateTimeColumn get at => dateTime()();
  TextColumn get entryId => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Books,
    Categories,
    BookCategories,
    Tags,
    Copies,
    Loans,
    Entries,
    EntryTags,
    Reviews,
    ActivityEvents,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? driftDatabase(name: 'librario'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
