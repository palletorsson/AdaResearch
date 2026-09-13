# W0 — WaveFunctions_Intro: the release, by a desktop hand (Fable, 13 September 2026)

Astra's card for active hall 1: exercise the real pickup/drop path and confirm the bob is reachable at both release positions; record two centre crossings with opposite angular velocities under the selected regime's actual config; measure the full installation bounds and check player clearance during a swing. Her status line: **"Partial probe evidence; required pickup/release untested."**

## What was there

The 2026-09-10 pilot gave `control_pendulum` a plumb line and a ring at the rest point, a signed angular-velocity readout and a crossing count, and a revised final that quotes the real integrator. Its probe proved the pendulum's behaviour by **emitting** the pickable's `picked_up` and `dropped` signals. Its live lane also tried the desktop rig's right-click and recorded nothing under the crosshair, the bob unmoved and the pendulum never grabbed. The pilot concluded that a desktop pickup could not be made through input in this project.

That conclusion described the code correctly and misread the cause.

- **The pointer did pick the bob up.** `DesktopInteractionPointer._grab_held` found it on its own grab mask, froze it and eased it toward the aim.
- **Nothing told the pendulum.** The carry called one opt-in hook, `on_desktop_grab`, on the carried body, and the drop called nothing. The pendulum hears only the XR pickable's signals, so its integrator went on writing the bob's position every physics frame and `_on_bob_dropped` never ran.
- **Two of the pilot's readings measured the wrong thing.** The hover read the pointer's interaction ray, whose mask cannot see layer 3, the pickable layer. The bob position was whatever the integrator had just written.

## What it is now

- **The pointer asks the carried body who should hear it.** A `desktop_hook_target` meta on the body names that listener, and `on_desktop_grab` and `on_desktop_drop` are called there. The body itself is asked when the meta is absent, which is exactly the old behaviour for every other pickable. The drop hook is new, and it is called after freeze and collision layers are restored.
- **The pendulum sets that meta on its own bob.** The bob is `grab_sphere_point.tscn`, one scene used by 54 files, so the hooks cannot live in its script. Both hooks go into `_on_bob_picked_up` and `_on_bob_dropped`, the handlers the VR grab reaches. A desktop release is therefore computed by the real code: the angle from where the bob was held, the angular velocity from the hand's own motion samples.

## Evidence

| lane | result |
|---|---|
| bare (`run_wcn_probe.sh intro`) | 26 checks, 1 failure, by design (below) |
| live (`run_wcn_probe.sh intro live`) | 58 checks, 0 failures, `status: passed` |

Grab, carry and release through the right-click, from one standing spot 1.15 m in front of the swing:

| | right | left |
|---|---|---|
| grab ray meets | BobSphere | BobSphere |
| pointer holds, pendulum knows | yes | yes |
| carried bob to the release point | 0.00 m | 0.01 m |
| angle at the release handler | +0.600 rad | −0.600 rad |
| ω at the release handler | 0.0 | 0.0 |
| first crossing | −2.250 rad/s | +2.249 rad/s |
| second crossing | +1.996 rad/s | −1.995 rad/s |
| grab ray at both turning points | BobSphere twice | BobSphere twice |

That gives two visits to the centre with opposite angular velocities, from either side. The first crossing reverses when the release side reverses. The two sides agree to a thousandth, which also shows both releases were from rest.

**Player clearance during a swing**, from every sampled bob position: the swing spans x 2.17 to 2.83 in the hall's cells, leaving 1.11 m to the west wall and 1.11 m to the raised strip. At the integrator's clamp of ±0.45π the worst case is 0.85 m each side. A 0.22 m capsule needs 0.44 m. The installation bounds, the rest point at 0.90 m and the swing envelope against the hall's collision are measured as before. The museum packs all 21 bodies verbatim, with none slid.

**The bare lane's one failure is deliberate.** Under `--script` the grab sphere cannot compile without its autoloads, so the bob never enters the tree. The 12 September ruling is that a script-only run must not pass the release contract. The failure message now names the live lane as where the contract is exercised.

## Two traps in my own first run

- **The pilot's stand put the rig inside a cube.** At 1.5 m in front it stood inside the driven cube two cells behind the pendulum. The stand is 1.15 m now, and the probe checks the rig was not pushed.
- **A from-rest release read ω −1.63.** The hold photograph was taken between the hold and the drop. Its stall made the frame that processed the click run catch-up physics with the bob already free, so the read came late. The release is now read inside the pendulum's own `released` signal, emitted before any physics step, and the photograph is taken before the hold settles.

## Also corrected

- **`technical.md`** still described the February oscilloscope room. It carried code under the names of three real files that is not in them, named two files that do not exist, and quoted the pendulum's release with a flipped sign. It is rewritten from the scripts the map actually places, and every quoted line is checked against its named file.
- **`field_notes.md`** said a desktop pickup could not be made through input. The new entry says why that was wrong.
- **`tutorial.md`** now shows the route a desktop hand takes, quoted verbatim.
- **The grid's `CONFIG_PARAM_NAMES`** still lacked the seven names the 10 September pilots added (`seed`, `octaves`, `offset`, `contrast_seed`, `frequency`, `amplitude`, `persistence`), in HEAD. Committed placements such as the Perlin/Simplex pair's `#seed:20260910#frequency:10` depend on them in the grid lane, which reads an unlisted `#key:number` as a rotation. That hunk is committed on its own. The `"hits"` line beside it belongs to another hand and stays uncommitted.

## Shared code I touched, said plainly

`commons/scenes/DesktopInteractionPointer.gd` is shared interaction code. The change is additive and gated by a meta that only this pendulum sets: every body without it gets the call it got before. The grab hook it builds on was not mine. It arrived with the uncommitted drink-me bottle work of 2026-09-09, unclaimed on the forum. I committed the pointer with it and left `drink_me_bottle.gd`, `drink_me_room.gd` and `scale_me.gd` untouched (forum 260913-9wk5k).

## Not done

- No headset walk and no tracked hand; the desktop pointer is not a hand.
- Whether the ring is legible at hall lighting from the approach is unmeasured beyond the captures.
- `commons/data/book/wavefunctions.json` carries this hall's rewritten book line from the pilot. That file's working-tree diff is a whole-file reindent mixed with other sessions' edits, so I did not commit it.
- Astra's review.

## Files

`commons/scenes/DesktopInteractionPointer.gd`, `commons/artifacts/control_pendulum/control_pendulum.gd`, `commons/grid/GridInteractablesComponent.gd` (the pilot hunk only), `commons/maps/WaveFunctions_Intro/map_data.json` and `{final,intent,blurb,summary,tutorial,technical,critical,field_notes}.md` (carrying the pilot's uncommitted 10 September edits), `commons/testing/probe_wcn_intro.gd` and its live port, `tools/build_wcn_captures_page.py`, and the captures page rebuilt and published. Forum: 260913-cx0rk, 260913-9wk5k.
