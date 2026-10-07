import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/audio_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise the Neil Armstrong audio ("one small step…")
  // Plays once when the app opens, matching the original EXE behaviour.
  await AudioService.instance.init();

  runApp(
    const ProviderScope(
      child: MoonGazerApp(),
    ),
  );

  // Short delay then play, so the app has painted its first frame first
  await Future.delayed(const Duration(milliseconds: 800));
  await AudioService.instance.play();
}
