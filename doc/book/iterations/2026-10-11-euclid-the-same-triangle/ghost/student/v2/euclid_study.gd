extends Node3D
const Triangle = preload("triangle_record.gd")
const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
const HEIGHT := 1.12
var model := Triangle.new()
var points: Array = []
var edges: Array = []
var labels: Array[Label3D] = []
var guide := LineSkin.new()
var face := MeshInstance3D.new()
var readout := Label3D.new()
var guide_on := true

func place(p: Vector2) -> Vector3:
    return Vector3(p.x, HEIGHT, p.y)

func _ready() -> void:
    var top := MeshInstance3D.new()
    var slab := BoxMesh.new()
    slab.size = Vector3(2.8, 0.08, 2.8)
    top.mesh = slab
    top.position.y = HEIGHT - 0.16
    top.material_override = finish(Color("e2ded5"))
    add_child(top)
    for i in range(3):
        var point := PointBody.new()
        point.name = ["A", "B", "C"][i]
        add_child(point)
        points.append(point)
        point.action_pressed.connect(func(_hand): toggle_guide())
        var edge := LineSkin.new()
        add_child(edge)
        edges.append(edge)
        var label := Label3D.new()
        label.font_size = 26
        label.outline_size = 0
        label.pixel_size = 0.002
        label.modulate = Color("25212a")
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        add_child(label)
        labels.append(label)
    add_child(guide)
    guide.material_override = finish(Color("a27622"))
    face.material_override = finish(Color("b2c2ca"))
    add_child(face)
    readout.position = Vector3(0, 1.65, -1.0)
    readout.font_size = 24
    readout.outline_size = 0
    readout.pixel_size = 0.002
    readout.modulate = Color("25212a")
    readout.no_depth_test = false
    add_child(readout)
    make_button("Guide", Vector3(-0.35, 1.03, 1.15), toggle_guide)
    make_button("Reset", Vector3(0.35, 1.03, 1.15), reset)
    redraw()

func finish(colour: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    material.roughness = 0.6
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    return material

func make_button(word: String, where: Vector3, callback: Callable) -> void:
    var button = PushButton.instantiate()
    button.name = word
    button.rotation = Vector3.ZERO
    button.position = where
    add_child(button)
    button.pressed.connect(callback)
    var label := Label3D.new()
    label.text = word.to_upper()
    label.position = where + Vector3(0, 0.13, 0)
    label.font_size = 22
    label.outline_size = 0
    label.pixel_size = 0.002
    label.modulate = Color("25212a")
    add_child(label)

func toggle_guide() -> void:
    guide_on = not guide_on
    redraw()

func reset() -> void:
    for point in points:
        if point.held(): return
    model.reset()
    redraw()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_G: toggle_guide()
        if event.keycode == KEY_R: reset()

func _process(_delta: float) -> void:
    for i in range(3):
        if points[i].held():
            var local := to_local(points[i].global_position)
            model.points[i] = Vector2(clampf(local.x, -1, 1), clampf(local.z, -1, 1))
    redraw()

func _physics_process(_delta: float) -> void:
    # Frozen rigid bodies need their released display position maintained too.
    for i in range(points.size()):
        if not points[i].held(): points[i].global_position = to_global(place(model.points[i]))

func redraw() -> void:
    var result := model.measure()
    for i in range(points.size()):
        var a := place(model.points[i])
        var b := place(model.points[(i + 1) % 3])
        if not points[i].held(): points[i].global_position = to_global(a)
        edges[i].show_segment(a, b - a, a.distance_to(b))
        labels[i].position = a + Vector3(0, 0.18, 0)
        labels[i].text = "%s: %.2f°" % [["A", "B", "C"][i], result.angles[i]] if result.valid else ["A", "B", "C"][i] + ": —"
    var ends := model.parallel_ends()
    guide.hide()
    if guide_on and result.valid and ends.size() == 2:
        var start := place(ends[0])
        var displacement := place(ends[1]) - start
        guide.show_segment(start, displacement, displacement.length())
    face.mesh = null
    if result.valid:
        var builder := SurfaceTool.new()
        builder.begin(Mesh.PRIMITIVE_TRIANGLES)
        for p in model.points: builder.add_vertex(place(p) + Vector3.DOWN * 0.018)
        builder.generate_normals()
        face.mesh = builder.commit()
    readout.text = "MOVE A, B OR C / trigger or G: guide / R: reset\nHand projects onto this flat table; x and z stay within ±1 m.\n"
    readout.text += "Measured sum %.2f° / area %.3f m²\nGuide through C copies the direction B − A." % [result.sum, result.area] if result.valid else "No triangle reading: corners coincide or nearly align.\nSeparate the points to measure again."
