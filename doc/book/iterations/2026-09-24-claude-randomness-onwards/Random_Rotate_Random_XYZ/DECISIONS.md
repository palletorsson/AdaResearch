# Random_Rotate_Random_XYZ — delivery

Sequence `randomness`, hall 6 of 14. 24 September 2026. Verdict: **Development** (the brief's named development candidate).

---

## 1. The question the brief asked

Can an existing configuration make the chapter's proposed rotation-only, matched-rate comparison immediate? **No.** `random_decay_multimesh.apply_grid_config` read one key, `stack_fit`; every rate, channel and seed is an export that no token reaches. As shipped the cubes ran at 0.3 and the prisms at 0.1, with drift, sinking and darkening on, so any difference between the stacks was mostly the setting.

## 2. The study, as a scoped addition

`#study:rotation` on `random_decay_multimesh`:

- both stacks at the cube's rate, 0.3; each stack's kicks scale with its piece count, so every piece expects the same share;
- drift, sinking and darkening off, so only orientation changes;
- the prisms laid on their regular grid (the shipped snap rounds half-step positions and, with twelve columns, leaves 11 distinct columns);
- no seed added: RESET still restores the arrangement, not the future;
- the random stream is untouched: drift draws are still taken, only scaled by zero;
- with no `stack_fit` of its own the study fits the display to 10 m, because a second key cannot be relied on: the grid lane reads `#stack_fit:N` as the rotation shorthand, and a bench stamp hands over only the first key.

A placement without the key is unchanged (probe case A).

## 3. Two museum defects the study exposed

- **Half the prism stack stood outside the hall.** The bench stamp in `ada_run/necklace_hand.json` centres the 10 m display at x 10.5 in a 12 m hall. This hall now opts out with `map_info.museum.artifact_placement: "map"`, the switch the museum provides for reviewed encounters; the display stands at the map's own cell and fits between the walls. `[em-pack] … 5 verbatim + 0 slid of 5, 0 left behind`.
- **The namesake rotator tumbled the museum's furniture.** In the museum, `RandomRotateRandomXYZ`'s fallback search took the first MultiMesh it met, `Lobby_view/FrameMultiMesh`, the lobby's picture frames. Its fallback now accepts only a grid floor (`GridMultiMesh`); in the museum it finds none and turns nothing. Grid maps resolve their floor as before. The chapter no longer mentions it.

### Map fixes the review required

The switch to map placement exposed three more layout faults, all fixed in this hall's map and checked on a museum boot:

- **The rig stood in the wall.** At cell (0,1) the rig's 6.8 m cabinet ran into the west wall and hid its box. At (4,4) or (4,3) it cut the hall across and the museum slid it to reopen the walk. Now `hardware_entropy_decay:90` at (1,6) runs along the right-hand wall facing in: `[em-pack] … 5 verbatim + 0 slid of 5`, no `[em-walk]` severance, all three shapes inside the wall face.
- **The dark sphere stood inside the prism stack.** Moved from (5,10) to (9,7).
- **The exit was cut off.** A 1 m step (structure `2`) in front of the exit door severed the walk (`[em-walk] Random_Rotate_Random_XYZ: SEVERED` in four boots that morning). Row 14, columns 8-10, now `1`. This fault predates the block.

`python tools/map_pathfinder.py check Random_Rotate_Random_XYZ`: OK, 119 of 208 cells reachable.

## 4. Evidence

`commons/testing/probe_rotation_study.gd`, stepping the simulation by hand and reading `_layers` (a headless MultiMesh reads back identity). All pass.

| | check | measured |
|---|---|---|
| A | default unchanged | rates 0.30 / 0.10, colour 0.35 / 0.16, cubes drift |
| B | study before `_ready` (museum) | rates 0.30 / 0.30, colour 0 / 0, drift 0 / 0, sink 0 |
| B | both stacks turn | 1.05° cubes, 1.03° prisms after 30 s |
| B2 | study alone, with a trailing tail | fits to 10 m, no drift, rate 0.30 |
| C | study after `_ready` (grid) | two layers, same settings |
| D | prism grid | 12 evenly spaced columns; shipped snap gives 11 |
| E | stream untouched | study angles equal a matched run's to 0.000000000 rad |
| F | shipped comparison, for the prose | cubes 0.76°, prisms 0.28° after 30 s |

Museum rotator target, measured with a scratch probe: before, `Lobby_view/FrameMultiMesh` (10 instances); after, nothing.

`python tools/map_pathfinder.py check Random_Rotate_Random_XYZ`: OK.

Evidence images: `hall_rr_plan.png` (bench layout, prisms through the right wall) and `hall_rr_plan_map.png` (map placement as now built: the rig along the right wall, the display inside the hall), both taken with `commons/testing/probe_hall_shot.gd`, because the decay scene's own Camera3D, marked current, stole the ordinary museum proof shot.

## 5. The revision

Original at `before.md`; candidate at `after.md`. The old chapter asked the reader to separate drift, rotation and colour and ended by proposing this experiment; the hall now performs it. Preserved: the question; size fixed; "one broad description of disorder can conceal different changes"; the per-instance state; the small-angle-repeated sentence; the DECAY label is not thermodynamics; restoring a reference is not replaying the future; the bridge to Random_Walk. Cut: the pause-and-compare directions, and "A piece can turn substantially while moving only a little", which is no longer true when pieces cannot move. Added: the rig by the door (worn by your movement, no random draw), the matched comparison and what still differs, the slope floor as rotation by place.

## 6. Limits

- **Rotation pace depends on frame rate.** Angles accumulate per frame without scaling by time: about 6.8° at 60 Hz against 4.7° at 90 Hz after five minutes (investigation probe). The chapter says the pace depends on the machine and quotes no rate.
- **The slope floor** (`RotateGridCubes`, which loads `SlopeGradientCubes`) is a 7 × 30 field; most of it lies beyond the hall. The chapter mentions only its tilt by place.
- **Grid lane:** `#stack_fit:10` was read there as the tutorial shorthand and gave a 2 m miniature. The study token avoids the key; the grid parser itself is untouched (INTEGRATION.md).
- **No headset walk.**

## 7. Review and install

Four reviewers and an editor judge; verdict ship with fixes. All ten mandatory sentence replacements are applied (the rig's live scratches against accumulating grime and rust; the pieces may already be turning on arrival; the furthest-turned-piece exercise restored; RESET does not rewind the draws; the slope field shows only its first degrees here; the closing contrasts a sum with a trail; the way on passes through the prisms). Required code fixes applied: the per-piece comment corrected; the study's rationale for the implicit fit names the grid-lane parse; the unused `_study` variable removed. Map fixes above.

**Commit hygiene.** `random_decay_multimesh.gd` and this hall's `map_data.json` both carry another session's uncommitted 19 September edits (`_stack_fit`, `_fit_stacks`, `_toggle_decay`; the structure walls and title). The study depends on them. Commit each file whole, after a forum note naming both, and say in the message that the grid lane changes: the old `#stack_fit:10` gave a 2 m miniature yawed 10 degrees; the study token gives a 10 m display at yaw 0.

| file | before | after |
|---|---|---|
| `final.md` | `4ab6e6a1681f6ad918c3f9d09914c2f4836c995f0d7e0e8edf1279a62dd34c6e` | `a418a65eab6c5a7d9bb107880a9e2c9f2c4d126d0f02aca176a55111373bb4b8` |
| `map_data.json` | `fdb8aa33404f84749f8155d212db196ceb7a9ec1b08ceff8b196ace8e791a6f8` | `9c71df12ff7f593dcf318283e33d0c936048a46d04f23a5f5e66b6b8d0deb9d4` |
| `blurb.md` | `blurb.before.md` | `38b7e0c7e86dce8d547a0969225a84c1c3201d73d60c0ba3985840c18b75020f` |
| `intent.md` | `intent.before.md` | `e1515abb453c92f62bd9f0c16d0565653cd4d5e0787c6238f1298e54885f5f78` |

