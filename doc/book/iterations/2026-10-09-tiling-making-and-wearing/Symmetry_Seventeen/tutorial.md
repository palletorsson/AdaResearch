# Symmetry Seventeen — a reflection that slips

## Learning elements

- Reflection composed with a half-height shift.
- Source height as a condition of the discrete rule.
- A construction rule versus a classification claim.

A short extension of the existing reader: add a half-height shift to reflection. Use P1 and PM as known comparisons. The new question is what composing operations permits; the wider gallery introduces classification without asking you to rebuild seventeen systems.

## Compare the installed fields

At the side-bay console, keep the asymmetric four-by-four source. The left panel holds its initial P1 image; the right panel and carpet follow your edits. Choose PM, then PG. Follow the corner colour: a reflection becomes a reflection with a shift of two source rows. HOLD keeps an image for comparison. A later paint edit changes the live field while the held pixels stay still; UNDO recovers the previous state.

Our smaller construction keeps the two-row, three-column source, twenty-five cubes and black point from Array Patterns. We already know how to reflect alternate blocks and place a receiver. Add one operation: on those reflected blocks, move the source row halfway around its cycle. Half of our two rows is **one row**. The installed four-row source shifts by two.

## Extend the receiver

Keep `04_surface_frame.gd`, `palette.gd`, `grid_surface.gd` and `point_body.gd` unchanged beside the new file. Attach **05_glide_reader.gd instead of 04_surface_frame.gd** to the same learner Node3D in the museum. Keep that root at unit scale. There is one running display.

`extends` keeps the previous construction and specializes its address lookup and actions. `super._ready()` builds that receiver once. The new `_ready()` adds only the central RULE label. The complete carried files are printed below; their camera, player and XR Tools still come from the museum.

Hold the point above RULE and press the trigger to cycle P1 → PM → PG → P1. FACE and CELL WIDTH still work at the sides. While comparing rules, keep the receiver and width fixed. The point can paint again: trigger over a selected cube cycles the source entry it reads through the three palette colours. Hovering only selects.

### 05_glide_reader.gd

<!-- student-code:05_glide_reader.gd -->
```gdscript
extends "04_surface_frame.gd"

const RULE_NAMES := ["P1 / TRANSLATE", "PM / REFLECT", "PG / GLIDE"]
var rule := 0

func _ready() -> void:
    assert(source.size() % 2 == 0, "This discrete half-height shift needs an even row count.")
    super._ready()
    var card := Label3D.new()
    card.text = "RULE"
    card.position = Vector3(0, 0.9, 2.5)
    card.font_size = 28
    card.pixel_size = 0.002
    add_child(card)

func source_address(address: Vector2i) -> Vector2i:
    var cell := super.source_address(address)
    var tile_column := floori(float(address.x) / source[0].size())
    if rule == 2 and posmod(tile_column, 2) == 1:
        cell.y = posmod(cell.y + source.size() / 2, source.size())
    return cell

func repaint() -> void:
    for address: Vector2i in grid.cells:
        grid.write(address, palette.colours[value_at(address)])

func cycle_rule() -> void:
    rule = (rule + 1) % RULE_NAMES.size()
    reflected = rule != 0
    repaint()

func operation() -> String:
    var local := to_local(control.global_position)
    if absf(local.x) <= 0.2 and local.y >= 0.95 and local.y <= 1.5 and absf(local.z - 2.5) <= 0.25:
        return "RULE"
    return super.operation()

func choose(held: Variant) -> void:
    if operation() == "RULE":
        cycle_rule()
    elif not operation().is_empty():
        super.choose(held)
    else:
        var address := selected_address()
        if address != Vector2i(-1, -1):
            var cell := source_address(address)
            source[cell.y][cell.x] = (source[cell.y][cell.x] + 1) % palette.colours.size()
            repaint()

func _process(delta: float) -> void:
    super._process(delta)
    label.text = RULE_NAMES[rule] + "\n" + label.text.replace("GRIP: inspect / TRIGGER at label: change receiver", "GRIP: select / TRIGGER: paint cell or use named action")
```

The inherited lookup wraps the column and row. When `reflected` is true, it also reverses the column in alternate source blocks. The new `source_address()` starts with that answer, then shifts its row only in PG's reflected blocks. `super.source_address()` calls the earlier method; `return cell` passes the resulting address back to the existing colour reader.

The rule number selects the operation, not a colour. Cycling synchronizes the inherited reflection flag and repaints the existing cubes. It does not change the stored source, the cube positions, or the receiver frame. Painting takes a different path: it uses that same lookup to find the original source entry, changes it, then repaints every copy that reads it.

The half-height shift requires an even number of discrete source rows. The assertion names that condition. Rounding half an odd height would define a different operation, so we do not silently substitute it. The museum's square four-by-four source and our rectangular two-by-three source both satisfy the condition.

## Predict three readings

Use **surface row 0, column 3**, the first column of the second source block. Addresses below are written `[row, column]`.

| Rule | Source address | Stored value | Colour |
| --- | --- | --- | --- |
| P1 | [0, 0] | 0 | Navy |
| PM | [0, 2] | 0 | Navy |
| PG | [1, 2] | 1 | Pink |

P1 and PM read different entries that happen to contain the same value. One equal-looking cell does not show that the operations agree. Follow the other row and the rest of the mark before drawing that conclusion.

On PG, trigger over this surface cell. Source `[1,2]` changes from 1 to 2: mint. The visible copies at surface `[0,3]`, `[1,2]`, `[2,3]`, `[3,2]` and `[4,3]` change together. You edit one stored entry through five displayed occurrences. The source is still two rows by three columns.

For this asymmetric source, moving six cells across restores the PG reading; moving three does not generally do so. Vertically it repeats after two rows. Applying the glide twice gives a full-height translation. It does not erase the journey through the intermediate reflected mark.

The five-column display cannot show a whole six-column horizontal period. Inspect its visible part, then use the lookup to compare an address six columns farther on. The installed panels show eight source blocks in each direction and make that repeated relation easier to see.

## Change the source height

Before `assert(...)` in the new `_ready()`, add `source = [[0, 1, 0], [0, 0, 1], [2, 0, 0], [0, 2, 0]]`. This replaces only the stored source before the inherited receiver is built. Predict the result before running:

- PG now moves two source rows. Surface `[0,3]` reads source `[2,2]`, value 0.
- Surface `[2,4]` reads source `[0,1]`, value 1.
- The vertical period becomes four cells. The horizontal translation period remains six for this source.

Change FACE or CELL WIDTH after finding those cells. Their positions change; their source addresses do not. This checks that the new reading composes with the receiver frame from Array Patterns.

As a separate comparison, make every source entry zero and cycle the rules. The image becomes uniform although the address operations still differ. Add one mark again. Which difference can that mark reveal?

## Return to the gallery

The console's P1, PM and PG names identify construction rules. Extra symmetries in a chosen source can give the resulting field more symmetry than that button alone suggests. These examples do not classify the entire field automatically.

The [IUCr tables](https://it.iucr.org/Ab/) describe seventeen plane-group types. Our three constructions and the cage's rotational diagram are ways into that subject; they do not prove the classification. A finite, coloured, sampled display also has edges and a viewing situation.

Carry the source, the operation that reads it, and the surface that receives it into **Pattern Temple**. There we will distinguish changing a shared source from choosing which architectural surface receives it. The later ribbon halls extend the reading through layers.

## Complete carried files

These four files are unchanged from Array Patterns. Use them beside the new script; do not attach a second copy of the previous entry to another node. The new subclass reuses their construction.

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

