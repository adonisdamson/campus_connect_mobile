# Analyze Baseline

Date: 2026-06-16
Project: `mobile/`

## Commands Run

```sh
flutter analyze
```

Result from the required forensic audit run:

- Exit code: `1`
- Total analyzer issues: `9`
- Total errors: `0`
- Total warnings: `0`
- Total infos/lints: `9`

Analyzer evidence:

```text
9 issues found. (ran in 167.1s)
```

## Analyzer Issue Classes

Observed analyzer issue classes:

- `deprecated_member_use`

The analyzer did not report null-safety errors, missing imports, undefined symbols, broken references, or broken route symbols.

## Analyzer Findings

All 9 findings were deprecated `withOpacity` calls:

- `lib/core/design_system/app_elevation.dart:11`
- `lib/core/design_system/app_elevation.dart:19`
- `lib/core/design_system/app_elevation.dart:27`
- `lib/shared/components/app_button.dart:48`
- `lib/shared/components/app_button.dart:49`
- `lib/shared/components/app_card.dart:40`
- `lib/shared/components/app_notification_card.dart:33`
- `lib/shared/components/app_notification_card.dart:36`
- `lib/shared/components/searching_radar_widget.dart:105`

## Broken Imports

Analyzer result:

- Broken imports: `0`

No `uri_does_not_exist`, `undefined_identifier`, or import-resolution errors were reported by `flutter analyze`.

## Broken Navigation

Route definitions found in `lib/app.dart`:

- `/splash`
- `/login`
- `/register`
- `/forgot-password`
- household home route from `AppFlavor.homeRoute`
- collector home route from `AppFlavor.homeRoute`

Navigation scan command:

```sh
rg -n "Navigator\.|pushNamed|routes:|onGenerateRoute|initialRoute|MaterialPageRoute" lib test
```

Baseline finding:

- Analyzer-detected broken navigation: `0`
- Manual risk: navigation mixes named routes and direct `MaterialPageRoute` pushes; full route behavior still needs runtime/widget coverage.

## Duplicated Widgets

Widget scan command:

```sh
rg -n "class\s+\w+\s+extends\s+(StatelessWidget|StatefulWidget)|Widget\s+build\(" lib test
```

Duplicated private widget/component names found:

- `_EmptyState`: household notifications, collector notifications, collector earnings
- `_RoundActionBtn`: household profile and collector profile
- Operational metadata row patterns: `_InfoRow`, `_InfoBit`, `_InfoColumn`
- Menu/list item patterns repeated across profile, drawer, jobs, wallet, help, and earnings screens

Count:

- Repeated widget/component name groups: `4`
- Estimated duplicated private UI component implementations: `10+`

## Duplicated Components

Existing shared component families found under `lib/shared/components/` include:

- `app_button.dart`
- `app_card.dart`
- `booking_card.dart`
- `app_notification_card.dart`
- `stats_row.dart`
- `status_badge.dart`
- `skeleton.dart`
- `app_shimmer.dart`

Baseline finding:

- Card patterns exceed the requested future system of `OperationalCard`, `MetricCard`, and `StatusCard`.
- Button usage is partly centralized in `AppButton`, but screen-local action buttons still exist, for example `_ActionButton` in `lib/features/household/screens/wallet_screen.dart`.

## Unused Assets

Asset scan command:

```sh
find assets -type f
```

Observed asset inventory:

- Asset tree contains hundreds of files including local SVGs, Lottie JSON, PNG/JPG assets, and legacy `icons8`/template illustration families.
- Exact unreferenced asset counts require a path-by-path reference script; the current audit records this as a high-risk cleanup area rather than a deletion list.

Important limitation:

- Assets included by `pubspec.yaml` directory declarations may still be bundled even when not directly referenced by Dart code.

## Dead Code

Static scan command:

```sh
find lib -maxdepth 3 -type f
```

Baseline finding:

- No analyzer-reported dead code errors.
- Candidate dead code exists based on static naming and low direct references, especially legacy shared components and design-system aliases.
- This baseline is not a deletion list; route entry points, platform entry points, and test-only references need verification before removal.

## Design-System Violations Baseline

Scan command:

```sh
rg -n "withOpacity|Color\(|TextStyle\(|BorderRadius\.|EdgeInsets\.|Icons\.|CupertinoIcons\.|LucideIcons\." lib
```

Baseline finding:

- Raw `Color(...)`, `TextStyle(...)`, `BorderRadius`, and `EdgeInsets` usages still exist.
- Some raw constructors are expected inside token files such as `app_colors.dart`, `app_typography.dart`, `app_radius.dart`, and `app_spacing.dart`.
- Phase 2 should separate allowed token definitions from disallowed screen/component usage and drive those violations down with focused scans.

## Icon-System Baseline

Scan command:

```sh
rg -n "\b(PhosphorIcons|Icons\.|CupertinoIcons\.|LucideIcons\.|FontAwesomeIcons\.)" lib
```

Baseline finding:

- Runtime icon usage in Dart is Phosphor-based.
- No `LucideIcons`, `CupertinoIcons`, or `FontAwesomeIcons` usage was found in `lib`.
- Some asset directories still contain non-Phosphor icon families and should be reconciled during rebranding.

## Worktree Baseline

`git status --short` in `mobile/` showed an already dirty worktree before Phase 0 documentation edits, including:

- Modified app, design-system, shared component, auth, household, and collector files
- Deleted old `lib/core/theme/*` files
- Deleted old `lib/shared/widgets/*` files
- Many untracked asset, script, and report files

This report does not revert or normalize existing changes.
