# Arrays — complete tutorials

12 October 2026.

---

<!-- hall:Array -->

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

Our program uses the first index for X and the second for Z. Nested arrays have no spatial axes of their own; this is the meaning we give those indices when placing and reading cubes. At the start, `grid_data` reads `[[1], [1], [1], [1]]`. Four X entries, each containing one Z entry. `grid_data[2][0]` selects the third cube's value. In the installed row, the display wraps four values as `array_data[0][i]`; our reduced study starts with the X/Z convention used by the hall's square grid.

Trace used an array to keep a growing history of positions. This record begins with fixed slots. We can change what one slot contains without removing that slot.

## Collect one; keep its address

Walk into the cube labelled `[2, 0]`. Its number in the readout changes to zero. The cube disappears; its address label remains above the gap. The cube at `[3, 0]` has not moved.

The sensor is the one from Trans_Pre: an `Area3D` with a matching `BoxShape3D`, listening for the museum player. The VR body belongs to `player_body` on layer 20; Day Zero supplies that connection. The same program also accepts Day Zero's preview body (`em_walker`, layer 1). The group check keeps ordinary props from collecting cubes.

Each sensor connects the same function, but `.bind(x, z)` adds this cube's two indices to the call. The signal provides the entering `body`; the bound indices follow it. The callback can therefore say which slot to collect without searching for the closest cube.

`collect` first rejects an address outside the record, including negative indices. It also returns immediately if that slot is already zero. Two overlapping player bodies must not try to remove the same cube twice.

Three lines perform the change: write zero, queue this cube for removal, then replace its stored reference with `null`. `queue_free()` removes the node at the end of the frame. We leave both array lengths unchanged. We also leave the study itself alive; in Pre, removing the entire one-cube study was enough. Here it would take every cube with it.

The labels belong to `ArrayStudy`, not to the cubes, so collection keeps them. The readout traverses the retained values again. This is why you can still locate and read an empty address. We do not use `remove_at`: removing a list entry would shift the later indices.

Our study keeps every address label visible to make stable indexing easy to follow. In the museum row, the label leaves with its cube; in the square grid, the floor plate stays. Both records retain their slots. The displays give us different ways to find those places again.

## Open the row into a plane

Change `depth` from `1` to `4` and run the study again. The same code now places sixteen cubes. For each X index, the inner loop visits four Z indices. The readout has four lines, each containing four values. Its lines represent X, and the entries across a line represent Z.

Find `[1, 2]`. It is 1.6 metres along local X and 3.2 metres along local Z. Compare it with `[2, 1]` before collecting either. Exchanging the numbers changes the place. Collect `[1, 2]` and inspect the second readout line: its third entry is zero. The other fifteen entries remain one.

`append([])` creates a fresh inner array on each outer-loop visit. Suppose X entries 0 and 1 instead referred to the same inner array. Writing zero to `grid_data[0][2]` would also make `grid_data[1][2]` read zero: both addresses would reach the same entry. Fresh inner arrays keep those changes separate. This is the distinction we met with cubes: making two objects differs from keeping two references to one object.

## Use a known transformation

Keep the four-by-four plane. Change `spacing` to `2.0` and run again. There are still sixteen slots. The distances between cubes have changed; their indices have not. Starting the study again constructs a fresh record, so earlier collections are reset.

Next, add `cubes[1][0].rotation_degrees.y = 45.0` in `_ready`, after both construction loops and just before `refresh_readout()`, with the same indentation as that call. Only this cube turns. Its child sensor turns with it; its occupancy stays one. We use the reference to address a body and a familiar transformation to change it. Its fixed label continues to name the site.

Taking another reference to that same cube would still give access to that one body. Making another body requires another construction. No special new cube class is needed for this lesson.

## Make a choice of your own

Return spacing to 1.6. Keep the plane and choose another address to turn. Predict its position before running. Then collect a different cube and check that only its occupancy changes. Explain which array let you turn a body and which array kept the record of its departure.

The installed hall also lets an agent change the floor beneath you, and lets nested frames depart from indexed sites. Those encounters take the relation further. This lesson gives us the smaller construction we can now extend upwards: a cube, an address, a stored value, and a rule connecting them.

Keep `lesson.gd` and its X/Z convention. In the next hall we will add height and make the connection between three displayed coordinates and nested storage explicit.


---

<!-- hall:Tutorial_3D -->

# Tutorial 3D — another index

**Learning elements**

- Layers of independently stored rows
- Displayed XYZ and stored YZX addresses
- Converting the earlier XZ plane
- Reading and collecting one cell without shifting its neighbours

Find `[1, 2, 0]` at the flight console. The selected cube is above you. Its address gives the program a way to find it; the flight enclosure gives your body a way to reach it. These are separate provisions.

Our construction continues with the cube and its contact sensor from Array. A third loop places copies at different heights. The important change is how we keep and read their addresses.

## Keep the plane; add layers

Save the previous lesson. Its four-by-four version stored values as `grid_data[x][z]`. After collecting `[1, 2]`, its second readout line was `[1, 1, 0, 1]`. Copy those four lines into `plane` below, surrounded by the outer brackets. The supplied value reproduces that result. You may instead copy your own four lines, keeping their order.

This is an explicit copy of the record. Leaving the hall does not automatically deliver a live array to another script. We keep the copied plane unchanged and use it to initialize the bottom layer of a new volume. The upper layers begin occupied.

| Displayed address | Previous plane | New volume |
| --- | --- | --- |
| `[1, 0, 2]` | `plane[1][2]` | `values[0][2][1]` |
| `[1, 2, 0]` | No height index yet | `values[2][0][1]` |

The display says X, Y, Z. Storage opens a layer Y, then a row Z, then an entry X. This is the convention used by this museum volume. The lists themselves do not name those directions.

Attach the complete script to a new empty `Node3D`, `VolumeStudy`, in your editable copy of the museum hall. Keep its origin at floor level and its scale at one. It needs about six metres along each axis. Use a clear area within the existing flight region to reach upper cells; flight is supplied by the museum, not by these arrays. Do not place the study through the installed cubes or enclosure. Face its labels from local positive Z. Its only external interaction dependency is the same declared museum player body as Array.

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

# Copy the four lines from the previous study's readout here.
var plane: Array = [[1, 1, 1, 1], [1, 1, 0, 1], [1, 1, 1, 1], [1, 1, 1, 1]]
var height := 4
var spacing := 1.6
var selected := Vector3i(1, 2, 0)
var values: Array = []
var cubes: Array = []
var readout: Label3D
var marker: MeshInstance3D

func _ready() -> void:
    assert(not plane.is_empty() and not plane[0].is_empty())
    assert(height > 0 and spacing > 1.2)
    var width := plane.size()
    var depth: int = plane[0].size()
    for column in plane:
        assert(column.size() == depth)
        for value in column:
            assert(value == 0 or value == 1)

    for y in height:
        values.append([])
        cubes.append([])
        for z in depth:
            values[y].append([])
            cubes[y].append([])
            for x in width:
                var value: int = plane[x][z] if y == 0 else 1
                values[y][z].append(value)
                cubes[y][z].append(make_cube(x, y, z) if value == 1 else null)
                var label := Label3D.new()
                label.text = "[%d, %d, %d]" % [x, y, z]
                label.position = place(x, y, z) + Vector3(0, 0.7, 0)
                label.font_size = 24
                add_child(label)

    marker = MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3.ONE * 1.2
    marker.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(1, 1, 1, 0.15)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    marker.material_override = material
    add_child(marker)
    readout = Label3D.new()
    readout.position = Vector3(2.4, 2.4, -1.2)
    readout.font_size = 30
    add_child(readout)
    assert(valid(selected.x, selected.y, selected.z))
    refresh_readout()

func place(x: int, y: int, z: int) -> Vector3:
    return Vector3(x * spacing, 0.8 + y * spacing, z * spacing)

func make_cube(x: int, y: int, z: int) -> MeshInstance3D:
    var cube := MeshInstance3D.new()
    cube.mesh = BoxMesh.new()
    cube.position = place(x, y, z)
    add_child(cube)
    var sensor := Area3D.new()
    sensor.collision_layer = 0
    sensor.collision_mask = 1
    sensor.set_collision_mask_value(20, true)
    cube.add_child(sensor)
    var hitbox := CollisionShape3D.new()
    hitbox.shape = BoxShape3D.new()
    sensor.add_child(hitbox)
    sensor.body_entered.connect(_on_body_entered.bind(x, y, z))
    return cube

func _on_body_entered(body: Node3D, x: int, y: int, z: int) -> void:
    if body.is_in_group("em_walker") or body.is_in_group("player_body"):
        collect(x, y, z)

func valid(x: int, y: int, z: int) -> bool:
    return y >= 0 and y < values.size() and z >= 0 and z < values[y].size() and x >= 0 and x < values[y][z].size()

func collect(x: int, y: int, z: int) -> void:
    if not valid(x, y, z):
        return
    if values[y][z][x] == 0:
        return
    values[y][z][x] = 0
    cubes[y][z][x].queue_free()
    cubes[y][z][x] = null
    refresh_readout()

func refresh_readout() -> void:
    marker.position = place(selected.x, selected.y, selected.z)
    readout.text = "[x,y,z] = [%d,%d,%d]\nvalues[y][z][x] = %d" % [selected.x, selected.y, selected.z, values[selected.y][selected.z][selected.x]]
```

## Read the loops from outside in

The Y loop appends an empty layer. Within that layer, the Z loop appends a fresh row. The X loop writes one value and, when it is one, makes a cube. Each enclosing list is constructed during its own loop visit. A change in one row therefore cannot silently change another row through a shared list.

At height zero, `plane[x][z]` supplies the value. Appending it inside the Y, Z, X loops gives it the new address `values[y][z][x]`. This copies integer values, not references to the plane's inner lists. The missing cube from the previous lesson stays missing in the bottom layer. Its address label is still built. Higher layers remain full.

`place` names the relation between an address and a local position. It multiplies three indices by spacing and lifts the cube centre 0.8 metres above its layer. The array index is still an integer; the position is measured in metres. The parent can place the complete study elsewhere in the museum without changing any address.

## Collect a named cell

The translucent box marks `selected`, initially `[1, 2, 0]`. Collection uses the same sensor and group check as before. The only change in `.bind` is the extra Y index. The signal sends a body; the bound X, Y, Z values identify this sensor's cell.

Approach the marker through the flight enclosure. The cube leaves, the marker and label remain, and the readout becomes zero. `values[2][0][1]` changed. `values[0][2][1]`, the gap copied from the plane, is a different address. Neither collection shifts a row or moves another cube.

The `valid` function checks the layer before reading its rows, then the row before reading its entries. `and` stops as soon as a condition is false. An invalid address is rejected before it can index a missing list. The next condition makes collecting an already empty slot harmless. These are the same responsibilities as Array, extended through another enclosing list.

## Choose another address

Change `selected` to another valid address with unequal numbers. Predict the corresponding `values[y][z][x]` entry and its position before running. Collect it and check that the adjacent cells remain. Then change spacing to `2.0`: the addresses and copied gap should stay the same while the volume spreads out. Each run constructs a fresh volume from `plane`; it does not remember collections made during an earlier run.

The open structures and suspended fragments elsewhere in this hall extend the question of what a site can hold. They remain available in the reflective text. For this lesson, carry one exact relation: an address selects a stored value, and a placement rule gives that address a location. In Floor, an address will choose a turn instead of an occupant.

<details>
<summary>Optional returns already in the museum</summary>

In **A rule takes up space**, change `(column + row) % 5` to `column` in `form_at()` in `commons/artifacts/spine_studies/open_rules.gd`. The supplied station handles the comparison. In **A place still held**, change the multiplier on `offset` in `commons/artifacts/reference_studies/suspension.gd`: the loops still place 75 fragments. These are source studies, not additional complete learner programs. [Open structures](/book-review/doc/book/iterations/2026-10-01-lewitt-reading-a-rule/index.html) · [Suspension](/book-review/doc/book/iterations/2026-10-01-hatoum-grid-under-load/index.html).

</details>


---

<!-- hall:Tutorial_Tiling_Floor -->

# Floor — an address chooses a turn

**Learning elements**

- A function from address to orientation
- Remainder and quarter-turns
- One exception versus a repeated rule
- A generated image saved for another surface

At the museum's four-by-four desk, hold the left sample still and apply the rule to the right. The unit has not changed. Different orientations let neighbouring tiles make a larger figure.

We return from the volume to a plane. Rotation is familiar from Transformation; nested traversal is familiar from Array. Here their relation changes: an address chooses how much to turn the same black-and-white tile. Zero means no added turn. It does not mean an empty place.

## Predict sixteen decisions

Our rule is `(column + row) % 4`. For non-negative indices, remainder by four gives 0, 1, 2, 3 and then returns to zero. Those numbers count quarter-turns. At `[1, 0]` the answer is one; at `[2, 0]` it is two; at `[3, 1]` it is zero.

Write the four answers for one row before running. Notice that the function needs this tile's address, not a picture of the completed field. Then compare plain repetition with the rule.

Save these two files together in your lesson folder. Attach `lesson.gd` to an empty, unit-scale `Node3D` named `FloorStudy` at floor level on clear floor in the existing hall. It creates two two-metre images, with a small gap between them. Allow five metres across. The existing museum floor supports your feet; the image surfaces add no collision. Keep the room, light and player from Day Zero.

The small renderer is printed in full so the rule has no hidden dependency. Begin by reading `turn_at`; the pixel loops below it translate those decisions into a picture. The renderer is support for this lesson, not a demand to learn every image API at once.

### pattern_image.gd

<!-- student-code:pattern_image.gd -->
```gdscript
extends RefCounted

var columns := 4
var rows := 4
var tile_pixels := 32
var use_rule := true
var exception := false
var exception_cell := Vector2i(1, 2)

func turn_at(column: int, row: int) -> int:
    var turns := (column + row) % 4 if use_rule else 0
    if exception and Vector2i(column, row) == exception_cell:
        turns += 1
    return turns % 4

func make() -> Image:
    assert(columns > 0 and rows > 0 and tile_pixels > 1)
    var image := Image.create(columns * tile_pixels, rows * tile_pixels, false, Image.FORMAT_RGB8)
    for row in rows:
        for column in columns:
            var turns := turn_at(column, row)
            for v in tile_pixels:
                for u in tile_pixels:
                    var source := Vector2i(u, v)
                    for quarter in turns:
                        source = Vector2i(source.y, tile_pixels - 1 - source.x)
                    var black := source.x > source.y
                    image.set_pixel(column * tile_pixels + u, row * tile_pixels + v, Color.BLACK if black else Color.WHITE)
    return image
```

### lesson.gd

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

const PatternImage = preload("pattern_image.gd")
var columns := 4
var rows := 4
var exception := false
var image: Image
var saved_path := "user://ada_array_pattern.png"

func _ready() -> void:
    var pattern := PatternImage.new()
    pattern.columns = columns
    pattern.rows = rows
    pattern.use_rule = false
    show_image(pattern.make(), Vector3(-1.3, 0.02, 0))
    pattern.use_rule = true
    pattern.exception = exception
    image = pattern.make()
    show_image(image, Vector3(1.3, 0.02, 0))
    var error := image.save_png(saved_path)
    assert(error == OK, "The pattern could not be saved.")
    var label := Label3D.new()
    label.text = "SAME TURN                       ADDRESS CHOOSES TURN"
    label.position = Vector3(0, 1.5, -1.5)
    label.font_size = 26
    add_child(label)

func show_image(picture: Image, at: Vector3) -> void:
    var surface := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(2, 2)
    surface.mesh = plane
    var material := StandardMaterial3D.new()
    material.albedo_texture = ImageTexture.create_from_image(picture)
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    surface.material_override = material
    surface.position = at
    add_child(surface)
```

## What is being turned?

`PatternImage.new()` creates a recipe object. Its `make` function returns an `Image`. The host first disables the address rule to draw plain repetition, then enables it to draw the comparison. The first image keeps its pixels when the recipe changes; each call constructs a new image.

Within one tile, U counts pixels across and V counts down. A pixel is black when U is greater than V; that divides the square along a diagonal. A quarter-turn changes which source pixel we read. Repeating that operation two or three times turns the same motif further. Finally, column and row locate the tile within the complete image.

These are image coordinates. Row does not mean world height. `PlaneMesh` places the picture flat in the study's local XZ plane. `ImageTexture` makes its pixels available to the material. The unshaded material and nearest filtering keep this small comparison legible without asking light to explain the rule. In [Godot's Image API](https://docs.godotengine.org/en/stable/classes/class_image.html), the stored image and the texture assigned to a material are separate resources.

## Change the rule, then one place

In `turn_at`, replace `(column + row) % 4` with `column % 4`. Predict which direction will still change from tile to tile. Run the study and compare both fields. Every row on the right now receives the same sequence of turns. Restore the original expression before the next comparison.

Set `exception` to `true` in `lesson.gd`. The right field receives one extra turn at `[1, 2]`; the left stays unchanged. The condition runs at every address but succeeds at only one. Increasing that cell's turn leaves the source motif and the other fifteen decisions intact.

Change `columns` and `rows` to `8`. The function has not become longer. It is asked at sixty-four addresses, and the first four-by-four corner still receives the same answers. Our display remains two metres wide, so the tiles become smaller. Pixel detail per tile, number of tiles and physical display size are separate choices.

## Keep this result

Each run saves the right image as `user://ada_array_pattern.png`, replacing the previous saved result at that name. `user://` is this Godot project's writable data folder. We check the save result rather than assume a file was written. The PNG contains the pixels; the editable rule remains in your script. A saved image does not preserve why each decision was made.

Choose another rule using column and row, or choose another exception address. Predict one row, run, and locate the change. Keep a result you want to look at upright. In the next hall we will load this exact saved image in the same museum project. We will not generate a replacement and call it your earlier work.


---

<!-- hall:Tutorial_Tiling_Walls -->

# Walls — the result has another surface

**Learning elements**

- Reusing a saved image
- Image axes and surface orientation
- Appearance versus collision
- Transforming a receiver and its children together

Find the field you followed underfoot, now standing in front of you. At the eye chart, move closer and back. The rule is unchanged while the distance changes how much you can read.

This is a reuse lesson. Bring the PNG made by your Floor study. The new script loads those pixels onto a solid upright panel. It does not contain the pattern generator. You keep that generator in the previous lesson for when you want another result.

## Put the image on a body

Use the same Godot museum project and its `user://` data folder as Floor. Stop the Floor study before running this one: otherwise Floor would save over your chosen image again. On another device or project, copy `ada_array_pattern.png` into that project's user-data folder first. Day Zero covers where those project files live.

Attach this script to an empty `Node3D`, `WallStudy`, at floor level in a clear part of the wall hall. Keep scale at one. Allow a three-metre square panel and space to walk around it. Its picture faces local positive Z. Place it beside the exhibits, away from the actual exit; this is a freestanding study, not a replacement for the museum's guarded hinged wall.

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

var saved_path := "user://ada_array_pattern.png"
var panel_turn := 0.0
var panel: StaticBody3D
var image := Image.new()

func _ready() -> void:
    if not FileAccess.file_exists(saved_path):
        var label := Label3D.new()
        label.text = "Run the Floor study first.\nIt saves ada_array_pattern.png in this project's user:// folder."
        label.position.y = 1.5
        add_child(label)
        return
    var error := image.load(saved_path)
    assert(error == OK, "The saved pattern could not be read.")
    panel = StaticBody3D.new()
    panel.position.y = 1.5
    panel.rotation_degrees.y = panel_turn
    panel.collision_layer = 1
    panel.collision_mask = 0
    add_child(panel)
    var backing := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(3, 3, 0.1)
    backing.mesh = box
    panel.add_child(backing)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = box.size
    collision.shape = shape
    panel.add_child(collision)

    var face := MeshInstance3D.new()
    var quad := QuadMesh.new()
    quad.size = Vector2(3, 3)
    face.mesh = quad
    face.position.z = 0.051
    var material := StandardMaterial3D.new()
    material.albedo_texture = ImageTexture.create_from_image(image)
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    face.material_override = material
    panel.add_child(face)
```

## Separate the picture from its support

The file check makes the dependency visible. Without Floor's saved result, the study displays an instruction and creates no substitute pattern. `image.load` reads the PNG. The image may contain an exception or a rule you chose; the panel does not need to know how you made it.

The construction brings together things already encountered. The `StaticBody3D` supplies a fixed boundary. Its `BoxMesh` shows the backing; its `BoxShape3D` gives that backing physical extent. The thin `QuadMesh` displays the image just in front, avoiding two visible surfaces at the same depth. Its local XY plane faces positive Z. Image columns run across it; image rows run down it.

`ImageTexture.create_from_image` assigns the saved result to the material. This is the same image-to-texture step as Floor. The material again shows black and white directly. Nothing in these pixels asks for a hole in the collision shape.

Walk towards a black triangle, then a white one. The panel stops your body at both. Walk around its side and look at the plain reverse. The image and the boundary have different responsibilities.

## Two changes to compare

Keep `panel_turn` at zero. Return to the Floor script, switch its exception or change one rule term, and run it to save the new image. Then stop Floor and run Walls again. The picture changes. The panel's position, three-metre size and collision remain the same. This is a deliberate file handoff between runs, not live synchronization between halls.

Now keep that PNG and change `panel_turn` to `90.0`. Run again. Picture, backing and collision turn together because they are children of the same body. A route that crossed the broad face can now pass beside its edge; approaching from the new front still meets a solid panel. The fixed pose is set before physics begins. Making a moving wall yield safely to visitors is the larger installed encounter, not an extra controller hidden in this script.

Choose another angle. Predict where the panel will stand and which way the image will face. Confirm that the saved image is unchanged, then approach from both sides. You are varying the receiver while keeping its input.

In the museum's eye chart, one result appears at several viewing sizes. At the hinged wall, a turn changes access. Our study gives those comparisons a small construction: stored image, visible face, solid support and shared transform. Next, keep the addresses and add a clock. The same places can be read again without moving them.


---

<!-- hall:Tutorial_Disco -->

# Disco — a reader returns

**Learning elements**

- A Boolean score
- A playhead that wraps through addresses
- Elapsed time, tempo and retained remainder
- Independent readers of independent records

Hold the museum floor, then press ONE STEP. Black and white exchange places. Hold the sequencer instead and let the floor run. One clock can stop while the other continues. Your footsteps are not being recorded into its score.

We bring back the clock from Transformation and the retained addresses from Array. This lesson has two short readings: the floor uses a changing phase in a rule; the score keeps decisions that a playhead visits. The installed instrument has four tracks and sixteen steps. Our construction begins with one track and eight steps so you can hear and follow each visit.

## Begin with both clocks held

Save the two files below together. Attach `lesson.gd` to an empty unit-scale `Node3D`, `DiscoStudy`, at floor level on clear floor in this museum hall. Allow about six metres across and seven deep. Keep the museum's player and support floor. The little floor behind the score is visual; it does not add holes or steps to the museum floor.

The four labelled pads use the overlap connection from Array. Walk into a pad to activate it, then leave before entering again. A pad is an `Area3D` sensor, not a physical push switch. The VR player's declared group and layer are the same as before. No controller installation or new input mapping is required here.

First use FLOOR STEP twice. Then leave the pad and return to SCORE STEP until you have visited all eight places. White score cells mean `true`, asking for a click; dark cells mean `false`, asking for silence. A small raised marker shows the last address read. It starts hidden because step `-1` means no address has been read yet.

### lesson.gd

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

const ClickSound = preload("click_sound.gd")
signal note_played(index: int)

var score: Array[bool] = [true, false, false, false, true, false, false, false]
var bpm := 120.0
var score_running := false
var floor_running := false
var floor_period := 0.5
var step := -1
var phase := 0
var score_elapsed := 0.0
var floor_elapsed := 0.0
var tiles: Array = []
var playhead := MeshInstance3D.new()
var speaker := AudioStreamPlayer3D.new()
var readout := Label3D.new()

func _ready() -> void:
    assert(not score.is_empty() and bpm > 0 and floor_period > 0)
    for x in 4:
        tiles.append([])
        for z in 4:
            tiles[x].append(make_box(Vector3(x * 0.65, 0.025, -3 + z * 0.65), Vector3(0.6, 0.05, 0.6)))
    for i in score.size():
        var cell := make_box(Vector3(i * 0.65, 0.8, 0), Vector3(0.55, 0.15, 0.55))
        cell.material_override.albedo_color = Color.WHITE if score[i] else Color(0.08, 0.08, 0.08)
    var marker_mesh := BoxMesh.new()
    marker_mesh.size = Vector3(0.55, 0.03, 0.55)
    playhead.mesh = marker_mesh
    playhead.visible = false
    add_child(playhead)
    speaker.stream = ClickSound.make()
    speaker.position = Vector3(2.3, 1, 0)
    speaker.volume_db = -12
    add_child(speaker)
    readout.position = Vector3(2.3, 2.0, -0.6)
    readout.font_size = 26
    add_child(readout)
    var names := ["FLOOR PLAY/HOLD", "FLOOR STEP", "SCORE PLAY/HOLD", "SCORE STEP"]
    for i in names.size():
        var button := make_box(Vector3(i * 1.6, 0.4, 2.3), Vector3(0.9, 0.15, 0.9))
        var sensor := Area3D.new()
        sensor.collision_layer = 0
        sensor.collision_mask = 1
        sensor.set_collision_mask_value(20, true)
        button.add_child(sensor)
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = Vector3(0.9, 1.2, 0.9)
        collision.shape = shape
        sensor.add_child(collision)
        sensor.body_entered.connect(_on_control.bind(i))
        var label := Label3D.new()
        label.text = names[i]
        label.font_size = 22
        label.position = button.position + Vector3(0, 0.7, 0)
        add_child(label)
    refresh_floor()
    refresh_readout()

func make_box(at: Vector3, size: Vector3) -> MeshInstance3D:
    var body := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    body.mesh = box
    body.material_override = StandardMaterial3D.new()
    body.position = at
    add_child(body)
    return body

func _process(delta: float) -> void:
    advance(delta)

func advance(delta: float) -> void:
    if floor_running:
        floor_elapsed += delta
        var ticks := floori(floor_elapsed / floor_period)
        if ticks > 0:
            floor_elapsed -= ticks * floor_period
            phase = (phase + ticks) % 2
            refresh_floor()
    if score_running:
        var duration := 60.0 / bpm / 4.0
        score_elapsed += delta
        var ticks := floori(score_elapsed / duration)
        if ticks > 0:
            score_elapsed -= ticks * duration
            step = (step + ticks) % score.size()
            read_step()
    refresh_readout()

func _on_control(body: Node3D, action: int) -> void:
    if not (body.is_in_group("player_body") or body.is_in_group("em_walker")):
        return
    if action == 0:
        floor_running = not floor_running
    elif action == 1 and not floor_running:
        phase = (phase + 1) % 2
        refresh_floor()
    elif action == 2:
        score_running = not score_running
    elif action == 3 and not score_running:
        step = (step + 1) % score.size()
        read_step()
    refresh_readout()

func refresh_floor() -> void:
    for x in 4:
        for z in 4:
            var value := (x + z + phase) % 2
            tiles[x][z].material_override.albedo_color = Color.WHITE if value == 1 else Color(0.08, 0.08, 0.08)

func read_step() -> void:
    playhead.visible = true
    playhead.position = Vector3(step * 0.65, 1.05, 0)
    if score[step]:
        speaker.play()
        note_played.emit(step)

func refresh_readout() -> void:
    readout.text = "floor phase %d | playing %s\nscore step %d | playing %s" % [phase, str(floor_running), step, str(score_running)]
```

### click_sound.gd — supplied receiver

This small receiver creates one short, quiet sound used by every event. Copy it unchanged for now. Its sample construction is printed so `speaker.play()` has a real source. Learning sound synthesis is a later task.

<!-- student-code:click_sound.gd -->
```gdscript
extends RefCounted

static func make() -> AudioStreamWAV:
    var bytes := PackedByteArray()
    var sample_count := 1323
    bytes.resize(sample_count)
    for i in sample_count:
        var sign_value := 1.0 if i % 50 < 25 else -1.0
        var envelope := 1.0 - float(i) / sample_count
        bytes[i] = int(48 * sign_value * envelope) & 255
    var sound := AudioStreamWAV.new()
    sound.format = AudioStreamWAV.FORMAT_8_BITS
    sound.mix_rate = 22050
    sound.data = bytes
    return sound
```

## A field receives a phase

The floor uses `(x + z + phase) % 2`. At phase zero, neighbouring cells alternate. Adding one exchanges them; adding another returns to the first arrangement. Sixteen boxes keep their positions. Their separately owned materials let one address change without repainting every box through a shared material.

The construction function returns each new box, as in Array. The floor stores those references in `tiles[x][z]`. The two nested loops in `refresh_floor` revisit them. This time we change an appearance instead of occupancy. We still use only black, white and grey before Colour.

Start FLOOR PLAY/HOLD. Every `floor_period` seconds the phase advances. Hold it again. FLOOR STEP changes the phase only while held, giving you time to compare two states. Walking on the little field does not advance or record anything.

## A score receives a reader

`score` is an `Array[bool]`: each entry is either `true` or `false`. The first and fifth entries begin true. `step` names the most recently read address. Adding one and taking `% score.size()` visits the next address and returns from seven to zero. Reading an event does not consume it. Its value remains available on the next circuit.

SCORE STEP makes one visit while playback is held. SCORE PLAY/HOLD lets elapsed time choose when to visit. The duration `60.0 / bpm / 4.0` gives a sixteenth-note step when BPM counts quarter-note beats. At 120 BPM, one step takes 0.125 seconds. Tempo describes visits, not how many entries the array owns.

`floori` takes the integer part of a non-negative quotient. Dividing accumulated seconds by step duration tells us how many complete steps have elapsed. Subtracting those complete durations keeps the leftover fraction. Resetting the accumulator to zero would repeatedly discard that time and make playback drift.

There is a deliberate rule for a stalled frame: advance the playhead past all elapsed steps, but sound only the final visited address. Missed visits stay in the stored score; they are not played in a burst. This small reader follows elapsed time without claiming to be an audio-accurate scheduler. Synthesis and precise musical scheduling can develop later.

The receiver stores signed sample bytes, their sample rate and a short decay. Its masking expression keeps a signed value's byte representation in the byte array. Those encoding details belong to the supplied sound helper, not to the meaning of a Boolean score. [Godot's AudioStreamWAV reference](https://docs.godotengine.org/en/stable/classes/class_audiostreamwav.html) specifies signed eight-bit PCM for this format.

## Keep one thing; change another

Play the score while holding the floor. Then reverse the arrangement. Neither clock writes into the other clock's record. Holding a reader retains its position and fractional elapsed time; resuming continues it. Stopping does not abruptly cut a click already sounding. Our small study omits the museum's additional sound-to-floor flash bridge.

Keep BPM at 120. Move the second `true` from index four to index three, and run again. The sound is the same; the interval between its visits changes. Restore that score, then change BPM to 90. The addresses stay fixed while their visits spread out in time.

Choose your own eight-entry score. Predict which steps will sound before you use SCORE STEP. Then run it, hold it, and resume. Explain which variable keeps your decisions and which keeps the reader's place. Changing the source and starting again makes a fresh study; pause and resume happen within the current run.

Across these halls, a value has meant an occupant, an orientation and an instruction to sound. The array gives each value an address; the reader gives it work to do. Keep that distinction for Colour. The same familiar forms will receive material values, and the neighbours already held in an arrangement will change how those values appear.

