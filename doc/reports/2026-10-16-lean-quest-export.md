# Smaller Quest export — 2026-10-16

The Android export was reduced from **1,229,081,295 bytes to 295,364,965 bytes**:
933,716,330 bytes removed from the package, or **75.97% smaller**. This is 281.7
MiB versus 1,172.1 MiB. The fresh debug export completed successfully in 987.4
seconds, with no script errors in the export log.

The change is an extension of `export_presets.cfg`'s exclusions. Saved encounter
captures, temporary reports, web-development files and task diagnostics no longer
ship. Their local directories and files were not deleted or moved. The large
`ada_run/encounter_pilot` directory still has its 331 immediate subdirectories.
Runtime museum controls, hall cartridges, maps, registries, scenes, scripts and
book excerpts remain included. See [the export policy](quest-export-policy.md).

## Package verification

`tools/verify_museum_apk.py` passes with zero errors:

- 35,174 previous runtime resources retained outside the explicitly excluded trees.
- 10,263 import/remap files have packaged targets.
- 3,274 current data files compared, including all 2,831 map files, sequences,
  artifact registries and canonical museum data.
- All 158 prefab/ghost dependency checks pass, including the three scripts that
  were missing in the older headset build.
- No excluded research/development entries remain in the package, and retained
  compiled resources contain no literal references to the excluded trees.

The smaller APK is `ada_run/lean-apk/ada-lean.apk`. SHA-256:

`3990b60a86348e4fd6383e9c7dbc88f81cceaccc30c19decef4424685e181e52`

Receipts, the prior export configuration, reference scan, build log and package
audit are in the ignored `ada_run/lean-apk` directory. The previous full APK is
retained under `ada_run/quest-prefab-repair`.

## Pending checks and installation

The user asked to keep the reopened Godot editor and desktop session running and
wait to test. **Rendered tests and headset installation are therefore pending.**
The smaller APK has not replaced the installed headset build.

`tools/test_packaged_museum.py` is prepared for the next testing window. It extracts
the APK's actual compiled resources and runs the prefab ghost's save/replay and
reconstruction checks plus Random_Entropy, Random_Definition, Noise_Columns and
Point_Animatedcube hall probes. Its Python syntax has been checked; its new
packaged-resource harness has not yet been executed. Inspect the captures and
resolve any failures before installation.

Then install with `adb install -r`, compare the installed APK hash and confirm a
fresh headset launch/log. Inspect both prefab tables and the ghost in VR. Package
retention checks alone do not establish rendering, interaction or VR usability.
