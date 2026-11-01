import 'package:autoscan/features/diagnostic/domain/repositories/diagnostic_scanner.dart';
import 'package:autoscan/features/diagnostic/domain/repositories/diagnostic_sessions_repository.dart';
import 'package:autoscan/features/diagnostic/presentation/controllers/diagnostic_controller.dart';
import 'package:autoscan/features/diagnostic/presentation/controllers/diagnostic_detail_controller.dart';
import 'package:autoscan/features/diagnostic/presentation/views/diagnostic_detail_screen.dart';
import 'package:autoscan/features/diagnostic/presentation/views/diagnostic_parts_screen.dart';
import 'package:autoscan/features/team/presentation/views/team_screen.dart';
import 'package:autoscan/features/search/domain/repositories/search_repository.dart';
import 'package:autoscan/features/search/presentation/controllers/catalog_search_controller.dart';
import 'package:provider/provider.dart';
import 'package:autoscan/features/history/domain/repositories/history_repository.dart';
import 'package:autoscan/features/history/presentation/controllers/history_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:autoscan/features/offers/domain/repositories/offers_repository.dart';
import 'package:autoscan/features/offers/presentation/controllers/saved_parts_controller.dart';
import 'package:autoscan/features/offers/presentation/views/saved_parts_screen.dart';
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
    GoRoute(
      path: '/login',
      builder: (_, state) =>
          LoginScreen(invitation: state.uri.queryParameters['invitation']),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/diagnostic',
          builder: (context, _) => ChangeNotifierProvider(
            create: (_) => DiagnosticController(
              context.read<DiagnosticScanner Function()>()(),
              context.read<DiagnosticSessionsRepository>(),
            )..load(),
            child: const DiagnosticScreen(),
          ),
        ),
        GoRoute(
          path: '/diagnostic/:id',
          builder: (context, state) => ChangeNotifierProvider(
            create: (_) => DiagnosticDetailController(
              context.read<DiagnosticSessionsRepository>(),
              state.pathParameters['id']!,
            )..load(),
            child: const DiagnosticDetailScreen(),
          ),
        ),
        GoRoute(
          path: '/diagnostic-parts/:id',
          builder: (context, state) => ChangeNotifierProvider(
            create: (_) => DiagnosticDetailController(
              context.read<DiagnosticSessionsRepository>(),
              state.pathParameters['id']!,
            )..load(),
            child: DiagnosticPartsScreen(
              code: state.uri.queryParameters['code'] ?? '',
            ),
          ),
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
        GoRoute(
          path: '/saved-parts',
          builder: (context, _) => ChangeNotifierProvider(
            create: (_) =>
                SavedPartsController(context.read<OffersRepository>())
                  ..refresh(),
            child: const SavedPartsScreen(),
          ),
        ),
        GoRoute(path: '/team', builder: (_, _) => const TeamScreen()),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      ],
    ),
  ],
);
