# Librario

A local-first home library and reading journal for iPhone, ported from the web prototype ("Reading Room").
Flutter, Riverpod, go_router, Drift (SQLite). No accounts and no backend.

## Run

```sh
flutter pub get
flutter run            # debug builds seed the prototype's sample library on first launch
flutter test
flutter analyze
```

Release builds start empty. Requires Xcode and a Mac to run on iOS (`open ios/Runner.xcworkspace` for signing).

## Regenerate database code

`lib/data/database.g.dart` is committed. After changing tables in `lib/data/database.dart`:

```sh
dart run build_runner build --delete-conflicting-outputs
```

Bump `schemaVersion` and add a migration step with every schema change.

## Layout

- `lib/core` theme tokens (`Tokens`, `Fonts`), shared widgets (`kit.dart`, `book_cover.dart`)
- `lib/data` Drift schema, `LibraryRepository` (all writes, each logs activity in the same transaction), providers, dev seed
- `lib/domain` pure date helpers and selectors ported from the prototype's `dates.ts` and `select.ts`
- `lib/features/<screen>` screens

Fonts (Figtree, Bricolage Grotesque, JetBrains Mono; all OFL) are bundled in `assets/fonts`.
The bundle id is `com.librario.librario` as a placeholder; change it before registering with App Store Connect.
