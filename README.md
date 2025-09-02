# Snack Hack

A modern Flutter app for discovering, spinning, and hacking together snack ideas. Built with Flutter and Firebase.

## Features

- Spin-based snack suggestion experience
- Smooth animations and polished UI
- Firebase integration (Auth/Firestore/Storage ready)
- Cross‑platform: Android, iOS, Web, macOS, Windows, Linux
- Production-ready project structure

## Tech Stack

- Flutter • Dart
- Firebase (configured via `lib/firebase_options.dart`)

## Getting Started

### Prerequisites

- Flutter SDK installed and set up
- Dart (bundled with Flutter)
- (Optional) Firebase CLI if you plan to deploy or emulate

Verify your setup:

```bash
flutter --version
```

### Installation

```bash
# Clone the repository
git clone https://github.com/Bhuvan9904/Snack-Hack.git
cd Snack-Hack

# Get packages
flutter pub get
```

If you use FVM, adapt commands accordingly.

### Firebase Configuration

This project uses FlutterFire. The generated file `lib/firebase_options.dart` is already present.
If you need to reconfigure:

```bash
# Install FlutterFire CLI if missing
dart pub global activate flutterfire_cli

# Configure Firebase for the project
flutterfire configure
```

Ensure your Firebase project has the relevant products enabled (e.g., Firestore/Storage/Auth) and your platform apps (Android/iOS/Web) are registered.

### Running the App

```bash
flutter run
```

To choose a device/emulator:

```bash
flutter devices
flutter run -d <device_id>
```

### Building

- Android (APK):
```bash
flutter build apk --release
```

- Android (AppBundle):
```bash
flutter build appbundle --release
```

- iOS (requires macOS/Xcode):
```bash
flutter build ios --release
```

- Web:
```bash
flutter build web --release
```

## Project Structure

```
lib/
  main.dart
  firebase_options.dart
  features/
    spin/
      SpinScreen.dart
assets/
```

- `lib/features/spin/SpinScreen.dart`: Core spin experience screen
- `lib/firebase_options.dart`: Auto-generated Firebase configuration

## Scripts and Useful Commands

```bash
# Analyze & format
flutter analyze
flutter format .

# Run tests
flutter test
```

## Contributing

Contributions are welcome! Please:

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Commit changes: `git commit -m "feat: add your feature"`
4. Push to branch: `git push origin feat/your-feature`
5. Open a Pull Request

## License

This project is licensed under the MIT License. See `LICENSE` if present, or include your preferred license.

## Links

- Repository: https://github.com/Bhuvan9904/Snack-Hack

## Acknowledgements

- Flutter team and community
- Firebase & FlutterFire
