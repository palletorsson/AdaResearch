# Array Patterns — give the address a surface

## Learning elements

- A receiver frame and its local axes.
- World position converted to a surface address.
- Cell spacing and finite extent in metres.

Return to Transformation with a purpose: place the pattern in a physical frame, then recover an address from your hand. Hold the pattern rule fixed. The tunnel makes this a passage to walk through as well as a display to inspect.

## Walk the larger example

Enter the tunnel's side bay. Its console stands beside the lower end of the ramp. Press COL + four times: the surface column advances while the source column returns. Press FACE and follow the indicator onto the right wall. The same row and column now point in different directions through the room.

The installed tunnel has a fixed four-by-four source. CELL SIZE changes a cell from 40 to 60 centimetres; the motif's width changes from 1.6 to 2.4 metres. The tunnel keeps its dimensions. GRID hides the drawn divisions while the supports still hold you. UNDO restores a setting.

Keep our smaller two-by-three source, five-by-five cube grid and black point. Tutorial Pattern changed the address that reads a source. Here we hold that reading still and change the receiver's position, orientation and scale. These are the operations from Transformation, returning with a purpose.

## Turn the carried grid

Replace the preceding entry script with `04_surface_frame.gd`. Keep the three carried files beside it, on the same empty Node3D in your museum learner space. The root stands on the floor at unit scale; it may be moved and turned. The museum supplies the player, camera, lighting and XR Tools. This small display has no floor or wall collision of its own.

Grip the point and move it above the cubes. Its centre selects an addressed interval; the ring follows that interval. The source remains fixed in this comparison. The point now inspects instead of painting.

At the front, hold the point over FACE, then press the trigger. The grid becomes a right-wall panel: columns go along the room and rows go down. Hold it over CELL WIDTH and trigger to enlarge the intervals from 32 to 48 centimetres. The labels stand 60 centimetres to either side, 2.5 metres from the root; select with the point centre between 95 and 150 centimetres above the floor. The readout names the action before you press. Hovering alone changes no setting.

### 04_surface_frame.gd

<!-- student-code:04_surface_frame.gd -->
```gdscript
extends Node3D

const Palette = preload("palette.gd")
const GridSurface = preload("grid_surface.gd")
const PointBody = preload("point_body.gd")
const LOCAL_PITCH := 0.32
var source := [[0, 1, 0], [0, 0, 1]]
var reflected := false
var widths := [0.32, 0.48]
var width_index := 0
var wall := false
var palette = Palette.new([Color("172051"), Color("fc62ad"), Color("55f3cf")])
var grid: Node3D
var control: PointBody
var label := Label3D.new()

func _ready() -> void:
    grid = GridSurface.new()
    add_child(grid)
    grid.readout.hide()
    control = PointBody.new()
    control.position = Vector3(0, 1.15, 2.5)
    var black := StandardMaterial3D.new()
    black.albedo_color = Color(0.025, 0.025, 0.03)
    black.roughness = 0.18
    control.get_child(0).material_override = black
    add_child(control)
    control.action_pressed.connect(choose)
    label.position = Vector3(0, 2.65, 1)
    label.font_size = 26
    label.pixel_size = 0.002
    add_child(label)
    for side in [-1, 1]:
        var card := Label3D.new()
        card.text = "FACE" if side == -1 else "CELL WIDTH"
        card.position = Vector3(side * 0.6, 0.9, 2.5)
        card.font_size = 28
        card.pixel_size = 0.002
        add_child(card)
    place_receiver()
    for address: Vector2i in grid.cells:
        grid.write(address, palette.colours[value_at(address)])

func source_address(address: Vector2i) -> Vector2i:
    var width: int = source[0].size()
    var tile_column := floori(float(address.x) / width)
    var column := posmod(address.x, width)
    if reflected and posmod(tile_column, 2) == 1:
        column = width - 1 - column
    return Vector2i(column, posmod(address.y, source.size()))

func value_at(address: Vector2i) -> int:
    var cell := source_address(address)
    return source[cell.y][cell.x]

func place_receiver() -> void:
    grid.position = Vector3(0.9, 2.2, 0) if wall else Vector3(-0.64, 0.82, 0)
    grid.rotation = Vector3(PI / 2, -PI / 2, 0) if wall else Vector3.ZERO
    grid.scale = Vector3.ONE * widths[width_index] / LOCAL_PITCH

func toggle_face() -> void:
    wall = not wall
    place_receiver()

func toggle_width() -> void:
    width_index = (width_index + 1) % widths.size()
    place_receiver()

func selected_address() -> Vector2i:
    var local: Vector3 = grid.to_local(control.global_position)
    var distance_m: float = local.y * grid.scale.y
    var address := Vector2i(floori((local.x + LOCAL_PITCH / 2) / LOCAL_PITCH), floori((local.z + LOCAL_PITCH / 2) / LOCAL_PITCH))
    if distance_m < 0.12 or distance_m > 0.65 or not grid.cells.has(address):
        return Vector2i(-1, -1)
    return address

func operation() -> String:
    var local := to_local(control.global_position)
    if local.y < 0.95 or local.y > 1.5 or absf(local.z - 2.5) > 0.25:
        return ""
    if absf(local.x + 0.6) <= 0.25:
        return "FACE"
    if absf(local.x - 0.6) <= 0.25:
        return "CELL WIDTH"
    return ""

func choose(_held: Variant) -> void:
    if operation() == "FACE":
        toggle_face()
    elif operation() == "CELL WIDTH":
        toggle_width()

func _process(_delta: float) -> void:
    var address := selected_address()
    grid.marker.visible = address != Vector2i(-1, -1)
    var selection := "no selection" if operation().is_empty() else operation()
    if grid.marker.visible:
        var cell := source_address(address)
        grid.marker.position = grid.instances.get_instance_transform(grid.cells[address]).origin + Vector3(0, 0.06, 0)
        selection = "surface row %d, column %d -> source row %d, column %d" % [address.y, address.x, cell.y, cell.x]
    label.text = "%s / CELL %.2f m / SOURCE WIDTH %.2f m\n%s\nGRIP: inspect / TRIGGER at label: change receiver" % ["RIGHT WALL" if wall else "TABLE", widths[width_index], source[0].size() * widths[width_index], selection]
```

`place_receiver()` changes the existing grid node. It neither recreates the cubes nor reads a different source. In the table pose, local X runs across and local Z follows the rows along the floor. The first cube centre is at the grid's origin. On the right wall, the two quarter-turns put local X along the room's Z direction, local Z downward, and local Y outward toward you.

The helper still places neighbouring cube centres 0.32 local units apart. Dividing the desired width by that spacing gives the scale: 0.48 / 0.32 = 1.5. The cubes, their gaps and the selection ring all grow together. Here **cell width means centre-to-centre spacing**, not the coloured cube's width; each cube leaves a small gap around it.

The address calculation has a return journey. `to_local()` takes the point's world position through the inverse of the grid's translation, rotation and scale. We can then use the same local X/Z calculation on either face. Adding half a pitch places the first interval's boundary half a cell before its centre. `floori()` chooses the interval; the dictionary rejects addresses outside the five-by-five display.

Local Y measures distance out from the receiver. Multiplying by the grid's uniform scale returns that distance to metres. The allowed point-centre distance stays 12–65 centimetres on both faces and at both sizes. Testing world Y would work above the table and fail beside the wall. This conversion assumes the lesson root remains at unit scale.

## Predict, then inspect

Select surface **row 1, column 3**. With the printed translation reader, it consults source **row 1, column 0**: navy. Turn the receiver into the right-wall pose and find that address again. Its position has changed; its value has not. Moving the whole learner root elsewhere in the museum should preserve this relation too.

At 32 centimetres per cell, the three-column source spans 96 centimetres. At 48 centimetres it spans 1.44 metres. The five addressed intervals span 1.6 and 2.4 metres respectively; the outermost cube edges sit slightly inside those bounds. Neither display contains two complete horizontal copies of the source.

Change the width list to `[0.24, 0.36]`. Before running, predict the new source widths: **0.72 and 1.08 metres**. Keep the source and the twenty-five colours unchanged. After turning and enlarging the receiver, the point should still find surface row 1, column 3. It should stop selecting when its centre is more than 65 centimetres from the surface.

The previous reflected reader is retained in `source_address()`. If you deliberately start with `reflected = true`, the same surface address reads source row 1, column 2: pink. For this asymmetric source, the horizontal translation period is then six cells, twice the source width. Turning or resizing the receiver does not switch that rule.

## Return to the passage

The little grid changes size as a whole. The installed tunnel holds its dimensions and changes how many intervals fit across each face. Both keep their source, but they answer different spatial constraints. Look for the cut interval at the tunnel's boundary and the place where its wall starts counting again.

Carry three things separately: the source entry, the address that reads it, and the frame that gives the address a place. Symmetry Seventeen will compare operations on the repeating field. The room's finite edges remain available to test what that comparison leaves out.

## Complete carried files

### The carried files

Palette, GridSurface and PointBody are unchanged from Tutorial Pattern. Their complete code is kept here for reconstruction; the new work is the receiver frame and its inverse selection. The point's pickup and release behaviour remain supplied by the earlier class.

### palette.gd

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

### grid_surface.gd

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

### point_body.gd

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
