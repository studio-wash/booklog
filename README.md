# booklog

모노레포: **기획·스펙·트래킹**은 저장소 루트, **Flutter 앱**은 `flutter/` 에서 개발·빌드한다.

| 경로 | 내용 |
|------|------|
| `flutter/` | Flutter 프로젝트 (`pubspec.yaml`, `lib/`, `android/`, `ios/`) |
| `plan/` | 플랜 문서 |
| `spec/` | 스펙 |
| `tracking/` | PLAN_INDEX 등 |

로컬에서 앱 실행:

```bash
cd flutter && flutter pub get && flutter run
```

**IDE**: Android Studio / IntelliJ에서는 **`flutter/` 디렉터리를 “Open”** 하면 기존 `.idea`(실행 구성 `main.dart` 등)가 그 안에서 동작한다. 저장소 루트만 열면 루트에 새 `.idea`가 생길 수 있으니, Flutter 전용 작업은 `flutter/`를 루트로 여는 편이 맞다.
