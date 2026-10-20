extends Node3D

const PointBody = preload("point_body.gd")
const CENTRE := Vector3(0, 1.5, 0)

var seed_value := 42
var requested := 12
var tries_per_place := 100
var half_size := Vector3(1.2, 0.7, 0.06)
var separation := 0.34
var rng := RandomNumberGenerator.new()
var homes: Array[Vector3] = []
var points: Array[Node3D] = []
var attempts := 0
var refused := 0
var control: Node3D
var label: Label3D

func _ready() -> void:
    build_frame()
    label = Label3D.new()
    label.position = Vector3(0, 2.65, 0)
    label.font_size = 28
    label.pixel_size = 0.002
    add_child(label)
    control = PointBody.new()
    control.position = Vector3(0, 0.65, 0.5)
    add_child(control)
    var black := StandardMaterial3D.new()
    black.albedo_color = Color(0.025, 0.025, 0.025)
    control.get_child(0).material_override = black
    control.action_pressed.connect(use_control)
    for i in range(4):
        var nameplate := Label3D.new()
        nameplate.text = ["REDRAW", "NEXT SEED", "LOAD", "RESTORE"][i]
        nameplate.position = Vector3(-1.2 + i * 0.8, 0.4, 0.5)
        nameplate.font_size = 26
        nameplate.pixel_size = 0.002
        add_child(nameplate)
    redraw()

func sample() -> void:
    rng.seed = seed_value
    homes.clear()
    attempts = 0
    refused = 0
    for place in range(requested):
        for attempt in range(tries_per_place):
            var candidate := Vector3(
                rng.randf_range(-half_size.x, half_size.x),
                rng.randf_range(-half_size.y, half_size.y),
                rng.randf_range(-half_size.z, half_size.z)
            )
            attempts += 1
            if far_enough(candidate):
                homes.append(candidate)
                pass # wrong: continue filling this place
            refused += 1

func far_enough(candidate: Vector3) -> bool:
    for existing in homes:
        if candidate.distance_to(existing) < separation:
            return false
    return true

func redraw() -> void:
    for point in points:
        remove_child(point)
        point.queue_free()
    points.clear()
    sample()
    for home in homes:
        var point := PointBody.new()
        point.position = CENTRE + home
        add_child(point)
        points.append(point)
    update_readout()

func restore() -> void:
    for i in range(points.size()):
        points[i].position = CENTRE + homes[i]
    update_readout()

func close_pairs() -> int:
    var count := 0
    for i in range(points.size()):
        for j in range(i + 1, points.size()):
            if points[i].position.distance_to(points[j].position) < separation - 0.001:
                count += 1
    return count

func update_readout() -> void:
    label.text = "Seed %d | spacing %.2f m\n%d requested | %d filled | %d unfilled\n%d candidates | %d refused | %d close pairs now" % [
        seed_value, separation, requested, homes.size(), requested - homes.size(),
        attempts, refused, close_pairs()
    ]

func _process(_delta: float) -> void:
    update_readout()

func use_control(_pickable) -> void:
    # Release the sampled balls before replacing or restoring their positions.
    for point in points:
        if point.is_picked_up():
            return
    var x := to_local(control.global_position).x
    if x < -0.8:
        redraw()
    elif x < 0.0:
        seed_value += 1
        redraw()
    elif x < 0.8:
        requested = 48 if requested == 12 else 12
        redraw()
    else:
        restore()

func build_frame() -> void:
    for axis in range(3):
        for a in [-1.0, 1.0]:
            for b in [-1.0, 1.0]:
                var bar := MeshInstance3D.new()
                var box := BoxMesh.new()
                var size := Vector3.ONE * 0.01
                var offset := Vector3.ZERO
                size[axis] = 2.0 * half_size[axis]
                offset[(axis + 1) % 3] = a * half_size[(axis + 1) % 3]
                offset[(axis + 2) % 3] = b * half_size[(axis + 2) % 3]
                box.size = size
                bar.mesh = box
                bar.position = CENTRE + offset
                add_child(bar)
