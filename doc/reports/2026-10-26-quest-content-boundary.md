# Quest gameplay and Ada Encyclopedia authoring

The previous installed APK (`ada_run/quest-latest-2026-10-26/ada-latest.apk`)
is 872,814,518 bytes and contains 44,850 asset entries. Direct `ada_run` entries
alone account for 4,572 files / 84,713,062 compressed bytes. The previous
`all_resources` preset plus broad JSON/Markdown inclusion allowed authoring
content to travel with the game. Documentation and `commons/testing` were
already excluded. These counts describe the existing APK, not a new lean build.

## New boundary

- Keep game scenes, player/XR/input/physics, models/materials/audio, authored
  main floors and arrangements, game catalogue/inventory, curriculum/game texts,
  legacy museum data and all required integrated-floor adapters.
- Exclude all `ada_run` content, evidence/screenshots, separate trial room/layout
  data, receipts, probes and other non-runtime trial files from the Android build.
- Keep 132 identified trial-folder resources as dependencies of integrated
  gameplay or reusable catalogue scenes. A folder named `trials` does not make
  these dependencies disposable. No source artifact or floor arrangement was
  deleted, scaled, rewritten or replaced.
- The `quest_game` export feature disables separate trial selection and CLI
  trial overrides. The full main-tower sequence picker remains. Desktop/editor
  authoring access is retained; Ada Encyclopedia still reads the shared sources.
- A packaging plugin also rejects future non-allowlisted trial and evidence
  files, so a new screenshot cannot slip through just because it was created
  after today's preset was generated.

Run `python tools/configure_quest_content.py --apply` before future Quest exports
when new integrated adapters are introduced. It refreshes the dependency
allowlist and exact preset exclusions without removing authoring sources.
The export policy preserves the existing museum rather than guessing a complete
dependency graph from Godot scenes: many game assets are loaded through JSON
registries. This is not a claim that every unused legacy resource has been
pruned or that a final APK size has been measured.

## Chains screenshot errors

The two reported `.png` captures contain JPEG/JFIF bytes. Thirty-two Chains
evidence files were moved, with per-file SHA-256 verification, to:

`C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/void-trial-evidence/chains_studies`

The two captures now have `.jpg` extensions; their image bytes were preserved.
The old evidence directory contains `.gdignore` so future captures there are
never imported as game textures. Gallery:
<http://localhost:3003/void-trial-evidence/chains_studies/index.html>.

## Android version and editor reload

The headset rejected code 2 because code 3 is installed. On-disk configuration
already said 3 when investigated, so the reported editor export was using an
older preset state. The Android preset now uses **version code 4**, with the
same application identity and signing settings. Do not uninstall or clear data
to work around a downgrade. Reload/reopen the Godot project before exporting;
this also enables the new export plugin. Save any current editor work first.

No new APK was built or installed by this task. Existing Quest saves and the
installed code-3 APK were left unchanged. The next real APK must be inspected
and smoke-tested before deployment; no headset acceptance is claimed here.

## Checks

`tools/test_quest_content_policy.py` uses an isolated real Godot PCK export and
then loads that PCK from an empty runtime folder, without falling back to source
files. It verifies the custom feature, retained game data and adapter, disabled
trial APIs, excluded trial scene/JSON/manifest, excluded run receipts/evidence,
and excluded plugin authoring files. A deliberately mislabeled PNG inside an
ignored evidence directory does not enter the importer. Reports and logs are
under `ada_run/quest-content-2026-10-26`.

This focused test proves the packaging boundary. It does not replace a full
APK resource/dependency check or physical Quest play testing.
