import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/main_screen.dart';

class MoonGazerApp extends StatelessWidget {
  const MoonGazerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Force portrait + status-bar style
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return MaterialApp(
      title: 'MoonGazer',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}
