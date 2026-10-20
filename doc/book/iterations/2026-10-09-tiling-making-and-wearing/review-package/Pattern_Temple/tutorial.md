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

