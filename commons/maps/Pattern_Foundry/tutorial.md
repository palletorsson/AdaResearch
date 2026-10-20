# Pattern Foundry — one mark, several places

## Learning elements

- An editable source of palette indices.
- Wrapped addresses into that source.
- One edit reaching its repeated occurrences.

Build the editable source. Stay with one mark and its repeated appearances. Copying recipes, dressing architecture and saving fabric are later questions; the larger machines remain available for a return visit.

## Find the source

At the museum's small four-by-four tile station, take a coloured cube and release it over an off-centre cell. Find that mark in the repeated preview. Add another beside it. Follow the pair before moving to the mirror station or the larger machines.

Disco calculated zero or one from an address and a phase. Here we replace that calculation with a small arrangement we can edit and keep. The cube grid, Palette class and grabbable point return. Their construction is already available; the new work is a source and the rule that reads it.

The installed small tile has sixteen cells. Our reduced motif has two rows and three columns, so every entry is easy to inspect and the two directions have visibly different repeat lengths. The same five-by-five preview from Disco shows several returns and cuts through the last repeat. It does not stretch the source to fit.

## Continue the same display

Use `02_source_motif.gd` on an empty Node3D at floor level and unit scale in your existing museum learner space. Put the three carried files beside it. Replace the previous lesson's entry script rather than running both on the same object. The museum supplies the player, camera, lights and XR Tools input; this small cube grid remains a display, not a walkable floor.

Hold the black point above a tile. Its centre must be between 12 and 65 centimetres above the display. A ring and the label show the selected preview address and the source cell it reads. Press the held trigger: that source value advances through navy, pink and mint. All preview cells reading it change together. Moving without pressing selects but does not paint. Moving outside the grid or height range prevents an edit.

### The source and its reader

<!-- student-code:02_source_motif.gd -->
```gdscript
extends Node3D

const Palette = preload("palette.gd")
const GridSurface = preload("grid_surface.gd")
const PointBody = preload("point_body.gd")
var source := [[0, 1, 0], [0, 0, 1]]
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
    paint()

func source_address(address: Vector2i) -> Vector2i:
    return Vector2i(posmod(address.x, source[0].size()), posmod(address.y, source.size()))

func value_at(address: Vector2i) -> int:
    var cell := source_address(address)
    return source[cell.y][cell.x]

func paint() -> void:
    for address: Vector2i in grid.cells:
        grid.write(address, palette.colours[value_at(address)])

func selected_address() -> Vector2i:
    var local: Vector3 = grid.to_local(control.global_position)
    var address := Vector2i(floori((local.x + 0.16) / 0.32), floori((local.z + 0.16) / 0.32))
    if local.y < 0.12 or local.y > 0.65 or not grid.cells.has(address):
        return Vector2i(-1, -1)
    return address

func edit(address: Vector2i) -> void:
    var cell := source_address(address)
    source[cell.y][cell.x] = (source[cell.y][cell.x] + 1) % palette.colours.size()
    paint()

func choose(_held: Variant) -> void:
    var address := selected_address()
    if address != Vector2i(-1, -1):
        edit(address)

func _process(_delta: float) -> void:
    var address := selected_address()
    grid.marker.visible = address != Vector2i(-1, -1)
    var selection := "outside / no edit"
    if grid.marker.visible:
        var cell := source_address(address)
        grid.marker.position = grid.instances.get_instance_transform(grid.cells[address]).origin + Vector3(0, 0.06, 0)
        selection = "preview %s -> source row %d, column %d" % [address, cell.y, cell.x]
    label.text = "SOURCE %s\n%s\nGRIP: move above a tile / TRIGGER: change its shared source" % [source, selection]
```

Read `source[0][1]` as row zero, column one. It begins at 1, which selects pink from the palette. The rows run along the grid's local Z direction; columns run along X. `Vector2i.y` is the row address here, not a height.

The reader wraps the column by three and the row by two. Preview addresses (1, 0), (4, 0), (1, 2), (4, 2), (1, 4) and (4, 4) all read source row zero, column one. These six places share one decision. `posmod` also gives a valid wrapped address for negative inputs; it returns a non-negative remainder.

`edit()` changes one stored number, then `paint()` visits the existing cube addresses and updates their colours. No cube is created or moved. The preview is refreshed explicitly: assigning an array entry alone does not notify a mesh. The image repeats the source; it does not contain a separately editable source array for each copy.

The hand adapter transforms the point into the grid's local frame before selecting a cell. The carried renderer spaces centres 32 centimetres apart. Adding half that pitch before rounding down selects the nearest cell, including the small visible gaps. The height check makes this a shallow interaction region. The selection stays meaningful if the whole learner object is turned in the room.

## Predict a shared change

Begin with source row zero, column one: it is pink. Select preview (4, 2) and press once. Predict the six addresses listed above before you inspect the result. They should become mint; the other nineteen colours and all twenty-five cube transforms should stay unchanged. Press twice more over the same source address to return to pink. Moving to another copy does not give it an independent value.

## Give the source another row

Before rerunning, replace the source declaration with `var source := [[0, 1, 0], [0, 0, 1], [2, 0, 0]]`. Predict the result. The width stays three; the row period becomes three. Preview (0, 2) should now be mint. The next occurrence of source row zero is at preview row three, not row two. The preview keeps five rows and five columns; it ends partway through a repeat.

Run the changed program, locate the new row, and explain why the receiver did not need to grow. Then choose one other source entry, list every preview address that will read it, and test your prediction with the held point. Keep every row the same length and every value a valid palette index. This example assumes that rectangular, non-empty source; it is not an importer for arbitrary data.

## Return to the larger room

The small tile, the loom's five-by-five card and the fabric studio are separate sources. Editing this learner array does not edit those installations. At the loom, MARK changes the same source image received by the flat and curved specimens. Holding the curve makes it decline later images. It does not give one repeated mark its own editable source.

A reference to a nested array, an independent copy of its rows and a held rendered image have different consequences. This first construction has one source and no copy or save control. Keep that distinction for a later return, rather than treating the held museum texture as a demonstration of array copying. The studio's save, receiver and architectural controls remain available in the encounter and the technical reference.

In Tutorial Pattern, keep an asymmetric source and change how copies read it. One mark near an edge, with a differently coloured neighbour, will make a reflected lookup easier to see.

## Complete carried files

### The carried files

These files are unchanged from Disco. `Palette` owns its colour list. `GridSurface` owns the addressed cube instances; we reuse its marker and hide its old readout. `PointBody` supplies grip and the action signal. They are printed for reconstruction, not introduced again as new subjects.

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
