import 'package:autoscan/features/search/domain/repositories/search_repository.dart';
import 'package:autoscan/features/search/presentation/controllers/catalog_search_controller.dart';
import 'package:provider/provider.dart';
import 'package:autoscan/features/history/domain/repositories/history_repository.dart';
import 'package:autoscan/features/history/presentation/controllers/history_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:autoscan/core/routing/app_shell.dart';
import 'package:autoscan/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autoscan/features/auth/presentation/views/login_screen.dart';
import 'package:autoscan/features/home/presentation/views/home_screen.dart';
import 'package:autoscan/features/diagnostic/presentation/views/diagnostic_screen.dart';
import 'package:autoscan/features/search/presentation/views/manual_search_screen.dart';
import 'package:autoscan/features/history/presentation/views/history_screen.dart';
import 'package:autoscan/features/settings/presentation/views/settings_screen.dart';

GoRouter createAppRouter(AuthController auth) => GoRouter(
  initialLocation: '/home',
  refreshListenable: auth,
  redirect: (context, state) {
    final onLogin = state.uri.path == '/login';
    if (!auth.isAuthenticated) return onLogin ? null : '/login';
    return onLogin ? '/home' : null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/diagnostic',
          builder: (_, _) => const DiagnosticScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, _) => ChangeNotifierProvider(
            create: (_) => CatalogSearchController(
              context.read<SearchRepository>(),
              canLookupVehicle: auth.session?.role != 'auditor',
            )..initialize(),
            child: const ManualSearchScreen(),
          ),
        ),
        GoRoute(
          path: '/history',
          builder: (context, _) => ChangeNotifierProvider(
            create: (_) =>
                HistoryController(context.read<HistoryRepository>())..refresh(),
            child: const HistoryScreen(),
          ),
        ),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      ],
    ),
  ],
);
