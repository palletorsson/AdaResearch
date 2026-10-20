# Prefab experiment missing from standalone Quest

The installed headset APK omitted three new resources: `commons/artifacts/prefab_disorder/part_witness.gd`, `commons/ghost_students/hall_walk.gd` and `commons/ghost_students/thought_stream.gd`. The headset's Godot log reported a missing preload at `prefab_disorder.gd:10`. That prevented the bench script from loading, so neither table nor the attached ghost was constructed. The museum placement was present in Random_Entropy; moving it or changing visibility would not fix this failure.

The old APK also contained an earlier prefab registry entry and tutorial. A fresh filesystem scan and Android export completed successfully. `tools/verify_prefab_ghost_apk.py` checks the literal dependency closure, four dynamically loaded source prefabs, the hall placement, registry, tutorial and final. Godot's compiled-script remaps are followed. The old APK fails; the replacement passes all 158 resource checks and all data comparisons.

Installed with `adb install -r` on 2026-10-16 at 10:25 local time, preserving app data. The installed APK's SHA-256 matches the verified export:

`69a19cd0f5aae8dc6dbcff1b9f4f4dd30c138b7e54db840d31c999647c5eccb4`

At this checkpoint, Quest intercepted launch with `LaunchCheckControllerRequiredDialogActivity`. The user needs to wake the controllers and continue into Ada. **Visual and runtime confirmation in the updated headset remains pending.** The log still dated 09:25 belongs to the old session and must not be treated as a new failure or a successful test of the replacement. No claim about headset readability, comfort or interaction follows from package validation.

Check in Random_Entropy for **WHOLE PREFABS** and **PARTS BECOME HYBRIDS**, with the blue ghost beside them. WATCH starts its rehearsal. The next verification is a fresh log and a live scene scan after entering this hall, followed by the visitor's visual check.

Local diagnostic receipts and both APKs are under the ignored `ada_run/quest-prefab-repair/` directory. The report files distinguish the old package, staged assets, final APK, installation and installed-package hash. The runtime apparatus was not redesigned in this repair.
