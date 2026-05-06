extends Node3D
## Shows all synthetic foliage types side by side.

const Foliage: GDScript = preload("res://commons/fold_system/synthetic_foliage.gd")

func _ready() -> void:
	var types := [
		{ "name": "Grass", "mesh": Foliage.make_grass(), "scale": 0.4 },
		{ "name": "Flower", "mesh": Foliage.make_flower(), "scale": 0.5 },
		{ "name": "Fern", "mesh": Foliage.make_fern(), "scale": 0.4 },
		{ "name": "Mushroom", "mesh": Foliage.make_mushroom(), "scale": 0.6 },
		{ "name": "Reed", "mesh": Foliage.make_reed(), "scale": 0.3 },
		{ "name": "Tree", "mesh": Foliage.make_tree(), "scale": 0.4 },
		{ "name": "Bush", "mesh": Foliage.make_bush(), "scale": 0.5 },
		{ "name": "Vine", "mesh": Foliage.make_vine(), "scale": 0.3 },
	]

	var spacing := 0.5
	var start_x := -float(types.size() - 1) * spacing * 0.5

	for i in types.size():
		var t: Dictionary = types[i]
		var mi := MeshInstance3D.new()
		mi.mesh = t["mesh"]
		mi.position = Vector3(start_x + i * spacing, 0, 0)
		mi.scale = Vector3.ONE * float(t["scale"])
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.roughness = 0.8
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = mat
		mi.name = t["name"]
		add_child(mi)

		var label := Label3D.new()
		label.text = t["name"]
		label.font_size = 48
		label.pixel_size = 0.002
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color(0.8, 0.9, 0.7, 0.9)
		label.position = Vector3(start_x + i * spacing, -0.15, 0)
		add_child(label)

func apply_grid_config(_config: Dictionary) -> void:
	pass
