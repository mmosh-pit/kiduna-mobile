# Kiduna Mobile

## Setup

```bash
flutter pub get

# Create your local config from the template, then fill in the values.
cp .env.example .env
```

Config values (`ENV`, `API_BASE_URL`) are loaded at runtime from `.env` by
`flutter_dotenv`. `.env` is bundled as an asset and never committed — only
`.env.example` is. It must hold only non-sensitive config. See CLAUDE.md Section 23.

## Run

`.env` is read at startup, so no extra flags are needed. The app asserts it is
configured, so a missing or empty `.env` fails loudly.

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
