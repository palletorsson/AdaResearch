# Pipes

Shared geometry and connections for pipes, cables and drawn tubes. The live workbench is `tube_painting` in **LSystems_Grammars_And_Curves** in the endless museum.

## Files

- `pipe_layout.gd`: named anchors, JSON layouts, live anchor edits, legacy glass/drain adapters
- `swept_tube.gd`: transported rings and indexed faces; optional inner wall and annular rims
- `swept_run.gd`: one reusable run with `GlassSegmentPorts`-compatible input/output metadata
- `run_network.gd`: explicit shared socket IDs, nearest-run snapping and bounded cable drape
- `part_library.gd`: sixteen existing GlassRack forms and five CableBuilder arrangements, with cached meshes and named free ports
- `pipe_canopy.gd`: deterministic ribs, weave and return layouts at architectural scale; uses PipeLayout and swept_run
- `turtle_pipe_base.gd`: separate older turtle base; the current glass and drain builders do not inherit it
- `PipeLayout.tscn`: scene wrapper

## Subfolders

- `layouts/`: JSON layout definitions, including `three_forms.json`

## Behavior

- **Tube:** retain the sampled centreline and close each end.
- **Pipe:** outer skin, inward-facing bore, and annular end rims. The museum adds sleeves and socket covers.
- **Cable:** a parabolic downward drape between endpoints and explicit joined supports. This is an authored shape, not a catenary solver or a length-conserving rope simulation.

## Use in another scene

```gdscript
var layout = preload("res://commons/primitives/pipes/pipe_layout.gd").new()
layout.auto_build = false
add_child(layout)
layout.load_layout("res://commons/primitives/pipes/layouts/three_forms.json")
layout.set_anchor("Right", Vector3(3, 3, 1))
```

Each JSON path can set `id`, `from`, `to`, `kind`, `pipe_radius`, `sides`, `colour`, `sag`, and `points`. Points and anchors use layout-local coordinates. Named endpoints override the first and last sample. Moving an anchor rebuilds its dependent runs; removing it removes dependent paths. IDs remain unique when paths are removed and added. `get_pipe_system()` returns a `Node3D`, since the actual builders have different classes.

`glass` and `drain` still accept their existing comma-separated turtle `code`. A coded path starts at `from`; if `to` is supplied, a straight hollow connector runs from the generated end to that anchor. This is direct routing and does not avoid obstacles. Anchor names remain case-sensitive. The layout does not send unsupported `@name` or `>name` commands to those renderers. Sampled `tube`, `pipe` and `cable` paths use points or two anchors rather than turtle commands.

## Museum interaction

**NETWORK** loads a white pipe, a black cable and a pink tube. **FORM** cycles the last run and the next pen stroke through all three kinds. **SAG** changes the last cable's drape. **EXAMPLE** returns to the three original suspended tube beginnings.

Grab a free end to extend it. Release near another run when the amber marker appears to create an explicit shared socket. Begin a pen gesture near an existing run and draw away to branch. Merely crossing skins does not join them. Connected ends become fixed sockets; use the pen there to branch. **UNDO** restores both geometry and connection records. Eight runs, 256 points per run, and sixteen undo states are retained per hall instance.

**PARTS** cycles bends (straight, 45°, 90°, U and S), branches (tee, Y, cross, reducer), coils/vessels (spiral, wave, flask, beaker), and ends (cap, drip, condenser). **CABLES** shows chord, spline, authored sag, festoon and truss. A selection replaces the work; UNDO restores it. Every declared free port has a pickup, including third and fourth junction ports. Grabbing one starts a new run while the supplied part stays fixed. Only named ports accept connections on stock pieces. Their meshes stay visible in PATH/RINGS; new runs expose their construction. The eight-record budget counts supplied pieces and drawn runs together.

The tube skin is visual geometry; the grips and receiver wall are collidable. Stock shapes include solid display geometry, so they are not all hollow fittings. Socket covers are separate meshes, not Boolean-welded junctions with sealed fluid passages. No fluid, electrical or audio routing is implemented. Drawings are not saved after the hall unloads. Physical XR comfort and Quest performance still need a headset pass.

## Procedural canopy

The tube bay has a glossy overhead application with its own left-hand console. RULE, DIAMETER, REPEAT and FINISH select the layout, 0.36/0.60/0.84 m diameter, 3/5/7 lanes or branch stations, and pink lacquer/pale enamel/chrome. RESET affects only the canopy. The first sweep lesson stays focused on rings; this is a later application before Architecture.

```gdscript
var canopy = preload("res://commons/primitives/pipes/pipe_canopy.gd").new()
canopy.rule = 1 # 0 ribs, 1 weave, 2 returns
add_child(canopy)
```

The generator uses floor-relative local coordinates, centred at 6.8 m high. `make_layout(mode, count, radius)` returns a dictionary usable by PipeLayout in another scene. It clamps count to 3–7 and radius to 0.18–0.42 m. The museum limits count to odd values 3/5/7 for comparison. There are at most 22 runs, 97 points per run and 24 radial sides. Geometry changes only on layout edits. `apply_finish()` reuses the meshes. The museum wrapper `spine_studies/pipe_ceiling.gd` supplies supports, physical controls and lighting; the generator alone has none of those.

The open pipe meshes have inner walls and annular rims. Ribs share anchors, but their skins overlap at the trunk; this is not a welded manifold or a flow solver. The local reflection probe in the museum captures the room once and excludes the pipe layer. It does not track subsequent moving objects. Headset performance needs a hardware pass.

## Validation

`python tools/capture_spine_studies.py LSystems_Grammars_And_Curves` runs native geometry, pickup, connection, undo and old-builder regression checks and captures the actual museum. See `commons/testing/run_network_checks.gd`, `part_library_checks.gd` and `tube_painting_checks.gd`. The catalogue checks extend every port, restore exact records with undo, join two pieces, and exercise XR-tools pickup on a cross branch. The old cable builder now uses the shared sweep for its default drape, keeps shader UVs, orients its handles along each span, and reuses its mesh while idle.
