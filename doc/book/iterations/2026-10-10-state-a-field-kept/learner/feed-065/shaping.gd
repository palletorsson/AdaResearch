extends Node3D

const PointBody = preload("point_body.gd")
const Recipe = preload("recipe.gdshader")
const Field = preload("field.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
const FEED := 0.065
var material := ShaderMaterial.new()
var control: PointBody
var readout := Label3D.new()
var field: Node
var alternate_ink := false
var buttons: Dictionary = {}
var cube: StaticBody3D

func _ready() -> void:
    material.shader = Recipe
    cube = make_box(Vector3(-0.6, 0.9, 0), Vector3.ONE * 0.60, material)
    make_box(Vector3(-0.6, 0.30, 0), Vector3(0.8, 0.60, 0.8))
    control = PointBody.new()
    control.position = Vector3(0.65, 1.2, 1.2)
    add_child(control)
    control.coat(material)
    control.action_pressed.connect(plant)
    var lamp := OmniLight3D.new()
    lamp.position = Vector3(-1.3, 2.4, 1.8)
    lamp.omni_range = 4.0
    lamp.light_energy = 5.0
    lamp.shadow_enabled = true
    add_child(lamp)
    readout.position = Vector3(0, 2.72, -0.5)
    readout.font_size = 28
    readout.pixel_size = 0.002
    add_child(readout)
    var board := MeshInstance3D.new()
    var quad := QuadMesh.new()
    quad.size = Vector2(2, 2)
    board.mesh = quad
    board.position = Vector3(0, 1.5, -0.5)
    board.material_override = material
    add_child(board)
    make_box(Vector3(0, 0.93, 1.8), Vector3(2.4, 0.10, 0.5))
    for i in range(5):
        var key: String = ["RUN/HOLD", "STEP", "RESET", "CLEAR", "INK"][i]
        var button = PushButton.instantiate()
        button.position = Vector3(-0.96 + i * 0.48, 0.99, 1.8)
        add_child(button)
        buttons[key] = button
        # This declared prefab creates its named press receiver.
        button.get_node("InteractableAreaButton").button_pressed.connect(func(_b): act(key))
        var label := Label3D.new()
        label.text = key
        label.font_size = 24
        label.pixel_size = 0.0015
        label.position = button.position + Vector3(0, 0.015, 0.19)
        label.rotation_degrees.x = -60
        add_child(label)
    field = Field.new()
    field.feed = FEED
    add_child(field)
    field.changed.connect(show_state)
    show_state()



func make_box(at: Vector3, size: Vector3, paint: Material = null) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.position = at
    var surface := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    surface.mesh = box
    var grey := StandardMaterial3D.new()
    grey.albedo_color = Color(0.12, 0.12, 0.12)
    surface.material_override = grey if paint == null else paint
    body.add_child(surface)
    var boundary := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    boundary.shape = shape
    body.add_child(boundary)
    add_child(body)
    return body

func plant(_point) -> void:
    if not control.is_picked_up():
        return
    var p := to_local(control.global_position)
    field.mark(Vector2(p.x / 2.0 + 0.5, 1.0 - (p.y - 0.5) / 2.0))

func act(key: String) -> void:
    match key:
        "RUN/HOLD": field.running = not field.running
        "STEP": field.step()
        "RESET": field.reset(true)
        "CLEAR": field.reset(false)
        "INK":
            alternate_ink = not alternate_ink
            material.set_shader_parameter("ink", Color("822547") if alternate_ink else Color("143436"))
    show_state()

func show_state() -> void:
    material.set_shader_parameter("state_texture", field.state_texture)
    readout.text = "%s / %d steps / F %.3f\nHold point; trigger plants at its X/Y address" % [
        "RUNNING" if field.running else "HELD", field.iterations, field.feed
    ]
