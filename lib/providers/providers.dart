import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/clock/simulation_clock.dart';
import '../core/astronomy/moon_calculator.dart';
import '../core/astronomy/sun_calculator.dart';
import '../core/astronomy/periapsis_calculator.dart';
import '../core/astronomy/eclipse_calculator.dart';
import '../core/models/moon_state.dart';

// ---------------------------------------------------------------------------
// Simulation clock
// ---------------------------------------------------------------------------

final simulationClockProvider =
    StateNotifierProvider<SimulationClockNotifier, ClockState>(
  (ref) => SimulationClockNotifier(),
);

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      isNorthernHemisphere:
          prefs.getBool('northern_hemisphere') ?? true,
      soundEnabled: prefs.getBool('sound_enabled') ?? true,
    );
  }

  Future<void> toggleHemisphere() async {
    state = state.copyWith(
        isNorthernHemisphere: !state.isNorthernHemisphere);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('northern_hemisphere', state.isNorthernHemisphere);
  }

  Future<void> toggleSound() async {
    state = state.copyWith(soundEnabled: !state.soundEnabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', state.soundEnabled);
  }
}

class AppSettings {
  final bool isNorthernHemisphere;
  final bool soundEnabled;

  const AppSettings({
    this.isNorthernHemisphere = true,
    this.soundEnabled = true,
  });

  AppSettings copyWith({
    bool? isNorthernHemisphere,
    bool? soundEnabled,
  }) =>
      AppSettings(
        isNorthernHemisphere:
            isNorthernHemisphere ?? this.isNorthernHemisphere,
        soundEnabled: soundEnabled ?? this.soundEnabled,
      );
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);

// ---------------------------------------------------------------------------
// Moon state – computed each clock tick
// ---------------------------------------------------------------------------

class MoonStateNotifier extends StateNotifier<MoonState> {
  final Ref _ref;
  Timer? _eclipseTimer;

  // Eclipse data is expensive to compute; cache it and refresh periodically
  EclipseEvent? _cachedSolarEclipse;
  EclipseEvent? _cachedLunarEclipse;
  DateTime? _lastEclipseCalc;

  MoonStateNotifier(this._ref)
      : super(_buildState(
          DateTime.now(),
          isNorthern: true,
          isSkipping: false,
          solar: null,
          lunar: null,
        )) {
    _ref.listen(simulationClockProvider, (_, clock) {
      _update(clock);
    });
    _ref.listen(settingsProvider, (_, __) {
      _update(_ref.read(simulationClockProvider));
    });
    // Compute initial eclipses after first frame
    Future.microtask(_refreshEclipses);
  }

  void _update(ClockState clock) {
    final settings = _ref.read(settingsProvider);
    final dt = clock.displayTime;

    // Refresh eclipse cache if the computed date has changed by >1 day
    if (_lastEclipseCalc == null ||
        dt.difference(_lastEclipseCalc!).abs().inHours > 24) {
      Future.microtask(_refreshEclipses);
    }

    state = _buildState(
      dt,
      isNorthern: settings.isNorthernHemisphere,
      isSkipping: clock.isSkipping,
      solar: _cachedSolarEclipse,
      lunar: _cachedLunarEclipse,
    );
  }

  Future<void> _refreshEclipses() async {
    final dt = _ref.read(simulationClockProvider).displayTime;
    _cachedSolarEclipse = EclipseCalculator.nextSolarEclipse(dt);
    _cachedLunarEclipse = EclipseCalculator.nextLunarEclipse(dt);
    _lastEclipseCalc = dt;

    // Trigger a state rebuild with fresh eclipse data
    if (mounted) {
      _update(_ref.read(simulationClockProvider));
    }
  }

  static MoonState _buildState(
    DateTime dt, {
    required bool isNorthern,
    required bool isSkipping,
    required EclipseEvent? solar,
    required EclipseEvent? lunar,
  }) {
    final pos = MoonCalculator.calculate(dt);
    final sunDist = SunCalculator.distanceKm(dt);

    return MoonState(
      displayTime: dt,
      utcTime: dt.toUtc(),
      illumination: pos.illumination,
      ageInDays: pos.ageInDays,
      phase: pos.phase,
      elongation: pos.elongation,
      moonDistanceKm: pos.distanceKm,
      sunDistanceKm: sunDist,
      lastNewMoon: MoonCalculator.lastNewMoon(dt),
      firstQuarter:
          MoonCalculator.nextPhaseEvent(dt, PhaseEventType.firstQuarter),
      fullMoon:
          MoonCalculator.nextPhaseEvent(dt, PhaseEventType.fullMoon),
      lastQuarter:
          MoonCalculator.nextPhaseEvent(dt, PhaseEventType.lastQuarter),
      nextNewMoon:
          MoonCalculator.nextPhaseEvent(dt, PhaseEventType.newMoon),
      nextPerigee: PeriapsisCalculator.nextPerigee(dt),
      nextApogee: PeriapsisCalculator.nextApogee(dt),
      nextSolarEclipse: solar,
      nextLunarEclipse: lunar,
      isNorthernHemisphere: isNorthern,
      isSkippingTime: isSkipping,
    );
  }

  @override
  void dispose() {
    _eclipseTimer?.cancel();
    super.dispose();
  }
}

final moonStateProvider =
    StateNotifierProvider<MoonStateNotifier, MoonState>(
  (ref) => MoonStateNotifier(ref),
);
