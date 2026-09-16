# Follow a corner through the cube

The small experiment is this: move one vertex and find which surfaces must follow. This room builds on the triangle hall's three positions per face and the polyhedra hall's distinction between a visible boundary and a physical obstacle.

## Begin with connections

At `cube_lines`, follow the three edges meeting at one corner. The complete outline shows twelve edges. Faces are not needed for you to recognise the cube, although its wire outline has not closed a surface around an interior.

The builder stores two kinds of information separately: where the vertices are, and which ones form edges or triangle patches. A list of positions by itself is not a surface.

## Replay before editing

Both `animatedcubebuilder` placements have the discovery instrument. Keep one unchanged so you have a reference.

| Control | What it does here |
| --- | --- |
| REPLAY | Hides and reveals corners, edges and patches using the current vertex positions. |
| PAUSE / RESUME | Stops or resumes this builder's assembly steps. Replay first if assembly has finished. |
| RESTORE CUBE | Returns the eight initial corner positions and shows the completed cube. |
| DIAGONALS | Shows or hides six face diagonals after assembly completes. |

Replay the builder and pause when the shape becomes recognisable. Resume and let it finish. Corner handles can be picked up after completion; they are disabled during assembly. Release a held corner before using replay or restore.

The source constructs the hidden geometry at setup. Its timed steps change visibility. This is not the same operation as translating a finished cube across the room. Pausing this sequence does not stop the room clock or the neighbouring net.

## Make the seam visible

Find the face containing `v4`, `v5`, `v6` and `v7`. Before moving anything, trace its boundary and predict what will follow `v6`. Pull that corner a little out of the face's plane, leaving the others unchanged. Look for a crease, then use DIAGONALS to check it.

The two triangle entries for that face are:

```gdscript
[4, 5, 7]
[5, 6, 7]
```

The numbers are indices into the builder's vertex list. Both triangles use vertices 5 and 7, so that pair forms their common edge. Only the second triangle uses vertex 6. Moving it out of the original plane tilts that triangle while the other remains in place. Moving it only within the plane would not demonstrate this crease.

The update reads a changed handle position into the stored geometry:

```gdscript
vertices[i] = handle_nodes[i].position / cube_size
```

`i` identifies the handle and its corresponding vertex. `position` is local to the builder; dividing by `cube_size` converts it back to the builder's stored coordinates. The edges and patches are rebuilt from those coordinates using the same connection lists.

Release the handle. Predict what REPLAY will show, then test it. Predict what RESTORE CUBE will change, then test that. One repeats the presentation; the other restores the original coordinates.

## Compare a different operation

At `polyhedron_nets_cube`, follow one square as the net folds and unfolds. Each square remains rigid. The program changes hinge angles through `fold_progress`. The room has one net placement using the default cross configuration and `loop_fold:true`; the source's other net configurations are not additional displays here.

In your edited builder a corner moved relative to its neighbours. In the net, an entire face rotates around a hinge. Use this difference to explain why one square creased and the other stayed flat.

The detailed timing, triangle counts and folding code are in the [technical chapter](/book?map=Point_Animatedcube&section=technical). More general position, rotation and scale experiments belong to the transformation sequence.

## Return visits

These comparisons remain in the room. Choose one if it helps the question you are following; none is an additional requirement for finishing the main walk.

### A world without composition yet

Read the pallet's **A WORLD / WITHOUT / COMPOSITION**, the supply pile's **WITHOUT COMPOSITION / YET**, and the single crate's **YET**. Their arrangement already composes a scene. The admission concerns what we have learned to choose and examine so far.

Compare the pallet, supply pile and two `station_crates` placements as arrangements. Which box seems accessible, protected, ready to move or forgotten? Identify the position, spacing or surrounding object that produces your reading. The box shape alone cannot account for all of it.

Compare a detailed crate with the bare builder. Both may be recognisable as boxes, but that resemblance does not require an identical mesh or triangle budget. The [technical chapter](/book?map=Point_Animatedcube&section=technical) counts the builder's particular representation; it does not assign that count to every crate.

### The glove between bodies

The single-glove chamber offers a different encounter with an enclosure. A glove stands between an imagined worker and the contents. Compare the kind of access its design suggests with the exposed handles on the cube. This is a comparison of represented access; the glove is not an additional working sculpting control.

### A shadow with a setting

In `first_shadow`, compare the turning triangle with the thin line beside it. Then inspect `_build_line()` in its source. The line is a narrow cylinder, and its `cast_shadow` setting is explicitly OFF. The triangle's is ON.

The missing line shadow therefore cannot establish that every line lacks a shadow because it has no area. This rendered line has thickness, and the program has disabled its shadow. The comparison exposes a setting as well as a shape. A later experiment could change that setting while keeping the same geometry; no switch for it is installed here.

### The point returns through an instrument

The dark glass of `first_phosphor` carries a green dot. Follow its repeating light and fading glow. The program changes material emission over time; this is a representation of a phosphor display, not an electron-beam simulation. What was added to make the point visible, and what does that addition let you notice?

### Another neighbour list

The nearby pyramid is configured `#base_sides:8`. Follow its apex connections and compare them with the three cube edges meeting at a corner. Its different pattern of neighbours provides a comparison for the builder, whose edits keep the old connections. The pyramid has no matching corner-editing instrument here.

The floating sphere field remains decoration. Its presence need not become another compulsory lesson before the next room's investigation of the sphere.

## For a second pass

The existing instruments support deformation and comparison. They do not validate an enclosure, save a collection of altered forms or make the surface into walkable collision geometry. Keep those possible developments distinct from actions available now. A headset visit still needs to check reach and sightlines between the two builders and the net.
