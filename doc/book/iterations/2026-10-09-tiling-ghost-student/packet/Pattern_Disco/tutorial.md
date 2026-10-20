# Pattern Disco — keep the pattern, change its colours

## Learning elements

- A pattern value and its assigned colour.
- Palette change versus phase change.
- A changed value hidden by equal colours.

A brief return to Arrays and Colour. Follow one square through a palette change and a phase change. Reuse the existing grid and point; the carried classes need no new explanation.

## The floor we already know

Step onto the museum's checker. Its colours can move without carrying your feet. Stop the musical sequencer, then HOLD the visual pattern. Choose CHECKER. Press COLOUR and watch one square. Now leave the palette alone and press ONE STEP. The two operations can produce a different picture for different reasons.

Arrays gave us addresses. Colour gave us an assigned colour and the small `Palette` class. We keep that class and the same 5 × 5 cube-tile receiver from the Colour review draft. The new work is the separation between a calculated zero or one and the colour used to display it.

## A small continuation inside the museum

Attach `01_palette_return.gd` to one empty Node3D in your existing learner space, at floor level with unit scale. Put `palette.gd`, `grid_surface.gd` and `point_body.gd` beside it. All four files are printed here. The museum still provides the player, camera, lights, XR Tools and grip/trigger actions. This small grid is a display at table height, with no supporting collider; the installed 12 × 12 dance floor remains the place to walk.

The point is the familiar grabbable sphere. Hold it and move it left of the study's centre, then press the trigger to change palette. In the middle, trigger advances one step. On the right, it toggles PLAY/HOLD. These regions use the host's local X coordinate: left below −0.3 metres, middle from −0.3 to +0.3, right above +0.3. Move to a region before pressing; carrying the point alone changes nothing.

We begin held, with navy and pink. The grid helper is carried unchanged, including its earlier address marker and readout; this script hides those two and supplies the new instruction label.

### The new rule and its controls

<!-- student-code:01_palette_return.gd -->
```gdscript
extends Node3D

const Palette = preload("palette.gd")
const GridSurface = preload("grid_surface.gd")
const PointBody = preload("point_body.gd")
var palettes := [
    Palette.new([Color.BLACK, Color.WHITE]),
    Palette.new([Color("172051"), Color("fc62ad")]),
    Palette.new([Color("104652"), Color("fcdb35")]),
    Palette.new([Color("512078"), Color("55f3cf")])]
var palette_index := 1
var phase := 0
var playing := false
var elapsed := 0.0
var interval := 0.5
var grid: Node3D
var control: PointBody
var label := Label3D.new()

func _ready() -> void:
    grid = GridSurface.new()
    grid.position = Vector3(-0.64, 0.82, 0)
    add_child(grid)
    grid.marker.hide()
    grid.readout.hide()
    control = PointBody.new()
    control.position = Vector3(0, 1.0, 1.9)
    var black := StandardMaterial3D.new()
    black.albedo_color = Color(0.025, 0.025, 0.03)
    black.roughness = 0.18
    control.get_child(0).material_override = black
    add_child(control)
    control.action_pressed.connect(choose)
    label.position = Vector3(0, 1.65, 0.3)
    label.font_size = 26
    label.pixel_size = 0.002
    add_child(label)
    paint()

func value_at(address: Vector2i) -> int:
    return posmod(address.x + address.y + phase, 2)

func paint() -> void:
    var pair: Array[Color] = palettes[palette_index].colours
    for address: Vector2i in grid.cells:
        grid.write(address, pair[value_at(address)])
    label.text = "PALETTE %d / STEP %d / %s\nGRIP + TRIGGER: left = palette / middle = step / right = play-hold" % [palette_index, phase, "PLAY" if playing else "HOLD"]

func cycle_palette() -> void:
    palette_index = (palette_index + 1) % palettes.size()
    paint()

func step() -> void:
    phase += 1
    elapsed = 0.0
    paint()

func toggle_running() -> void:
    playing = not playing
    paint()

func choose(_held: Variant) -> void:
    if control.position.x < -0.3:
        cycle_palette()
    elif control.position.x > 0.3:
        toggle_running()
    else:
        step()

func _process(delta: float) -> void:
    if not playing:
        return
    elapsed += delta
    var changed := false
    while elapsed >= interval:
        elapsed -= interval
        phase += 1
        changed = true
    if changed:
        paint()
```

In the grid's `Vector2i`, `x` is the column and `y` is the row along local Z. Adding the two coordinates gives neighbouring squares opposite parity. `posmod(..., 2)` returns zero or one. Adding `phase` makes one step exchange them; a second step restores the visible arrangement even though the counter has advanced to two.

`palettes[palette_index]` selects a Palette object. Its `colours` list supplies the pair; `pair[value_at(address)]` selects the colour for this address. Changing the pair leaves the address and calculated value intact. This is a shared assignment: every zero receives one colour, every one the other. The earlier Grid lesson could leave one address changed; this rule repaints all addresses.

`cycle_palette()` changes neither phase nor elapsed time. `step()` advances phase and starts a fresh interval. PLAY counts elapsed seconds; the loop consumes every completed half-second and keeps the remainder. HOLD preserves that remainder. This small study has one clock and no audio. In the installed hall the score has its own clock, so hold both instruments for a still comparison. The installed console also offers other patterns and a shader-drawn triangle mode; they remain encounters outside this checker reconstruction.

## Make the distinction disappear

First predict the values at (0, 0), (1, 0) and (1, 1) at phase zero. Check them against 0, 1 and 0. Advance once: they become 1, 0 and 1. Advance again: the arrangement returns. Follow one fixed cube throughout.

Now edit only the navy/pink pair in the script: replace both entries with `Color(0.4, 0.4, 0.4)`. Predict before running: all 25 tiles should be grey. ONE STEP should still exchange the underlying zero/one values while leaving the displayed colours unchanged. Change to another palette and the checker should become visible again, at the current phase. Its geometry should never move.

Explain why a still-looking surface does not establish that its input has stopped. Then choose your own two different colours and keep the phase fixed while comparing them. A test can verify the assignment; you decide which relations the colours make easier to see.

## Carry a source onward

This hall calculates its motif. Foundry will let us edit and retain a small source, then read it repeatedly onto different receivers. Carry the distinction between the source values, the rule that reads them and the surface that displays them. The rest of the disco remains available to dance with.

## Complete carried files

### The Palette class, carried unchanged

Colour introduced owned state and methods here. We use its `colours` list without advancing its `index`: the pattern value chooses an entry, not `next_colour()`. Each instance copies the supplied choices into its own list.

<!-- student-code:palette.gd -->
```gdscript
extends RefCounted

var colours: Array[Color] = []
var index := 0

func _init(choices: Array[Color]) -> void:
    assert(not choices.is_empty())
    colours.assign(choices)

func current_colour() -> Color:
    return colours[index]

func next_colour() -> Color:
    index = (index + 1) % colours.size()
    return current_colour()
```

### The addressed cube grid, carried unchanged

This supplied renderer retains the earlier BoxMesh, 25 fixed transforms and dictionary from address to instance index. `write()` changes only an instance colour. Its unshaded material makes the assigned colours easier to compare; it does not model illumination or claim how they will feel to every viewer. The old `mark()` method remains available for the earlier lesson but is not called here.

<!-- student-code:grid_surface.gd -->
```gdscript
# Supplied addressed receiver; a compact model of address_lesson.gd's floor.
extends Node3D

var cells: Dictionary = {}
var instances: MultiMesh
var marker: MeshInstance3D
var readout: Label3D

func _ready() -> void:
    var tile := BoxMesh.new()
    tile.size = Vector3(0.28, 0.06, 0.28)
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    tile.material = material
    instances = MultiMesh.new()
    instances.transform_format = MultiMesh.TRANSFORM_3D
    instances.use_colors = true
    instances.mesh = tile
    instances.instance_count = 25
    var view := MultiMeshInstance3D.new()
    view.multimesh = instances
    add_child(view)
    var index := 0
    for z in range(5):
        for x in range(5):
            var address := Vector2i(x, z)
            cells[address] = index
            instances.set_instance_transform(index, Transform3D(Basis.IDENTITY, Vector3(x * 0.32, 0, z * 0.32)))
            instances.set_instance_color(index, Color.WHITE)
            index += 1
    marker = MeshInstance3D.new()
    var ring := TorusMesh.new()
    ring.inner_radius = 0.19
    ring.outer_radius = 0.205
    marker.mesh = ring
    add_child(marker)
    readout = Label3D.new()
    readout.position = Vector3(0.64, 0.65, 0.2)
    readout.font_size = 24
    readout.pixel_size = 0.003
    add_child(readout)

func write(address: Vector2i, colour: Color) -> bool:
    if not cells.has(address):
        return false
    instances.set_instance_color(cells[address], colour)
    return true

func read(address: Vector2i) -> Color:
    assert(cells.has(address))
    return instances.get_instance_color(cells[address])

func mark(address: Vector2i) -> void:
    marker.position = instances.get_instance_transform(cells[address]).origin + Vector3(0, 0.06, 0)
    readout.text = "(%d, %d) #%s\nX / Z: select   C: colour   P: palette   R: rule" % [address.x, address.y, read(address).to_html(false)]
```

### The inherited point

The body supplies pickup and its action signal. The new lesson connects that signal to `choose()`. We set its starting position before adding it to the physics tree, as in the earlier point lessons.

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```
