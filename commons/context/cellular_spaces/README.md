# Cellular interiors

## Installed maps and strand sculpture

The **noise** sequence now runs `Noise_Inside_Noise` → **Cellular Noise**
(`Noise_Cellular`) → **Box Noise** (`Noise_Box`) → `Noise_Space_10`.
Both new maps are also declared and placed in the Endless Museum plan.
Run `cellular_noise_map_preview.tscn` with F6 to start the sequence at Cellular
Noise; Page Down continues to Box Noise in the desktop map tester.

Cellular Noise holds the two rooms plus **Voronoi Strands**. Run
`voronoi_strands_preview.tscn` to inspect the sculpture by itself: WASD walks,
hold right mouse to look, R changes the seed, Space highlights shared junctions.
An enlarged eight-legged spider now builds the strands on arrival. **B** replays
construction, **P** pauses construction/forces, **F** finishes and releases the
net, and **G** tugs a knot near the centre of the view (finishing first if needed).
**T** switches weaving speed. These keys belong to the standalone preview;
the map exhibit starts construction automatically.

This is a spider performing a mathematical construction. Real spiders make
[three-dimensional tangle webs](https://www.nhm.ac.uk/discover/spider-webs.html),
but the exact Voronoi cells here come from distances to sites, not a biological
web-growth model. The spider follows graph edges, lays silk behind its abdomen
and retraces completed lines to reach branches. Completed strands stay visible.
`weave_on_start` / grid token `#weave:false` skips construction;
`weave_speed` sets travel speed in metres per second. The animation changes
batched instance visibility and a single growing strand, without rebuilding
the cell mesh. The generator retains one connected component; the spider can
reach every strand. F shows that same net, without adding detached fragments.

Every connection uses a shared 3D vertex ID. True centreline intersections are
split into edges at a common junction; over-under crossings stay separate.
Unanchored free ends are pruned to convergence. Tethers attach directly to
existing floors, walls and ceilings, with small fixing plates aligned flush to
the hit surfaces. Outward 3D raycasts stop at the first surface. When an outward
ray misses, lower wall probes locate alternatives and a second raycast checks
the complete cord for intervening geometry. There is no separate support frame.
The standalone preview supplies a 20 × 23 m room with a ceiling and a walkable
doorway. Its default net has 12 floor, 12 wall and 12 ceiling attachments.
The map exhibit discovers existing surfaces after construction and placement
finish. The open-roof Cellular Noise gallery supplies floor and wall anchors;
ceiling anchors are used wherever a ceiling actually exists. `surface_reach`
limits the search radius (default 80 m); `wall_reach` remains a legacy grid alias.
When no surface can be found, no support is invented and the exhibit stays hidden.
The zero-anchor option is a static mathematical study without external supports.
Junction highlighting keeps all cords visible for inspection.

The sculpture draws true 3D Voronoi edges as thin tubes. It uses Delaunay
tetrahedron circumcentres, clips the dual network, removes unanchored tips and
adds up to 36 tethers to the host room surfaces. There are no opaque faces or
player-blocking line colliders. Inspector controls include seed, cell count,
thickness, anchor count, surface search distance and construction playback.

The complete net then settles under gravity. `strand_dynamics.gd` models one
particle per shared knot, with tension-only elastic cable constraints using
[XPBD (Macklin, Müller and Chentanez, 2016)](https://mmacklin.com/xpbd.pdf).
Room anchors have zero inverse mass. Every incident strand and its knot sphere
read the same moving position: connections cannot tear or drift apart. Slack
cables exert no compression; damping dissipates motion. Knot sweeps stop at
actual room collision surfaces. Construction is staged before this release,
so invisible, unbuilt strands never carry a simulated load.

The model uses 120 Hz fixed steps, six constraint passes, 20 g per free knot,
9.81 m/s² gravity, 0.00002 m/N cable compliance and 1.8/s velocity damping.
Rest lengths include a small initial 2 N pretension. `#compliance` and
`#knot_mass` change the elastic response; `#tension:false` preserves the exact
Voronoi geometry. Combine `#weave:false#tension:false` for a static exhibit.
The relaxed geometry retains the graph but is no longer an exact Voronoi diagram.
This is a lumped cable approximation: no silk failure, bending, strand
self-collision, distributed strand weight or load from the illustrative spider.
New crossings created by motion do not automatically become knots.

Box Noise contains `box_shell_space` and `box_atrium_space`: box-sampled
versions of the same cellular fields, with stepped walls and ceilings.
Here “box noise” means constant occupancy per sampled box, rather than a new
stochastic basis. The square faces are real geometry with matching collision.

Map placements use `#floor:false` and `auto_ground:false`: the gallery provides
the level floor, so a second coincident floor cannot flicker or raise the entry.
Standalone room scenes retain their own floor by default.

These five exhibits are registered in `cellular_noise_rooms.json`, separate
from the independently authored `cellular_space` artifact.
`python tools/test_noise_space_maps.py --capture` checks the strand geometry,
loads both actual maps and saves a render in the encyclopedia capture folder.

Run `cellular_spaces_preview.tscn` with F6 to walk through both spaces.
WASD or arrows walk, hold the right mouse button to look, Shift moves faster.
**1** selects the womb, **2** selects the open cells, **R** returns to the entrance.

- **cellular_womb_space.tscn**: a pink, softly folded enclosure. Three-dimensional
  Worley noise deforms an ellipsoidal shell, including its ceiling. The rounded
  entrance is 3.2 m wide with 3.2 m of clearance at its centre.
- **cellular_atrium_space.tscn**: sixteen ground-level cells, with four further
  feature points overhead, make a three-dimensional Voronoi partition. Arched
  passages lead from each ground cell to the shared centre. Central partitions
  are removed through their entire height inside a 4.6 m radius.

Both have real mesh collision and a level floor at local y = 0. Place them at
scale 1 for metre-sized geometry. The floor occupies a 27.6 m diameter; reserve
roughly 28 × 29 m and 11 m of height. Their entrance faces +Z. The separate scenes
include local lights but no player, camera or WorldEnvironment, so they can be
used with the existing desktop or XR player. Headset performance needs testing.

## Use in AdaResearch

Registry tokens: `cellular_womb_space` and `cellular_atrium_space`.
Examples: `cellular_womb_space#seed:42#softness:0.65` and
`cellular_atrium_space#seed:42#clearing_radius:4.6`.

TopologyManager flags: `create_cellular_womb_space` and
`create_cellular_atrium_space`. Runtime keys: `cellular_womb`, `cellular_atrium`.
The manager uses each room's entrance spawn instead of dropping you onto its roof.

Inspector settings are sampled on startup; call `regenerate()` after runtime
changes. Seed is deterministic. `voxel_size` controls mesh sampling (0.28–0.65 m,
default 0.42 m); walls retain a minimum thickness relative to this spacing.
Generation happens once, with no moving floor or per-frame collision rebuild.
The comparison loads both rooms before movement starts.

## Construction

[The Book of Shaders, chapter 12](https://thebookofshaders.com/12/) introduces
distance to feature points and the neighbouring-cell search. Here the surface
material searches 27 neighbouring cubes, extending that construction to 3D.
The architecture uses a finite, seeded set of 3D sites and distances to their
bisector planes, so partition thickness is measured in metres. It is not an
extruded image or a heightmap. Marching tetrahedra extracts the solid boundary;
the exact resulting triangles also generate the collision shape.

The floor deliberately stays level. Deleting walls changes what bodies can
reach, while preserving a readable distinction between small chambers and the
common space. The overhead cells are ceiling geometry, not a second walkable
storey.

## Verification

Run `python tools/test_cellular_spaces.py`. It stages only these source files in
an isolated Godot project, checks geometry and physics, traverses the entrance
and every ground-cell route, and verifies the existing TopologyManager's new
spawn path. Add `--capture` to save interior renders under the encyclopedia's
capture directory. `GODOT_EXE` can select a different Godot 4.6 binary.
