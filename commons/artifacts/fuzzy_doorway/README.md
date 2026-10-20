# A doorway reads your approach

Installed in **Endless Museum → Shaders → Patterns (`Shader_05_Patterns`)**, cell `[8,53]`, rotation 180°. It follows `fuzzy_body` in the rear gallery. Open `museum.tscn` from this folder in the Ada project to enter the actual museum.

The previous sphere let the visitor move an object through overlapping fields. Here the visitor's own approach supplies two inputs: distance from the opening and speed toward it. Fourteen ribs respond. The walking passage remains open in every state.

## Try it

- Walk toward the opening, stop, pass through, then return. LIVE reads the museum desktop body or the active XR head.
- REACH changes the distance over which the doorway responds (1–7 m).
- PACE changes the speed scale used to grade an approach (0.4–2.4 m/s).
- DEMO SLOW and DEMO FAST supply declared inputs at 1 m distance: 0.15 and 2.6 m/s. They let a stationary visitor compare the responses. The console labels them DEMO INPUT.
- SWAP RULES makes fast approaches open the ribs and slow approaches curl them. The rule labels change with the assignment.
- RESET restores reach 4 m, pace 1.2 m/s, the original rule assignment and LIVE input.

The rectangular buttons and dials use the existing native interactive console. Desktop pointer controls and XRTools handles are supported. The artifact never changes the visitor's camera or applies force to the player.

## Exact operation

Distance is measured on the floor plane to a 2.8 m wide opening, using artifact-local coordinates. Height is ignored:

```text
d = length(Vector2(max(abs(local_x) - 1.4, 0), local_z))
approach = max(0, (previous_d - d) / dt)
near = 1 - smoothstep(0.65, reach, d)
fast = smoothstep(0.4 * pace, 1.5 * pace, approach)
open = min(near, 1 - fast)
curl = min(near, fast)
rest = 1 - near
pose_target = Vector2(open, curl) / (open + curl + rest)
```

These are graded memberships and minimum-AND rules with normalized output weights. They are not probabilities or a claim to read intentions. The speed estimate has a separate 0.12 s low-pass filter; the visible pose eases toward the result over 0.24 s. A displacement above 12 m/s resets the speed estimate as a discontinuity. Entering LIVE also initializes the derivative. Retreat contributes zero approach speed.

The same 3,696 vertex entries and indices describe seven pairs of tube ribs. The two pose weights widen/lift or curl their centre curves. The rest source is retained and tested for exact regeneration. There is no recursive accumulation of transformed vertices. Mesh changes are capped at 20 Hz and skipped below a pose change of 0.001; labels refresh at 10 Hz.

Changing ribs have no collision. Fixed supports and museum floor retain collision. Sampled deformation extremes keep rib vertices below 2.3 m outside the central ±0.85 m clearance; the actual museum CharacterBody also traverses the installation in the native test.

## Evidence

`tools/probes/fuzzy_doorway_museum.gd` runs inside the real museum loader. The full receipt has **142/142 passing checks**, including 97 earlier model/sphere checks. It tests membership fixtures, weighted outputs, source retention, bounded geometry, speed sensing, real CharacterBody movement through `move_and_slide`, native pointer controls, simulated XR eye motion and XRTools dial grips, and the supported route to the onward portal.

Command:

```text
python tools/run_encounter_probe.py Shader_05_Patterns --sequence shaders --render --no-bridges --output-tag fuzzy-doorway --probe tools/probes/fuzzy_doorway_museum.gd
```

Actual capture/report: `doc/book/iterations/2026-10-09-a-doorway-reads-your-approach/index.html`.

The comparison photographs use explicitly selected demonstration inputs; separate LIVE movement assertions verify the sensor path. The XR poses are synthetic. Physical headset use, Quest performance and a learner's understanding remain untested. Existing unrelated UID, registry and renderer warnings remain in the engine log.

This is an installed research artifact. It does not rewrite the canonical tutorial, reflective text or sequence order.
