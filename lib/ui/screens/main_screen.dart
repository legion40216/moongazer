import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/providers.dart';
import '../../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/star_field_widget.dart';
import '../widgets/moon_canvas_widget.dart';
import '../widgets/info_cards.dart';

final _localFmt = DateFormat('HH:mm:ss  d MMM yyyy');
final _utcFmt = DateFormat('HH:mm  d MMM yyyy');

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moonStateProvider);
    final settings = ref.watch(settingsProvider);
    final clock = ref.watch(simulationClockProvider);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Persistent star field fills entire screen ──────────────────
          Positioned.fill(
            child: StarFieldWidget(
              numStars: 1000,
              height: screenSize.height,
            ),
          ),

          // ── Scrollable content on top ──────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // ── Hero section: moon + time + hemisphere ──────
                        _HeroSection(state: state),

                        const SizedBox(height: 8),

                        // ── Time display ────────────────────────────────
                        _TimeCard(
                          localTime: state.displayTime,
                          utcTime: state.utcTime,
                          isSkipping: state.isSkippingTime,
                        ),

                        const SizedBox(height: 4),

                        // ── Data cards ──────────────────────────────────
                        MoonStatusCard(state: state),
                        LunarEventsCard(state: state),
                        PeriapsisCard(state: state),
                        EclipseCard(state: state),

                        const SizedBox(height: 80), // space above bottom bar
                      ],
                    ),
                  ),
                ),

                // ── Sticky bottom controls ───────────────────────────────
                BottomControls(
                  isSkipping: clock.isSkipping,
                  isNorthern: settings.isNorthernHemisphere,
                  soundOn: settings.soundEnabled,
                  onToggleSkip: () =>
                      ref.read(simulationClockProvider.notifier).toggleSkip(),
                  onToggleHemisphere: () =>
                      ref.read(settingsProvider.notifier).toggleHemisphere(),
                  onToggleSound: () async {
                    await ref.read(settingsProvider.notifier).toggleSound();
                    final enabled =
                        ref.read(settingsProvider).soundEnabled;
                    if (enabled) {
                      AudioService.instance.play();
                    } else {
                      AudioService.instance.stop();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero: moon canvas + hemisphere badge ───────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final dynamic state; // MoonState

  const _HeroSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Moon
          MoonCanvasWidget(
            illumination: state.illumination,
            elongation: state.elongation,
            isNorthernHemisphere: state.isNorthernHemisphere,
            size: 220,
          ),

          // Hemisphere badge – top right
          Positioned(
            top: 12,
            right: 16,
            child: _HemisphereBadge(isNorthern: state.isNorthernHemisphere),
          ),

          // Phase label – bottom centre, over the moon
          Positioned(
            bottom: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.75),
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '${state.phase.emoji}  ${state.phase.label}  '
                '· ${(state.illumination * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.value(size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HemisphereBadge extends StatelessWidget {
  final bool isNorthern;
  const _HemisphereBadge({required this.isNorthern});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentFaint,
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        isNorthern ? '🌐  N' : '🌐  S',
        style: AppTextStyles.label(size: 11)
            .copyWith(color: AppColors.accentDim),
      ),
    );
  }
}

// ── Time card ──────────────────────────────────────────────────────────────────

class _TimeCard extends StatelessWidget {
  final DateTime localTime;
  final DateTime utcTime;
  final bool isSkipping;

  const _TimeCard({
    required this.localTime,
    required this.utcTime,
    required this.isSkipping,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Local time:', style: AppTextStyles.label()),
              const Spacer(),
              if (isSkipping)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentFaint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text('⏩ SKIP',
                      style: AppTextStyles.label(size: 9)
                          .copyWith(color: AppColors.accent)),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(_localFmt.format(localTime),
              style: AppTextStyles.hero(size: 16)),
          const SizedBox(height: 6),
          Text('Universal time (GMT):',
              style: AppTextStyles.label()),
          const SizedBox(height: 2),
          Text(
            '${_utcFmt.format(utcTime)} UTC',
            style: AppTextStyles.value(),
          ),
        ],
      ),
    );
  }
}
