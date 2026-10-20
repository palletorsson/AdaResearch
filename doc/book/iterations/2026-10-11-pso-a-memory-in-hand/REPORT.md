# A memory in hand

Endless Museum · Particle Swarm Optimization · 11 October 2026

Take the black grip into the existing twelve-metre search field. A tilted panel shows the selected point's current coordinate and score, its remembered best in blue, and the group's best encounter in gold. Its six buttons operate the same model as the two original control banks.

## One paragraph for the lesson

Bring the familiar PointBody from Ant Colony. There, the traveller read marks left in the floor; here, each candidate keeps a scored position. Hold a sphere, select it with its trigger and move it away from its blue ring. The present coordinate changes while the old best remains. Release it and take one step: inertia, attraction to its own memory and attraction to the shared best contribute to its next displacement. Place the same sphere at a better position and step again; now the recorded position and score change together. Switch CENTER to EDGE or RIDGE and compare the new gathering. Movement is retained, but memories are evaluated afresh under the new criterion. Explain why the gold ring means best encountered under this rule, then choose another position and predict whether it will replace the selected point's record. In the next hall, the record changes again: we account for bodies arriving, disappearing and being supplied.

Learning elements: **objective function; current state versus memory; position/score pairs; personal and shared attraction; fixed shared record per iteration; changing the criterion.**

## In the museum

Enter **Swarm Intelligence → Particle Swarm Optimization**. The small black grip waits beside the entrance controls. Take it with one hand. Its trigger toggles RUN / PAUSE; the upper row offers RUN / PAUSE, ONE STEP and RESTART. The lower row chooses CENTER, EDGE or RIDGE. The selected rule lights up.

With the other hand, hold a large sphere and press its trigger to select it. Holding that candidate pauses all candidates and blocks stepping, restarting and changing the objective. Release the sphere before stepping. Holding the control grip alone does not pause the search. Drop the panel and it docks after five seconds; regrabbing cancels the return.

The small control grip is not an additional candidate. Twenty-four existing spheres remain the tutorial objects. The panel displays model coordinates in the search plane, rounded to two decimals. Floating-point negative zero is displayed as zero; underlying records remain untouched.

## What changed

Added `pso_hand_control.gd` through the existing museum wrapper: one tilted portable panel, six existing commands and a small dock. The original end controls, personal/shared rings, connecting cylinders and rear comparison exhibits remain. No map, museum-plan, sequence or canonical tutorial/final text changed. All 60 recorded source/text hashes match. The three runtime lesson files remain byte-identical to the printed student files.

The panel reads the existing model. It does not advance the random stream, change a score or preview an uncomputed random movement. The floor cylinders join current and remembered positions; they are not ropes or the three weighted vectors of the next iteration.

## What the comparison asks

CENTER rewards proximity to the centre. EDGE rewards distance from it, which can still lead all points to one corner. RIDGE permits equally good positions along a diagonal; the shared memory can still draw candidates together. A scoring rule that permits several answers does not guarantee a varied population.

This remains close to the reflective text: the sphere is here, its remembered answer is there, and we supplied the rule that makes one answer better. The tutorial implements and tests that rule. The reflection asks what we hear in the word “best.”

## Evidence and limits

**105/105 automated checks passed:** 39 exact printed-code assertions, 54 installed-museum checks and 12 portal checks. Printed-code checks include independent numerical expectations, a zero-social-pull variation, three executed faults and 1,800 bounded iterations across the objectives. The portable observer was also compared with an untouched model for 120 seeded iterations: positions, velocities, memories and random state matched.

Installed tests exercise the actual point and button methods: held selection, worse and better hand placements, unchanged memory until evaluation, objective changes, restart, original bank compatibility, dropped/regrabbed controls and XRTools near-grab/release with a synthetic controller. Three routes have floor support and standing-capsule clearance at 208 sampled positions. The portal coordinator completed Particle Swarm → Population Support → Particle Swarm, with supported arrivals and one resident hall.

The first run caught the displayed minus-zero mismatch. The panel now normalizes zero at display precision. Native image review also prompted larger text, a 25-degree panel tilt and moving the dock instruction beside it so it does not cover the readout. The first failed receipt is retained.

Final runs contain no script or shader errors. Existing UID, Jolt, renderer and loading messages remain in the logs. This is author-operated automated verification, not a physical-headset test, Quest performance measurement or independent learner trial.

Thirteen native Godot captures show the installed museum. Before/after views use identical cameras and the same six-step CENTER state. Optional comparisons run independently. The three close-up records use the same camera: a worse placement, a better placement after stepping, and then a changed objective. Those interventions are deliberately staged through the same point/command interfaces used by the visitor.
