# Findings for the next agent — session of 2026-09-02/03

Everything here was measured or read from code, not inferred. Each item names the
file, the probe that proves it, the commit that carries it, and whether it is done,
open, or someone's ruling. Read the **Open** column first if you have an hour; read
**Traps** first if you are about to write wall text.

## 1. The museum re-implements the grid's rules, and the copies drift  (DONE, partly)

`endless_museum.gd` does not call the grid's utility code. It carries its own
`_utility_apply_params` (a hand-copy of `GridUtilitiesComponent`'s per-code branches)
and **two** stamping doors: `_stamp_utility` (pearl utility list + authored-map
utilities layer) and `_stamp_gaps` (a pearl's hollow, `crossing:` spec). A fix in one
door does not reach the other.

Measured on the transport cube (`tc`), Palle: "they only work in the grid":

| drift | grid | old museum | blast radius |
|---|---|---|---|
| axis word not x/y/z | +X (cube default) | +Z | `tc:1:auto:auto`, 425 cells in 26 maps (none authored halls) |
| two-parameter cell | waits for a body | auto_start forced on | 11+ authored cells |
| carry mask | n/a (rider is layer 20) | `_stamp_utility` widened to layer 1; `_stamp_gaps` never | Trans_AxisDecomposition `tc:4:z:auto` ran empty |
| seat | placed at surface y | `_stamp_utility` seats collider top on deck; `_stamp_gaps` never | crossing stood 0.5 m proud |

Fix: one implementation. `UtilityRegistry.transport_params()` IS the grid's branch,
moved; `UtilityRegistry.make_carriable()` widens the areas; `_spec_lift()` reads the
`#lift:` suffix once for both doors; `_gap_seat()` seats and prints. Both doors call
them. Commits `925452191`, `c3ff3c154`.

Probes (both PROBE OK): `commons/testing/probe_transport_cube_parity.gd` — holds the
grid rule as reference, runs all 19 corpus token forms, keeps the OLD museum rule as
the negative test (it disagreed on 15/19); `probe_gap_crossing_seat.gd` — proud by
0.500 before, top at 0.000 after, cached start moves with the body, `#lift:1.0` → 1.000.

**Open:** the same copy exists for `rc`, `sc`, `br`, `jp` in `_utility_apply_params`
(~line 7070) and has NOT been swept. Same probe shape applies. Also: the cube's
`CarryArea` is dead scenery — only `DetectionArea` is wired. Also: no row in
`ada_run/em_plan.json` carries `gaps`, so `_stamp_gaps` is unreached until the plan is
re-dealt (`spine_run.py:638` writes them; `em_map_halls.py --apply` does not).

## 2. VFM_09_Legs: the walkers do not do what any prose says  (RULING WAITING, forum 260902-jyp5w)

Seven readers + seven skeptics over `commons/hazards/octapod_crawler/*.gd`:
two–six run ONE rule (most-stretched foot steps, one foot up, no phase/pairs/tripods,
no support polygon); `one_leg` never steps; only `octapod_ik` groups (two tetrapods);
no physics, no collider, body pinned (measured 0.26 m after auto-ground, `legs_room.txt`).
Intent/registry/identity headers (pogo, controlled fall, diagonal trot, alternating
tripods, "the crawler with its hunt off", 1.1 m leash, same scale) are fiction.

Fixed: pace scaled with size (`-basis.z` carries `walker_scale`) → normalised,
`probe_walker_pace.gd` (old 1.40 m/s, new 0.35). Not fixed: `walker_scale:8.0` is
clamped to 4.0 in silence (`leg_walker_base.gd:144`). Text written TRUE TO THE CODE
(`VFM_09_Legs/final.md`), `probe_legs_tutorial.gd` answers can_lift per count.
**Palle's ruling:** keep the honest text, or re-author the walkers with real gaits.

## 3. Transformation chapter: code bugs the wall text now describes  (OPEN, one-liners)

My drafts were wrong in ~80 places; another session's ten-agent critique rewrote all
seven rooms (`a7e7504da`). The rewrite is true to the code, and the code is broken:

- `grower_block` never breathes: `min`/`max` not in `CONFIG_PARAM_NAMES`
  (`GridInteractablesComponent.gd:16-132`) → become yaw shorthand → `float(true)`=1.0.
- `pusher_block` slides +X regardless of `axis:z`: `_end_pos` baked in `_ready`
  (`pusher_block.gd:38-41`) before the deferred config; `distance`/`pause` not in the allow-list.
- `scale_me` writes the player's position (x,z ×2, y=5) at pickup and never reverts
  (`scale_me.tscn`: `scale_duration 1000`); a teleport out of a museum hall.
- `pick_up_cube` cannot be carried: an `Area3D` that frees itself on `body_entered`.
- `science_screen#mode:wave|bars` ARE modes and LOCK the screen so it never scans.

Text issues still standing in the rewrite: spin defined as "how many turns" (false for
spin-2); "puts you back at the door" unverified; an invented code block in
RotationSpectacle (`tunnel_angle`/`layer_speed` exist in no file); the 3t wall sentences
("Translation produces space as navigable extent") dropped from AxisDecomposition; the
same cube sentence in five rooms. Field notes per room carry the full critique.

## 4. Change chapter: read stopped, probe done  (OPEN — the rooms are not written)

`probe_change_tutorials.gd` PROBE OK on all three tutorials: forward difference settles,
centred is exact on the parabola; valley at x=1.500; midpoint beats left/right;
`pi_estimate(10)=3.305`, `(1000)=3.1436`; workbench ∫=2.8638 ("2.864" ✓); FTC both
directions; the step at x=2 breaks direction two only.

**The finding to build on:** `riemann_pi` is NOT π from rectangles. Its scene is
`algorithms/spacetopology/riemann_pi/pi_infinity_surface.gd` — the prime-counting
function π(x) against x/ln x and li(x) (its `law` axis). The blurb and the tutorial's
whole third block describe a station that is not in the room. It rhymes: a second
staircase chasing a smooth law, which IS the room's claim ("discrete becomes continuous
by limit"). Keep it as the chosen disagreement; fix `Accumulation_Riemann/blurb.md` and
`tutorial.md`. Other stale prose: "the previous map" (Accumulation_Area was folded),
"fifth map" (second), Change_Reconciliation's "door into the chamber" (no chamber),
`ftc_bridge` is a standing statement with a pulse, not a round-trip animation;
`paper_regatta` (Flow hero, rung 3) stands in the rung-1 room; `zeno_staircase` is
Change_Intro's turn (its rate IS the tutorial's secant).

## 5. Spine and museum state changes  (DONE)

- 17 catalyst chambers deferred out of the spine (`deferred_maps` + reason),
  `map_authored.json` minus Chamber_Boolean/Swarm, transformation chamber pearl dropped.
  `3aeb773c4`. Orphaned by it: only the catalyst apparatus.
- `boolean_tunnel` moved to the east edge of Trans_RotationSpectacle (r4 c12) via
  `/api/maps/cell-edit`; nothing refused it.
- Plan re-derived and re-baked by the breather (forum 260902-r7vso): museum shows
  current maps; **Melencolia hall unbaked**, one fossil segment (`array_tutorial|trans
  introduction`) in the bake.
- Rooms written: VFM_07_Gravity (`probe_gravity_tutorial.gd`: three-body divergence
  ratio 510,190×), VFM_09_Legs, Trans_* ×7 (then rewritten). Red Thread page at 24 written.

## 6. The loop doc  (DONE, with open instrument faults)

`doc/MUSEUM_LOOP.md` now opens with THE GOAL (a hall works when the visitor's loop
closes; close the gap toward the claim; chosen disagreement, not zero; the loop must make
itself cheaper) and the Nature of Code lineage (64 registry tokens named
`example_N_M`/`exercise_N_M`). Open faults the doc lists with lines: `coherence.py` ranks
by todo count; `walk_evaluator.py` keeps a second traversal (extract `stamp.py
walk_doors`); the fast survey never reads the museum; `shelf.json` has no invalidation;
nothing consumes `doc/curation_lessons.json`.

## Traps — each cost a published wrong sentence this session

1. **The `.tscn` overrides the `.gd` exports.** Open the scene; report what ships.
2. **`#key:value` reaches the artifact only if the key is in `CONFIG_PARAM_NAMES`.**
   Otherwise it silently becomes a yaw.
3. **Config arrives deferred, after `_ready`.** Whatever `_ready` bakes ignores the token.
4. **How a visitor meets a thing is a fact about its code**, not the registry entry.
5. **One rule, two readers, drifts.** When a grid thing misbehaves in the museum, find
   the museum's second reader; move the rule to `UtilityRegistry`; gate with a probe that
   keeps the old rule as the negative test.
6. **GDScript has no `%e`.** The line prints raw and the assert beside it passes.
7. **A SceneTree probe's `_init` is not live:** `global_position` reads zero, `_ready`
   of added children waits for the first frame (stage in `_init`, read in `_process`),
   and the physics space is closed (`_settle_floor` aborts the whole call).
8. **The bake merges; a matching count is not a matching set.** Compare keys.

## Commits this session (AdaResearch)
`01c3fb71d` gravity · `b08d26172` legs + pace fix · `3aeb773c4` chambers + tunnel ·
`35f5bd431` transformation (superseded by `a7e7504da`) · `925452191` tc parity ·
`c3ff3c154` gap seat · `20de65028` loop goal. Encyclopedia: manuscript rebuilds.
