extends Node3D
const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
var drawing := Node3D.new()
var point
var point_home := Vector3(0, 1.1, 0)
var readout: Label3D
var buttons: Array = []

func start(title: String, words: Array, actions: Array) -> void:
    block(self, Vector3(0, 0.94, 0), Vector3(2.8, 0.08, 1.9), Color("d3ccc1"))
    block(self, Vector3(0, 1.94, -0.85), Vector3(2.9, 0.72, 0.04), Color("182330"))
    label(self, title, Vector3(0, 2.17, -0.8), 27)
    readout = label(self, "", Vector3(0, 1.9, -0.8), 22)
    add_child(drawing)
    point = PointBody.new()
    point.name = "CarriedPoint"
    point.tint = Color("e8c18c")
    add_child(point)
    for i in words.size():
        var button = PushButton.instantiate()
        button.name = "Action%d" % i
        button.position = Vector3((i-(words.size()-1)*0.5)*0.48, 1.02, 0.77)
        add_child(button)
        button.pressed.connect(actions[i])
        buttons.append(button)
        label(self, words[i], button.position+Vector3(0, 0.12, 0), 18)

func _physics_process(_delta: float) -> void:
    if point != null and not point.held(): point.position = point_home

func clear_drawing() -> void:
    for child in drawing.get_children(): child.free()

func block(parent: Node, at: Vector3, size: Vector3, colour: Color) -> MeshInstance3D:
    var body := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    body.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    body.material_override = material
    body.position = at
    parent.add_child(body)
    return body

func label(parent: Node, words: String, at: Vector3, size: int = 22) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.0018
    text.outline_size = 5
    text.outline_modulate = Color("182330")
    parent.add_child(text)
    return text

func segment(a: Vector3, b: Vector3) -> void:
    var line := LineSkin.new()
    drawing.add_child(line)
    line.show_segment(a, b-a, a.distance_to(b))
