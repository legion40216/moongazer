import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ClockState {
  final bool isSkipping;
  final DateTime displayTime;
  final DateTime _refReal;
  final DateTime _refSim;

  /// How many simulated minutes pass per real second in skip mode.
  static const double skipFactor = 3600.0; // 1 hour per second

  const ClockState._({
    required this.isSkipping,
    required this.displayTime,
    required DateTime refReal,
    required DateTime refSim,
  })  : _refReal = refReal,
        _refSim = refSim;

  factory ClockState.live() {
    final now = DateTime.now();
    return ClockState._(
      isSkipping: false,
      displayTime: now,
      refReal: now,
      refSim: now,
    );
  }

  ClockState startSkip() {
    final now = DateTime.now();
    return ClockState._(
      isSkipping: true,
      displayTime: now,
      refReal: now,
      refSim: now,
    );
  }

  ClockState stopSkip() => ClockState.live();

  /// Called by the timer to compute the next displayTime.
  ClockState tick() {
    if (!isSkipping) {
      return ClockState._(
        isSkipping: false,
        displayTime: DateTime.now(),
        refReal: _refReal,
        refSim: _refSim,
      );
    }
    final realElapsed = DateTime.now().difference(_refReal);
    final simMs = (realElapsed.inMilliseconds * skipFactor).round();
    final simTime = _refSim.add(Duration(milliseconds: simMs));
    return ClockState._(
      isSkipping: true,
      displayTime: simTime,
      refReal: _refReal,
      refSim: _refSim,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class SimulationClockNotifier extends StateNotifier<ClockState> {
  Timer? _timer;

  SimulationClockNotifier() : super(ClockState.live()) {
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    // Fast ticks in skip mode (smooth animation), slower in live mode
    final interval = state.isSkipping
        ? const Duration(milliseconds: 200)
        : const Duration(seconds: 1);
    _timer = Timer.periodic(interval, (_) {
      state = state.tick();
    });
  }

  void toggleSkip() {
    if (state.isSkipping) {
      state = state.stopSkip();
    } else {
      state = state.startSkip();
    }
    _startTimer(); // restart with the right interval
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
