# App core

**마지막 업데이트**: 2026-05-12

## Spec 정보

- **Spec 파일**: `spec/features/booklog-mvp/booklog-mvp.md` (FR-9)
- **Plan 파일**: `plan/PLAN-000001_haruhanjang-mvp/plan.md`
- **구현 상태**: ✅ 완료

## 코드 위치

- **브랜딩**: `flutter/lib/core/app_branding.dart` — `appDisplayName` (`--dart-define=APP_DISPLAY_NAME`)
- **라이트 테마**: `flutter/lib/core/app_theme.dart` — 흰 배경 + 잔디 초록 (플랜 샘플 이미지 톤)
- **API 기본 origin (FR-7)**: `flutter/lib/core/api_config.dart` — `kApiBaseUrlDefault`; 빌드 시 `--dart-define=API_BASE_URL=...`로 덮어쓰기
- **Android 라벨**: `flutter/android/app/src/main/res/values/strings.xml` + `AndroidManifest.xml` `android:label`
- **iOS 표시명**: `flutter/ios/Runner/Info.plist` `CFBundleDisplayName`

## Spec-Code 매핑

| Spec 요구사항 | 코드 / 리소스 | 상태 |
|--------------|---------------|------|
| FR-9 표시명·번들 변경 용이 | 위 파일들 + `app_theme.dart` (밝은 UI 톤) | ✅ |
