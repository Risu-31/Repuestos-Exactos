import 'package:autoscan/features/search/data/repositories/api_search_repository.dart';
import 'package:autoscan/features/search/domain/repositories/search_repository.dart';
import 'package:autoscan/features/history/data/repositories/api_history_repository.dart';
import 'package:autoscan/features/history/domain/repositories/history_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:autoscan/core/network/api_client.dart';
import 'package:autoscan/core/routing/app_router.dart';
import 'package:autoscan/core/theme/app_theme.dart';
import 'package:autoscan/core/theme/theme_provider.dart';
import 'package:autoscan/features/auth/data/repositories/api_auth_repository.dart';
import 'package:autoscan/features/auth/domain/repositories/auth_repository.dart';
import 'package:autoscan/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autoscan/features/settings/data/repositories/api_settings_repository.dart';
import 'package:autoscan/features/settings/domain/repositories/settings_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const RepuestosExactosApp(),
    ),
  );
}

class RepuestosExactosApp extends StatefulWidget {
  const RepuestosExactosApp({
    super.key,
    this.authRepository,
    this.settingsRepository,
    this.historyRepository,
    this.searchRepository,
  });
  final AuthRepository? authRepository;
  final SettingsRepository? settingsRepository;
  final HistoryRepository? historyRepository;
  final SearchRepository? searchRepository;
  @override
  State<RepuestosExactosApp> createState() => _RepuestosExactosAppState();
}

class _RepuestosExactosAppState extends State<RepuestosExactosApp> {
  late final ApiClient _client;
  late final AuthController _auth;
  late final HistoryRepository _history;
  late final SearchRepository _search;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _auth = AuthController(
      widget.authRepository ?? ApiAuthRepository(_client),
      widget.settingsRepository ?? ApiSettingsRepository(_client),
    );
    _history = widget.historyRepository ?? ApiHistoryRepository(_client);
    _search = widget.searchRepository ?? ApiSearchRepository(_client);
    _router = createAppRouter(_auth);
  }

  @override
  void dispose() {
    _router.dispose();
    _auth.dispose();
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        Provider<HistoryRepository>.value(value: _history),
        Provider<SearchRepository>.value(value: _search),
      ],
      child: MaterialApp.router(
        title: 'Repuestos Exactos',
        themeMode: theme.themeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
