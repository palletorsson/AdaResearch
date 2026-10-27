# Floor 46 matter studies on Quest — 2026-10-25

The corrected full-tower debug APK was installed on Palle's connected Quest 3
using `adb install -r`; existing app saves were retained. Installed bytes match
the checked APK, SHA-256
`282b11592f57500efb0efe87cc249606bf21e2110e4cbe75501c7f21797e2df0`.
APK: `ada_run/quest-matter-2026-10-25/ada-matter.apk` (894,888,526 bytes).

The package audit passed with 39,296 previous runtime resources retained,
11,389 valid import/remap entries, 2,831 current map files and zero audit errors.
An isolated desktop load of the APK's actual compiled resources loaded all four
floor-46 studies, confirmed six loose bodies under gravity, imported wood/grit
textures and the pendulum dependency, with zero runtime errors. This is package
load evidence, not a physical headset interaction test.

The first package exposed raw-PNG reads in the Matter material helpers and a
pendulum pickup dependency in the excluded book-study tree. The helpers now load
Godot's imported Texture2D resources. The pendulum carries an unchanged runtime
copy of its study pickup sphere. Sequence paths use `path_join` so the ZIP resource
backend resolves them correctly. No physics parameters, parts, room transforms or
saved layouts changed in this deployment.

Quest launch was requested, but its controllers-required system dialog remains
active and the app has no running PID. Wake both controllers and accept the
headset prompt. Then use **Void / full spine → Vectors & Forces → 046 / Vectors
Act4a KineticForces**. Grip holds parts; trigger points/taps controls and pieces.

Detailed receipts are in `ada_run/quest-matter-2026-10-25/DEPLOYMENT.json`,
`package-verification.json`, `packaged-load.json` and `retention-checks-final.json`.
Failed first-build logs are retained separately. No physical headset play or
comfort check is claimed. No native test/export job remains active.
