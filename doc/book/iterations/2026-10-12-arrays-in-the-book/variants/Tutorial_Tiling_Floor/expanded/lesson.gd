extends Node3D

const PatternImage = preload("pattern_image.gd")
var columns := 8
var rows := 8
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
