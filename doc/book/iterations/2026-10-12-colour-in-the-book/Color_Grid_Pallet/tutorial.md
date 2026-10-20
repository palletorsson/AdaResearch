# Grid — a colour left at an address

**Learning elements**

- An address selecting stored instance colour
- A small class holding a palette and its current index
- Independent instances of the same class
- A local edit beside a rule over the whole grid

In the museum's grid, select a place and leave a colour there. Move to another place. The first choice remains. An address keeps the colour after your attention has moved on.

Arrays gave us indexed parts. Nails and Pillar returned a colour from a position. Now one of those returned colours becomes stored data. The new class keeps an ordered palette and remembers which entry comes next.

## Make two palettes

Save the four files printed here together. Attach `lesson.gd` to a Node3D on a clear display surface in your working copy of the Grid hall. The museum supplies your view and movement. This compact 5 by 5 model reconstructs the addressed colour operation; the installed floor and its interaction console remain in place.

`GridSurface` supplies 25 visible tiles and a dictionary connecting each `Vector2i(x, z)` address to a MultiMesh instance. Its `read`, `write` and `mark` methods are printed below. The second component of a Vector2i is called `y` in code; here we use it for the floor's Z address.

## The complete continuation — lesson.gd

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

const Palette = preload("palette.gd")
const GridSurface = preload("grid_surface.gd")
const Controls = preload("controls.gd")

var selected := Vector2i(2, 2)
var palette_index := 0
var palettes: Array = []
var grid: Node3D

func _ready() -> void:
    var sample := Color(0.1875, 0.5, 0.359375)
    palettes = [
        Palette.new([sample, Color.WHITE, Color.BLACK]),
        Palette.new([Color(0.8, 0.2, 0.6), Color(1, 0.8, 0.15)])
    ]
    grid = GridSurface.new()
    add_child(grid)
    add_child(Controls.new())
    apply_rule()
    select_address(selected)

func select_address(address: Vector2i) -> void:
    if not grid.cells.has(address):
        return
    selected = address
    grid.mark(selected)

func paint_selected() -> void:
    var palette = palettes[palette_index]
    grid.write(selected, palette.current_colour())
    palette.next_colour()
    grid.mark(selected)

func next_palette() -> void:
    palette_index = (palette_index + 1) % palettes.size()

func apply_rule() -> void:
    var colours: Array[Color] = palettes[palette_index].colours
    for address: Vector2i in grid.cells:
        var i := (address.x + address.y) % colours.size()
        grid.write(address, colours[i])
    grid.mark(selected)
```

## The state we keep — palette.gd

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

`Palette.new(choices)` creates an instance. Its `_init` copies the chosen list with `assign`, so changing the caller's list later will not quietly change this palette. Colour values are copied; this is not a general deep-copy rule for objects.

`current_colour` returns the entry at `index`. `next_colour` advances the index, wraps it with `%`, and returns the new current entry. `paint_selected` first writes the current colour, then advances. The next press therefore uses the next entry. An empty palette violates the constructor's assertion.

We already used a PointBody class. This class has no mesh or position: its useful behaviour is remembering an ordered choice. The two instances have separate lists and indices. Advancing the first cannot advance the second.

The first palette includes the RGB sample recorded in Pillar. The second includes our earlier Nails choice. Those are explicit recorded values, not an automatic connection to either previous hall.

## Leave one mark

Run. Aim the prepared museum pointer at **X+** or **Z+** and activate it to advance the selected address along that axis, wrapping after four. Activate **COLOUR** to write the active palette's current colour there. Move the selection: the colour remains at the old address. Activate **PALETTE** to select the other palette; this alone changes no tile. Activate **COLOUR** again to use it.

Selection and painting are separate functions. `select_address` first checks that the address exists, then moves the marker. `paint_selected` changes the stored instance colour. Neither operation changes tile positions.

Activate **RULE**. `apply_rule` visits every address and chooses `(x + z) % colours.size()` from the active palette. The sum advances along either axis, producing diagonal repetition. This replaces individual edits in the study's 25 tiles. A local memory can be overwritten by a later rule.

## Check what remains independent

Paint twice with the first palette. Switch to the second and paint once. Switch back: the first should continue at its third entry. Selecting another tile should neither consume an entry nor recolour it.

Try a one-entry first palette: replace its choices with `[sample]`. Every index wraps to zero. Then try four entries, `[sample, Color.WHITE, Color.BLACK, Color(0.8, 0.2, 0.6)]`. Predict how the diagonals change when you activate RULE. The address dictionary and tile geometry stay unchanged.

For your own continuation, choose a new palette and make a small arrangement by painting selected addresses. Record one address and its colour. Predict which entry the rule will put there, then activate RULE and compare. Explain the difference between the address, the instance index and the palette index.

## Supplied display — grid_surface.gd

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

`use_colors` is enabled before the instance count is assigned. The shared mesh material reads each instance's colour through `vertex_color_use_as_albedo`. The tiles share a material; they do not require 25 separate materials. The dictionary declares the address-to-index connection rather than assuming that every museum floor uses the same ordering.

## Supplied museum controls — controls.gd

<!-- student-code:controls.gd -->
```gdscript
# Supplied museum pointer targets and Day Zero preview keys.
extends Node3D

class Target extends StaticBody3D:
    var action: Callable
    func pointer_event(event) -> void:
        # XRToolsPointerEvent.PRESSED; release and movement do not activate.
        if event.event_type == 2:
            action.call()

var buttons: Array[StaticBody3D] = []

func add_target(title: String, at: Vector3, width: float, action: Callable) -> void:
    var target := Target.new()
    target.position = at
    target.collision_layer = 1
    target.collision_mask = 0
    target.action = action
    add_child(target)
    buttons.append(target)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(width, 0.12, 0.05)
    mesh.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.08, 0.08, 0.08)
    mesh.material_override = material
    target.add_child(mesh)
    var boundary := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = box.size
    boundary.shape = shape
    target.add_child(boundary)
    var label := Label3D.new()
    label.text = title
    label.font_size = 24
    label.pixel_size = 0.0015
    label.position.z = 0.03
    target.add_child(label)

func _ready() -> void:
    var titles := ["X+", "Z+", "COLOUR", "PALETTE", "RULE"]
    for i in titles.size():
        add_target(titles[i], Vector3(i * 0.32, 0.16, 1.8), 0.29, activate.bind(i))

func activate(command: int) -> void:
    var study := get_parent()
    match command:
        0: study.select_address(Vector2i((study.selected.x + 1) % 5, study.selected.y))
        1: study.select_address(Vector2i(study.selected.x, (study.selected.y + 1) % 5))
        2: study.paint_selected()
        3: study.next_palette()
        4: study.apply_rule()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        var command := [KEY_X, KEY_Z, KEY_C, KEY_P, KEY_R].find(event.keycode)
        if command >= 0:
            activate(command)
```

The labelled targets receive pressed events from the prepared museum pointer and call the named operations above. Their construction is supplied support, printed in full. The keyboard adapter remains available for the Day Zero preview. The small display is separate from the installed floor; it has no walking-floor collider.

Keep `Palette`. Walls will give two surfaces their own instances. Paint first changes the scale of the stored mark: from one tile to a region of a surface.
