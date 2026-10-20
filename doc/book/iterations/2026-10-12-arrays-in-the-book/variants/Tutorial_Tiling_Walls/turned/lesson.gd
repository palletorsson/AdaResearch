extends Node3D

var saved_path := "user://ada_array_pattern.png"
var panel_turn := 90.0
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
