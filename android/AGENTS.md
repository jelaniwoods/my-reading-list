# Android Core

Read `FOUNDATION.md` before changing generated seams or runtime responsibilities.
Use the pinned Gradle wrapper and JDK 17. Keep Kotlin source independent of any
particular Foundation Plan. Prefer Hotwire Native public APIs and read the pinned
upstream source before adding navigation or WebView plumbing.

Run `bin/android test`, `bin/android lint`, and `bin/android build` after source
changes. Test observable behavior on a device before making runtime claims.
Coordinate seam changes with the service Compiler and update `FOUNDATION.md`.
An exact archived Core revision is required for Compiler publication.
