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
