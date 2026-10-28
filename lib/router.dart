import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/tokens.dart';
import 'features/activity/activity_screen.dart';
import 'features/add/add_screen.dart';
import 'features/book/book_screen.dart';
import 'features/home/home_screen.dart';
import 'features/journal/journal_screen.dart';
import 'features/library/library_screen.dart';

/// Five tabs, each with its own navigation stack (StatefulShellRoute), as in the
/// prototype's Route union. Detail routes are children of the tab that opens them.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _Shell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'book/:id',
                    builder: (_, s) =>
                        BookScreen(bookId: s.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (_, _) => const LibraryScreen(),
                routes: [
                  GoRoute(
                    path: 'book/:id',
                    builder: (_, s) =>
                        BookScreen(bookId: s.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/add', builder: (_, _) => const AddScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/activity',
                builder: (_, _) => const ActivityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/journal',
                builder: (_, _) => const JournalScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _Shell extends StatelessWidget {
  const _Shell({required this.shell});
  final StatefulNavigationShell shell;

  static const _tabs = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.menu_book_outlined, Icons.menu_book, 'Library'),
    (Icons.add_circle_outline, Icons.add_circle, 'Add'),
    (Icons.history, Icons.history, 'Activity'),
    (Icons.edit_note_outlined, Icons.edit_note, 'Journal'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Tokens.surface,
          border: Border(top: BorderSide(color: Tokens.line)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: shell.currentIndex == i,
                      label: _tabs[i].$3,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        // Tapping the active tab pops back to its root.
                        onTap: () => shell.goBranch(
                          i,
                          initialLocation: i == shell.currentIndex,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              shell.currentIndex == i
                                  ? _tabs[i].$2
                                  : _tabs[i].$1,
                              size: 24,
                              color: shell.currentIndex == i
                                  ? Tokens.ink
                                  : Tokens.muted,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _tabs[i].$3.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 9,
                                letterSpacing: 0.9,
                                color: shell.currentIndex == i
                                    ? Tokens.ink
                                    : Tokens.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
