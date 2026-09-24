# Foundation Android Core

A conventional Kotlin/Gradle Hotwire Native shell, composed into a First Draft
Foundation at `android/`. Open this directory in Android Studio or use the
Gradle wrapper. The fixture opens `https://example.com`; a generated application
supplies its Rails origin and public navigation.

Install JDK 17 and Android SDK platform 36 plus build-tools 36.0.0, set
`ANDROID_HOME` to the SDK directory, then run:

```sh
bin/android doctor
bin/android test
bin/android lint
bin/android build
```

The debug APK is `app/build/outputs/apk/debug/app-debug.apk`. It builds for Android
9 (API 28) and later and targets Android 16 (API 36). No signing account is
needed for this development build. `bin/android release` builds an unsigned
release APK; store signing and distribution remain application work.

For local development, launch a Debug build with the Intent string extra
`APP_ROOT_URL`. HTTPS origins are accepted; HTTP is limited to localhost,
loopback, and the Android Emulator's host alias `10.0.2.2`. Release builds ignore
the override. The generated Foundation's `ANDROID_PREVIEW.md` owns the Revyl
workflow and the commands at the Rails repository root.

The shell uses Hotwire Native Android 1.3.1, Kotlin 2.3.0, AGP 8.13.2, Gradle
9.2.0, Material Components 1.14.0, and ConstraintLayout 2.2.2. The Gradle
distribution has a pinned checksum. Dependency freshness is reviewed separately
from lint so upstream releases do not change whether an existing pin builds.
Material navigation icons retain their Apache 2.0 license and source revision
in `THIRD_PARTY_NOTICES.md`.

See `FOUNDATION.md` for the Compiler seams and runtime responsibilities.
