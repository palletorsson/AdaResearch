# Quest export boundary

The Android preset `adaresearchonexy` keeps all runtime resources and includes
Markdown and JSON because the museum loads registries, maps, sequences and book
excerpts at runtime. Development captures are excluded by directory. Exclusion
changes packaging only: the research files stay in the checkout.

The 2026-10-16 reduction adds `ada_run/encounter_pilot`, `reports_tmp`, `tmp`,
`output`, `ada_encyclopedia`, `.codex`, all `node_modules` directories, root
`.tmp*` files and the two APK diagnostic folders to the existing export exclusions.
The old package included about 738 MiB of compressed encounter-pilot files alone.

Do not exclude `ada_run` wholesale. The museum uses its control files and
`em_cartridges`. Do not remove `adaresearch` or `tests` wholesale either: existing
scenes still reference resources there. Imported runtime textures and compiled
scripts under `.godot` are required. Check dependencies before extending the list.

## Verification before installation

1. Export from a fresh Godot filesystem scan with the Android preset. New scripts
   must be included; a live data update cannot supply missing compiled scripts.
2. Run `python tools/verify_museum_apk.py NEW.apk --baseline PREVIOUS.apk --report REPORT.json`.
   This rejects excluded files, checks retention of previous runtime resources,
   follows import/remap targets, compares current map/sequence/registry data and
   verifies the prefab/ghost dependency closure. The baseline must be a known
   usable export from the same project. Inspect intentional resource changes
   separately rather than weakening the retention check to hide them.
3. Run `python tools/test_packaged_museum.py NEW.apk --output DIAGNOSTIC_DIRECTORY`.
   This extracts the actual APK resources, injects only test harnesses and an
   isolated user-data configuration, and exercises the packaged museum and
   artifact scripts. It tests the prefab ghost, KEEP/REPLAY/reconstruction,
   walking to the next instrument, and representative halls. Captures and JSON
   receipts stay local. This is a desktop render of the packaged resources,
   not evidence of Quest comfort or controller usability.
4. Install with `adb install -r NEW.apk` to retain the application's saved data.
   Compare the installed APK hash with the verified file. Open the application,
   inspect a fresh headset log and visit the changed hall. A controller-required
   launch dialog is not an app launch; an old log is not a test of the new build.

For the prefab hall, confirm both labelled tables and the blue ghost in
`Random_Entropy`. WATCH should run the rehearsal, restore the starting experiment
and walk toward the Shannon ledger. Human interaction and headset readability
remain separate checks from the scripted rehearsal.
