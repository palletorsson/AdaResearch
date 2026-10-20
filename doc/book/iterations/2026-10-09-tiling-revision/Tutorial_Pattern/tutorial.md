# Tutorial Pattern — change the reading

## Learning elements

- Reflected lookup on alternating copies.
- Changing an address versus changing stored data.
- Translation period and tile width.
- An asymmetric mark as a diagnostic.

## Keep the source

In the museum's side bay, find the red bend on both wall panels. The left panel repeats it with the same facing. On the right, alternate copies face back. Press PM, then P1: the floor changes, but the sixteen source buttons do not. Press FLIP X. Now the source changes, and both panels follow it.

Continue Foundry's source, cube display and held point. Last time, every copy read a row in the same direction. We will let alternate copies read it backwards. Then we will reverse the stored rows and compare the consequences. The museum's shader, quarter-turn control and undo history stay supplied; the new lesson is the address operation.

## Two actions on the carried object

Replace the Foundry entry script with `03_reflected_reader.gd`, on the same empty Node3D at floor level and unit scale in your museum learner space. Keep the three carried files beside it. The museum still supplies the player, lights, camera and XR Tools. This five-by-five display is not a walkable floor. Its two-by-three source is the same reduced motif from Foundry, rather than a replacement for the installed four-by-four editor.

Grip the black point. Over a cube, trigger still edits that cube's shared source entry. At the front, hold it just above the **READ RULE** label and trigger to switch between translation and alternating reflection. Over **FLIP SOURCE**, trigger reverses each stored row. The upper readout names the selected action before you press. Moving the point alone changes nothing.

The front labels sit 60 centimetres to either side of the starting point. Their selection regions extend 25 centimetres sideways and forwards/backwards, with the point centre between 95 and 150 centimetres above the learner floor. These bounds are part of the supplied hand adapter; changing the reader does not require changing them.

### The source and two operations

<!-- student-code:03_reflected_reader.gd -->
```gdscript
extends Node3D

const Palette = preload("palette.gd")
const GridSurface = preload("grid_surface.gd")
const PointBody = preload("point_body.gd")
var source := [[0, 1, 0], [0, 0, 1]]
var reflected := false
var palette = Palette.new([Color("172051"), Color("fc62ad"), Color("55f3cf")])
var grid: Node3D
var control: PointBody
var label := Label3D.new()

func _ready() -> void:
    grid = GridSurface.new()
    grid.position = Vector3(-0.64, 0.82, 0)
    add_child(grid)
    grid.readout.hide()
    control = PointBody.new()
    control.position = Vector3(0, 1.15, 1.9)
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
    for side in [-1, 1]:
        var card := Label3D.new()
        card.text = "READ RULE" if side == -1 else "FLIP SOURCE"
        card.position = Vector3(side * 0.6, 0.9, 1.9)
        card.font_size = 28
        card.pixel_size = 0.002
        add_child(card)
    paint()

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

func paint() -> void:
    for address: Vector2i in grid.cells:
        grid.write(address, palette.colours[value_at(address)])

func toggle_reader() -> void:
    reflected = not reflected
    paint()

func flip_source() -> void:
    for row: Array in source:
        row.reverse()
    paint()

func selected_address() -> Vector2i:
    var local: Vector3 = grid.to_local(control.global_position)
    var address := Vector2i(floori((local.x + 0.16) / 0.32), floori((local.z + 0.16) / 0.32))
    if local.y < 0.12 or local.y > 0.65 or not grid.cells.has(address):
        return Vector2i(-1, -1)
    return address

func operation() -> String:
    var local := to_local(control.global_position)
    if local.y < 0.95 or local.y > 1.5 or absf(local.z - 1.9) > 0.25:
        return ""
    if absf(local.x + 0.6) <= 0.25:
        return "READ RULE"
    if absf(local.x - 0.6) <= 0.25:
        return "FLIP SOURCE"
    return ""

func edit(address: Vector2i) -> void:
    var cell := source_address(address)
    source[cell.y][cell.x] = (source[cell.y][cell.x] + 1) % palette.colours.size()
    paint()

func choose(_held: Variant) -> void:
    var command := operation()
    if command == "READ RULE":
        toggle_reader()
    elif command == "FLIP SOURCE":
        flip_source()
    else:
        var address := selected_address()
        if address != Vector2i(-1, -1):
            edit(address)

func _process(_delta: float) -> void:
    var address := selected_address()
    grid.marker.visible = address != Vector2i(-1, -1)
    var selection := "no selection" if operation().is_empty() else operation()
    if grid.marker.visible:
        var cell := source_address(address)
        grid.marker.position = grid.instances.get_instance_transform(grid.cells[address]).origin + Vector3(0, 0.06, 0)
        selection = "preview %s -> source row %d, column %d" % [address, cell.y, cell.x]
    label.text = "SOURCE %s\nREADER %s / %s\nGRIP: select with point / TRIGGER: apply" % [source, "alternating reflection" if reflected else "translation", selection]
```

`source_address()` first finds the column of the repeated tile, then the cell inside it. With a source three cells wide, display columns 0–2 belong to tile column zero; columns 3–5 belong to tile column one. The second tile is partly cut off by our five-column display. A copy need not fit entirely inside a receiver.

For a reflected tile, `width - 1 - column` reads columns 2, 1, 0 instead of 0, 1, 2. The stored row stays where it was. `floori()` counts tile columns correctly on the negative side too; `posmod()` supplies a non-negative local address. The condition is based on the **tile column**, not on alternate individual cells.

`toggle_reader()` changes one Boolean and repaints. `flip_source()` changes the arrays themselves: `row.reverse()` reverses each row in place. Reversing the outer `source` array would swap top and bottom rows, which is a different operation. Both functions repaint the existing cubes; neither changes their geometry.

### The carried files

These three files are unchanged from Foundry. They remain printed so the example can be reconstructed completely. Their construction is not a new obligation here. The existing `choose()` adapter gains two named actions; its old cube selection and source editing remain.

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

## Predict before pressing

Begin with the printed source and translation. Display (3, 1) reads source row one, column zero: navy. Switch READ RULE. It now reads row one, column two: pink. The source label must still read `[[0, 1, 0], [0, 0, 1]]`.

Keep reflection on and press FLIP SOURCE. The lower source row becomes `[1, 0, 0]`. Display (3, 1) becomes navy again; display (0, 1) becomes pink. Press FLIP SOURCE a second time. Every stored entry and displayed colour should return. The Boolean stays on throughout these two source edits.

Now point at display (3, 1) and trigger once. Because that copy reads backwards, you edit source column two, not column zero. Predict its other appearances before pressing. In this bounded display, (2, 1), (3, 1), (2, 3) and (3, 3) all become mint. A reflected view must also lead an edit back to the correct stored cell.

The source width is three cells. Under translation its horizontal period is three. With alternating reflection, this asymmetric motif returns to the same arrangement after six cells. Our preview is smaller than that period: call `value_at(Vector2i(6, 1))` to compare it with (0, 1), or follow the complete paired copies on the museum panel. A tile width and a pattern's translation period need not be equal.

## Make a change that hides the rule

Before running again, replace only the declaration with `var source := [[0, 1, 0], [2, 0, 2]]`. Predict both actions. Each row now reads the same backwards. READ RULE still changes the Boolean and the addresses, but no displayed colour should change. FLIP SOURCE performs its reversal, yet produces the same stored values. An unchanged image cannot tell you that no operation happened.

Break the symmetry: with reflection on, edit display (3, 1) once. This changes source column two from mint to navy, while column zero stays mint. Switch READ RULE again and locate the newly visible difference. Explain it using the source address, not just the appearance. The program assumes a non-empty rectangular source containing valid palette indices, as in Foundry.

## What travels onward

The source is data; a reader decides which entry each place receives. A mutation and a changed reader may produce similar images, so inspect the stored cells as well. The installed wall panels provide two fixed rules for comparison; our single learner display switches between those rules. It does not control the museum station.

In Array Patterns, keep this distinction and give the reading a physical frame: where it begins, which way its axes run, and how much space one cell occupies.
