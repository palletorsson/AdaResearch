extends Node3D

var width := 4
var depth := 4
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
    cubes[1][0].rotation_degrees.y = 45.0
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
