# A direction can have another reading

This hall follows Growth's saved turtle state. It keeps position, heading and a branch stack, then separates two changes: the angle of a turn and the mapping from heading to a drawing direction. Architecture will assign width, walls and room placements to interpreted records.

## The actual shared program

The unchanged original rule is F -> FF+[+F-F-F]-[-F+F+F]. One generation has 20 symbols and 8 Fs; two have 172 symbols and 64 Fs. The ordinary artifact defaults to generation four, with 4096 Fs. Its original three drawings still show at most 261 segments each and use strides 0.055 / 0.050 / 0.050 m. The stochastic pair retains its own two rules and seeds, at most 91 drawn segments each. The original generation bars are capped at 1.1 m; their numeric labels report actual counts. The brass stack is a static maximum-depth summary, not an animated push/pop instrument.

The new opt-in InterpreterLesson calls the same interpret() method as the original three drawings. It returns raw segment endpoints plus state records after every symbol. The new desk uses one or two complete generations without the ordinary prefix cap. All three readers use 0.32 m strides, no fitting, and origins raised equally to 2.2 m so downward reflected branches remain above their cases.

The shared interpreter uses this operation:

```gdscript
var dir := Vector2(cos(heading), sin(heading))
if sideways:
    dir = Vector2(dir.y, dir.x)
var nxt := pos + Vector3(dir.x, dir.y, 0.0) * step
```

Heading begins at PI/2. Plus adds the turn angle and minus subtracts it. The brackets push/pop [pos,heading]. The component exchange changes displacement without changing stored heading. Applying it uniformly to all displacements and saved positions reflects the whole path across x=y. It preserves distances and the abstract branch connections; it does not create a new graph. Merely seeing intersecting strokes does not establish new connected junctions either.

## Physical controls and observation

STEP advances all three state traces together and wraps from the final symbol to START. READ F toggles the blue reader's exchange; ANGLE cycles the middle reader through 25 / 45 / 90 degrees. The green reference remains at 25 degrees and forward. TREE toggles one/two generations and reveals their full traces. RESET restores one generation, first F, 25 degrees throughout and forward. RULE shows the vector exchange. Twenty-symbol sentences are shown in full; longer ones show an explicit local window and symbol index/total. A window in the text does not truncate the geometry.

The gold arrow represents the stored heading and the white arrow the interpreted next drawing direction. All raw endpoints use a common metre scale. Rendering uses cylinder MultiMeshes and adds no branch colliders. The compact 3×2 desk keeps six full-sized controls at 1.045 m and a small tilted transparent pane. STEP exposes recorded states; it does not suspend the interpreter between presses.

## What the other works actually supply

space_filling_curve_gallery retains Hilbert n=4, Peano n=3 and Moore n=3 in its standard grammar comparison. Its panels are independently fitted to 512×512 pixels. The Hilbert panel yields 256 distinct integer grid vertices and 255 connecting segments. Those are finite sampled positions, not every point of a continuous region. The existing modes depth/overlay/single remain available through map configuration; the gallery has no new physical controls in this pass. Curve closure, coverage and resolution deserve their own later controlled comparison.

Hilbert3D retains its algorithm and controls, with its scene's stale l_systems path repaired to algorithms/lsystems/Hilbert3D.gd. ContextFreeGrammars retains its existing timed derivation and controls. lindenmayer_tube_tree retains its tube geometry. These separate algorithms are not additional readers of the primary's sentence.

## Restoration and boundaries

The baseline museum omitted the believing turtle because its registry entry lacked map_ready. The repaired entry now resolves the existing scene; no substitute artifact was created. The new 19×28 hall embeds the original 13×12 structure at (3,16), including its raised cell, and fills the obsolete teleporter hole. All four other placements retain their relative arrangement. The primary moves to the approach; its original lectern, alphabet, rule board, drawings, stack plates and stochastic pair are grouped seven metres behind it. Scoped lighting and smaller oversized captions support the collection.

The previous map and manuscripts, two historical grid versions and the failed baseline are archived under doc/space/grammar-curves-2026-09-14. Desktop checks exercise real pointer actions, equal stride lengths, exact reflection correspondence at every state, reversibility, unchanged reference, counts, absence of fitting/colliders, original study preservation, the floor gallery's finite Hilbert count and a complete exit route. Headset reach, comfort, readability and Quest timing remain pending.


<!-- study-spine:tube_painting -->

## Installed application: A line takes up room

`tube_painting` occupies a new adjoining bay, after the existing encounters. Cell [11, 39], rotation 180°, museum adapter `res://commons/artifacts/spine_studies/tube.tscn`. Original Ada geometry lesson, continuing an already started drawing.

Change the middle ring side count from twelve to eight. Keep the path and radius; compare the skin. Reuses trace, mesh, refinement, rotation, array, sweep; introduces the sweep capability after those earlier tools. The display and main-player controls are supplied.

<!-- tube-making -->

## Sweeping a retained path

`swept_tube.gd` constructs a capped or hollow ArrayMesh with clockwise faces and radial side normals. It drops consecutive duplicate points, supplies a transported perpendicular frame, and keeps ring resolution distinct from spatial input sampling. `tube_painting.gd` bounds strokes to eight and points to 256 per stroke, with sixteen undo snapshots. End grips remain persistent pickup bodies while the displayed meshes rebuild at most thirty times per second during drawing. Release commits; extending reuses an existing record and leaves its prior centres unchanged. Wall attachment clamps the final centre to the receiver's front surface. Tube geometry does not collide or weld. FORM also offers a hollow pipe and a cable with authored parabolic sag between its endpoints and joined supports. Cable sag is a bounded shape rule, not gravity integration. Join-on-release uses shared port IDs, with visible couplers and fixed connected ends; a pen gesture beginning on another run makes a branch. Undo restores geometry and ports together. Work does not persist after its hall unloads. PATH/RINGS/TUBE share the same records. Native tests cover topology, winding, frame edge cases, pickup, trigger dispatch, extension, undo, attachment and budgets; physical Quest use and performance remain unverified.

PARTS and CABLES expose sixteen existing GlassRack segment forms and five CableBuilder arrangements through `part_library.gd`. Cached Mesh resources and local transforms are retained in undo records. Named port metadata supplies up to four persistent grips per record. Taking a free part grip creates a new run while the part stays fixed; joining to a part tests declared ports only. Thirty-two pooled pickup bodies cover eight four-port records. The catalogue shares the eight-record budget with drawn runs. Stock part meshes retain their representation in PATH/RINGS and are not uniformly hollow or watertight. Native tests cover all twenty-one forms, every free port, extension, exact undo and XR-tools pickup on a third junction port.

<!-- /tube-making -->
