// Plan: single source for user-visible app name.
// Override at build time: flutter run --dart-define=APP_DISPLAY_NAME=하루한장
const String _kDisplayNameDefine = String.fromEnvironment(
  'APP_DISPLAY_NAME',
  defaultValue: '',
);

/// Launcher / in-app title. Change here or via `--dart-define=APP_DISPLAY_NAME=...`.
String get appDisplayName =>
    _kDisplayNameDefine.trim().isEmpty ? 'booklog' : _kDisplayNameDefine.trim();
