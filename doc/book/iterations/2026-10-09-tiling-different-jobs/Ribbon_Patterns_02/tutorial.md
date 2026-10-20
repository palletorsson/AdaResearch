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

