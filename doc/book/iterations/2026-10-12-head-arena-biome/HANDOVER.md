# Head Arena in the biome — 12 October 2026

**Superseded layout:** the user then requested the encounter inside the biome itself. See `../2026-10-12-biome-is-the-arena/HANDOVER.md`. The current scene uses one reviewed seed-7 patch as its actual floor, with a compact terrain encounter and no separate stage. The record below describes the preceding three-patch arrangement.

User: “also we should have the arena to be the biome as scene”. Implemented as the arena's setting: the **Head Arena** menu button opens `commons/hazards/catalyst_counterpart/biome_arena.tscn`. No new main-spine encounter or change to the tutorial text.

The scene inherits the existing `base.tscn` XR rig. `biome_arena.gd` creates a level clearing, three full-stage `biome_object.tscn` patches (seeds 7, 11, 19), the existing head/catalyst arena and a MAIN MENU control. The ground of each patch has its original generated collider. This is a composed test landscape, not persistent biome evolution or automatic unlock progression.

User correction: **use the last iterated biome**. The last kept RSI lineage entry is generation 17 (19 September, commit `71cbf320ad`), also the current generator's `GENERATION`. The first arena composition used that generator but disabled catalogue residents and changed the DNA. Corrected to the published profiles: seed 7 = moisture .50 / relief .50 / wildness .60; seed 11 = .80 / .30 / .70; seed 19 = .45 / .40 / .50. All use size 12, full stage, phase 1, community seed 0, drawn foliage and residents on. The actual generator and catalogue code are reused without edits. Recording stays off to avoid overwriting the original RSI evidence.

Validation now reports **44/44 runtime assertions**. For each patch, the probe reads the reviewed `ada_run/biome_rsi/gen_17/state_<label>.json` and compares DNA, community DNA, every non-timing ecology count and resident identities, recipes, local positions, scales and facing data (float tolerance .0001). It also verifies the corresponding resident nodes exist. All match: 12 residents for seed 7, 14 for seed 11 and 8 for seed 19. The existing menu/terrain/pickup/projectile/return checks also pass. Native captures and `checks.json` here now show this corrected version. The shutdown limitation below still applies.

`test_arena.gd` has one new default-false `open_landscape` flag: the standalone scene gets a smaller freestanding display; the original museum court retains its wall. Head state logic, motion, trigger/projectile interaction and three-interruption goal are shared unchanged. Rest/start/reset remain reachable outside the head's travel bounds.

Desktop preview reuses `desktop_player.tscn` with the cave lamp removed before it enters the tree. VR uses the existing pickup, pointer and movement providers. Scene cameras own their environment because the staging menu's WorldEnvironment stays alive when hidden. Low visible curbs mark the finite landscape, with a fall/bounds recovery that rests the encounter. MAIN MENU returns through the previous staging helper. Stuck-detector and mouse state restore on exit.

Run `python -X utf8 tools/test_catalyst_first_abilities.py --menu --render`. The actual menu/staging probe checks the biome ground, camera environment, original head, real pickup/trigger/projectile path, round completion, authoring-file preservation and menu return. Native photographs are taken at standing height inside the scene. Result and logs are copied beside this file after validation.

Known limitation inherited from the previous task: process cleanup crashes after the assertions with Windows access violation 3221225477. A menu-only control run reproduces it without an arena. Do not report a clean process exit. No headset or APK deployment has been performed; installed Quest copies need a new export.

The older `head_arena.tscn` museum destination and all F6 progression scenes remain available. Menu points to the new biome scene only.
