extends Node3D

const STAGES = [
	{"label": "1. UV Mapping", "shader": "res://algorithms/shaders/tilesexplained/stage1_uv.gdshader"},
	{"label": "2. Tiling", "shader": "res://algorithms/shaders/tilesexplained/stage2_tile.gdshader"},
	{"label": "3. Rotation", "shader": "res://algorithms/shaders/tilesexplained/stage3_rotate.gdshader"},
	{"label": "4. Rotate Tile Pattern", "shader": "res://algorithms/shaders/tilesexplained/stage4_rotate_pattern.gdshader"},
	{"label": "5. Final Pattern", "shader": "res://algorithms/shaders/tilesexplained/stage5_final.gdshader"}
]

@export var box_spacing: float = 3.0

func _ready() -> void:
	var start_x = -((STAGES.size() - 1) * box_spacing) / 2.0
	for i in range(STAGES.size()):
		_add_stage(i, start_x + i * box_spacing)

func _add_stage(i: int, x: float) -> void:
	var data = STAGES[i]
	var box := MeshInstance3D.new()
	box.mesh = BoxMesh.new()
	box.scale = Vector3(2, 2, 0.2)
	var mat := ShaderMaterial.new()
	mat.shader = load(data["shader"])
	box.material_override = mat
	box.position = Vector3(x, 0, 0)
	add_child(box)

	var label := Label3D.new()
	label.text = data["label"]
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1, 1, 1)
	label.position = Vector3(x, 1.8, 0)
	label.font_size = 36
	add_child(label)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

