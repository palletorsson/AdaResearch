# Read one sentence three ways

**Learning elements**

- Geometric interpretation
- Swept surfaces
- Ring resolution
- Explicit connections

1. Begin with all three readers at 25 degrees, forward, after one 0.32 m F. READ F exchanges x/y only in the blue reader. Compare its stored heading (gold) with its drawing direction (white).
2. ANGLE changes only the middle reader to 45 degrees. The first F does not move. STEP five times to symbol six, where the first branch segment makes the changed turns visible.
3. Finish all 20 symbols / 8 drawn segments. Match local forks; brackets save and restore position/heading. Reference and blue reader retain the same angle and stride.
4. RULE exposes the direction exchange. Compare corresponding points relative to each origin: (x,y) becomes (y,x). This reflection preserves lengths and branching connections. It is not a ninety-degree rotation or a new branching graph.
5. READ F undoes the exchange. TREE toggles one/two generations and shows the full reading: 172 symbols / 64 segments at generation two. STEP then cycles from the end to START. RESET restores the opening conditions.
6. Continue around the cases to the original lectern and four other works. The smaller original comparison uses different strides and capped prefixes. The floor gallery uses different grammar depths. Do not treat either as the new desk's controlled comparison.

Primary: the_believing_turtle. All five authored works now instantiate. The original artifact's internal studies remain behind the new desk. The next hall is LSystems_Architecture. Headset review remains pending.


<!-- study-spine:tube_painting -->

## Return: A line takes up room

Change the middle ring side count from twelve to eight. Keep the path and radius; compare the skin. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This lesson introduces sweep using trace, mesh, refinement, rotation and array. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`tube`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-02-tube-painting-a-line-takes-room/index.html). Finish the current gesture before editing the work. RESET returns the original comparison.

<!-- study-edit:tube_painting -->

### One source change: A line takes up room

Replace the middle value 12 with 8 in SIDE_COUNTS. Restart the prepared study. Each supplied path still has 41 points and the same radius. A capped tube now has 656 triangles instead of 984. Compare PATH, RINGS and TUBE before drawing your own continuation.

```gdscript
const SIDE_COUNTS := [6, 8, 24]
```

Source: `commons/primitives/pipes/swept_tube.gd`. Use the prepared scene to run and compare.

<!-- tube-making -->

## Continue a drawing that has already begun

This is the later **sweep** lesson, in **L-systems → Grammars and Curves**, before Architecture. Point Trace introduced keeping positions. Mesh introduced vertices and triangle connections; refinement introduced circular sampling; rotation supplied changing orientation. Here those tools meet: a path carries a ring, and neighbouring rings carry faces. Point Trace keeps its earlier, simpler encounter.

### First use what is here

Three supplied strokes are suspended in front of the wall. Their six pink end grips are part of the interface. Grab a lower end and move your hand slowly. The old length stays where it was; sampled positions are added beyond it. Release to leave the addition in the air. You can also continue from the other end; the stored path reverses its order before growing there.

Bring an end close to the receiving wall. Its centre snaps to the wall surface and sampling stops until you release. This makes a visible attachment. It is not a structural joint or a gravity simulation. The runs can now join through explicit sockets. Their skins can overlap and do not become a welded solid or block the visitor. Together their paths can compose another, incomplete wall in front of the room's wall.

The pen on the plinth begins a separate stroke. Pick it up, hold its trigger while moving, and release the trigger to keep the line. On desktop, the existing right-click pickup/drop and left-button held action drive the same pen. The artifact adds no player, controller mapping or installation step.

**UNDO** restores the whole drawing before the last completed gesture or geometry edit. Extending a supplied line and undoing leaves the supplied line intact. **CLEAR** removes the strokes; **EXAMPLE** replaces them with the three opening strokes using the current radius and side count. Both can be undone. **RESET** also restores default settings and returns the pen; put it down first. Undo restores geometry, not the pen pose or the next-stroke settings. History keeps the last sixteen states during this visit. Closing or unloading the hall does not save a drawing to disk.

### Inspect the same work three times

**VIEW** cycles TUBE → PATH → RINGS → TUBE. It changes the representation, not the stored positions. PATH is the retained centreline. RINGS shows the sampled cross-sections. TUBE connects them with faces and closes the two ends. The controls are available after you finish a gesture.

**THICKNESS**, **SIDES** and **COLOUR** edit the last stroke in the list and choose the setting for the next new pen stroke. Continuing an earlier stroke preserves that stroke's own material and resolution. Undo an extension before trying a different route. The readout counts the last stroke in the list, not the sum of the whole work.

### What one ring needs

The production builder is `commons/primitives/pipes/swept_tube.gd`. Its `build(path, radius, sides)` function receives positions we already know how to retain. At each position it supplies two perpendicular directions, `frame_normal` and `binormal`, across the path. This is the ring expression, taken from that builder:

```gdscript
var angle := TAU * j / float(sides)
var radial := frame_normal*cos(angle)+binormal*sin(angle)
vertices.append(points[i]+radius*radial)
```

`i` addresses a point along the path; `j` addresses a place around its ring. Changing `sides` changes the second count. It does not take more samples of your hand movement. Changing `radius` moves each ring vertex away from its centre without moving the centre.

The supplied frame transport carries the ring around bends without making it suddenly look towards world-up. Understanding or rewriting quaternion transport is not required for this first edit. First locate the familiar circular rule inside the supplied construction.

### Join two rings

Let `a` and `b` be neighbouring vertices on one ring, and `c` and `d` their corresponding neighbours on the next. This production line adds two triangles:

```gdscript
indices.append_array(PackedInt32Array([a,c,b,b,c,d]))
```

The last address wraps to the first with `% sides`. That closes the seam around a ring. Separate triangles cap the two ends. For N path points and S sides, the body has `2 × (N - 1) × S` triangles and the two caps add `2 × S`. The total is `2 × N × S`.

Make the one source edit above before changing the path: twelve sides become eight. Each opening stroke retains its 41 centres and 0.065 m radius. The capped mesh changes from 984 to 656 triangles. Look near a curved silhouette. Then make your own continuation and compare again. The number is a check on a visible decision, not the reason to prefer one drawing.

### After the first sweep: a connected system

Choose **NETWORK** to load the three-form example. **FORM** cycles the last run and next pen stroke through tube, pipe and cable. A tube retains the path you drew. A pipe uses outer and inner rings with annular rims, leaving an open bore; its sleeves make the mouths visible. A cable redraws between its endpoints and any joined supports with a downward parabolic offset. **SAG** changes that offset while keeping the supports fixed. This is authored drape, not a simulation of gravity or cable length.

Hold the pen trigger beside another run and draw away to start a branch. To join a free end, continue it close to another run, wait for the amber marker, then release. The shared port is recorded only on release. Silver fittings mark these sockets. Connected endpoint grips disappear so extending cannot silently pull a joint apart. Use the pen there to branch, or UNDO to restore both runs and their port records. Merely crossing two skins makes no connection.

`run_network.gd` owns that relationship; `swept_tube.gd` owns the mesh. The reusable `PipeLayout` accepts named anchors and per-run `kind`, radius, sides, sag and optional sampled points. Moving an anchor rebuilds its dependent runs. Its existing glass and drain command builders remain available. See `commons/primitives/pipes/README.md` and `layouts/three_forms.json` for an executable layout example. The hand-drawn runs have no fluid, audio or electrical routing and does not save a drawing between hall visits.

### Explore the form library

**PARTS** cycles four groups from the existing pipe and glass library: straight, 45° and 90° bends, U-bend and S-bend; tee, Y-junction, cross and reducer; coil, wave, flask and beaker; cap, drip and condenser. **CABLES** shows five existing cable arrangements: chord, spline, authored sag, festoon and truss. These are supplied forms to work from, rather than five new algorithms to learn now.

Each group replaces the current drawing; UNDO brings that drawing back. A pink grip marks every declared free port, including the third and fourth arms of a junction. Choose FORM, then take a grip and draw onward. The supplied piece stays in place while a new tube, hollow pipe or cable grows from its port. Release beside another free port to connect two pieces. On supplied parts only the declared ports accept a connection; on drawn runs you can also branch along the path.

The catalogue reuses the existing geometry and port metadata through `part_library.gd`. Some stock pieces are solid display meshes; they are not all hollow plumbing. The new PIPE run has an open bore. Neither kind simulates flow. The supplied pieces keep their shape in PATH and RINGS views while your new runs reveal their construction. THICKNESS and SIDES apply to drawn runs, not the supplied part meshes. COLOUR can recolour the last supplied piece. Eight pieces and runs share the workbench budget, so a five-piece group leaves room for three additions.

### What is supplied, and what is limited

`tube_painting.gd` owns the retained strokes, undo states, view modes and bounded input. `tube_pen.gd` reuses the existing drawing pen. `tube_end.gd` reuses the existing pickup handle. `station.gd` supplies the museum console. Their complete source accompanies this tutorial; keep them intact for the first ring edit.

New samples are actual nib or end-grip positions at least 0.045 m apart. A sudden jump above 0.75 m stops further additions until release. Each stroke can retain 256 positions; the work can keep eight pieces and runs. The drawing volume and feedback keep an endpoint from writing into another exhibit. A tube at the point limit needs a separate new stroke. Tight turns and self-intersections are not repaired into a manifold solid. The pink grips and the wall are interactive/collidable; the tube skin is visual geometry. Native automated pickup and input tests are recorded separately from physical headset testing.

### Optional application: patch a sound, wake a machine

Beside the drawing workbench, the existing modular rack now has a focused VCO → VCF → VCA → SPEAKER patch. Close POWER with the physical lever or its matching button. WAVE selects saw, square, triangle or sine (0–3); FREQ and FINE change pitch, AMP changes level, and PAN moves the sound between channels. Turn CUTOFF, then switch the FILTER lever. You should hear the high harmonics change. The sound is generated continuously; adjusting the filter does not restart a recorded note.

Unplug the VCF route and connect VCO OUT directly to VCA IN. The signal bypasses the filter. An incomplete path to SPEAKER is silent. Grab and release plugs close to a compatible socket, or select an output then an input with the museum pointer. A selected occupied socket removes its cord. PATCH EXAMPLE restores the four supplied cords; UNPATCH removes them. Put down a held plug before either operation.

The second route is POWER GATE → MOTOR. Unplugging it stops the coloured bodies without breaking the sound patch. Opening the power lever stops both. Audio and gate sockets accept their own signal kind; a drawn tube crossing a socket cannot silently become an electrical connection. Moving beads show route direction and enabled state at an illustrative speed, not audio frequency or electrical propagation.

The bodies reuse transformed primitives and swept limbs. Their cranks use a shared elapsed phase at three different rates. This is a kinematic study after Jean Tinguely and Niki de Saint Phalle, not a physical motor model or a reconstruction of a particular sculpture. The connected system extends the sweep lesson; synthesizer implementation is supplied. Inspect `commons/audio/cables/live_patch.gd` for the bounded audio graph and `commons/artifacts/spine_studies/patch_and_motion.gd` for its motor receiver. Other rack presets retain their existing sound behavior.

### Optional application: let the line become a ceiling

Look above the drawing bay. The small console on the left controls a canopy made with the same `PipeLayout` and hollow sweep. **RULE** cycles woven crossings, returning U-bends and branching ribs. **DIAMETER** selects 0.36, 0.60 or 0.84 metres; **REPEAT** selects three, five or seven lanes or branch stations. **FINISH** changes pink lacquer to pale enamel and chrome. **RESET** restores the pink five-lane weave without changing the drawing or synth patch.

Keep diameter and repetition fixed. Change only the rule, then look up from the same position. In WEAVE, the two families have opposite heights at every crossing. A cosine raises and lowers each run; the next lane adds half a cycle. In RIBS, repeated branches meet a central run at named anchors. In RETURNS, each lane runs to a semicircular bend and comes back. The same rings and faces make all three; the path rule changes their relation.

`commons/primitives/pipes/pipe_canopy.gd` is the reusable generator. Its `make_layout(mode, count, radius)` returns an ordinary layout dictionary, so another scene can use it with the existing PipeLayout. The museum wrapper adds a frame, hangers, controls, luminaires and a local reflection probe. The inherited museum ceiling presets still handle conventional tiles, vents and fixtures. This installation is an open canopy above the work, leading towards Architecture.

The pipes have real inner surfaces and open mouths. The rib intersections share logical anchors but their surfaces overlap; they are not welded plumbing and carry no simulated flow. The canopy is visual geometry above the reachable drawing volume. Support posts and the console collide. Meshes rebuild only when the layout changes; changing finish reuses them. A local probe captures the surrounding room once, so it is not a live mirror of subsequent drawing or machine movement. Settings last for this hall visit. Physical Quest performance remains untested.

<!-- /tube-making -->
