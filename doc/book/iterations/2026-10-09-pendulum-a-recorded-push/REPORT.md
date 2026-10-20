# The same release / a recorded push

9 October 2026 · G1 implemented in the existing Forces oscillation hall.

## What changed

One optional comparison at cell[8,20],rotation90°, between the spring row and swings. The inherited PointBody sphere becomes a constrained release handle. Its rod remains1.1m long during pickup. OFF/ON changes the external force while matching damping; SAME INPUT changes B's damping while matching force. Parameter changes reset the pair; REPLAY reuses the stored input. Two sliders and five buttons remain together.

This is an explicit angular point-mass model, extending the equation already used by the museum's pendulum. It is not a Jolt joint or contact solver. Existing engine-driven springs and swings remain in the same hall. Five earlier works and the hall infrastructure token retain their positions; architecture, utilities and spine order remain unchanged. The installer rederived only this hall's plan row.

## Evidence

43 native model/scene/control assertions pass. 21 installed-museum assertions pass, including capture-camera checks. The room probe operates all five controls through the real desktop pointer, pulls the actual inherited point through XRTools with supplied controller poses, verifies its rod and out-of-plane constraint, releases with an intentionally large supplied throw speed, and checks both sliders. The model discards the throw speed as declared. 176 floor/capsule samples clear the comparison approach and east bypass (radius0.28m,height1.7m,masks1|4). This is not a full portal journey or physical headset assessment.

Known-case checks cover zero force, matched input and drag, independent acceleration calculations, replay equality, force cutoff, bound601 snapshots, terminal tolerance, opposite release and finite extreme-control cases across three seeds. The small-angle first zero crossing is0.522083s, compared with a quarter-period reference0.526263s. The undamped small-angle case has maximum relative energy discrepancy1.2593% over20s. Finite-step mechanics remains an approximation.

Default OFF/ON peak angles:34.38° and42.47°. Neither satisfies the terminal settling criterion within20s. Under the same force record, B with drag1.2kg/s satisfies it at5.05s; A at0.35kg/s does not within20s. These are sample-specific results, not a monotonic law for damping.

## What remains open

No physical headset, Quest benchmark or independent student. The playback and hand controls were exercised through native software poses. There is no adaptation, fuzzy inference or feedback controller. No failure rate is estimated. Rendered arrows show the external force only. The plots disclose their clipping limits; the state and measurements are not clipped.

The first core run completed its assertions but crashed during immediate teardown of the manually driven rig, before producing a receipt. Its log is preserved as first-core-engine.log. The harness now stops child handle processing and waits across physics/process boundaries before freeing the rig; subsequent runs exit cleanly. That repair does not establish the cause of an engine-level access violation. Existing UID/Jolt diagnostics and the hall's already-overwide30m layout ruling remain; final logs contain no SCRIPT ERROR or Parse Error.

## Text and handoff

The canonical hall tutorial receives a short optional study linking the complete five-file companion: model, inherited point, constrained point, full apparatus and scene wrapper. All five printed code blocks match tested source. final.md receives three paragraphs on a push ending while its consequence continues, matched input and the authored settling criterion. The primary spring lesson remains intact.

G0 and G1 are built; G2, an agent with an imperfect observation, remains next in the plan. The six original P packages remain proposals. Browser rendering of this report was not tested; native museum images and static link/package checks are separate evidence.
