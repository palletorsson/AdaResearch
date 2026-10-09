# Forces review comments — 25 September 2026

Ten review comments addressed through focused revisions to five chapters, one lesson-only artifact fix and two unmodified native museum photographs. Eight other chapters, all thirteen maps, companion manuscripts, code excerpts, sequence order and roles retained.

## Findings

The relation between an instruction and its receiver remains the strongest thread. This pass makes that relation more accurate at the visitor’s body: the coloured passage modifies a stick request, the carrying field yields at its edge, and the default XR controller waits for support before ground control resumes. The code does not make an external physical force act on the visitor’s muscles.

The old cube could preserve a short arrow even at supplied exact rest. The trace in place-before/report.json shows 0.03 m/s followed by zero still displaying a roughly 0.015 m vector and 17 meshes. The corrected lesson quantises below 0.02 m of display length (0.04 m/s) before the redraw deadband; the same sequence now clears the arrow and collapsed component geometry. It returns at 0.041 m/s. Other uses retain their resting-vector behaviour. No physics, force, damping or pickup settings changed.

The review’s boundary wording needed a further correction: returning the ordinary movement providers does not guarantee immediate airborne stick control. The default ground-control gate requires contact. The text now follows the source rather than making a broad promise at the volume edge. The near-pole yaw display also remains idle over a small neighbourhood, not just at the mathematical pole.

## Evidence and limits

Final runs: 10/10 Kinetic Forces checks, 31/31 Force as Place checks; both exit 0 with no GDScript errors. The 18-check baseline reproduces the retained-arrow issue; the first 23-check corrected run and its partially obscured crossing view are retained. The final camera was moved to the centre approach; the existing room was not altered for the photograph. All captures preserve actual architecture, materials, lighting and adjacent works.

The explicit XRToolsPlayerBody fixture has no tracked pose or collision simulation. It receives the real production provider; its move_player returns supplied velocity/contact state. The test checks entry, accumulation, post-contact retention, exit without velocity reset, default ground-control gating, and disabled-provider release. It does not certify a headset traversal, comfort, actual controller jitter, Quest performance or a completed field crossing. Those remain experiential checks. The drag checks use actual buttons and bodies, plus the production walk multiplier; they do not measure subjective resistance.

Existing unresolved-UID and renderer warnings remain in logs. The drag run reports GL buffer/RID and ObjectDB leaks at exit. They did not fail its checks, but are not called a clean shutdown. No live museum bake or save is replaced. Reload the hall to pick up the cube script fix.

## Reference

The [galpy Plummer potential documentation](https://docs.galpy.org/en/latest/reference/potentialplummer.html) supports the short softening footnote; the local gravity_relations.gd provides the actual 0.25 m setting.

## Decisions

### book_forces.001 — Walk-through instruction leads with the desktop

Replaced the desktop-first sentence with the same movement of the stick carrying the visitor progressively less quickly. Kept the explicit distinction from physical tracked walking and from rigid-body drag. Existing WALK controls and three speed multipliers pass native checks; no human resistance or headset comfort claim.

### book_forces.002 — 'Keyboard' steering in the field paragraph

Removed keyboard language, but did not adopt the proposed immediate return of stick steering at the boundary. Leaving ends the field override; the default XR body also requires ground contact for stick control. That condition now appears in the chapter.

### book_forces.003 — The far face is described for the desktop walker

Replaced the desktop-specific exit with the actual XR relation: the field yields, velocity is retained in the air under ordinary gravity, and stick steering becomes available at ground contact. A nontracked XRToolsPlayerBody fixture exercises the production provider and default ground-control gate. Its move_player supplies a contact result; this is not a tracked or collision-solver test.

### book_forces.004 — No pointer from the timing machines to Gravity

Added a short bridge from Choreography to Gravity. The spring’s reference now acquires a body, and the question is whether that centre can respond. Kept Gravity’s deliberate return to the spring and the conveyor’s critical close.

### book_forces.005 — Yaw overstated just off the pole

Removed the claim that a tiny lift makes yaw the most powerful control. Described the growing horizontal component instead, and named the display’s small near-pole idle region. Native slider checks confirm both the unchanged vector at the pole and the held bearing, the idle band and full horizontal yaw.

### book_forces.006 — The held cube's arrow does not disappear

Reproduced the old retained-arrow bug in the loaded hall: after 0.03 m/s, a supplied zero-motion step retained a roughly 0.015 m arrow. Added a lesson-only 0.02 m arrow threshold (0.04 m/s) before the redraw deadband, clearing collapsed component geometry as well. Low, zero, renewed and just-above-threshold movements pass; the legacy resting-vector mode remains. The text now identifies a threshold for displayed stillness instead of promising exact physical rest. Actual controller jitter and headset legibility remain to be assessed.

### book_forces.007 — Hold the promise Flow_Field made

The preceding Change pass already deferred the push to Later in Forces. Added the particles in the last room to the opening’s recall of points and transformations. Kept the encounter’s immediate start with pins and the arrow; no four-hall itinerary inserted.

### book_forces.008 — 'Stops at fifteen' has no unit

Named the acceleration limit as fifteen metres per second squared. The loaded machine and readout confirm the value and units. No change to the slider or field.

### book_forces.009 — Name the softening

Named Plummer softening at the existing EPS explanation and added a short linked footnote. The project source declares EPS = 0.25 metres and uses the softened inverse-cube factor. The galpy Plummer potential documentation supplies a primary implementation reference without burdening the encounter with another derivation.

### book_forces.010 — The one untitled chapter in the sequence

Added What carries you across? above the closing hall. Kept its opening hole, two routes, plank, local field and difference between receivers.
