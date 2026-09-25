# Random_Cubes — delivery

Sequence `randomness`, hall 5 of 14. 24 September 2026. Verdict: **Development.**

---

## 1. What the hall had

The chapter anchored the die only, and asked the reader to watch "face counts" and a reward. The room holds four works, and three of the chapter's central promises failed in the running game.

| What the chapter needed | What the room did |
|---|---|
| a throw gives a reading | **Almost never on a desktop, as shipped (60 Hz physics); mostly yes in the headset (90 Hz: 15 of 16).** On its felt a landed die hops a few millimetres every physics tick and usually keeps turning about the vertical at 5 to 9 degrees per tick; it never sleeps (bounce 0.4, gravity scale 1.5). Its settle test wanted under 0.02 m/s and 0.1 rad/s for 0.8 s. Of sixteen seeded throws, two were read. |
| the reward rains on the table | **It rained elsewhere, and through the table.** The balls are children of the table but were placed at `global_position` + offset, so they fell at twice the table's offset from the origin: 126 m away in the museum. Falling 3-4 m onto a 3 cm felt, they also tunnelled through it: of 64, 4 were still above the floor after 2.5 s. |
| a desktop visitor can throw | **No reading at all.** The desktop carry emits no XR signal, and the die listened only for XR `dropped`. |
| the coin record counts throws | **It counted the hand.** A held coin is frozen, so its velocity reads zero: lifted 0.2 m and held 0.6 s, it was counted in the hand. Its landing then usually buzzed too and was never counted. |
| "face counts" | The glass shows shares and bars, not counts. |

And the chapter ignored three works doing real work: a two-sided coin with a record that keeps order, a field of 48 bounded random draws, and two cube spawners that forget at random.

## 2. Repairs

All three scripts are shared (dice_throw 22 maps, coin_toss 65). Each change repairs a failure no map depends on; placements that do not trip the failure behave as before.

- **`dice_throw.gd`** — reward balls spawned in local space, with continuous collision so they land on the felt. Desktop hooks (`desktop_hook_target`, `on_desktop_grab`, `on_desktop_drop`) route the carry into the XR handlers. A second way to count as settled: the same face on top, within about 18° of up, at a steady height (1 cm) for 0.8 s. Turning about the vertical is ignored because it cannot change the reported face. The velocity test still passes where it did. The die's physics is untouched: a sweep over seeded throws found no single setting that lets most thrown dice sleep (gravity scale 1.0: 11 of 16; bounce 0: 9 of 16), and each would change the throw on 22 maps.
- **`coin_toss.gd`** — frozen coins (tray or hand) are never read. A per-coin desktop hook unfreezes the coin on release and runs the drop handler. A second way to settle: lying clearly face up or down, normal within 20° and centre within 1 cm over the window.
- **`commons/maps/Random_Cubes/map_data.json`** — `coin_toss` → `coin_toss#disclosure:origin`, which adds the SPIN / DROP / TILT launch gauges in this hall only.
- **The same map, `map_info.museum.artifact_placement: "map"`.** The museum had built this hall from the bench stamp written by the 26 August "force place" pass. Its beads ran past the hall's last usable cell and were clamped: both spawners stood at one point, three fence rows piled up to four slabs into one cell, rows merged into ragged lines of 5 to 10, and two slabs stood sunk inside the raised block (spatial review, from `em_built.json`). The map's own layout is the one the chapter was written for: the die and coin along the entry wall, the two spawners on separate cells of the raised block, eight aligned rows of six slabs. `[em-pack] randomness · random cubes <- Random_Cubes: 53 verbatim + 0 slid of 53, 0 left behind`. Plan: `hall_rc_plan_map.png`.

## 3. Evidence

`commons/testing/probe_random_cubes.gd`, every repair run against the shipped script (before-copy compiled with its `class_name` stripped) as a negative control.

| | check | now | shipped |
|---|---|---|---|
| A | reward rain centre from the table | 0.03 m | 126.5 m |
| F | die dropped on its own felt is read | 1 roll, face 6 | 0 rolls |
| G | sixteen seeded throws (random attitude, speed, spin; XR order) | 16 read, 16 as the face on top | 2 read |
| H | reward rain after 2.5 s | 64 of 64 above the floor, 35 on the felt | 4 above the floor, 0 on the felt |
| B | desktop drop gives a reading | 1 roll, face 6 | 0 |
| C | held coin counted in the hand | 0 | 1 |
| C | one throw adds one to the tally | 1 | — |
| D | desktop-dropped coin falls and is read once | 1, not frozen | — |
| E | `#disclosure:origin` builds and fills the gauges | drop 1.33 m, spin 25 rad/s | — |
| E | default rung builds no gauges | none | — |

`python tools/map_pathfinder.py check Random_Cubes`: OK.

## 4. The revision

Original at `before.md`; candidate at `after.md`. Preserved: the question; the short-sequence and record sentences; the pull-of-the-mean paragraph; the 3.5 paragraph; the symmetry-is-a-reason sentence; the reward rule; "combining the records immediately would erase the intervention you are testing" (moved to the coin, where the gauges make it testable). Cut: the procedural directions with no encounter behind them. Added: what the table does not do (no random number; a flat drop after RESET reads six; on a screen every drop is like that), what the record forgets, the spawners, the fence field as one rule shown in space, and the coin's record against the die's.

Evidence images: `hall_rc_plan_map.png` (as now built); `hall_rc_plan.png`, `hall_rc_vest.png`, `hall_rc_eye.png` (the earlier bench layout).

## 5. Limits

- **No headset throw.** The settle windows were measured in headless physics at 60 Hz.
- **The buzz and the spin are still there.** A landed die still vibrates and, at the desktop's 60 Hz, often keeps turning on its face; at the headset's 90 Hz it mostly comes to rest (15 of 16 shipped throws met the old velocity test there). Only the reading was repaired. The chapter says so, in the review panel's wording: "It may go on rocking slowly on its face after it lands." Changing bounce or gravity would change the throw on 22 maps and is left to Astra (INTEGRATION.md).
- **The coin's in-hand fix assumes XR Tools freezes a held pickable**, which `pickable.gd` does at pick-up.
- **Under the bench layout the fences sealed three walk cells** in the museum's walk map, although the slabs carry no collider. The map-placed build logged no seal.

## 6. Review

Four reviewers (fact-check, space, code, loss and continuity) and an editor judge. Before the judge, the two reviewers who threw dice found the decisive fault: a thrown die almost never gave a reading, because it lands on a face and keeps turning. The first repair (a stillness window over the whole orientation) only covered a flat drop; the face rule above replaced it, and probe case G now throws sixteen seeded dice. The spatial reviewer found the force-placed bench layout clamped (two spawners at one point, up to four slabs in one cell), which led to the map-placement switch. Text fixes applied from the reviews: the reading waits for a face, not for stillness; the glass keeps the face it read even if the rain knocks the die over; no random number decides the face (the only draws scatter the balls); on a screen nothing is thrown and the view sets the face; watch one face's bar; the ribbon's two runs with REFILL; the coin on a screen; the ratio beside the process like 205.5; slab heights by point; the closing names the heap that loses pieces and hands on accumulation.

## 7. The judge's fixes, and install

Editor judge: ship with fixes. Applied:

- **The rain no longer touches the die** (code, `dice_throw.gd`). The first repair brought the rain back over the table, where it landed on the die: reviewers measured the face changed in 9-10 of 12 throws and the die knocked off the table in 6-11 of 12, on every map. The balls now live on collision layer 6 and scan only the static world and each other. Probe case I: 12 of 12 dice still on the felt showing the face read, 4 s after the rain.
- **The shipped die mostly worked in the headset.** At 90 Hz physics the shipped script read 15 of 16 seeded throws (probe case G at 90 Hz); the failure was a 60 Hz, desktop fact. The code comment and section 1 now say so. The new rule reads 16 of 16 at both rates.
- **Settle timers clamped** to 0.05 s per frame in both scripts, so one long frame cannot fill the window; a frozen die (held) is never read; the coin's pose gate tightened to about 37 degrees of flat; the collapsed line continuation removed.
- **Text:** the die "may go on rocking slowly on its face"; compare the top face with the glass after the rain; a dead-level drop reads six and a ten-degree tilt can land another face; watch a face's percentage, which falls on every other throw (the bar moves in 5% steps); 0.5000 is the model's claim printed beside the count (the 10 PRINT console's number did set the odds once the breathing stopped); the block and the slabs placed as built; on a screen the face depends on how far you look down; the balls are scattered and tinted by chance.

Probe `commons/testing/probe_random_cubes.gd`: all pass (A, B, C, D, E, F, G at 60 and 90 Hz, H, I). One negative control was dropped: switching the balls back to layer 1 after they spawn left 11 of 12 dice undisturbed, which did not reproduce the reviewers' measurements on the pre-repair script, so the probe reports that number and does not gate on it.

| file | before | after |
|---|---|---|
| `final.md` | `a7b9c7d24246a4be627e2e3dc74492aac82ea2b9d4a69ac2f38144775a48536f` | `58a37f7c2b4d7ef88230de60a8fd11ed71f5f4331a52fa8ad784958ca60ee3d4` |
| `map_data.json` | `4d7b2e05773064cd1bcffa7fac948b5dbba4184cd61f554d51f948b11fd0096c` | `b90c08efcc188867994a514aecc34bcd5900abeee7ea09208b521c1dd9412415` |
| `blurb.md` | `blurb.before.md` | `476419007c8acf5f68f30d864e369aa6ab3a1329ae904245dda8857751caf843` |
| `intent.md` | `intent.before.md` | `2c22d40349743e43e6ec8d746ca8e0eced7c819f4c18fce71649dba8fdb8f895` |

