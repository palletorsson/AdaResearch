# Ribbon colour → pattern consolidation

The seven Ribbon_Color rooms were removed from the active map tree and preserved intact under `retired/`. Their 75 placements were reconciled against the existing authored colour and tiling rooms: 38 redundant ribbon copies removed, 37 remaining tokens retained once. The nine recovered colour rooms and four authored pattern rooms were not rearranged.

The remaining collection now follows the authored rooms in the existing `tiling` sequence:

| Map | Collection | Artifacts | Size |
|---|---|---:|---|
| Ribbon_Patterns_01 | Structure and repetition | 11 | 27 × 49 m |
| Ribbon_Patterns_02 | Sampling and comparison | 12 | 45 × 74 m |
| Ribbon_Patterns_03 | Signals and glitches | 14 | 79 × 113 m |

Rooms use two exhibit bays and a clear central aisle. Original scene size and orientation are retained. Recorded AABBs determine reservations, with explicit conservative reservations for unmeasured procedural scenes. These are collection annexes; their large dynamic installations need more space than the old ribbon anchors suggested.

`report.json` lists every duplicate and its retained authored location, every source cell, every destination and every reservation. Deduplication is by artifact token in the colour/tiling scope. Intentional repetitions inside authored teaching rooms and other sequences remain.

Updated: sequence membership, registry sequence tags, primary/secondary roles, book navigation, museum core records, both museum plans, the spine manifest, long-museum index and necklace index. Four existing scenes needed missing readiness flags before the museum could instantiate them: hue_carousel, two_roads, neon_garden and one_bulb_room.

A global necklace export was blocked by older placement records that reported a ring-search distance but omitted its reason. The builder now preserves the displacement and explicitly reports that the reason was not recorded. Three regression tests cover the sparse and complete records; no cause is fabricated.

Verification: 43 runtime checks passed, including each retained artifact instantiated exactly once and capsule sweeps down all three aisles. 358 inventory/layout/ownership checks and 30 Python tests passed. The necklace index passes its source check. There are no script errors in the successful room probes.

The global index tools also report a pre-existing ragged interactables layer in Tutorial_Disco; that map was not edited. A headset walkthrough and teaching development of these collections remain pending. Overview captures contain distance culling and pre-existing scene UI/labels and do not establish headset usability.

Commands:

```powershell
python doc/space/ribbon-pattern-consolidation-2026-09-09/audit.py
python -m unittest tools.test_museum_necklace_ledger tools.test_artifact_roles_book_inventory tools.test_build_spine_artifact_order tools.test_museum_progress
python tools/museum_necklace.py --check
```
