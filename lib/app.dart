import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/theme_controller.dart';
import 'providers/energy_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/equity_modes_screen.dart';
import 'screens/history_screen.dart';
import 'screens/model_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';

class EquiCareApp extends StatelessWidget {
  const EquiCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeController>().mode;
    final hasOnboarded = context.watch<EnergyProvider>().hasCompletedOnboarding;

    return MaterialApp(
      title: 'EquiCare Energy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // Route to onboarding if they haven't finished it
      initialRoute: hasOnboarded ? '/' : '/onboarding',
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/': (_) => const DashboardScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/model': (_) => const ModelScreen(),
        '/history': (_) => const HistoryScreen(),
        '/equity': (_) => const EquityModesScreen(),
      },
    );
  }
}
