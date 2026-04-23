# Annotation Demo

A 12×12 reference map that uses every authorial `@`-code in one grid. Not pedagogy — tooling example.

## What to see

Open in the voxel editor, switch to the **Utilities** layer, look at the 3D view:

- **`@void:3:2`** top-left — pale-grey 3×2 block of argued emptiness.
- **`@look:2:2`** top-right — blue 2×2 zone for change-detection (capture diff watches only this).
- **`@sample:pedestal_single:3:3`** middle — yellow 3×3 golden reference, named `pedestal_single`. The signature artifact `interactive_point_origin` sits inside it on a raised pedestal (structure code 2).
- **`@hold:4:2`** bottom-left — cyan 4×2 frozen region. Generator cannot modify any cell inside, regardless of contents.
- **`@breath`** middle-right — single grey cell declaring authored sparseness.
- **`s`** standard spawn, **`t`** standard teleporter.

Each sized region renders as a translucent pad at floor level **and** a 0.6m-tall wireframe volume so you can see the footprint from any angle. The anchor cell (NW corner of the footprint) gets a solid dot.

## Why

Before shipping these codes to actual spine maps, a reference map lets you verify:

1. Every code renders as distinct
2. Size params parse correctly (`@void:3:2` vs `@sample:key:3:3` vs `@hold:4:2`)
3. The key label (`pedestal_single`) shows on the label sprite
4. `map_to_spec.py` extracts the annotations with the right footprint

Run `python tools/map_to_spec.py Annotation_Demo --check` and the spec should list five authorial annotations with footprints and keys preserved.
