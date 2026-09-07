import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:autoscan/core/theme/app_theme.dart';
import 'package:autoscan/core/theme/theme_provider.dart';
import 'package:autoscan/core/routing/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const RepuestosExactosApp(),
    ),
  );
}

class RepuestosExactosApp extends StatelessWidget {
  const RepuestosExactosApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: 'Repuestos Exactos',
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
