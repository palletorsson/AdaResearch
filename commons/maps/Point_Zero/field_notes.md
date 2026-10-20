# Point Zero — field notes

## 2026-10-20 — First rooftop field note: two surfaces, one depth

**Observer:** Palle, playing the Void rooftop. First field note of this rooftop investigation.

**Observation, lightly edited from Palle's report:** Beside a pipe sticking out of the floor, I see a pink dot flickering on the floor. It reminds me that surfaces sharing the same plane can flicker. There is also a cube saying “Point zero”. Where is the real point zero in the map?

**Evidence:** [Palle's screenshot](../../../doc/book/iterations/2026-10-20-roof-arrival-crate/field-note-01.png). The image records the pink patch; flickering over time is reported by the observer and cannot be established from this still alone.

**Question:** Is the pink patch a pipe cap competing with the roof surface? Does the cube identify the actual world origin clearly?

**Baseline:** Point Zero on the Void roof, following removal of its pink artifact leads and above-roof electrical risers. No intervention was made for this observation. No prediction was recorded in advance.

**Source verification:** In `commons/void/architecture.gd`, the roof slab's top is at world y = 0. The next floor's electrical risers still run from y = -6 to y = 0. Their cylinders have closed top caps of radius 0.07 m. These caps therefore occupy the roof plane, beside the larger main pipes. Their centres are (-6.08, 0, -4.2) and (6.92, 0, -4.2). Removing the roof's own riser segments did not remove the caps belonging to the floor below.

**Interpretation:** This is consistent with z-fighting: coincident surfaces competing in the depth buffer. The source supplies a concrete candidate, but the exact patch in the screenshot has not been isolated by a controlled rendering comparison. Near-coplanar geometry elsewhere or overlapping transparent geometry remain alternative explanations until that comparison.

**Origin verification:** `commons/void/floor_content.gd` places WorldZero at (0, 0, 0) on the roof. The black sphere's centre is at that origin. The wire cube is separately shifted to (0, 0.5, 0), so the true zero is at the centre of its bottom face, at floor height—not at the centre of the raised cube. The sphere has a 0.07 m radius, so its lower half intersects the slab. The label names the reference; it is not itself the reference point.

**Decision:** Leave open and preserve the observation. This note makes no geometry change.

**Next comparison, proposed:** Move one lower-floor electrical cap below the roof surface and compare the same camera position before and after. Separately, make the sphere's centre and the cube's offset legible without moving the world origin.

**Literary possibility, not a technical finding:** The first unexpected mark comes from a meeting between two constructed surfaces. The label offers certainty about “zero”, while the body has to discover which part of the object it names.
