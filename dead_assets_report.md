# Dead Asset Audit

## Overview
Total Assets Downloaded: 7,124
Referenced in Registries: 42
Actively Consumed in UI: 8

## Orphaned Asset Groups
- assets/icons/tabler/* (Downloaded as fallback, 0 UI usages)
- assets/icons/maki/* (Downloaded for Maps, currently using Flutter default markers)
- assets/illustrations/enterprise/* (Downloaded for future enterprise features, 0 active UI usages)
- assets/icons/fluent/* (550+ icons downloaded, 1 active usage in Profile)

## Duplicate Assets
- assets/icons/brands/google.svg vs assets/svg/google.svg
- assets/lottie/searching.json vs assets/lottie/booking/searching.json

## Purge Recommendation
Purge all non-registry SVGs from the production APK during Phase 9 (Performance Audit).
