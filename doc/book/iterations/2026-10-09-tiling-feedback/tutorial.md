# Tiling — complete tutorial sequence

<!-- hall: Pattern_Disco -->

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


---

<!-- hall: Pattern_Foundry -->

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


---

<!-- hall: Tutorial_Pattern -->

# Tutorial Pattern — change the reading

## Learning elements

- Forward and reflected source lookup.
- Changing a reader versus mutating its data.
- Painting back through a reflected occurrence.

Change how a copy reads the source. This room separates a reflected lookup from a mutation of the stored mark. Keep the source small and asymmetric; classification and glide will come later.

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

## Complete carried files

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


---

<!-- hall: Array_Patterns -->

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


---

<!-- hall: Symmetry_Seventeen -->

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

The hand loom is an optional encounter. Carry the shuttle through the raised threads, then beat the pass into place. Change the draft after a completed pass and compare the old crossings with the next ones. Earlier passes keep their instructions. You can investigate that history without programming the loom; completing it is not required to continue the reader tutorial.

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



---

<!-- hall: Pattern_Temple -->

# Pattern Temple — the same, for now

## Learning elements

- Selecting the receiver of an edit.
- A recipe copied once versus a continuing shared reference.
- Composing agreement and difference across a room.

Compose with the source, rules and frames you already have. Foundry made every occurrence consult one source. Here separate receivers own separate recipes: copying makes them agree once, while a later edit can stay local. The temple gives that choice room to matter.

## Read the room

At DRESS THE TEMPLE, TARGET moves the gold marker between eight surface groups: floor, far wall, east wall, west wall, entrance wall, columns, dome and frieze. Selecting a group does not change its pattern. SOURCE, GROUP, PALETTE and SEED change the selected group's settings. Start with one of the fixed sources, such as STARS; imported studio packages have their own settings.

Press ALL. The selected recipe is copied to the other seven groups. Now press PALETTE once. Only the selected group changes. ALL was an action taken once; it did not establish an ongoing connection.

Each group owns a material. The columns share their group's material with one another; a wall does not share that material with the columns. A recipe can agree across groups while the surfaces keep separate materials, orientations and texture coordinates. The same settings need not produce the same apparent spacing or silhouette.

## Carry the small construction

Keep our black point, palette, five-by-five receiver and the source from Symmetry. Keep its P1, PM and PG address operations. Make two receivers visible together: a table and a wall. Each gets its own source record and rule number. This is the small part of the temple that we will reconstruct.

Replace the previous entry script with **06_receivers.gd** on the same learner Node3D inside the museum. Keep its root at unit scale. Keep the three unchanged files printed below beside it. The museum supplies the player, camera, light and XR Tools. This replaces the small display; it does not replace the installed temple or add another player.

We rewrite the entry because it now manages two receivers. The familiar lookup accepts an extra `i`: whose source should it read? The supplied `GridSurface` still builds the same twenty-five cubes. The controls for changing the earlier receiver's width and orientation are no longer needed in this comparison: its two poses stay fixed.

Grip the point. Hold it above TARGET and trigger to change the selection. RULE cycles that receiver's reading. ALL copies its recipe to the other receiver. Hover the point over a selected cube and trigger to paint the source entry it reads. Hovering alone changes nothing. A point over the unselected surface cannot paint it; select that receiver first.

### 06_receivers.gd

<!-- student-code:06_receivers.gd -->
```gdscript
extends Node3D

const Palette = preload("palette.gd")
const GridSurface = preload("grid_surface.gd")
const PointBody = preload("point_body.gd")
const RULE_NAMES := ["P1", "PM", "PG"]
const ACTIONS := ["TARGET", "RULE", "ALL"]
var source := [[0, 1, 0], [0, 0, 1]]
var recipes: Array = []
var receivers: Array[Node3D] = []
var target := 0
var palette = Palette.new([Color("172051"), Color("fc62ad"), Color("55f3cf")])
var control: PointBody
var label := Label3D.new()

func _ready() -> void:
    assert(source.size() % 2 == 0, "PG needs an even number of source rows.")
    for i in 2:
        recipes.append({"source": source.duplicate(true), "rule": 2})
        var grid := GridSurface.new()
        add_child(grid)
        grid.readout.hide()
        grid.position = Vector3(-1.5, 0.82, 0) if i == 0 else Vector3(0.3, 2.2, 0)
        grid.rotation.x = 0 if i == 0 else PI / 2
        receivers.append(grid)
        repaint(i)
    control = PointBody.new()
    control.position = Vector3(0, 1.15, 2.5)
    var black := StandardMaterial3D.new()
    black.albedo_color = Color(0.025, 0.025, 0.03)
    black.roughness = 0.18
    control.get_child(0).material_override = black
    add_child(control)
    control.action_pressed.connect(choose)
    label.position = Vector3(0, 2.75, 0)
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

func source_address(i: int, address: Vector2i) -> Vector2i:
    var data: Array = recipes[i]["source"]
    var rule: int = recipes[i]["rule"]
    var width: int = data[0].size()
    var odd := posmod(floori(float(address.x) / width), 2) == 1
    var cell := Vector2i(posmod(address.x, width), posmod(address.y, data.size()))
    if rule != 0 and odd:
        cell.x = width - 1 - cell.x
    if rule == 2 and odd:
        cell.y = posmod(cell.y + data.size() / 2, data.size())
    return cell

func value_at(i: int, address: Vector2i) -> int:
    var cell := source_address(i, address)
    return recipes[i]["source"][cell.y][cell.x]

func repaint(i: int) -> void:
    for address: Vector2i in receivers[i].cells:
        receivers[i].write(address, palette.colours[value_at(i, address)])

func next_target() -> void:
    target = (target + 1) % receivers.size()

func cycle_rule() -> void:
    recipes[target]["rule"] = (recipes[target]["rule"] + 1) % RULE_NAMES.size()
    repaint(target)

func dress_all() -> void:
    for i in receivers.size():
        if i != target:
            recipes[i] = recipes[target].duplicate(true)
            repaint(i)

func selected_address() -> Vector2i:
    var grid: Node3D = receivers[target]
    var local: Vector3 = grid.to_local(control.global_position)
    var cell := Vector2i(floori((local.x + 0.16) / 0.32), floori((local.z + 0.16) / 0.32))
    if local.y < 0.12 or local.y > 0.65 or not grid.cells.has(cell):
        return Vector2i(-1, -1)
    return cell

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
        "TARGET": next_target()
        "RULE": cycle_rule()
        "ALL": dress_all()
        _:
            var address := selected_address()
            if address != Vector2i(-1, -1):
                var cell := source_address(target, address)
                var data: Array = recipes[target]["source"]
                data[cell.y][cell.x] = (data[cell.y][cell.x] + 1) % palette.colours.size()
                repaint(target)

func _process(_delta: float) -> void:
    var address := selected_address()
    for i in receivers.size():
        receivers[i].marker.visible = i == target and address != Vector2i(-1, -1)
    var selection := operation()
    if address != Vector2i(-1, -1):
        receivers[target].mark(address)
        var cell := source_address(target, address)
        selection = "surface [%d,%d] -> source [%d,%d]" % [address.y, address.x, cell.y, cell.x]
    label.text = "%s / %s\n%s\nGRIP: inspect / TRIGGER: paint or use named action" % ["TABLE" if target == 0 else "WALL", RULE_NAMES[recipes[target]["rule"]], selection]
```

## What is being copied?

`recipes[i]` is a dictionary: a record with the named entries `source` and `rule`. The source is still a list of rows. The rule is still a number. `target` selects one record and its corresponding receiver. Nothing about choosing another index requires rebuilding the cubes.

`duplicate(true)` copies the dictionary and its nested rows. Assigning `recipes[i] = recipes[target]` would make both entries refer to the same dictionary. A shallow `duplicate()` would separate the dictionaries but leave their source rows shared. Either could let a later paint edit reach a surface we meant to keep independent.

The local `data` in `choose()` deliberately refers to the selected recipe's rows: painting must reach that record. We copy when independence is needed, and refer to the existing record when editing it. The initial `source` remains a template; the two working copies change separately.

The installed temple stores scalar recipe values rather than our nested rows. Its ordinary dictionary copy is sufficient for those values; each material then renders from its copied settings. Our deeper copy answers the different shape of our data. Neither version copies the architectural geometry.

## Predict the next action

Both receivers begin with the familiar source and PG. Addresses here are `[row, column]`.

1. Keep TABLE selected. Hover at surface `[0,3]`. PG reads source `[1,2]`, value 1: pink. Trigger once: that source entry becomes 2, mint. Its copies change on the table; the wall stays pink at the corresponding address.
2. Use ALL. Both receivers now read mint there. The wall stays upright and the table stays horizontal.
3. Use TARGET to select WALL. Paint its surface `[0,3]`. Its value cycles from 2 to 0: navy. The table remains mint. Equal recipes have become different again.
4. Use RULE once. The wall goes from PG to P1; surface `[0,3]` now reads source `[0,0]`. Its source record is unchanged by the rule change. The table still uses PG.

Each paint action repaints all occurrences on the selected receiver, not just the cube touched. ALL repaints the other receiver after copying. TARGET only changes which receiver will receive the next edit.

## Make another case

Replace the template with `[[0, 1, 2, 0], [2, 0, 1, 2]]`. Keep two rows and all the other code. Predict before running: PG at surface `[0,4]` reads source `[1,3]`, value 2. Paint it and it cycles to 0. The other receiver retains 2 until ALL is used. After copying, change the wall's same entry once more: it becomes 1 while the table stays 0.

The source is now four columns wide. Its PG horizontal translation period is eight cells, beyond this small five-column display. Use `source_address()` to compare addresses farther apart, as in Symmetry. The ownership question can be tested on one visible occurrence without displaying the whole period.

Try copying in the opposite direction as well. Can you make the table agree with the wall, then change the table without changing the wall? Explain which record each action reaches before using it.

## Return to the temple

Compare floor, wall and dome with the same recipe. Their shapes, orientations and mappings remain different. Our two flat receivers isolate selection and ownership; they do not reconstruct the temple's curved mappings or seventeen shader groups.

AGE changes weathering parameters in the selected material. CLEAN sets that appearance back to age zero on every group; it does not restore the original sources and palettes. This is a generated surface treatment, not elapsed time or a record of earlier visitors.

Before leaving, choose your own arrangement of agreement and difference. Make the two receivers agree, change one, then explain why the other stays as it was. In the installed court, choose a reason to keep one wall different. The next hall takes a branch into layers: it uses the source to fill a volume, rather than requiring this room to become a larger surface catalogue.

## Complete carried files

These are unchanged from Symmetry. The new entry uses their existing geometry, palette and pickable point; it does not rebuild the point's behaviour here.

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



---

<!-- hall: Ribbon_Patterns_01 -->

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



---

<!-- hall: Ribbon_Patterns_02 -->

# Ribbon Patterns 02 — keep the value

## Learning elements

- A fixed value under changing viewing conditions.
- Surface distance versus projected appearance.
- Prediction and observation kept distinct.

An investigation between builds. Use the installed comparisons, predict what stays fixed and record what you see. The complete reconstruction remains below as an optional return to shared materials; building another selector is not required before the fabric lesson.

## Look before changing

At the installed **SimultaneousContrast** display, compare the two grey targets. Press SWAP, then SURROUNDS, then CONNECT. Return with UNDO or RESET. These controls leave both target colours at RGB (0.5, 0.5, 0.5). A test can establish that equality. Your visual comparison is a separate observation; it need not match another visitor's.

The previous hall separated stored values from visible layers. Here, a visible value meets its surroundings. Keep our point, palette and two-row, three-column source. In the optional reconstruction, use the familiar five-by-five grid as a selector. A trigger above a cell reads its source value and gives the corresponding colour to **both targets together**. It does not paint the source. We begin with navy, as before; the installed study begins with grey.

## Carry the method to the curved display

At the installed **MetamerismLab** station, find the blue corner of the same bent mark on the plane and half-cylinder. The name is a registry label; this placement does not demonstrate spectral metamerism. Its code supplies one RGB texture and a small directional shading model.

Both carriers measure four metres horizontally **along their surfaces**. Four repeats therefore occupy one metre each. REPEAT SIZE changes to eight repeats: fifty centimetres each. The two vertical repeats stay one metre high. GRID marks repeat boundaries, not individual source pixels. The half-cylinder has open ends; it is not a seam test.

Walk sideways. Equal surface distances do not guarantee equal widths in the image reaching you. Then try FLAT / SHADED and LIGHT SIDE. The surface directions differ along the curve; the plane keeps one direction. LIGHT SIDE changes a direction used inside the supplied shader, not the museum's sun. Keep the source and geometry fixed while comparing these settings.

We are using those controls to investigate, not rebuilding the curve or introducing dot-product code here. Record one prediction and observation about spacing, then one about shading. Those are different operations, even when both change the appearance. The next hall, Ribbon Patterns 03, follows the sampled value into the shader and fabric studio.

## Optional reconstruction — one material, two targets

Replace the previous entry with **08_equal_targets.gd** on the same learner Node3D in the museum, at unit scale. The three unchanged helper files follow below. The museum supplies the player, camera, lights and XR Tools. We set the layered construction aside for this comparison; saved source edits are not imported automatically.

The two targets and their connector use one `StandardMaterial3D`. This is intentional sharing: changing its colour should change all three. Each surround has its own material, so one can remain dark while the other becomes light. Both kinds are unshaded; this exercise removes lighting-dependent shading from the comparison, not the display's colour processing or the viewer.

Grip the black point. Trigger above SWAP to exchange the surrounds, above EQUAL to match them to the target, or above CONNECT to join the targets. Each action toggles back. Unlike the installed console, this small version has no UNDO history. Trigger over the grid to select another colour. Hovering alone changes nothing.

### 08_equal_targets.gd

<!-- student-code:08_equal_targets.gd -->
```gdscript
extends Node3D

const Palette = preload("palette.gd")
const GridSurface = preload("grid_surface.gd")
const PointBody = preload("point_body.gd")
const ACTIONS := ["SWAP", "EQUAL", "CONNECT"]
var source := [[0, 1, 0], [0, 0, 1]] # [z][x]
var palette = Palette.new([Color("172051"), Color("fc62ad"), Color("55f3cf")])
var selected := Vector2i(0, 0)
var swapped := false
var equal := false
var connected := false
var reference: Node3D
var control: PointBody
var targets: Array[MeshInstance3D] = []
var surrounds: Array[MeshInstance3D] = []
var bridge: MeshInstance3D
var target_material := StandardMaterial3D.new()
var label := Label3D.new()

func _ready() -> void:
    reference = GridSurface.new()
    add_child(reference)
    reference.position = Vector3(-0.64, 0.7, 1.0)
    reference.readout.hide()
    for cell: Vector2i in reference.cells:
        reference.write(cell, palette.colours[value_at(cell)])
    target_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    for x in [-0.95, 0.95]:
        surrounds.append(box(Vector3(x, 1.75, 0), Vector3(1.8, 1.2, 0.06)))
        var target := box(Vector3(x, 1.75, 0.08), Vector3(0.38, 0.38, 0.06))
        target.material_override = target_material
        targets.append(target)
    bridge = box(Vector3(0, 1.75, 0.09), Vector3(1.9, 0.07, 0.04))
    bridge.material_override = target_material
    control = PointBody.new()
    control.position = Vector3(0, 1.15, 2.8)
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
        card.position = Vector3((i - 1) * 0.6, 0.9, 2.8)
        card.font_size = 28
        card.pixel_size = 0.002
        add_child(card)
    refresh()

func value_at(cell: Vector2i) -> int:
    return source[posmod(cell.y, source.size())][posmod(cell.x, source[0].size())]

func refresh() -> void:
    target_material.albedo_color = palette.colours[value_at(selected)]
    for i in 2:
        var dark := (i == 0) != swapped
        surrounds[i].material_override.albedo_color = target_material.albedo_color if equal else (Color(0.1, 0.1, 0.1) if dark else Color(0.9, 0.9, 0.9))
    bridge.visible = connected
    reference.mark(selected)

func operation() -> String:
    var local := to_local(control.global_position)
    if local.y < 0.95 or local.y > 1.5 or absf(local.z - 2.8) > 0.25:
        return ""
    for i in ACTIONS.size():
        if absf(local.x - (i - 1) * 0.6) <= 0.2:
            return ACTIONS[i]
    return ""

func hovered_cell() -> Vector2i:
    var local: Vector3 = reference.to_local(control.global_position)
    var cell := Vector2i(floori((local.x + 0.16) / 0.32), floori((local.z + 0.16) / 0.32))
    if local.y < 0.12 or local.y > 0.35 or not reference.cells.has(cell):
        return Vector2i(-1, -1)
    return cell

func choose(_held: Variant) -> void:
    match operation():
        "SWAP": swapped = not swapped
        "EQUAL": equal = not equal
        "CONNECT": connected = not connected
        _:
            var cell := hovered_cell()
            if cell != Vector2i(-1, -1): selected = cell
    refresh()

func _process(_delta: float) -> void:
    var address := Vector2i(posmod(selected.x, source[0].size()), posmod(selected.y, source.size()))
    label.text = "SOURCE [%d][%d] = %d / BOTH TARGETS #%s\n%s / %s\nGRIP: move / TRIGGER: select cell or act at label" % [address.y, address.x, value_at(selected), target_material.albedo_color.to_html(false), "EQUAL SURROUNDS" if equal else "DARK + LIGHT", operation()]

func box(at: Vector3, size: Vector3) -> MeshInstance3D:
    var view := MeshInstance3D.new()
    var shape := BoxMesh.new()
    shape.size = size
    view.mesh = shape
    view.position = at
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    view.material_override = material
    add_child(view)
    return view
```

## Follow what stays

`value_at()` is the wrapped lookup we already know. The selector has twenty-five cubes, but the source still has six entries. Grid column 4, row 3 reads source `[1][1]`, value 0. Column 2, row 1 reads source `[1][2]`, value 1. The readout names the **source** address, in `[z][x]` order.

`refresh()` first gives the selected colour to the shared target material. It then sets two independently owned surround materials. SWAP changes which surround is dark; EQUAL makes both match the target. CONNECT changes the bridge's visibility. None of those actions edits a source entry, moves a target or changes its size.

This revisits Temple's ownership question. We copied recipes there when later changes needed to stay local. Here, one material is deliberately shared because equality is the condition we want to preserve. Sharing and copying answer different purposes.

## Predict, then compare

Select column 1, row 0. Both targets become pink. Before pressing SWAP, predict what should happen to each material. The left surround changes from 0.1 grey to 0.9 grey; the right makes the reverse change. Both targets remain pink.

Turn EQUAL on. Both surrounds now use that same pink. The faces may become difficult to distinguish; edges can still disclose the raised targets. Turn CONNECT on, then EQUAL off. The bar shares the targets' colour in either arrangement. Decide what the connector helps you compare. The program cannot decide that for you.

Keep this record in words: **changed condition / values held fixed / what I observed**. Do not replace the last part with what you think you were supposed to see.

## Make another comparison

Make two small edits in the entry file: change the first palette colour from `Color("172051")` to `Color(0.5, 0.5, 0.5)`, and change the source to `[[0, 1, 0], [0, 0, 2]]`. The source still has six entries; the last one now selects the existing mint colour.

Predict before running:

- The first selection gives grey to both targets and the hidden connector. The reference grid's zero-valued cells are grey too.
- Selecting column 2, row 1 gives mint to both targets and the connector; the source remains unchanged by the selection.
- EQUAL makes both surrounds mint. SWAP while EQUAL is on leaves them equal; turning EQUAL off reveals the exchanged dark/light order.
- All twenty-five selector cubes and both target meshes keep their positions.

That is a new comparison made with the same object and controls. It tests whether you can choose the condition being held fixed, not whether you can reproduce a prescribed illusion.

## Complete carried files

These are unchanged from Ribbon Patterns 01. The grid and pickable point retain their construction; the entry changes what their controls do.

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



---

<!-- hall: Ribbon_Patterns_03 -->

# Ribbon Patterns 03 — a source reaches a skirt

## Learning elements

- UV repeat and offset in a fragment shader.
- Texture sampling onto differently mapped surfaces.
- A saved recipe versus its shader interpreter.

The address calculation returns in a new place: the fragment shader. Keep the studio as the supplied host. A garment and procession make the result available to wear and compare; saved settings and the program interpreting them remain separate.

## Begin at the studio

Find the source editor beside the wall and preview dress. Choose a paint colour and touch one source cell. The mark changes on both receivers. UNDO restores it. Try OFFSET, then REPEAT. The first shifts the reading; the second changes how many copies fit.

Earlier we changed how the source was read by cubes. Here the reading happens for each drawn fragment of a surface. The studio supplies a four-by-four source and its cream, red, blue and gold palette. This is its existing bent mark, not an automatic import of our earlier two-by-three source. We carry the address operation into this larger supplied example.

Keep the wall, dress, source editor and pointer controls. They already exist inside the museum. Our task is one small shader. Cut-outs, finishes and vertex movement remain experiments in the full studio; they are not requirements for this first shader.

## Your part in this lesson

- **Write and change:** the small shader below. Follow a surface address through repeat, offset and texture sampling; then change the vertical repeat from two to three.
- **Use as supplied:** the studio, mesh UV layouts, material adapter, save system and wardrobe. Their connections are declared below; building them is not this lesson's task.
- **Check your understanding:** predict a sampled colour and the spacing on the wall before running. Explain why saving the source does not transfer your changed shader to the worn skirt.

## The supplied host

Work in your lesson copy of the museum. Open `commons/artifacts/fabric_shader_studio/fabric_shader_studio.tscn`. Its root, **FabricShaderStudio**, already has the script that creates the wall, preview, sixteen source buttons and controls. Add a plain Node child named **Lesson** and attach **09_studio_lesson.gd** below. Keep **09_fabric_sample.gdshader** beside that script. Run the same museum hall. Remove the Lesson child and reload to return to the full studio.

For reconstruction, **09_studio_lesson.tscn** below contains that complete root-and-child arrangement. Our test uses it in place of the one studio instance inside an isolated copy of the actual hall. The museum still supplies the player, camera, wardrobe and runway. No replacement world or player is constructed.

The existing `fabric_recipe.gd` converts sixteen palette indices into a four-by-four texture. Its `material()` function assigns that texture to `motif`, the chosen repeat count to `repeats`, and the offset to `phase`. The studio's `refresh()` gives materials made from that recipe to the wall and the preview's named **Skirt** mesh. These are supplied services. They do not hide any part of our address calculation.

### 09_fabric_sample.gdshader

<!-- student-code:09_fabric_sample.gdshader -->
```glsl
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D motif : source_color, filter_nearest, repeat_enable;
uniform float repeats = 4.0;
uniform float phase = 0.0;

void fragment() {
    vec2 address = UV * vec2(repeats, 2.0) + vec2(phase, 0.0);
    ALBEDO = texture(motif, address).rgb;
}
```

`UV` is a two-component address supplied by the mesh, conventionally spanning zero to one across a mapped region. `UV.x` and `UV.y` are surface coordinates, not world x and y. The wall and skirt each provide their own layout.

`vec2(repeats, 2.0)` multiplies the horizontal address by the chosen count and the vertical address by two. Adding `vec2(phase, 0.0)` offsets only the horizontal reading. `repeat_enable` wraps the texture address; `filter_nearest` selects source texels without blending neighbours. `source_color` identifies the sampled texture as colour data. The returned RGB goes to `ALBEDO`.

This reduced shader is unshaded so we can follow the sampling without the full studio's lighting response. It has no cut-out or displacement. The sampler still runs for many fragments; the source remains sixteen texels. A texel, a fragment and a mesh vertex are different things.

### 09_studio_lesson.gd

The small supplied adapter below replaces the shader on the two preview materials. It waits for the parent studio to create them. Every edit makes fresh materials, so it also reconnects our shader after an edit. The named `Skirt` is the actual receiver in the existing preview, not an unexplained scene dependency. Other parts of the outfit keep their materials.

<!-- student-code:09_studio_lesson.gd -->
```gdscript
extends Node

const SAMPLE = preload("09_fabric_sample.gdshader")

func _process(_delta: float) -> void:
    var studio = get_parent() # The supplied FabricShaderStudio root.
    if not is_instance_valid(studio.wall) or not is_instance_valid(studio.preview):
        return
    var skirt: MeshInstance3D = studio.preview.outfit.get_node("Skirt")
    for surface in [studio.wall, skirt]:
        var material: ShaderMaterial = surface.material_override
        if material.shader != SAMPLE:
            material.shader = SAMPLE
    studio.code.text = "STUDY: UV -> repeat + offset -> sample\nUse PAINT / OFFSET / REPEAT\nFull shader features wait in the original studio"
```

### 09_studio_lesson.tscn

This is the supplied studio root with the Lesson child added. Keep the three lesson files together if using this ready-made scene. The existing studio script path is the explicit dependency on the museum project.

<!-- student-code:09_studio_lesson.tscn -->
```ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://commons/artifacts/fabric_shader_studio/fabric_shader_studio.gd" id="1"]
[ext_resource type="Script" path="09_studio_lesson.gd" id="2"]

[node name="FabricShaderStudio" type="Node3D"]
script = ExtResource("1")

[node name="Lesson" type="Node" parent="."]
script = ExtResource("2")
```

During the reduced study, use the paint cells, OFFSET, REPEAT and UNDO. UV / FABRIC, CUT OUT, FINISH and VERTICES belong to the full shader and will not alter this reduced preview. Return to the original studio to investigate them. SAVE and WEAR still use the existing recipe system; they do not install our new shader on the wearer.

## Read one address

Before painting, consider `UV = (0.15, 0.20)` on the initial mark. At four horizontal repeats and phase zero, the texture address is `(0.60, 0.40)`. In the four-by-four source this reads column 2, row 1: value 0, cream.

Press OFFSET. Its phase is 0.125, so the address becomes `(0.725, 0.40)`. This still reads column 2, row 1. Not every offset changes every sampled colour. At `UV = (0.22, 0.20)`, however, the horizontal address goes from 0.88 to 1.005. Wrapping gives 0.005: column 0 instead of column 3. On row 1 that changes cream to red.

Press OFFSET again to return to zero, then REPEAT. Eight repeats give `(1.20, 0.40)` at the first UV; wrapping reads column 0, row 1, red. Repeat and offset can both change a sample, but they do different work.

An offset of 0.125 is one eighth of the texture's width, not one eighth of the wall. At four repeats it moves the pattern by one thirty-second of the wall's UV width. At eight repeats the same phase moves it by one sixty-fourth. Positive phase moves the visible motif towards decreasing U because each fixed surface position reads farther into the source.

## Count along a surface

The wall is three metres wide. Four horizontal copies span 0.75 metres each; eight span 0.375 metres. On its two-metre height, two copies span one metre each. These distances apply to this wall's mapping.

The skirt receives the same repeat counts on its own UV domain. Its circumference, height and cap mapping differ. Equal UV counts do not promise equal physical spacing. The last hall let us compare equal surface widths; here we deliberately meet different ones.

## Make a change the saved recipe cannot contain

Change only the vertical multiplier from `2.0` to `3.0` in the shader. Predict: the wall now has three copies over two metres, each two thirds of a metre high. Its horizontal count and phase controls should work as before. Neither the source texture nor the mesh changes.

At `UV = (0.15, 0.20)`, four repeats and phase zero now read texture address `(0.60, 0.60)`: source column 2, row 2, value 3, gold. Check a region away from a texel boundary. The full program is printed; this is your independent edit of its operation.

Now SAVE and WEAR SAVED. The preview can show your three vertical repeats, but the worn skirt is built by the original wardrobe shader, whose vertical count is still two. SAVE stores the supported recipe: source cells, horizontal repeats 4 or 8, offset 0 or 0.125, and the existing display flags. It does **not** store our shader text, its vertical multiplier, the palette, meshes or the current LOOK choice.

This difference is useful evidence. Saving data does not save every program capable of interpreting it. To make vertical count travel, the recipe schema, validation and receiving shader would all need to accept it. That extension is a later decision, not an invisible service this tutorial assumes.

## What travels

Restore the vertical multiplier and return to the original studio. Save a source, choose a preview silhouette with LOOK, then WEAR SAVED. The current preview look is chosen separately when wearing; it was not stored by SAVE. The saved fabric goes to the named Skirt. The bodice, crown and sleeves retain the look's materials.

Edit the preview after saving. The worn skirt keeps the saved version. RUNWAY SAVED gives that version to four performer skirts. UNDO can restore a prior application, but does not rewind the saved file. Use the mirror and procession as comparisons of the same record on different bodies.

Across Tiling we have reused classes and reading operations, with declared sources for each study. We have not automatically saved one edited motif through every hall. The volume was a branch; the garment returns to surface sampling. Keep those distinctions when the picture changes. In Change Intro, we return to comparing readings at different positions, this time to ask how much a value changes between them.
