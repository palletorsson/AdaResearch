extends Node3D
const SurfaceTriangle = preload("surface_triangle.gd")
const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
const HEIGHT := 1.12
const CENTRE := Vector3(0, 0.82, 0)
const RADIUS := 0.75
const PIECES := 24
var model := SurfaceTriangle.new()
var points: Array = []
var edges: Array = []
var labels: Array[Label3D] = []
var plane := MeshInstance3D.new()
var sphere := MeshInstance3D.new()
var face := MeshInstance3D.new()
var readout: Label3D
var hand_refused := false

func display(p: Vector3) -> Vector3:
    return CENTRE + RADIUS * p if model.spherical else p + Vector3.UP * HEIGHT

func finish(colour: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    material.roughness = 0.6
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    return material

func _ready() -> void:
    var slab := BoxMesh.new()
    slab.size = Vector3(2.4, 0.04, 2.4)
    plane.mesh = slab
    plane.position.y = HEIGHT - 0.1
    plane.material_override = finish(Color("e2ded5"))
    add_child(plane)
    var skin := SphereMesh.new()
    skin.radius = RADIUS
    skin.height = RADIUS * 2
    skin.radial_segments = 64
    skin.rings = 32
    sphere.mesh = skin
    sphere.position = CENTRE
    sphere.material_override = finish(Color("b2c2ca"))
    add_child(sphere)
    face.material_override = finish(Color("b2c2ca"))
    add_child(face)
    for i in range(3):
        var point := PointBody.new()
        point.name = ["A", "B", "C"][i]
        add_child(point)
        points.append(point)
        var label := make_label("", 25)
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        labels.append(label)
    for i in range(3 * PIECES):
        var line := LineSkin.new()
        add_child(line)
        edges.append(line)
    readout = make_label("", 24)
    readout.position = Vector3(0, 1.95, -1)
    var console := MeshInstance3D.new()
    var board := BoxMesh.new()
    board.size = Vector3(2.1, 0.08, 0.44)
    console.mesh = board
    console.position = Vector3(0, 0.96, 1.35)
    console.material_override = finish(Color("e2ded5"))
    add_child(console)
    make_button("Plane", -0.6, func(): select(false))
    make_button("Sphere", 0.0, func(): select(true))
    make_button("Reset", 0.6, reset)
    redraw()

func make_label(word: String, size: int) -> Label3D:
    var label := Label3D.new()
    label.text = word
    label.font_size = size
    label.pixel_size = 0.002
    label.modulate = Color("25212a")
    label.outline_size = 6
    label.outline_modulate = Color.WHITE
    add_child(label)
    return label

func make_button(word: String, x: float, callback: Callable) -> void:
    var button = PushButton.instantiate()
    button.name = word
    button.rotation = Vector3.ZERO
    button.position = Vector3(x, 1.03, 1.35)
    add_child(button)
    button.pressed.connect(callback)
    make_label(word.to_upper(), 22).position = Vector3(x, 1.16, 1.35)

func any_held() -> bool:
    for point in points:
        if point.held(): return true
    return false

func select(spherical: bool) -> void:
    if any_held(): return
    model.spherical = spherical
    hand_refused = false
    redraw()

func reset() -> void:
    if any_held(): return
    model.reset()
    hand_refused = false
    redraw()

func record_hand(index: int, local: Vector3) -> bool:
    var p := Vector2(local.x, local.z)
    if model.spherical:
        var direction := local - CENTRE
        # Below/too near the equator, this chart has no safe inverse.
        if direction.y <= 0.02: return false
        p = Vector2(direction.x, direction.z) / direction.y
    model.points[index] = Vector2(clampf(p.x, -1, 1), clampf(p.y, -1, 1))
    return true

func _process(_delta: float) -> void:
    var changed := hand_refused
    hand_refused = false
    for i in range(points.size()):
        if points[i].held():
            if not record_hand(i, to_local(points[i].global_position)): hand_refused = true
            changed = true
    if changed: redraw()

func _physics_process(_delta: float) -> void:
    for i in range(points.size()):
        if not points[i].held(): points[i].global_position = to_global(display(model.corner(model.points[i])))

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_P: select(false)
        if event.keycode == KEY_S: select(true)
        if event.keycode == KEY_R: reset()

func redraw() -> void:
    var result := model.measure()
    plane.visible = not model.spherical
    sphere.visible = model.spherical
    for i in range(points.size()):
        var p := display(model.corner(model.points[i]))
        if not points[i].held(): points[i].global_position = to_global(p)
        labels[i].position = p + Vector3.UP * 0.18
        labels[i].text = "%s: %.2f°" % [["A", "B", "C"][i], result.angles[i]] if result.valid else ["A", "B", "C"][i] + ": —"
        var samples := model.edge(i, PIECES)
        for j in range(PIECES):
            var a := display(samples[j])
            var b := display(samples[j + 1])
            edges[i * PIECES + j].show_segment(a, b - a, a.distance_to(b))
    face.mesh = null
    if result.valid and not model.spherical:
        var builder := SurfaceTool.new()
        builder.begin(Mesh.PRIMITIVE_TRIANGLES)
        for p in model.points: builder.add_vertex(display(model.corner(p)) + Vector3.DOWN * 0.018)
        builder.generate_normals()
        face.mesh = builder.commit()
    readout.text = "SPHERE / great-circle edges\n" if model.spherical else "PLANE / straight edges\n"
    readout.text += "Sum %.2f° / difference from 180°: %+.2f°\n" % [result.sum, result.sum - 180] if result.valid else "No triangle reading: separate the corners.\n"
    readout.text += "Release points before PLANE / P, SPHERE / S or RESET / R.\n"
    readout.text += "Hand outside upper chart: last record kept." if hand_refused else "Same coordinate pairs; different positions and paths."
