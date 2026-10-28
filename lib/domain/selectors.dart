import '../data/database.dart';
import 'dates.dart';

/// Pure selectors ported from the prototype's select.ts.
const statusLabel = {
  ReadingStatus.notStarted: 'Not started',
  ReadingStatus.reading: 'Reading',
  ReadingStatus.finished: 'Finished',
  ReadingStatus.dnf: 'Did not finish',
};

enum LoanState { overdue, dueSoon, noDate, active }

LoanState loanState(Loan l, {int soonDays = 7, String? todayYmd}) {
  if (l.dueAt == null) return LoanState.noDate;
  final diff = daysBetween(todayYmd ?? today(), l.dueAt!);
  if (diff < 0) return LoanState.overdue;
  if (diff <= soonDays) return LoanState.dueSoon;
  return LoanState.active;
}

String dueText(Loan l, {String? todayYmd}) {
  if (l.dueAt == null) return 'No return date';
  final diff = daysBetween(todayYmd ?? today(), l.dueAt!);
  if (diff < 0) return '${-diff} day${diff == -1 ? '' : 's'} overdue';
  if (diff == 0) return 'Due today';
  if (diff == 1) return 'Due tomorrow';
  return 'Due in $diff days';
}

class LoanView {
  const LoanView(this.loan, this.copy, this.book, this.state);
  final Loan loan;
  final Copy copy;
  final Book book;
  final LoanState state;
}

/// Open loans, soonest due first; loans with no due date sort last.
List<LoanView> activeLoans(
  List<Loan> loans,
  List<Copy> copies,
  List<Book> books, {
  String? todayYmd,
}) {
  final copyById = {for (final c in copies) c.id: c};
  final bookById = {for (final b in books) b.id: b};
  final out = <LoanView>[];
  for (final l in loans.where((l) => l.returnedAt == null)) {
    final copy = copyById[l.copyId];
    final book = copy == null ? null : bookById[copy.bookId];
    if (copy == null || book == null) continue;
    out.add(LoanView(l, copy, book, loanState(l, todayYmd: todayYmd)));
  }
  out.sort(
    (a, b) => (a.loan.dueAt ?? '9999').compareTo(b.loan.dueAt ?? '9999'),
  );
  return out;
}

class LibraryStats {
  const LibraryStats({
    required this.copies,
    required this.titles,
    required this.reading,
    required this.lent,
    required this.overdue,
    required this.onShelf,
  });
  final int copies, titles, reading, lent, overdue, onShelf;
}

LibraryStats stats(
  List<Loan> loans,
  List<Copy> copies,
  List<Book> books, {
  String? todayYmd,
}) {
  final active = activeLoans(loans, copies, books, todayYmd: todayYmd);
  return LibraryStats(
    copies: copies.length,
    titles: books.length,
    reading: books.where((b) => b.status == ReadingStatus.reading).length,
    lent: active.length,
    overdue: active.where((l) => l.state == LoanState.overdue).length,
    onShelf: copies.length - active.length,
  );
}

String authorLine(Book b) =>
    b.authors.isEmpty ? 'Unknown author' : b.authors.join(', ');
