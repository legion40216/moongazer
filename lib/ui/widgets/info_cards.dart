import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/moon_state.dart';
import '../../core/astronomy/astro_math.dart';
import '../../core/astronomy/moon_calculator.dart';
import '../../core/astronomy/eclipse_calculator.dart';
import '../theme/app_theme.dart';

// ── Shared formatters ────────────────────────────────────────────────────────

final _dateFmt = DateFormat('d MMM yyyy');
final _timeFmt = DateFormat('HH:mm');
final _dtFmt = DateFormat('d MMM  HH:mm');

String _fmtDT(DateTime dt) => _dtFmt.format(dt.toLocal());
String _fmtDate(DateTime dt) => _dateFmt.format(dt.toLocal());

// ── Card shell ───────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.cardBorder, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── header ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Text(title.toUpperCase(),
                style: AppTextStyles.heading(size: 11)),
          ),
          // ── rows ─────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: AppTextStyles.label()),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.value()),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. Moon Status Card
// ═══════════════════════════════════════════════════════════════════════════════

class MoonStatusCard extends StatelessWidget {
  final MoonState state;

  const MoonStatusCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final pct = (state.illumination * 100).toStringAsFixed(1);
    final age = state.ageInDays.toStringAsFixed(2);

    return _InfoCard(
      title: '🌙  Moon',
      rows: [
        _Row('Phase:', '${state.phase.emoji}  ${state.phase.label}'),
        _Row('Illumination:', '$pct%'),
        _Row('Age:', '$age days'),
        _Row('Distance:', AstroMath.formatKm(state.moonDistanceKm)),
        _Row('Sun distance:', AstroMath.formatKm(state.sunDistanceKm)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. Lunar Events Card
// ═══════════════════════════════════════════════════════════════════════════════

class LunarEventsCard extends StatelessWidget {
  final MoonState state;

  const LunarEventsCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: '📅  Lunar Events',
      rows: [
        _Row('Last new moon:', _fmtDT(state.lastNewMoon)),
        _Row('First quarter:', _fmtDT(state.firstQuarter)),
        _Row('Full moon:', _fmtDT(state.fullMoon)),
        _Row('Last quarter:', _fmtDT(state.lastQuarter)),
        _Row('Next new moon:', _fmtDT(state.nextNewMoon)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. Perigee / Apogee Card
// ═══════════════════════════════════════════════════════════════════════════════

class PeriapsisCard extends StatelessWidget {
  final MoonState state;

  const PeriapsisCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: '🛸  Perigee & Apogee',
      rows: [
        _Row('Next perigee:', _fmtDate(state.nextPerigee)),
        _Row('Next apogee:', _fmtDate(state.nextApogee)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4. Eclipse Card
// ═══════════════════════════════════════════════════════════════════════════════

class EclipseCard extends StatelessWidget {
  final MoonState state;

  const EclipseCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final solar = state.nextSolarEclipse;
    final lunar = state.nextLunarEclipse;

    return _InfoCard(
      title: '🌑  Eclipses',
      rows: [
        _Row(
          'Next solar eclipse:',
          solar == null
              ? 'Calculating…'
              : '${_fmtDate(solar.date)}  ${solar.typeLabel}',
        ),
        _Row(
          'Next lunar eclipse:',
          lunar == null
              ? 'Calculating…'
              : '${_fmtDate(lunar.date)}  ${lunar.typeLabel}',
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 5. Bottom control bar
// ═══════════════════════════════════════════════════════════════════════════════

class BottomControls extends StatelessWidget {
  final bool isSkipping;
  final bool isNorthern;
  final bool soundOn;
  final VoidCallback onToggleSkip;
  final VoidCallback onToggleHemisphere;
  final VoidCallback onToggleSound;

  const BottomControls({
    super.key,
    required this.isSkipping,
    required this.isNorthern,
    required this.soundOn,
    required this.onToggleSkip,
    required this.onToggleHemisphere,
    required this.onToggleSound,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CtrlButton(
            label: isSkipping ? 'Normal Time' : 'Skip Time',
            icon: isSkipping ? Icons.access_time : Icons.fast_forward,
            active: isSkipping,
            onTap: onToggleSkip,
          ),
          _CtrlButton(
            label: isNorthern ? 'S. Hemisphere' : 'N. Hemisphere',
            icon: Icons.public,
            active: false,
            onTap: onToggleHemisphere,
          ),
          _CtrlButton(
            label: soundOn ? 'Sound On' : 'Sound Off',
            icon: soundOn ? Icons.volume_up : Icons.volume_off,
            active: soundOn,
            onTap: onToggleSound,
          ),
        ],
      ),
    );
  }
}

class _CtrlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _CtrlButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
              color: active ? AppColors.accent : AppColors.cardBorder),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 3),
            Text(label,
                style: AppTextStyles.label(size: 9).copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
