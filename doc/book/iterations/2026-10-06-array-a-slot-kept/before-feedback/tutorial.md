# Array — a slot kept

**Learning elements**

- Independent cube instances
- Arrays of values and arrays of references
- Reading and changing an address
- Nested loops: a row becomes a plane
- Collection without shifting the remaining entries

In Transformation, walking into a cube made it disappear. Here there are four. Collect the one marked 2. The next cube keeps its place. What must the program keep when one body goes?

We continue with the same `BoxMesh` construction and overlap detection from Trans_Pre. For now the cubes stay still. The new work is giving each copy an address and keeping a record of its presence.

## Begin with a row

Work in the existing Endless Museum Array hall. Keep the museum's room, light and player. Attach `lesson.gd` to an empty `Node3D` named `ArrayStudy` on clear floor beside the exhibits. Keep its scale at `(1, 1, 1)`. Its local X axis runs along our row; local Y is up. Face the labels from the positive-Z side. The script creates the cubes, sensors, labels and readout; it needs no child nodes or other lesson scripts.

Allow about six metres along X for the row. The plane version will need the same space along Z. The study's origin is below the centre of the first cube. Each cube is one metre wide, with its centre 0.8 metres above the floor. These floating cubes detect arrival; they are not solid platforms.

Read the complete script once. Leave `depth` at `1` for the first comparison. We use the same two-index structure throughout so opening the row into a plane needs one edit. At first, every Z index is zero.

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

var width := 4
var depth := 1
var spacing := 1.6
var grid_data: Array = []
var cubes: Array = []
var readout: Label3D

func _ready() -> void:
    assert(width >= 0 and depth >= 0 and spacing > 1.0)
    readout = Label3D.new()
    readout.position = Vector3((width - 1) * spacing * 0.5, 2.4, -1.2)
    readout.font_size = 32
    add_child(readout)

    for x in width:
        grid_data.append([])
        cubes.append([])
        for z in depth:
            grid_data[x].append(1)
            cubes[x].append(make_cube(x, z))

            var label := Label3D.new()
            label.text = "[%d, %d]" % [x, z]
            label.position = Vector3(x * spacing, 1.5, z * spacing)
            add_child(label)
    refresh_readout()

func make_cube(x: int, z: int) -> MeshInstance3D:
    var cube := MeshInstance3D.new()
    cube.mesh = BoxMesh.new()
    cube.position = Vector3(x * spacing, 0.8, z * spacing)
    add_child(cube)

    var sensor := Area3D.new()
    sensor.collision_layer = 0
    sensor.collision_mask = 1
    sensor.set_collision_mask_value(20, true)
    cube.add_child(sensor)
    var hitbox := CollisionShape3D.new()
    hitbox.shape = BoxShape3D.new()
    sensor.add_child(hitbox)
    sensor.body_entered.connect(_on_body_entered.bind(x, z))
    return cube

func _on_body_entered(body: Node3D, x: int, z: int) -> void:
    if body.is_in_group("em_walker") or body.is_in_group("player_body"):
        collect(x, z)

func collect(x: int, z: int) -> void:
    if x < 0 or x >= grid_data.size():
        return
    if z < 0 or z >= grid_data[x].size():
        return
    if grid_data[x][z] == 0:
        return
    grid_data[x][z] = 0
    cubes[x][z].queue_free()
    cubes[x][z] = null
    refresh_readout()

func refresh_readout() -> void:
    readout.text = "grid_data[x][z]"
    for x in grid_data.size():
        readout.text += "\n" + str(grid_data[x])
```

## Four bodies, four places

`for x in width` visits 0, 1, 2 and 3. On each visit, `make_cube(x, z)` creates another mesh instance, gives it the familiar cube mesh and returns a reference to it. The assignment of its position uses a relation we already know: an index multiplied by spacing.

With `depth = 1`, the inner loop visits only `z = 0`. The four positions therefore lie along X: 0, 1.6, 3.2 and 4.8 metres. The cubes look alike, but each has its own transform and sensor. We are repeating a construction, not adding four names for one object.

The two arrays keep different things. `grid_data[x][z]` holds a number: `1` means a cube is present, and `0` means it has been collected. `cubes[x][z]` holds a reference to that cube, or `null` after collection. A number describing presence cannot turn a mesh. A reference to a mesh does not explain what an empty place means.

The outer list selects X; the inner list selects Z. At the start, `grid_data` reads `[[1], [1], [1], [1]]`. Four X entries, each containing one Z entry. `grid_data[2][0]` selects the third cube's value. In the installed row, the display wraps four values as `array_data[0][i]`; our reduced study starts with the X/Z convention used by the hall's square grid.

Trace used an array to keep a growing history of positions. This record begins with fixed slots. We can change what one slot contains without removing that slot.

## Collect one; keep its address

Walk into the cube labelled `[2, 0]`. Its number in the readout changes to zero. The cube disappears; its address label remains above the gap. The cube at `[3, 0]` has not moved.

The sensor is the one from Trans_Pre: an `Area3D` with a matching `BoxShape3D`, listening on the declared desktop and XR body layers. The museum supplies `em_walker` on layer 1 and `player_body` on layer 20. The group check keeps ordinary props from collecting cubes.

Each sensor connects the same function, but `.bind(x, z)` adds this cube's two indices to the call. The signal provides the entering `body`; the bound indices follow it. The callback can therefore say which slot to collect without searching for the closest cube.

`collect` first rejects an address outside the record, including negative indices. It also returns immediately if that slot is already zero. Two overlapping player bodies must not try to remove the same cube twice.

Three lines perform the change: write zero, queue this cube for removal, then replace its stored reference with `null`. `queue_free()` removes the node at the end of the frame. We leave both array lengths unchanged. We also leave the study itself alive; in Pre, removing the entire one-cube study was enough. Here it would take every cube with it.

The labels belong to `ArrayStudy`, not to the cubes, so collection keeps them. The readout traverses the retained values again. This is why you can still locate and read an empty address. We do not use `remove_at`: removing a list entry would shift the later indices.

## Open the row into a plane

Change `depth` from `1` to `4` and run the study again. The same code now places sixteen cubes. For each X index, the inner loop visits four Z indices. The readout has four lines, each containing four values. Its lines represent X, and the entries across a line represent Z.

Find `[1, 2]`. It is 1.6 metres along local X and 3.2 metres along local Z. Compare it with `[2, 1]` before collecting either. Exchanging the numbers changes the place. Collect `[1, 2]` and inspect the second readout line: its third entry is zero. The other fifteen entries remain one.

`append([])` creates a fresh inner array on each outer-loop visit. This matters: if every X entry referred to the same inner array, one change would appear in several places. The cube factory likewise creates a new node on every call. Similar appearance does not mean shared identity.

## Use a known transformation

Keep the four-by-four plane. Change `spacing` to `2.0` and run again. There are still sixteen slots. The distances between cubes have changed; their indices have not. Starting the study again constructs a fresh record, so earlier collections are reset.

Next, add `cubes[1][0].rotation_degrees.y = 45.0` in `_ready`, after both construction loops and just before `refresh_readout()`, with the same indentation as that call. Only this cube turns. Its child sensor turns with it; its occupancy stays one. We use the reference to address a body and a familiar transformation to change it. Its fixed label continues to name the site.

Taking another reference to that same cube would still give access to that one body. Making another body requires another construction. No special new cube class is needed for this lesson.

## Make a choice of your own

Return spacing to 1.6. Keep the plane and choose another address to turn. Predict its position before running. Then collect a different cube and check that only its occupancy changes. Explain which array let you turn a body and which array kept the record of its departure.

The installed hall also lets an agent change the floor beneath you, and lets nested frames depart from indexed sites. Those encounters take the relation further. This lesson gives us the smaller construction we can now extend upwards: a cube, an address, a stored value, and a rule connecting them.

Keep `lesson.gd` and its X/Z convention. In the next hall we will add height and make the connection between three displayed coordinates and nested storage explicit.
