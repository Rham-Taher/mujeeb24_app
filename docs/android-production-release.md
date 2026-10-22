# Android release: build speed, artifact sizes, signing and QA isolation

## What the previous build actually contained

Build 40 on commit `2f3274f1` produced `app-release.apk` of **60,200,093 bytes**.
The GitHub artifact ZIP was **27,352,084 bytes**, because ZIP compresses the contents of an APK.
Those numbers must not be confused.

Inspection of this actual APK found native libraries for three ABIs:
`arm64-v8a`, `armeabi-v7a`, and `x86_64`, totaling roughly 59.6 MB
of uncompressed native libraries. A fat APK includes libraries a given phone cannot use.

## Current release pipeline

- A PR runs `flutter analyze`, widget/unit tests, and an Android build using
  **isolated QA signing**; no production signing secrets are made available.
- A push to `master` runs tests, then creates three ABI-specific APKs for
  QA only. The QA app ID ends with `.preview` and its Android label is
  **مجيب 24 (تجريبي)**.
- A **manual workflow dispatch with `production_release: true`**
  requires an approved Android release keystore and an expected signing
  certificate SHA-256. If either is missing or mismatched, the build fails
  before any production artifact is uploaded.
- Production artifacts use the original production app ID, **مجيب 24** as the
  app label, and an actual release signing key; they are not debug signed.
- The production AAB is built only on explicit production release, for
  submission through Google Play.
- APKs are split by `arm64-v8a`, `armeabi-v7a`, and `x86_64`.
  Most contemporary Android phones use `arm64-v8a`, but choose based on
  the target device's supported ABI; don't assume every phone is ARM64.
- Each APK is checked with the Android SDK `apksigner`. Checksums are recorded
  in the separately uploaded build manifest.
- Android CI caches Flutter/pub and Gradle dependencies/build state. This
  reduces repeated downloads, but GitHub-hosted jobs still use clean runners:
  **the first cold build and some updates will take minutes**.
- GitHub CI uses a locked `pubspec.lock` for the release build.
- Artifacts are retained for **14 days**. Archive or promote approved releases
  to a durable release distribution channel before that expiration.

## Production signing secrets (create locally, never paste into a chat)

For a new application without an existing signing identity, create and back up a
unique Android upload keystore locally. **If an app is already published**, use
its existing upload key or the approved Play Console key rotation process.
Do not replace an existing key at random.

An example local, interactive key creation command:

```sh
keytool -genkeypair -v -keystore mujeeb24-upload.jks -storetype PKCS12 \
  -keyalg RSA -keysize 4096 -validity 10000 -alias mujeeb24-upload
```

Choose strong passwords interactively. Store the keystore and recovery copies
outside the Git repository and protect access with business-owned credentials.

Set these GitHub **Actions secrets** in the fork's repository settings:

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Base64 of the binary JKS/PKCS12 keystore |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_ALIAS` | Existing alias in the keystore |
| `KEY_PASSWORD` | Key password (for PKCS12, normally the store password) |
| `ANDROID_RELEASE_CERT_SHA256` | SHA-256 fingerprint of the intended upload certificate |

Example: `base64 -w0 mujeeb24-upload.jks` on Linux (keep output secret).
Obtain the expected certificate fingerprint locally with:

```sh
keytool -list -v -keystore mujeeb24-upload.jks -alias mujeeb24-upload
```

Record the displayed `SHA256` value as the fingerprint secret (with or without
colons). Never share private key bytes, base64, or passwords in a chat.

## Publishing a release

1. Ensure the `master` branch passed quality and Android QA build checks.
2. Verify the Play Console app ID and existing key continuity.
3. Open **GitHub → Actions → Mujeeb24 Flutter CI/CD → Run workflow** from
   `master`.
4. Set **production_release = true** and enable the desired `build_android_apk`
   and `build_android_bundle` options.
5. The workflow validates the keystore fingerprint and the APK signatures;
   verify the checksums, API destination, and build number before distribution.
6. For Google Play submit the **AAB**, not the preview APK. For controlled
   direct installs select the **correct signed production APK by device ABI**.

Do not publish `.preview` APKs. A QA APK uses different signing and a
different app ID; it is NOT a production-ready app or a Play Store update.

## Build-time versus app startup

Build-time dependency downloads and Gradle compilation happen on GitHub's
build runner **before** an APK is delivered. They are not packages
downloaded every time a customer opens the installed app. Slow app startup,
network timeouts, or a sleeping API server require a **separate** on-device
performance test and backend telemetry; build caching does not solve them.

References:
- https://docs.flutter.dev/deployment/android
- https://docs.github.com/en/actions
