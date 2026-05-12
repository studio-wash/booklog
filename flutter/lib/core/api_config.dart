/// Default origin for the deployed Next.js API (no path suffix). Change when the deploy URL changes.
///
/// Override at build time: `flutter run --dart-define=API_BASE_URL=https://other.example`
/// Hide book search UI: `flutter run --dart-define=API_BASE_URL=`
const String kApiBaseUrlDefault = 'https://booklog-wash.vercel.app';
