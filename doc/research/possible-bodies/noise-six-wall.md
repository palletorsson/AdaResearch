# The room wears the sum

[Noise Voxel](noise-voxel.html) → **Noise 6 Wall** → [Noise Inside Noise](/necklace/thread?map=Noise_Inside_Noise&role=primary)

[Two primary works and their book passages](/necklace/thread?map=Noise_6_Wall&role=primary) · [Sequence progress](/research/waves-chance-noise/index.html#Noise_6_Wall)

There is a room inside the hall. Pink gathers in its corners; the little sphere seems to have borrowed something from its walls. **What would have to change for those apparent folds to carry your feet?**

![The staged shader enclosure, with a clear side entrance and the retained pink interior](noise-six-wall-entrance.png)

The enclosure was already here, but its walls extended beyond the museum hall. It now fits around a five-metre floor with two opposing doors. You can enter, look around, and walk out the other side. The original panel, internal sphere and independent dark orb all remain.

## Hold the moment. Change the dress.

These are two actual Godot captures with the same camera, held phase, Perlin basis and six cloud terms. DRESS switches between the cloud accumulation and the complete pink finish. Compare the floor, sphere and opening. The geometry and collision shapes remain the same.

<!-- dress -->

Grey has its own encoding: a gain of two and clipping into the display range. It lets us inspect one part of the construction. The complete finish adds four terms of turbulence, density, colour, corner and edge shading, roughness and a small change to the lighting normal. A surface can be understood and still be desired.

## One instrument, several surfaces

![The supported panel, four comparison patches, cased readout and four reachable desktop controls](noise-six-wall-readout.png)

**LAYERS** sends 1, 2, 4 or 6 cumulative cloud terms into the room and its sphere. **BASIS** changes the shader generator separately. **FREEZE** holds the current local moment without jumping to time zero. **DRESS** changes the finish. The four little windows retain their separate counts and share the selected clock and basis.

The state now reaches the complete local receiver. The sphere also needed its material applied at the combined CSG root that actually draws it; changing a shader below that node had left a misleading result. The repaired wall and sphere shaders produce matching output at matching UV coordinates.

## How much does one more term add?

This small viewer uses the rendered shader captures from the same held moment. Choose a term count and inspect the contribution it adds. The displayed mean is the red channel sampled at 256 positions in each 96 × 96 capture; it is a display measurement, not the raw field value.

<!-- terms -->

Each term adds a weighted absolute value, then halves the amplitude and doubles the frequency for the next term. At a fixed coordinate, additional nonnegative terms cannot reduce the sum. The total weights are **.5 → .75 → .9375 → .984375**. Actual brightness also depends on the sampled magnitudes and the display mapping. The later terms add smaller variations; they are not merely a uniform brightness adjustment.

The live shader branch begins with this accumulation. The code is in the book below, so the reader can move between the room's appearance and the operation that produces it.

## Follow a cloud towards a seam

The material crosses from a square to an enclosure and a sphere. Each wall piece starts its own UV chart, and the sphere wraps another chart around its body. The same calculation can stretch, repeat or meet a seam. This is a shared procedure on several surfaces; it does not claim continuous world-space sampling around the room.

The seam gives us something to discover. Knowing how the dress fits makes another alteration possible. The grey comparison is also a dress: it maps values into something we can see, with a range that can hide differences.

![The retained dark orb on solid floor near the exit](noise-six-wall-orb.png)

The dark orb continues its sine-driven emission while the room is held. FREEZE has a local reach. The book keeps this second primary because the hall contains more than one time, and because a varying value can still find another operation to receive it.

## The complete hall remains

![Overhead view after the pointer tests, showing the staged room and retained surrounding map](noise-six-wall-plan.png)

All three authored placements remain. The map's recovered structure and utilities are unchanged; the new artifact floor bridges the central opening. The orb moves to solid floor near the exit. The overhead view follows the control tests and shows another state: Value, one cloud term, live greyscale. It is not the held Perlin comparison above.

The large legacy scene resource remains available in other placements. This hall explicitly selects the compact room stage. The shared shaders also receive a normal-map encoding correction, which can change shading in their other consumers.

**39 rendered museum checks passed.** They include held/resumed state, complete local control propagation, an excluded outside receiver, sphere/wall shader readback and unchanged collision shapes through DRESS. All four buttons work through the actual desktop pointer with synthetic mouse events. The desktop body crosses both doors and the floor; the surrounding museum route stays connected.

Headset reach, comfort, legibility and Quest performance remain for the later headset session. The web comparisons are recorded states, so you can review the work remotely.

<!-- book -->

Next is **Noise Inside Noise**: from adding answers to changing the coordinates at which another field is read.

[Download the chapter](noise-six-wall-final.md) · [Tutorial](noise-six-wall-tutorial.md) · [Technical account](noise-six-wall-technical.md) · [Critical account](noise-six-wall-critical.md) · [Captured evidence](noise-six-wall-evidence.json) · [Run receipt](noise-six-wall-run.json)
