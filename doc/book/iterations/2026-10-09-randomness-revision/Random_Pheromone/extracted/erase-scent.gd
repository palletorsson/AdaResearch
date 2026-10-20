extends Node3D

const PointBody = preload("point_body.gd")
const SIDE := 8
const LIMIT := 256
const DT := 0.2
const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0),
    Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1),
    Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]

var sample_seed := 42
var guidance := 0.4
var deposit := 0.6
var decay_rate := 0.2
var avoid := false
var at := Vector2i(4, 4)
var field: Array[float] = []
var visits: Array[int] = []
var path: Array[Vector2i] = []
var rng := RandomNumberGenerator.new()
var tiles: Array[MeshInstance3D] = []
var columns: Array[MeshInstance3D] = []
var markers: Array[MeshInstance3D] = []
var point: XRToolsPickable
var status: Label3D

func _ready() -> void:
    box(Vector3(2.8, 0.9, 1.8), Vector3(0, 0.45, 0), Color(0.82, 0.80, 0.76))
    box(Vector3(2.8, 0.6, 0.04), Vector3(0, 1.83, -0.87), Color(0.88, 0.86, 0.81))
    status = label("", Vector3(0, 1.83, -0.83), 25)
    label("SCENT NOW                VISITS KEPT", Vector3(0, 0.97, 0.65), 24)
    label("REPLAY       STEP       +20       RULE", Vector3(0, 0.82, 0.92), 23)
    for y in range(SIDE):
        for x in range(SIDE):
            var cell := Vector2i(x, y)
            tiles.append(box(Vector3(0.12, 0.02, 0.12), place(cell, -0.68), Color.WHITE))
            columns.append(box(Vector3(0.12, 1.0, 0.12), place(cell, 0.68), Color(0.5, 0.5, 0.5)))
    for side in range(2):
        var marker := MeshInstance3D.new()
        var sphere := SphereMesh.new()
        sphere.radius = 0.035
        sphere.height = 0.07
        marker.mesh = sphere
        marker.material_override = material(Color(0.0, 0.75, 0.8))
        add_child(marker)
        markers.append(marker)
    point = PointBody.new()
    point.position = Vector3(0, 1.12, 0.85)
    add_child(point)
    point.action_pressed.connect(use_point)
    replay()

func index(cell: Vector2i) -> int:
    return cell.y * SIDE + cell.x

func valid(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.x < SIDE and cell.y >= 0 and cell.y < SIDE

func replay() -> void:
    rng.seed = sample_seed
    field.resize(SIDE * SIDE)
    field.fill(0.0)
    visits.resize(SIDE * SIDE)
    visits.fill(0)
    at = Vector2i(4, 4)
    path.assign([at])
    redraw()

func fade(seconds: float) -> void:
    for i in range(field.size()):
        field[i] = maxf(0.0, field[i] - decay_rate * seconds)

func advance(amount: int) -> void:
    for _i in range(mini(amount, LIMIT - (path.size() - 1))):
        fade(DT)
        field[index(at)] += deposit
        visits[index(at)] += 1
        at = choose(at)
        path.append(at)
        fade(20.0)
        # visits and path are deliberately retained
    redraw()

func choose(cell: Vector2i) -> Vector2i:
    var direction: Vector2i = DIRS[0]
    if rng.randf() < guidance:
        var best := INF if avoid else -1.0
        for d in DIRS:
            var target := cell + d
            if not valid(target):
                continue
            var scent := field[index(target)]
            var better := scent < best if avoid else scent > best
            if better:
                best = scent
                direction = d
    else:
        direction = DIRS[rng.randi() % DIRS.size()]
    var next := cell + direction
    return Vector2i(clampi(next.x, 0, SIDE - 1), clampi(next.y, 0, SIDE - 1))

func change_rule() -> void:
    avoid = not avoid
    replay()

func use_point(_held) -> void:
    var x := to_local(point.global_position).x
    if x < -0.6:
        replay()
    elif x < 0.0:
        advance(1)
    elif x < 0.6:
        advance(20)
    else:
        change_rule()

func place(cell: Vector2i, centre: float) -> Vector3:
    return Vector3(centre + (cell.x - 3.5) * 0.14, 0.92, (cell.y - 3.5) * 0.14)

func redraw() -> void:
    for i in range(field.size()):
        tiles[i].material_override.albedo_color = Color(0.95, 0.94, 0.90).lerp(Color(0.8, 0.02, 0.35), clampf(field[i] / 3.0, 0.0, 1.0))
        var height := 0.02 + minf(visits[i] * 0.06, 0.6)
        columns[i].scale.y = height
        columns[i].position.y = 0.91 + height / 2.0
    markers[0].position = place(at, -0.68) + Vector3.UP * 0.06
    markers[1].position = place(at, 0.68) + Vector3.UP * (0.06 + minf(visits[index(at)] * 0.06, 0.6))
    status.text = "%s | seed %d | step %d / %d\nSignal-guided %.0f%% | height caps at 10 visits\nTwo views of ONE walker" % [
        "AVOID" if avoid else "ATTRACT", sample_seed, path.size() - 1, LIMIT, guidance * 100]

func material(colour: Color) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = colour
    result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return result

func box(size: Vector3, position: Vector3, colour: Color) -> MeshInstance3D:
    var view := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    view.mesh = mesh
    view.position = position
    view.material_override = material(colour)
    add_child(view)
    return view

func label(words: String, position: Vector3, font_size: int) -> Label3D:
    var view := Label3D.new()
    view.text = words
    view.position = position
    view.font_size = font_size
    view.pixel_size = 0.0025
    view.modulate = Color(0.02, 0.02, 0.02)
    view.outline_size = 0
    add_child(view)
    return view
