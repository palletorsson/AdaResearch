# Noise 6 Wall — the room wears the sum

Accepted 13 September 2026. Illustrated review: `/research/possible-bodies/noise-six-wall.html`. Next hall: **Noise_Inside_Noise**. This is one completed hall review, not a certification of later maps or earlier batches.

## Retained work and repaired encounter

The original map contains three placements: a shader_noise_space panel at (9,2), its enclosure at (6,6), and dark_sphere at (6,8). All remain. The enclosure opts into stand:room; the orb moves to (10,10), onto solid floor near the exit. The original internal CSG sphere remains part of the enclosure. Two primary tokens correspond to two book passages; the first covers both shader placements.

The old enclosure extended about 18.1 × 13.6 × 27.1 m around a 13 × 13 m hall. Its large walls were outside the place a visitor could enter. The new optional stage has a 5 m floor, a 4.8 m enclosure, a 2.8 m ceiling and two 1.6 × 2.3 m door openings. Its floor bridges the existing central pit. Original structure and utilities are unchanged. The original tscn remains byte-identical and legacy standalone geometry stays available.

The supported panel now has a complete tilted readout and four controls. LAYERS selects 1/2/4/6 cloud terms; BASIS selects the shader generator; FREEZE holds current time, colour and density; DRESS selects emitted cloud sum or full pink finish. The four comparison patches keep their fixed term counts and share the selected basis and clock. Broadcasts reach only room-mode receivers within the same hall.

Two quiet source mismatches mattered: the sphere shader lacked the wall shader's term bound and comparison branch, and its assigned material sat below the CSG combiner that actually draws it. Both are repaired. Both shaders now expose the same accumulation. The full finish retains its separate four-term detail loop. Its signed normal offsets are now encoded into 0–1 tangent-normal channels. That shared normal repair can change other consumers' shading; legacy geometry being preserved is not a claim that faulty shading stays pixel-identical.

## Evidence

Final runner: `ada_run/review_wall.py`; acceptance: `ada_run/wall_acceptance.gd`; base driver: `ada_run/wall_probe_base.gd`. Latest accepted receipt: `ada_run/wall-review-2026-09-13/run.json`. It records PID 26032, 12:52:11–12:52:37 +02:00, exit 0, **39 checks, zero failures**, unchanged fingerprinted sources and unchanged original saved necklace hand. The runner used its own hand snapshot and owned hidden/offscreen rendered process. The prelaunch inventory showed no other Godot process. Earlier runs overlapped another review's GPU work; no timing comparison or headset performance claim is made.

The checks cover all three placements, optional enclosure geometry, controlled CSG root material, separate material instances, held current state, resumed continuity, matching local clocks, the independent orb, basis/count/finish propagation, foreign receiver exclusion, four desktop pointer controls and unchanged collision shapes through DRESS. The actual desktop body crosses the west opening, floor and east opening from x=3.55 to x=9.3475 in hall-local coordinates. The museum reports no severed surrounding route.

Each of the 1/2/4/6 prefixes is rendered through both actual spatial shaders in a 96 × 96 viewport. A 16 × 16 sampling grid reads 256 corresponding pixels. Maximum sphere/wall red-channel difference is zero at every prefix; adding nonnegative terms yields a changing nondecreasing captured comparison. These are display-channel measurements, not raw scalar samples or a CPU/GPU precision equivalence claim.

Captures under the run's Noise_6_Wall directory: panel, readout, entrance, interior-sum, interior-dressed, orb, plan and GPU prefix images. The two interior views have identical camera, held phase, basis and six cloud terms; only the finish changes. The overhead image follows the pointer tests and shows another state (Value, one cloud term, live sum). It should not be captioned as the six-term Perlin comparison.

Baseline files under `baseline/` preserve the original rendered test. It had two failed propagation checks and shader-parameter script errors on the sphere. Its stored-parameter checks are not proof that the original sphere's GPU output followed controls. `staging-run/` is an intermediate capture, not final acceptance. `before/` preserves the complete old hall folder, relevant sources and shared data.

After the accepted run, trailing whitespace was removed from the two shader files. `accepted-source/` preserves the rendered bytes; `formatting-only.json` records both sets of hashes. The verifier requires exact equality after trimming line ends, with no code changes. This formatting correction does not require another rendering run.

## Text and reuse

The chapter, tutorial, technical account, critical account, summary, blurb, intent and artifact inventory are updated together. Prior broad claims about GPU simultaneity, absence of memory, one seed, brightness depending only on weight totals, and pausing by rate zero are corrected in current prose. Historical field notes remain labelled as earlier evidence. Book anchors and primary roles are shader_noise_space then dark_sphere. The next hall is Noise_Inside_Noise; old final prose naming Noise_Perlin_Simplex next was wrong.

Reusable principle: a tabletop comparison can become an enterable enclosure if it shares the same full parameter state, provides a clear floor and doorway, and makes mapping differences explicit. Use opt-in staging so restoration does not resize every legacy placement. A pause must hold all locally owned animation inputs at their current values. A material toggle is a useful comparison only when its additional calculations and its unchanged collision are stated.

Headset reach, legibility, comfort and Quest performance remain deferred. Potential extensions—world-coordinate mapping, editable weights or display gain, and actual geometric displacement—are not existing controls. There are no new agent assignments.
