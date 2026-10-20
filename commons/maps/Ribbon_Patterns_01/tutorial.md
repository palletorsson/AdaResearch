# Ribbon Patterns 01 — an address gains depth

## Learning elements

- Layers of rows stored as values[y][z][x].
- Height used as an input to the source lookup.
- A hidden layer versus deleted data.

Take a branch from the surface into a volume. The extra index is the subject. This prepares later work with spatial data; the next colour comparison and fabric shader do not require a volume. Keep that distinction instead of pretending every room is a prerequisite for the next.

## Start with the installed pair

The low source array and the volume near the entrance belong together. The console names their storage order: SOURCE `[z][x]`, VOLUME `[y][z][x]`. Use X + and Z +, then LAYER +. A frame moves up through the volume while another names the source entry it reads. REPEAT / SHIFT makes height enter that reading. SLICE / ALL hides the other layers; UNDO returns to an earlier state.

There are sixteen source entries and sixty-four volume entries. A slice shows sixteen of the sixty-four. Zero selects a pale cube here. It is a value with a visible body, not an empty address.

## Carry the source and the point

In Pattern Temple we kept a separate record for each receiver. Here, make a related arrangement: layers of receivers filled by one rule. Keep our two-row, three-column source, three colours, black point and five-by-five `GridSurface`. Put one grid on the left as a reference; stack four on the right. There are **six source values, twenty-five reference cubes and one hundred stored volume values**. The counts differ from the installed pair because we are developing our smaller construction.

Begin with translation, the P1 reading we already know. Hold reflection and glide aside while asking what height adds. In REPEAT, all four layers read the same source. In SHIFT, layer `y` adds `y` to the source column before wrapping. Cube positions stay fixed.

Replace the previous entry with **07_layer_reader.gd** on the same learner Node3D in the museum. Keep its root at unit scale. The three unchanged helper files follow below. The existing museum still supplies the player, camera, light and XR Tools.

The point now inspects the selected layer. Grip it, hold it above LAYER, SLICE or SHIFT, and trigger. Over the grid, hovering shows the volume and source addresses; triggering there does not paint. We keep the source fixed for this comparison. The left marker identifies the source entry in the first two rows and three columns of the reference grid; the remaining reference cells repeat those values.

### 07_layer_reader.gd

<!-- student-code:07_layer_reader.gd -->
```gdscript
extends Node3D

const Palette = preload("palette.gd")
const GridSurface = preload("grid_surface.gd")
const PointBody = preload("point_body.gd")
const LAYER_COUNT := 4
const SHIFT_STEP := 1
const ACTIONS := ["LAYER", "SLICE", "SHIFT"]
var source := [[0, 1, 0], [0, 0, 1]] # [z][x]
var values: Array = [] # [y][z][x]
var layers: Array[Node3D] = []
var layer := 0
var shifted := false
var slice_only := false
var palette = Palette.new([Color("172051"), Color("fc62ad"), Color("55f3cf")])
var reference: Node3D
var control: PointBody
var label := Label3D.new()

func _ready() -> void:
    reference = GridSurface.new()
    add_child(reference)
    reference.position = Vector3(-1.5, 0.65, 0)
    reference.readout.hide()
    for address: Vector2i in reference.cells:
        reference.write(address, palette.colours[source[posmod(address.y, source.size())][posmod(address.x, source[0].size())]])
    for y in LAYER_COUNT:
        var grid := GridSurface.new()
        add_child(grid)
        grid.position = Vector3(0.3, 0.55 + y * 0.4, 0)
        grid.readout.hide()
        layers.append(grid)
    control = PointBody.new()
    control.position = Vector3(0, 1.15, 2.5)
    var black := StandardMaterial3D.new()
    black.albedo_color = Color(0.025, 0.025, 0.03)
    black.roughness = 0.18
    control.get_child(0).material_override = black
    add_child(control)
    control.action_pressed.connect(choose)
    label.position = Vector3(0, 2.65, 0)
    label.font_size = 26
    label.pixel_size = 0.002
    add_child(label)
    for i in ACTIONS.size():
        var card := Label3D.new()
        card.text = ACTIONS[i]
        card.position = Vector3((i - 1) * 0.6, 0.9, 2.5)
        card.font_size = 28
        card.pixel_size = 0.002
        add_child(card)
    fill_values()
    update_view()

func source_address(x: int, y: int, z: int) -> Vector2i:
    var offset := y * SHIFT_STEP if shifted else 0
    return Vector2i(posmod(x + offset, source[0].size()), posmod(z, source.size()))

func sample(x: int, y: int, z: int) -> int:
    var cell := source_address(x, y, z)
    return source[cell.y][cell.x]

func fill_values() -> void:
    values.clear()
    for y in LAYER_COUNT:
        var sheet: Array = []
        for z in 5:
            var row: Array = []
            for x in 5:
                row.append(sample(x, y, z))
            sheet.append(row)
        values.append(sheet)
        for address: Vector2i in layers[y].cells:
            layers[y].write(address, palette.colours[values[y][address.y][address.x]])

func update_view() -> void:
    for y in layers.size():
        layers[y].visible = not slice_only or y == layer

func operation() -> String:
    var local := to_local(control.global_position)
    if local.y < 0.95 or local.y > 1.5 or absf(local.z - 2.5) > 0.25:
        return ""
    for i in ACTIONS.size():
        if absf(local.x - (i - 1) * 0.6) <= 0.2:
            return ACTIONS[i]
    return ""

func choose(_held: Variant) -> void:
    match operation():
        "LAYER":
            layer = (layer + 1) % layers.size()
            update_view()
        "SLICE":
            slice_only = not slice_only
            update_view()
        "SHIFT":
            shifted = not shifted
            fill_values()

func selected_address() -> Vector2i:
    var grid: Node3D = layers[layer]
    var local: Vector3 = grid.to_local(control.global_position)
    var cell := Vector2i(floori((local.x + 0.16) / 0.32), floori((local.z + 0.16) / 0.32))
    if local.y < 0.12 or local.y > 0.35 or not grid.cells.has(cell):
        return Vector2i(-1, -1)
    return cell

func _process(_delta: float) -> void:
    var address := selected_address()
    for y in layers.size():
        layers[y].marker.visible = y == layer and address != Vector2i(-1, -1)
    reference.marker.visible = address != Vector2i(-1, -1)
    var selection := operation()
    if address != Vector2i(-1, -1):
        layers[layer].mark(address)
        var cell := source_address(address.x, layer, address.y)
        reference.mark(cell)
        selection = "VOLUME [%d][%d][%d] <- SOURCE [%d][%d] = %d" % [layer, address.y, address.x, cell.y, cell.x, values[layer][address.y][address.x]]
    var visible_cells := 25 if slice_only else LAYER_COUNT * 25
    label.text = "%s / LAYER %d / %d VISIBLE / %d STORED\n%s\nGRIP: inspect / TRIGGER at a label: act" % ["SHIFT" if shifted else "REPEAT", layer, visible_cells, LAYER_COUNT * 25, selection]
```

## One more index

`values[y]` selects a layer. `values[y][z]` selects a row in that layer. `values[y][z][x]` reads one stored palette index. When placed in space, the directions are still x, y and z. Storage order is a convention we declare, not a change in those directions.

The outer loop in `fill_values()` creates a fresh `sheet` for each height. Its inner loop creates a fresh `row`. Reusing one row or sheet would make several entries refer to the same mutable list—the ownership problem from Temple would return inside the volume.

`source_address()` gives the original source address. `sample()` reads its value. `fill_values()` stores those readings and colours the existing cubes. The loop that positions the grids runs only when the construction starts. SHIFT fills new values; it does not move the layers.

Our volume is a derived record. Changing the source in code requires running `fill_values()` again to update it. No automatic live connection is implied by having sampled a source once.

## Predict a cell before selecting it

Set LAYER to 1 and inspect column 4, row 3: volume `[1][3][4]`. In REPEAT, column 4 wraps to source column 1; row 3 wraps to source row 1. That entry contains 0, navy.

In SHIFT, the column reads `(4 + 1)` wrapped across three columns: source column 2. Source `[1][2]` contains 1, pink. The marker on the reference moves one column. The selected volume address and the cube position stay still.

Now follow volume column 0, row 1 through layers 0, 1, 2 and 3 with SHIFT on. Its values are **0, 0, 1, 0**. The reading returns after three height steps because the source is three columns wide. Four stored layers do not imply a four-layer pattern period.

## A view is not a deletion

SLICE calls `update_view()`. It changes each layer's `visible` property; it does not clear `values`, remove children or regenerate cubes. The display shows twenty-five volume cells and keeps one hundred stored. The twenty-five reference cubes are separate from that counter.

Use LAYER while sliced. Inspect the same row and column at another height. Then restore ALL. Hidden values return with their bodies because neither was deleted. A cube obscured behind another cube is different again: its node may be visible even though your view is blocked.

In our carried palette, zero is navy; in the installed pair it is pale. In both cases, the program draws a cube for it. A previous occupancy lesson could use zero to mean vacancy. These meanings come from what the program does with a value, not from the number alone.

## Change the direction of the reading

Make an independent edit: set `LAYER_COUNT` to 3 and `SHIFT_STEP` to -1. Keep the same source and rendering helper. Predict before running:

- The volume stores 75 values. SLICE shows 25; the reference still has 25 cubes.
- With SHIFT on, volume `[1][1][0]` reads source `[1][2]`: value 1, pink. The negative offset wraps back into the source.
- At column 0, row 1, the three layers read **0, 1, 0**.
- Three presses of LAYER return to the starting layer. SHIFT changes no receiver positions.

`posmod()` is useful here: a negative input still produces an address between zero and width minus one. Do not replace it with a remainder that can stay negative. The readout should name column 2, not -1, even if a language allows a negative list index to reach the same value.

## Return to the larger array

Find the same distinction at the installed console: a selected layer, a source lookup, a stored value, and a body you may or may not see. Its fixed four-by-four source shifts with a four-column wrap. Our smaller source repeats with a three-column wrap. Neither example imports edits from the other automatically.

The bars, shelves and sorting examples elsewhere in the hall can remain other encounters. This tutorial follows the layered reader. In Ribbon Patterns 02, keep the value fixed and ask what its surroundings and receiving surface add to what you see.

## Complete carried files

The grid, palette and pickable point are unchanged from Pattern Temple. Their construction is supplied here; the new work is how layers are filled and inspected.

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
    readout.text = "(%d, %d) #%s\nX+ / Z+: select   COLOUR: leave a colour" % [address.x, address.y, read(address).to_html(false)]
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

