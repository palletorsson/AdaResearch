# Transformation / two shafts

User approved the Trans_Pre adaptation after discussing the two falls. Work is
limited to the separate selectable Transformation trial. The original chapter
texts, original map JSON and curated Primitives arrangement are preserved by
SHA256 checks against `before.json`.

## Built

- A arrival on floor 1; B departure to catch floor 2. Narrow corner pads retain
  open shaft centres. Shared pad builder and floor signs read per-floor shaft
  overrides; normal tower defaults remain B and have a native regression check.
- All 13 source placements retain their artifact and interaction configuration.
  Static, rise, rise/turn and rise/turn/scale precede the finished pickup path.
- The original `platform_block.tscn` and `wedge_blocker.tscn` supply the 24 cubes
  and six wp ramps. The latter retain `walkableprism.tscn` collision.
- `cube_walkway.gd` accepts a recipe path. Its default Cube recipe is unchanged.
  New `trials/transformation/pickup_walkway.json` and `.tscn` compose a 1 m high,
  3 m wide, 8 m long deck with 2 m entry/exit ramps and three editable captions.
- Replaced the old 0.6 m timber course; removed the redundant second assembly.
  Raised four pickups to suit the new deck, moved one health cross beside it,
  added route captions and routed around the fixed north/south pillars.
- API save uses the live revision and writes the separate Desktop mirror.
  Native GLB export now supplies the new assembly's defaults to line_parts.json
  so editor copy/place/turn validation understands its 33 parts.
- Scene audio cleanup now kills its fading tween and releases player streams
  when leaving. An intermittent resource-at-exit error was observed before this;
  the final headless and rendered checks exit cleanly.

## Verification

`python tools/test_transformation_two_shafts.py --verbose`

112 assertions using desktop and synthetic tracked XR, actual movement and
physics. Original wp slopes, supported joins, both real six-metre drops,
collection, score isolation, healing, streaming return and retry are exercised.

`python tools/test_transformation_two_shafts.py --capture`

57 assertions in the native Mobile renderer and five screenshots. Compare
`tests/checks.json`, `images/checks.json` and their engine logs. The render run
uses synthetic tracking, not a physical headset.

`node tools/test_transformation_two_shafts_editor.cjs`

Seven checks: native mesh contents, independent copies, movement and rotation,
API validation without saving fixtures, retained source configs, hashes, and
editor/native/Desktop agreement. A fresh browser trial view loads 51 real mesh
snapshots and lists all 33 assembly parts under On this floor.

`python tools/export_void_trial.py transformation`

106 GLB snapshots exported successfully, including prefab palette entries.

No physical headset performance or comfort claim. Earlier full-menu integration
had a renderer/shutdown caveat; it was not rerun or claimed fixed in this pass.
Trans_Introduction's moving platform/gap/hazard design remains future work.

## Primary files

- commons/void/trials/transformation/{layout,rooms,pickup_walkway}.json
- commons/void/trials/transformation/pickup_walkway.tscn
- commons/void/{cube_walkway,architecture,game,soundscape}.gd
- commons/void/{catalog,line_parts}.json
- tools/export_void_trial.py
- tools/probes/{transformation_two_shafts_probe,void_trial_probe}.gd
- tools/test_transformation_two_shafts.py
- tools/test_transformation_two_shafts_editor.cjs

Documentation updated in commons/void/{README,construction-lineage,capacity-tree}.md
and trials/{README.md,reviews.json}. No tutorial or reflective text rewrite.
