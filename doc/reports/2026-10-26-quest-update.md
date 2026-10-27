# Quest update / 2026-10-26

Version **2026.10.26**, Android version code **3**, is installed on Palle's
connected Quest 3 as `com.example.adaresearchzeroone`. Installation used
`adb install -r`; package UID and application data were preserved. The device's
actual APK SHA-256 matches the signed, checked file:

`e92f46203e89dba1ec0b66b6c23b1ef38c414fd2e2567fafcfb5ed205cdbefb4`.

The app has not started: Quest's controllers-required launch dialog is active.
Wake both controllers and accept that prompt. Then use **Void / full spine →
Cellular Automata → 112 / CA SoftRules** for the enlarged wind tunnel. Four Logic
floors inserted after Transformation moved it from108 to112. Matter studies are
now on50. This package contains the209-floor snapshot.

## Scope of this snapshot

Other sessions continued editing during this long export. The gameplay payload
was frozen at the signed08:38 snapshot; later editor metadata, the new Chains
registry and subsequent work are outside this upload. Exact included source
fingerprints are in `ada_run/quest-latest-2026-10-26/build.json`; later differences
are recorded in `post-snapshot-edits.json` and `DEPLOYMENT.json`. This is not a
claim that the continuously changing checkout is identical to the installed APK.

Godot's wrapper reached its20-minute timeout after exporting assets and starting
Gradle. Gradle completed successfully independently. Three existing scripts had
changed during export: pallet_assemblage, modular/builder and modular/mod_field.
Their captured current GDScript source was included with identity remaps and is
compiled on load. The remaining compiled resources were retained. The final
package is zip-aligned, signed with the same certificate as the prior installed
build, and actual package loads verify all three source scripts.

The packaged museum loader also exposed a missing runtime image-filter shader
under the excluded tools tree. The final APK carries the identical shader at its
old compatibility path and `commons/book/book_image_filter.gdshader`. The source
installation-capture helper now uses the commons path for future exports. No
shader algorithm, game layout, artifact physics or chapter text was changed by
this packaging fix.

## Evidence and limits

- All39,529 previous runtime resources retained; import/remap targets and binary
  dependencies audited. The strict moving-checkout audit flags two registry JSON
  files edited after the snapshot (Chains and Modular); those are explicitly
  recorded as later work, not silently labelled identical to the frozen package.
- Twenty actual-APK tower checks pass, with no runtime errors: three updated
  scripts compile; wind field/wheel/solid mask/solver run; all four Logic rooms
  load; four Matter studies, six live gravity bodies, imported material textures
  and pendulum/slingshot dependencies load.
- Legacy museum load checks pass for Random Entropy (35), Noise Columns (24) and
  Point Animatedcube (35). These are desktop loads of actual APK resources,
  with isolated test application identity and settings decoded from the APK.
- Two old limitations remain open and are **not** reported as passing: the prefab
  ghost rehearsal pauses at its text-review guard; the Random Definition shelf
  references excluded book-study dependencies. Its32 basic load assertions pass,
  but that case has runtime dependency errors. Ghost bytecode/texts and shelf
  scene/scripts match the previous Quest APK; the required shelf study files are
  absent from both. No chapter rewrite or legacy interaction repair was done.
- No physical-headset interaction, comfort or performance acceptance is claimed.
  Fresh launch inspection confirms the controller prompt and no running app PID.

Main receipts: `ada_run/quest-latest-2026-10-26/DEPLOYMENT.json`, `build.json`,
`verification.json`, `final-retention.json`, `signature-final.log`,
`packaged-void.json` and the referenced load logs. Failed attempts remain separate.
