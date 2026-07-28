# Kiduna Mobile

## Setup

```bash
flutter pub get
```

## Run

### Mobile (Android / iOS)

```bash
# List available devices / emulators
flutter devices

# Run on the connected device or a running emulator
flutter run

# Or target a specific device
flutter run -d <device-id>
```

### Web

```bash
# One-time: enable web support for this project
flutter create --platforms web .

# Run in Chrome
flutter run -d chrome
```

### Desktop

```bash
# One-time: enable the desktop platform(s) you need
flutter create --platforms macos,windows,linux .

# Run on the current desktop OS
flutter run -d macos     # macOS
flutter run -d windows   # Windows
flutter run -d linux     # Linux
```
