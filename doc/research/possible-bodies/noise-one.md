# What does a value become?

[Noise Columns](noise-columns.html) → **Noise One** → [Noise Voxel](/necklace/thread?map=Noise_Voxel&role=primary)

[Three primary works and book passages](/necklace/thread?map=Noise_One&role=primary) · [Sequence progress](/research/waves-chance-noise/index.html#Noise_One)

**The full hall changes the question.** The pair of rings asks how a field becomes relief or colour. The existing landscape extends that into combination. The dark orb brings its own periodic brightness. All three belong in the book.

![Matching rings, field markers and controls in the actual museum](noise-one-pair.png)

## A dark patch has a history

Watch the rings before pausing. FREEZE now holds the current local moment, including both shader stages. SAMPLE moves matching coordinate probes. AMPLITUDE changes how far a value moves a vertex; FREQUENCY changes where the field is sampled.

The initial colour rule sends every negative value to black. **REMAP** gives those differences another address: `(value + 1) / 2`. The relief and field stay the same. A difference that looked absent returns through a change in the receiving operation.

![The cased coordinate readout, showing a negative sample as inward relief and remapped brightness](noise-one-readout.png)

## Try the receiving operation

These are **72 values captured from the Godot instrument**, around its outer equator at t = 4.25 s, coordinate frequency 24 and displacement amplitude 0.04 m. The graph changes the reading of those recorded values; it does not run the VR scene. The photographs show a separate held comparison at frequency 14.

<!-- viewer -->

The field is addressed in local x and z, with no y input. A three-dimensional body is receiving a two-dimensional field. Relief is sampled at vertices, colour across rendered fragments; the displayed scalar is not a measurement of a final lit pixel.

## The landscape that was already here

![The original three-source terrain in a compact basin, with its coordinate frame and contribution controls](noise-one-terrain.png)

The old scene was 200 units wide and placed 20 metres overhead. It now appears at one-fiftieth scale in the room's existing opening. Its complete terrain generator, three noise resources and three coordinate planes remain. SUM, LOW, MIDDLE and HIGH expose the weighted contributions through a panel at the southern edge.

The names deserve inspection: LOW and MIDDLE have nearly equal base frequencies, but different algorithms, seeds and octave counts. The contributions are not three isolated frequency bands. Each view also receives the original three-pass slope-lowering operation. Since that processing comes after addition, the visible SUM need not equal the three processed views added together.

The terrain keeps its violet material. Grass, rock and snow colours are computed in the source but are not enabled as the visible albedo. A calculation can be present without being selected for display. The visible terrain triangles do have a matching collider; the rings' pictured folds do not.

## A pause has an address

![The retained dark orb beside the exit, with its own animation](noise-one-orb.png)

The orb keeps pulsing while the rings are held. It receives a remapped sine through emission, and turns independently. A familiar work can extend the lesson without being converted into another noise demonstration.

![Plan view of the retained room structure and the new terrain staging](noise-one-plan.png)

## What the review established

**49 checks passed in the rendered museum.** The desktop pointer reaches all nine controls. FREEZE holds the shader and CPU phase; 256 rendered GPU field samples differ from CPU values by at most 0.0000153. The pair now uses a reproducible integer lattice hash; legacy single-ring placements retain the original floating hash.

The terrain restores every one of its 10,201 vertices when SUM returns. Each mode has one collider matching the displayed triangles. The recovered map structure and utilities remain unchanged, all three authored works are retained, and the museum reports a connected route. Headset reach, comfort and Quest performance remain for later.

<!-- book -->

[Download the chapter](noise-one-final.md) · [Technical account](noise-one-technical.md) · [Critical account](noise-one-critical.md) · [Captured evidence](noise-one-evidence.json) · [Run receipt](noise-one-run.json)
