# Stabilization Report

Date: 2026-06-16
Project: `mobile/`

## Scope

Phase 1 stabilization addressed the analyzer findings from `ANALYZE_BASELINE.md`.

## Modified Files

- `lib/core/design_system/app_elevation.dart`
- `lib/shared/components/app_button.dart`
- `lib/shared/components/app_card.dart`
- `lib/shared/components/app_notification_card.dart`
- `lib/shared/components/searching_radar_widget.dart`
- `ANALYZE_BASELINE.md`
- `STABILIZATION_REPORT.md`

## Fixes Applied

- Replaced deprecated `Color.withOpacity(...)` calls with `Color.withValues(alpha: ...)`.
- Kept behavior equivalent by preserving the original opacity values:
  - `0.05`
  - `0.08`
  - `0.12`
  - `0.5`
  - `0.7`
  - `0.2`
  - dynamic radar painter opacity

## Evidence

Baseline analyzer result before fixes:

```text
9 issues found. (ran in 167.1s)
```

The verification commands for this phase are:

```sh
flutter analyze
flutter test
```

Final verification results are recorded after the commands are rerun.
