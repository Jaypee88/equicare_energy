import 'package:equicare_energy/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/theme_controller.dart';
import 'providers/energy_provider.dart';

import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await NotificationService.init(); // Initialize Notifications

  final themeController = ThemeController();
  await themeController.load();

  final energyProvider = EnergyProvider();
  await energyProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: energyProvider),
      ],
      child: const EquiCareApp(),
    ),
  );
}
