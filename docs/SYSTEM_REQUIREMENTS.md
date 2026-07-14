# docs/SYSTEM_REQUIREMENTS.md
# N.Y Kitchen — System Requirements

> Source of Truth: `PROJECT_BLUEPRINT.md`

---

## Purpose
Document the hardware, software, and platform requirements for running and developing the N.Y Kitchen application.

---

## Development Requirements

### Development Tools
- Flutter SDK (latest stable)
- Dart SDK (bundled with Flutter)
- Android Studio (for Android builds and emulator)
- Visual Studio Community (for Windows builds)
- Git
- GitHub (version control)
- Figma (UI design)

### Platform Requirements (Development)
- Windows 10 or later (development machine)
- Android SDK API Level 21+ (Android 5.0+)

---

## Runtime Requirements

### Android Phone
- Android 5.0 (API 21) or later
- Minimum 2GB RAM recommended
- Storage: Minimum 100MB free space

### Android Tablet
- Android 5.0 (API 21) or later
- Screen: 7-12 inch
- Minimum 2GB RAM recommended

### Windows Desktop
- Windows 10 or later (64-bit)
- Minimum 4GB RAM
- Storage: Minimum 200MB free space

---

## Network Requirements
- **Not required for core operation.** The application is offline-first.
- Internet access is optional for future Supabase cloud features only.

---

## Printer Requirements
- **TODO:** Define supported printer models and interfaces (Bluetooth, USB, network).
- See `docs/RECEIPT_SYSTEM.md` for receipt generation details.

---

## Security Considerations
- The application must not transmit data without explicit user action.
- The application must function on devices with no internet access.

---

## Open Questions
- [ ] Minimum Android API level to support (currently assumed API 21)
- [ ] Supported printer models (Bluetooth vs USB vs network)
- [ ] Windows minimum version requirement

---

## TODO
- [ ] Confirm Android minSdk during Phase 11 deployment preparation
- [ ] Document printer compatibility in `docs/RECEIPT_SYSTEM.md`
