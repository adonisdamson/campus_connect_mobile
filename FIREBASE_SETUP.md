# Firebase & Google Sign-In Setup

Google sign-in/sign-up is **fully wired in code** (provider, buttons, Firebase
init, backend `/auth/google`). What remains are **console + credential steps**
that can't live in the repo. This doc is the canonical checklist.

Firebase project: **`campus-connect-84893`**

---

## The one security rule

| Artifact | Secret? | Where it lives |
|---|---|---|
| `google-services.json` (client API key, OAuth client ID) | **No** — restricted by package name + SHA-1; designed to ship in the APK | Per-flavor under `android/app/src/{user,partner,admin}/` |
| Firebase **Admin service-account private key** | **YES** — can impersonate any user | Backend env **only** (`backend/.env` locally, Railway vars in prod). Never in this repo, never in an APK. |

`google-services.json` is gitignored here purely to keep the public repo clean
and force CI to use the canonical copy — **not** because it's a credential.

---

## Part 1 — Register SHA-1 (so sign-in returns an ID token)

The `oauth_client` arrays are empty until a SHA-1 is registered. Do **debug**
(local testing) **and release** (shipped APKs), for **all three** packages.

### 1. Get fingerprints

```bash
# Debug keystore — local emulator/device
keytool -list -v -alias androiddebugkey \
  -keystore ~/.android/debug.keystore \
  -storepass android -keypass android | grep -E "SHA1|SHA-1|SHA256"

# Release keystore — shipped APKs (path from android/app/build.gradle.kts)
keytool -list -v -alias campusconnect \
  -keystore android/app/keystore.jks | grep -E "SHA1|SHA-1|SHA256"
```

Copy both **SHA-1** and **SHA-256** for each.

### 2. Add them in Firebase

Firebase console → project **campus-connect-84893** → ⚙️ **Project settings →
General → Your apps**. For **each** Android app:

- `com.campusconnect.user`
- `com.campusconnect.partner`
- `com.campusconnect.admin`

→ **Add fingerprint** → paste debug SHA-1, release SHA-1, and both SHA-256s.

### 3. Enable the Google provider

**Authentication → Sign-in method → Google → Enable** → set a support email →
Save. (Auto-creates the OAuth web client used to verify ID tokens.)

### 4. Re-download configs

**Project settings → Your apps** → download the fresh `google-services.json`
per app and replace:

```
android/app/src/user/google-services.json
android/app/src/partner/google-services.json
android/app/src/admin/google-services.json
```

✅ Success check: the new files have a **non-empty `oauth_client` array**.

### 5. Lock down the API key (real hardening)

[Google Cloud Console → APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials)
→ the **Android key**:

- **Application restrictions → Android apps**: add the 3 package names + SHA-1s.
- **API restrictions**: limit to Identity Toolkit, Token Service, FCM.

An unrestricted key is the only way the shipped file becomes a liability.

---

## Part 2 — Backend service-account credentials (server-only)

`backend/.env` `FIREBASE_*` are placeholders **and the project ID is wrong**, so
`verifyIdToken` 401s until fixed.

### 1. Generate the key

Firebase console → ⚙️ **Project settings → Service accounts → Generate new
private key** → downloads a JSON. **Treat it like a password.**

### 2. Set the three values in `backend/.env` (already gitignored)

```bash
FIREBASE_PROJECT_ID=campus-connect-84893
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@campus-connect-84893.iam.gserviceaccount.com
# Whole PEM on ONE line with literal \n (config/firebase.js converts \n → newline):
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQ...\n-----END PRIVATE KEY-----\n"
```

`FIREBASE_PROJECT_ID` **must** equal `campus-connect-84893` or verification fails
on a project mismatch.

### 3. Production (Railway)

Set the **same three** as Railway environment variables (not a file). Delete the
downloaded JSON from disk afterward. Never paste the private key into this repo.

---

## Part 3 — Verify locally (no deploy)

```bash
cd backend && npm run dev      # must NOT log "Firebase ... disabled"
cd mobile && flutter run -t lib/main_user.dart
```

Tap **Continue with Google** → pick an account → land signed-in; a `User` row
with `firebaseUid` set appears in Postgres.

**Troubleshooting**

| Symptom | Cause |
|---|---|
| `idToken null` in Flutter logs | SHA-1 not registered → redo Part 1.2 |
| Backend `401 Invalid Google token` | Backend creds wrong / project mismatch → Part 2 |
| Backend `503 Google sign-in is not configured` | `FIREBASE_*` env missing on server |
