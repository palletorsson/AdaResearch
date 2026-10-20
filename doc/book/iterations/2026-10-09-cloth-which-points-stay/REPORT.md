# Which points must stay?

Soft Bodies, hall 2 of 9. The first lesson fixed one point of a yielding cube. Here the student keeps the same black PointBody, changes the closed mesh to an open sheet and selects a boundary: an upper row, its two corners, or none. The next hall will move that attachment.

|Part|Before|Now|
|---|---|---|
|Tutorial|Encounter description and pin snippets; optional membrane study|A complete sheet class and host, with the inherited point included unchanged|
|Learning operation|Changing controls|Selecting a set from retained local coordinates, then predicting which entries are free|
|Transfer|No complete learner reconstruction|Change one subdivision constant: 112 → 168 entries; 8 → 12 row pins; still two corners|
|Reflection|A pin formula inside the prose|The encounter and question remain in prose; technical construction belongs to the tutorial|
|Room entrance|Desk occupied the centre arrival|Same desk moved to cell (11,5) from (15,3)|

**27 exact-code checks and 30 actual museum checks passed.** The three printed files are extracted from tutorial.md and executed together under Jolt. Tests check real vertex motion, the fixed corners, transformed-parent coordinates, the explicit rebuild and the same point's grip/action/release. Point contact is compared with an equivalent disabled-contact host. The full subdivision edit runs as another host. Three deliberately wrong versions fail the boundary invariant: forgetting to unpin the old row, combining tests with OR, and selecting from current world coordinates instead of retained local coordinates.

## A test changed the lesson

The initial draft said that repinning a moving edge would hold it exactly where it had reached. A native run contradicted that claim: the flags were set, but newly selected entries continued to move. The tutorial now uses the clearest reliable comparison: release a row to two corners; rebuild before returning to the full row. REBUILD creates a new sheet and retains the same PointBody. This is not an assertion that a pin flag restores dynamic state.

Gold markers initially sampled positions before the body's first physics update. That also failed a transformed-parent test. They now follow the queried positions on physics steps. The small sphere's contact is resolved against a discrete cloth mesh; the contact check passes through a vertex column and compares the result with contact disabled. It does not certify gap-free contact at every point on a coarse mesh.

The installed curtain still has its existing pin toggle. We have not changed that production algorithm. The tutorial asks for the one-way row → corners → release comparison, followed by the existing REBUILD control. Runtime selection is explained without promising unrestricted capture of a moving surface.

## Inside the existing museum

The eight-strip curtain remains the main encounter. Its seven desk buttons were exercised through the real desktop pointer. The installed support can disappear while the pins remain; its physical frame and its simulated attachment are different constructions.

The learner scene was temporarily placed beside the curtain at hall-local (12.5,0,10.5), yaw 180 degrees, unit scale. Its standing approach has floor and capsule clearance. It is included as a runnable study, **not newly installed as a permanent exhibit**. Native images show the row, corners and complete subdivision edit. The released upper edge moved 0.009 metres in the supplied hand-contact run; the image is a moment in that evolving state, not a calibrated material comparison.

The original arrival was blocked by the desk. Only that placement was moved, four metres sideways and two metres into the hall. The route then follows the side aisle, turns through the central opening into the membrane bay, and approaches the exit. All 441 samples on that route have floor support and capsule clearance. An earlier test incorrectly continued the side aisle through the dividing wall; that failed probe is retained. The wall needs a doorway route, not removal.

The view from above exposes a long empty interval between the front encounters and the membrane room. There is room to shorten that walk or articulate it later; this pass repairs arrival and teaches one boundary operation. It does not redesign the whole hall.

The four falling samples and the separate tension membrane remain. The membrane's optional tutorial and reflective passage are preserved byte for byte. Its source, the curtain source and workshop control algorithms are hash-checked unchanged. The optional supplied load-edit lesson was not independently rerun in this pass.

## Evidence and limits

The code files, learner edit, faulty controls, test scripts, hashes, engine logs and before/after texts are included in the review ZIP. These are author-led executable checks using supplied input and XRTools poses. They do not establish headset comfort, Quest performance or an independent student's understanding.

Native screenshots use the compatibility renderer and camera exposure 0.45. Lighting and physics continue between photographs, so before/after images show placement rather than identical illumination. The project logs retain unrelated UID, registry and renderer warnings; the passing runs contain no script/parse or missing-physics-space errors. Local HTML references and rendered code parity are checked; browser layout was not automated.

Next: **Carusell — the support moves**. Boundary selection is now available to reuse; it does not need to be taught again.
