# W1c — WaveFunctions_Sine_Space: clearance, the player's body, and what a change leaves behind (Fable, 13 September 2026)

Astra's card for active hall 3 asks for three pieces of evidence:
- the minimum clearance across the exposed parameter range;
- the implemented route walked with the actual player collider, recording which surfaces collide;
- proof that freeze and parameter changes reach the displayed mesh or material and leave no stale colliders.

Her status line reads **"Runtime report reviewed; actual input and headset pending."**

## Found before starting

This hall carries a complete piece of another session's work from 2026-09-12, uncommitted and unclaimed on the forum:
- a six-row forecourt, which moved the corridor from (6,4) to (6,10);
- a second primary, `sine_flow_tray`, with its registry entry and its own probe (41 checks);
- a new final and rewritten supporting texts;
- an article page and a before snapshot;
- an eight-line adaptation of this hall's probe to the new coordinates.

Astra's current card already lists the tray as a primary. I worked on the corridor, which is what her evidence list is about. I did not modify the tray, its probe or its article (forum 260913-l46cz).

## Evidence

| lane | result |
|---|---|
| bare (`run_wcn_probe.sh sine`) | 65 checks, 0 failures |
| live (`run_wcn_probe.sh sine live`) | 84 checks, 0 failures |

**Minimum clearance across the exposed range.** The probe swept every combination of AMP (0 to 0.45 m, five steps), PHASE offset (0 to π, nine) and running phase (sixteen through a turn). That is 720 states, evaluated on the corridor's own displacement function without rebuilding. For each it recorded the local-X gap the readout prints and the true shortest distance between the two wall curves. The search window was sized per state, so the result is exact.

| | value | where |
|---|---|---|
| narrowest local-X gap | 0.725 m | AMP 0.45, walls in step, phase 0 |
| narrowest true clearance | 0.725 m | the same state; the pinch is symmetric |
| body diameter it must admit | 0.44 m | a 0.22 m capsule |

**The actual player collider.** The desktop rig's own CharacterBody3D walked 7.5 m through the passage at that narrowest setting, with every slide contact kept. Its 87 contacts were all floors: 79 with the corridor's FloorBody and 8 with the hall's Collision. The corridor produced no side contact at any point.

**Changes reach the mesh and leave no collider.** Every control was worked through the desktop pointer:
- **FREEZE:** neither wall mesh changed over 20 frames.
- **AMP**, dragged from 0.20 to 0.34 m: both wall meshes changed, and the readout printed the new amplitude.
- **PHASE**, dragged from 0.60 to 1.89 rad: the right wall's mesh changed and the left wall's stayed exactly as it was, because the offset belongs to one wall.
- **Colliders:** the census was `FloorBody/FloorShape:BoxShape3D` before, after the changes and after RESET. No wall shape appeared at any point.
- **RESET:** the declared 0.20 m, 0.60 rad and running state came back.

## A risk, reported and not changed

While running, the corridor rebuilds both walls through SurfaceTool every frame, about 8,400 vertices each. On this desktop that costs 9 to 12.5 ms of a 16.7 ms frame across runs. A headset's mobile CPU is several times slower, so this is a likely frame-budget problem there. It is not measurable from here and has not been tried. The corridor is placed in eight maps, and either a throttle or a vertex-shader version would change how the walls move in all of them. **That choice is Palle's and Astra's.**

## Traps met

- **The slider handle is a separate body.** It rides the track at the current value, so the drag must start at the handle, not the slider's root. The first drags met nothing. The Perlin/Simplex drag this morning worked only because its handle sat mid-track.
- **The first clearance window was too narrow.** It was a fixed 0.70 m, narrower than the 0.725 m answer, so that run could not show the result was exact.

## Not done

- No headset walk, where the rebuild cost matters most.
- No person at the panel.
- Astra's review.

## Files

- `commons/testing/probe_wcn_sine_space.gd` and its live port.
- `commons/maps/WaveFunctions_Sine_Space/{technical,field_notes,summary}.md`.
- `tools/build_wcn_captures_page.py`, and the captures page rebuilt and published.
- Committed with this hall, attributed to the session that made them: the forecourt map, the tray artifact, its registry entry and probe, the final, and the rewritten supporting texts.
- Left uncommitted: its article page and its before snapshot.

Forum: 260913-l46cz.
