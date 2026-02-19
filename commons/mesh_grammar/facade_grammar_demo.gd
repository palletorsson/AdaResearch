## FacadeGrammarDemo — Standalone demo scene showcasing facade grammar + element library.
## Shows Italian presets as full facades (row 1) and individual elements (row 2).
## Run this scene directly to test the facade system.
extends Node3D

@export var facade_spacing: float = 12.0
@export var element_spacing: float = 2.0

func _ready() -> void:
	_create_environment()
	_create_floor()
	_create_facade_gallery()
	_create_element_gallery()


# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
func _create_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.65, 0.8)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.75, 0.85)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAP_ACES
	env.ssao_enabled = true

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# Sun
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 25, 0)
	light.light_color = Color(1.0, 0.95, 0.88)
	light.light_energy = 1.4
	light.shadow_enabled = true
	add_child(light)

	# Fill
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, -130, 0)
	fill.light_color = Color(0.6, 0.65, 0.8)
	fill.light_energy = 0.35
	fill.shadow_enabled = false
	add_child(fill)

	# Camera — pulled back to see the facades
	var cam := Camera3D.new()
	cam.position = Vector3(24, 8, 30)
	cam.rotation_degrees = Vector3(-12, 0, 0)
	cam.fov = 50
	add_child(cam)


# ---------------------------------------------------------------------------
# Floor
# ---------------------------------------------------------------------------
func _create_floor() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	add_child(floor_body)

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 40)
	floor_mesh.mesh = plane

	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.35, 0.32, 0.28)
	floor_mat.roughness = 0.95
	floor_mesh.material_override = floor_mat
	floor_body.add_child(floor_mesh)

	var col := CollisionShape3D.new()
	var col_shape := BoxShape3D.new()
	col_shape.size = Vector3(80, 0.1, 40)
	col.shape = col_shape
	col.position.y = -0.05
	floor_body.add_child(col)


# ---------------------------------------------------------------------------
# Row 1: Full Facade Presets (from italy_facade.json)
# ---------------------------------------------------------------------------
func _create_facade_gallery() -> void:
	var presets: Array[Dictionary] = [
		{"name": "Villa San Michele", "preset": "villa_san_michele", "width": 10, "height": 10},
		{"name": "Certosa di San Giacomo", "preset": "certosa_di_san_giacomo", "width": 12, "height": 8},
		{"name": "Villa Jovis", "preset": "villa_jovis", "width": 8, "height": 10},
		{"name": "San Gregorio Armeno", "preset": "san_gregorio_armeno", "width": 10, "height": 14},
		{"name": "Casa del Fauno", "preset": "casa_del_fauno", "width": 8, "height": 8},
		{"name": "Generic Classical", "preset": "generic_classical", "width": 10, "height": 12},
	]

	# Section label
	var section_label := Label3D.new()
	section_label.text = "ITALIAN FACADE PRESETS"
	section_label.font_size = 64
	section_label.pixel_size = 0.003
	section_label.position = Vector3(0, 15, -2)
	section_label.modulate = Color(0.3, 0.25, 0.2)
	add_child(section_label)

	var x_offset: float = 0.0
	for i in range(presets.size()):
		var spec := presets[i]
		var fw: float = spec["width"]
		var fh: float = spec["height"]

		# Create FacadeGrammarNode
		var facade_node := FacadeGrammarNode.new()
		facade_node.name = "Facade_%s" % spec["preset"]
		facade_node.study_pack = "italy"
		facade_node.preset = spec["preset"]
		facade_node.total_width = fw
		facade_node.total_height = fh
		facade_node.base_color = Color(0.85, 0.8, 0.72)
		facade_node.roughness = 0.8
		facade_node.position = Vector3(x_offset, 0, 0)
		add_child(facade_node)

		# Name label
		var label := Label3D.new()
		label.text = spec["name"]
		label.font_size = 40
		label.pixel_size = 0.002
		label.position = Vector3(x_offset + fw / 2.0, -0.3, 0.5)
		label.modulate = Color(0.2, 0.15, 0.1)
		add_child(label)

		x_offset += fw + facade_spacing


# ---------------------------------------------------------------------------
# Row 2: Individual Element Specimens
# ---------------------------------------------------------------------------
func _create_element_gallery() -> void:
	var elements: Array[Dictionary] = [
		{"name": "Column (Ionic)", "type": "column", "params": {"depth": 0.5, "taper": 0.85}, "width": 1.0, "height": 4.0},
		{"name": "Column (Corinthian)", "type": "column", "params": {"depth": 0.5, "taper": 0.87}, "width": 1.0, "height": 5.0},
		{"name": "Pilaster", "type": "pilaster", "params": {"depth": 0.08, "taper": 0.95}, "width": 1.0, "height": 4.0},
		{"name": "Rectangular Opening", "type": "opening_rectangular", "params": {"inset": 0.03, "frame_width": 0.1}, "width": 2.0, "height": 3.0},
		{"name": "Arched Opening", "type": "opening_arched", "params": {"inset": 0.05, "frame_width": 0.08}, "width": 2.0, "height": 4.0},
		{"name": "Cyma Recta Cornice", "type": "horizontal_band", "params": {"profile": "cyma_recta", "scale": 1.0}, "width": 4.0, "height": 0.5},
		{"name": "Dentil Band", "type": "horizontal_band", "params": {"profile": "dentil", "scale": 1.0}, "width": 4.0, "height": 0.5},
		{"name": "Rustication", "type": "rustication", "params": {"rows": 4, "cols": 1, "depth": 0.02}, "width": 2.0, "height": 3.0},
		{"name": "Balustrade", "type": "balustrade", "params": {"count": 6}, "width": 4.0, "height": 0.8},
		{"name": "Pediment", "type": "pediment", "params": {"height": 0.3}, "width": 4.0, "height": 1.5},
	]

	# Section label
	var section_label := Label3D.new()
	section_label.text = "ELEMENT LIBRARY"
	section_label.font_size = 64
	section_label.pixel_size = 0.003
	section_label.position = Vector3(0, 6, -14)
	section_label.modulate = Color(0.3, 0.25, 0.2)
	add_child(section_label)

	var x_offset: float = 0.0
	for i in range(elements.size()):
		var spec := elements[i]
		var ew: float = spec["width"]
		var eh: float = spec["height"]

		var node := _build_element_specimen(spec)
		node.position = Vector3(x_offset, 0, -16)
		add_child(node)

		# Label
		var label := Label3D.new()
		label.text = spec["name"]
		label.font_size = 32
		label.pixel_size = 0.002
		label.position = Vector3(x_offset + ew / 2.0, -0.3, -15.5)
		label.modulate = Color(0.2, 0.15, 0.1)
		add_child(label)

		x_offset += ew + element_spacing


func _build_element_specimen(spec: Dictionary) -> MeshInstance3D:
	var ew: float = spec["width"]
	var eh: float = spec["height"]
	var element_type: String = spec["type"]
	var params: Dictionary = spec.get("params", {})

	# Create seed quad
	var mesh_data := MeshData.new()
	var v0 := mesh_data.add_vertex(Vector3(0, 0, 0))
	var v1 := mesh_data.add_vertex(Vector3(ew, 0, 0))
	var v2 := mesh_data.add_vertex(Vector3(ew, eh, 0))
	var v3 := mesh_data.add_vertex(Vector3(0, eh, 0))
	mesh_data.add_face(PackedInt32Array([v0, v1, v2]), PackedStringArray(["facade"]), 0)
	mesh_data.add_face(PackedInt32Array([v0, v2, v3]), PackedStringArray(["facade"]), 0)

	# Apply element rules
	var rules := FacadeElementLibrary.get_element(element_type, params)
	for rule in rules:
		if rule.selector == null:
			rule.selector = MeshSelector.all_faces()
		rule.apply(mesh_data)

	# Convert to mesh
	var array_mesh := mesh_data.to_array_mesh({
		"double_sided": false,
		"generate_normals": true
	})

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Element_%s" % element_type
	mesh_instance.mesh = array_mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.82, 0.76, 0.66)
	mat.roughness = 0.8
	mesh_instance.material_override = mat

	return mesh_instance
