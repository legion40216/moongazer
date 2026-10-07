# 🌕 MoonGazer

A modern Flutter reimplementation of the classic 1998 Windows astronomy app **MnGazer.exe** by Webster Publishing.

Built mobile-first for iOS and Android, with cross-platform desktop support.

---

## ✨ Features

- **Animated star field** — 1,000 twinkling stars as live background
- **Real moon phase renderer** — hemisphere-aware terminator, craters, glow
- **Live astronomy data** — all calculated from Jean Meeus algorithms (no fake data)
  - Moon phase, illumination %, age in days
  - Moon distance & Sun distance (km)
  - Last/next new moon, first/last quarter, full moon
  - Next perigee & apogee
  - Next solar & lunar eclipse with type (Total / Partial / Annular / Penumbral)
- **Skip Time mode** — accelerated simulation (1 hour/sec) to watch the moon cycle
- **Hemisphere toggle** — Northern / Southern (mirrors moon orientation)
- **Neil Armstrong audio** — "one small step…" plays on launch (NASA public domain)
- **Fully offline** — all calculations run on-device

---

## 🚀 Quick Start

### 1. Prerequisites

```bash
# Install Flutter (https://flutter.dev/docs/get-started/install)
flutter --version  # should be ≥ 3.0.0
```

### 2. Clone your GitHub repo and add these files

```bash
git clone https://github.com/YOUR_USERNAME/moongazer.git
cd moongazer
# Copy all files from this project into the repo
```

### 3. Add the audio asset

Copy your `mngazer.wav` (the Neil Armstrong recording) into:
```
assets/audio/mngazer.wav
```

> The file is NASA content and is in the **public domain** in the US.

### 4. Install dependencies & run

```bash
flutter pub get
flutter run                  # runs on connected device/emulator
flutter run -d chrome        # runs in browser (audio may not play)
```

---

## 🧪 Run Tests

```bash
flutter test
```

Tests validate against known NASA-confirmed astronomical events:
- Full moon Jan 25 2024 17:54 UTC ✓
- New moon Feb 9 2024 22:59 UTC ✓  
- First quarter Mar 17 2024 04:11 UTC ✓
- Perihelion (Sun closest) in January ✓
- Moon distance bounds 356,000–406,700 km ✓

---

## 🏗 Architecture

```
lib/
├── core/
│   ├── astronomy/
│   │   ├── astro_math.dart          — trig utils, formatters
│   │   ├── julian_date.dart         — JD ↔ DateTime (Meeus Ch. 7)
│   │   ├── moon_calculator.dart     — phase, illumination, events (Ch. 47–49)
│   │   ├── sun_calculator.dart      — Sun distance (Ch. 25)
│   │   ├── periapsis_calculator.dart — perigee/apogee (Ch. 50)
│   │   └── eclipse_calculator.dart  — eclipse prediction (Ch. 54)
│   ├── models/
│   │   └── moon_state.dart          — all computed data for one tick
│   └── clock/
│       └── simulation_clock.dart    — real time vs skip-time mode
├── providers/
│   └── providers.dart               — Riverpod: clock, settings, moon state
├── services/
│   └── audio_service.dart           — Neil Armstrong quote on launch
└── ui/
    ├── theme/app_theme.dart         — deep space dark + lime green
    ├── screens/main_screen.dart     — main scrollable screen
    └── widgets/
        ├── star_field_widget.dart   — 1000-star animated canvas
        ├── moon_canvas_widget.dart  — phase renderer with craters
        └── info_cards.dart          — all data cards + bottom controls
```

---

## 📐 Algorithms

All astronomy calculations use **Jean Meeus, "Astronomical Algorithms" 2nd ed.**:

| Feature | Chapter |
|---|---|
| Julian Date conversions | 7 |
| Moon illumination & phase angle | 47–48 |
| Moon phase event dates | 49 |
| Moon distance (km) | 47 Table B |
| Perigee / apogee | 50 |
| Eclipse prediction | 54 |
| Sun distance | 25 |

---

## 🗺 Roadmap (Phase 2+)

- [ ] Moonrise / moonset times (location-aware)
- [ ] Monthly phase calendar
- [ ] Push notifications (full moon, eclipses)
- [ ] Home screen widget
- [ ] Planet positions overlay
- [ ] Dark sky / red-light mode
- [ ] Date picker (jump to any historical/future date)
- [ ] Apple Watch / Wear OS companion

---

## ⚖️ Legal

The original `MnGazer.exe` carries a **Copyright 1998 Webster Publishing Pty Ltd** notice.  
Before publishing under the MoonGazer name or using original moon artwork, confirm you hold the necessary rights.

The Neil Armstrong audio (`mngazer.wav`) is NASA content and is in the **public domain** in the United States.

---

## 🤝 Contributing

PRs welcome. Run `flutter test` before submitting.
