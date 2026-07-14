# docs/ANDROID_DEPLOYMENT.md
# N.Y Kitchen — Android Deployment

---

## Purpose
Document the steps to build and deploy the application for Android devices.

---

## Target Devices
- Android Phone (Android 5.0+ / API 21+)
- Android Tablet (Android 5.0+ / API 21+)

## Build Steps (To Be Detailed in Phase 11)
1. Configure Android signing keystore.
2. Set minSdk, targetSdk, compileSdk in android/app/build.gradle.
3. Run flutter build apk --release.
4. Test release APK on physical devices.
5. (Optional) Build AAB for Google Play distribution.

## Security Requirements
- Debug mode must be disabled.
- No test credentials or API keys in release build.
- ProGuard/R8 obfuscation: TBD.

---

## TODO
- [ ] Define signing keystore strategy
- [ ] Confirm minSdk before Phase 11
- [ ] Test on both phone and tablet before Phase 11 sign-off
