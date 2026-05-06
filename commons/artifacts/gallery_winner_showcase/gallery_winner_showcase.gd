extends Node3D
class_name GalleryWinnerShowcase

const MorphologySim = preload("res://commons/morphology_grammar/morphology_sim.gd")
const RDSim = preload("res://commons/rd_grammar/rd_sim.gd")
const LSystemSim = preload("res://commons/lsystem_grammar/lsystem_sim.gd")
const LSystemTurtle = preload("res://commons/lsystem_grammar/lsystem_turtle.gd")
const PrimitiveStackScript = preload("res://commons/primitive_grammar/primitive_stack.gd")
const NoiseDisplacePS = preload("res://commons/noise_grammar/noise_displace.gd")

@export var manifest_path: String = "res://commons/generated/gallery_best_of/manifest.json"
@export var columns: int = 4
@export var max_panel_width: float = 2.3
@export var max_panel_height: float = 1.4
@export var gap_x: float = 3.0
@export var gap_z: float = 2.8
@export var live_object_size: float = 1.0
@export var label_color: Color = Color(0.92, 0.92, 0.95)
@export var accent_color: Color = Color(0.98, 0.74, 0.28)

var _items: Array = []
var _content_root: Node3D


func _ready() -> void:
	_content_root = Node3D.new()
	_content_root.name = "ContentRoot"
	add_child(_content_root)
	_load_manifest()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("manifest"):
		manifest_path = str(config_data["manifest"])
	if config_data.has("columns"):
		columns = max(1, int(config_data["columns"]))
	if config_data.has("gap_x"):
		gap_x = max(1.0, float(config_data["gap_x"]))
	if config_data.has("gap_z"):
		gap_z = max(1.0, float(config_data["gap_z"]))
	if config_data.has("max_panel_width"):
		max_panel_width = clamp(float(config_data["max_panel_width"]), 0.5, 4.0)
	if config_data.has("max_panel_height"):
		max_panel_height = clamp(float(config_data["max_panel_height"]), 0.5, 3.0)
	if config_data.has("live_object_size"):
		live_object_size = clamp(float(config_data["live_object_size"]), 0.3, 2.5)
	if _content_root:
		_content_root.queue_free()
		_content_root = Node3D.new()
		_content_root.name = "ContentRoot"
		add_child(_content_root)
	_load_manifest()
	_build()


func _load_manifest() -> void:
	_items.clear()
	if not FileAccess.file_exists(manifest_path):
		push_warning("GalleryWinnerShowcase: Missing manifest %s" % manifest_path)
		return

	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if not file:
		push_warning("GalleryWinnerShowcase: Could not open manifest %s" % manifest_path)
		return

	var parsed := JSON.new()
	var err := parsed.parse(file.get_as_text())
	file.close()
	if err != OK or not (parsed.data is Dictionary):
		push_warning("GalleryWinnerShowcase: Failed to parse manifest %s" % manifest_path)
		return

	var data: Dictionary = parsed.data
	var items_variant: Variant = data.get("items", [])
	if items_variant is Array:
		_items = (items_variant as Array).duplicate(true)


func _build() -> void:
	if not _content_root:
		return

	_build_title()
	if _items.is_empty():
		_build_empty_note()
		return

	for index in _items.size():
		var item: Dictionary = _items[index]
		var col := index % columns
		var row := index / columns
		var x := (float(col) - float(columns - 1) * 0.5) * gap_x
		var z := float(row) * gap_z
		var panel := _build_panel(item)
		panel.position = Vector3(x, 0.0, z)
		_content_root.add_child(panel)


func _build_title() -> void:
	var title := Label3D.new()
	title.text = "Best Of The Galleries"
	title.font_size = 72
	title.pixel_size = 0.0015
	title.modulate = accent_color
	title.outline_size = 8
	title.outline_modulate = Color(0.06, 0.06, 0.08, 0.95)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector3(0.0, 2.6, -1.1)
	_content_root.add_child(title)

	var subtitle := Label3D.new()
	subtitle.text = "Live object where possible, image panel where not"
	subtitle.font_size = 34
	subtitle.pixel_size = 0.0012
	subtitle.modulate = label_color
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector3(0.0, 2.2, -1.1)
	_content_root.add_child(subtitle)


func _build_empty_note() -> void:
	var note := Label3D.new()
	note.text = "No gallery manifest found."
	note.font_size = 48
	note.pixel_size = 0.0013
	note.modulate = label_color
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.position = Vector3(0.0, 1.5, 0.0)
	_content_root.add_child(note)


func _build_panel(item: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = str(item.get("gallery", "panel"))

	var has_live := _can_build_live(item)
	var base_depth := 1.6 if has_live else 0.8

	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(2.1, 0.08, base_depth)
	base.mesh = base_mesh
	base.position = Vector3(0.0, 0.04, 0.0)
	base.material_override = _solid_material(Color(0.12, 0.13, 0.16))
	root.add_child(base)

	var post := MeshInstance3D.new()
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.08, 1.35, 0.08)
	post.mesh = post_mesh
	post.position = Vector3(0.0, 0.68, -0.10)
	post.material_override = _solid_material(Color(0.19, 0.20, 0.24))
	root.add_child(post)

	var texture_path := str(item.get("image_path", ""))
	var texture := load(texture_path) as Texture2D if ResourceLoader.exists(texture_path) else null
	var image_size := _fit_size(texture)

	var frame := MeshInstance3D.new()
	var frame_mesh := PlaneMesh.new()
	frame_mesh.size = image_size + Vector2(0.12, 0.12)
	frame_mesh.orientation = PlaneMesh.FACE_Z
	frame.mesh = frame_mesh
	frame.position = Vector3(0.0, 1.45, 0.0)
	frame.material_override = _solid_material(Color(0.16, 0.17, 0.20))
	root.add_child(frame)

	var screen := MeshInstance3D.new()
	var screen_mesh := PlaneMesh.new()
	screen_mesh.size = image_size
	screen_mesh.orientation = PlaneMesh.FACE_Z
	screen.mesh = screen_mesh
	screen.position = Vector3(0.0, 1.45, 0.01)
	screen.material_override = _image_material(texture)
	root.add_child(screen)

	var gallery_label := _make_label(
		str(item.get("gallery_title", item.get("gallery", ""))).to_upper(),
		40,
		accent_color
	)
	gallery_label.position = Vector3(0.0, 2.32, 0.0)
	root.add_child(gallery_label)

	var title_label := _make_label(str(item.get("title", "")), 26, label_color)
	title_label.position = Vector3(0.0, 0.5, 0.0)
	root.add_child(title_label)

	var verdict := str(item.get("verdict", "")).strip_edges()
	var stars := int(item.get("stars", 0))
	var meta_line := "%s  %s" % [_star_string(stars), verdict]
	var meta_label := _make_label(meta_line.strip_edges(), 22, Color(0.78, 0.80, 0.84))
	meta_label.position = Vector3(0.0, 0.25, 0.0)
	root.add_child(meta_label)

	if has_live:
		var live_pedestal := MeshInstance3D.new()
		var ped_mesh := CylinderMesh.new()
		ped_mesh.top_radius = 0.22
		ped_mesh.bottom_radius = 0.28
		ped_mesh.height = 0.24
		live_pedestal.mesh = ped_mesh
		live_pedestal.position = Vector3(0.0, 0.12, 0.62)
		live_pedestal.material_override = _solid_material(Color(0.20, 0.21, 0.24))
		root.add_child(live_pedestal)

		var live_object := _build_live_variant(item)
		if live_object:
			live_object.position = Vector3(0.0, 0.24, 0.62)
			root.add_child(live_object)

	return root


func _fit_size(texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2(max_panel_width, max_panel_height)

	var w: float = max(1.0, float(texture.get_width()))
	var h: float = max(1.0, float(texture.get_height()))
	var aspect: float = w / h
	var size := Vector2(max_panel_width, max_panel_width / aspect)
	if size.y > max_panel_height:
		size.y = max_panel_height
		size.x = max_panel_height * aspect
	return size


func _make_label(text_value: String, font_size: int, color_value: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text_value
	label.font_size = font_size
	label.pixel_size = 0.0011
	label.width = 900
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = color_value
	label.outline_size = 5
	label.outline_modulate = Color(0.04, 0.04, 0.05, 0.95)
	return label


func _solid_material(color_value: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_value
	mat.roughness = 0.85
	mat.metallic = 0.05
	return mat


func _image_material(texture: Texture2D) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	if texture:
		mat.albedo_texture = texture
		mat.emission_texture = texture
	mat.emission_energy_multiplier = 0.9
	return mat


func _star_string(stars: int) -> String:
	var count: int = clamp(stars, 0, 5)
	return "*".repeat(count)


func _can_build_live(item: Dictionary) -> bool:
	var live_kind := str(item.get("live_kind", "")).strip_edges()
	var config_path := str(item.get("config_path", "")).strip_edges()
	return not live_kind.is_empty() and not config_path.is_empty() and FileAccess.file_exists(config_path)


func _build_live_variant(item: Dictionary) -> Node3D:
	var live_kind := str(item.get("live_kind", "")).strip_edges()
	var config_path := str(item.get("config_path", "")).strip_edges()
	var cfg := _load_json_dict(config_path)
	if cfg.is_empty():
		return null

	var raw: Node3D = null
	match live_kind:
		"morphology":
			raw = _build_live_morphology(cfg)
		"rd":
			raw = _build_live_rd(cfg)
		"lsystem":
			raw = _build_live_lsystem(cfg)
		"primitive_stack":
			raw = _build_live_primitive_stack(cfg)
		_:
			return null

	if raw == null:
		return null
	return _fit_live_node(raw, live_object_size)


func _load_json_dict(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var parsed := JSON.new()
	if parsed.parse(text) != OK or not (parsed.data is Dictionary):
		return {}
	return parsed.data


func _build_live_morphology(cfg: Dictionary) -> Node3D:
	var sim := MorphologySim.new()
	var result: Dictionary = sim.simulate(cfg)
	var mesh: ArrayMesh = result.get("mesh")
	var mesh_data = result.get("mesh_data")
	if mesh == null or mesh.get_surface_count() == 0 or mesh_data == null:
		return null

	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var surface_names: Array = result.get("surface_names", [])
	for i in range(surface_names.size()):
		mi.set_surface_override_material(i, _morphology_material(_role_name(str(surface_names[i]))))
	root.add_child(mi)
	return root


func _role_name(tag: String) -> String:
	return tag.trim_prefix("role:")


func _morphology_material(role: String) -> Material:
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.72
	match role:
		"body", "wall":
			mat.albedo_color = Color(0.76, 0.68, 0.56)
		"cushion":
			mat.albedo_color = Color(0.78, 0.88, 0.92)
		"support":
			mat.albedo_color = Color(0.72, 0.76, 0.82)
			mat.metallic = 0.18
			mat.roughness = 0.28
		"garment":
			mat.albedo_color = Color(0.88, 0.33, 0.62)
			mat.roughness = 0.46
		"hair":
			mat.albedo_color = Color(0.91, 0.78, 0.30)
		"heel":
			mat.albedo_color = Color(0.15, 0.14, 0.18)
			mat.roughness = 0.34
		"ornament":
			mat.albedo_color = Color(0.52, 0.84, 0.86)
			mat.metallic = 0.12
			mat.roughness = 0.26
		"trunk", "branch":
			mat.albedo_color = Color(0.42, 0.28, 0.17)
			mat.roughness = 0.88
		"tip":
			mat.albedo_color = Color(0.36, 0.63, 0.31)
		"aperture":
			mat.albedo_color = Color(0.16, 0.19, 0.24)
			mat.roughness = 0.92
		"cap":
			mat.albedo_color = Color(0.63, 0.24, 0.18)
			mat.roughness = 0.78
		_:
			mat.albedo_color = Color(0.78, 0.78, 0.82)
	return mat


func _build_live_rd(cfg: Dictionary) -> Node3D:
	var n: int = int(cfg.get("grid_size", 96))
	var field: PackedFloat32Array = RDSim.simulate(cfg)
	var world_size: float = float(cfg.get("world_size", 3.0))
	var color_lo := _cfg_color(cfg.get("color_lo", [0.15, 0.2, 0.3]), Color(0.15, 0.2, 0.3))
	var color_hi := _cfg_color(cfg.get("color_hi", [0.9, 0.8, 0.5]), Color(0.9, 0.8, 0.5))
	var mode := str(cfg.get("render_mode", "heightmap"))
	match mode:
		"plate":
			return _build_rd_plate(field, n, color_lo, color_hi, world_size)
		"pillars":
			return _build_rd_pillars(field, n, color_lo, color_hi, world_size, float(cfg.get("threshold", 0.25)))
		_:
			return _build_rd_heightmap(field, n, color_lo, color_hi, world_size, float(cfg.get("height_amp", 0.8)))


func _cfg_color(raw: Variant, fallback: Color) -> Color:
	if raw is Array and raw.size() >= 3:
		return Color(float(raw[0]), float(raw[1]), float(raw[2]))
	return fallback


func _build_rd_heightmap(field: PackedFloat32Array, n: int, color_lo: Color, color_hi: Color, world_size: float, amp: float) -> MeshInstance3D:
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var cell: float = world_size * 2.0 / float(n - 1)
	for iy in n:
		for ix in n:
			var x: float = -world_size + float(ix) * cell
			var z: float = -world_size + float(iy) * cell
			var h: float = field[iy * n + ix] * amp
			verts.append(Vector3(x, h, z))
			var t: float = clampf(field[iy * n + ix] * 2.0, 0.0, 1.0)
			colors.append(color_lo.lerp(color_hi, t))
	for iy in n - 1:
		for ix in n - 1:
			var i0: int = iy * n + ix
			var i1: int = iy * n + ix + 1
			var i2: int = (iy + 1) * n + ix + 1
			var i3: int = (iy + 1) * n + ix
			indices.append_array([i0, i1, i2, i0, i2, i3])

	var normals := PackedVector3Array()
	normals.resize(verts.size())
	for i in normals.size():
		normals[i] = Vector3.ZERO
	for k in indices.size() / 3:
		var ia: int = indices[k * 3]
		var ib: int = indices[k * 3 + 1]
		var ic: int = indices[k * 3 + 2]
		var normal: Vector3 = (verts[ib] - verts[ia]).cross(verts[ic] - verts[ia])
		if normal.length_squared() > 1e-12:
			normal = normal.normalized()
		normals[ia] += normal
		normals[ib] += normal
		normals[ic] += normal
	for i in normals.size():
		normals[i] = normals[i].normalized() if normals[i].length_squared() > 1e-12 else Vector3.UP

	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mi := MeshInstance3D.new()
	mi.mesh = am
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.55
	mi.material_override = mat
	return mi


func _build_rd_plate(field: PackedFloat32Array, n: int, color_lo: Color, color_hi: Color, world_size: float) -> MeshInstance3D:
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var cell: float = world_size * 2.0 / float(n - 1)
	for iy in n:
		for ix in n:
			var x: float = -world_size + float(ix) * cell
			var z: float = -world_size + float(iy) * cell
			verts.append(Vector3(x, 0.0, z))
			var t: float = clampf(field[iy * n + ix] * 2.0, 0.0, 1.0)
			colors.append(color_lo.lerp(color_hi, t))
	for iy in n - 1:
		for ix in n - 1:
			var i0: int = iy * n + ix
			var i1: int = iy * n + ix + 1
			var i2: int = (iy + 1) * n + ix + 1
			var i3: int = (iy + 1) * n + ix
			indices.append_array([i0, i1, i2, i0, i2, i3])

	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mi := MeshInstance3D.new()
	mi.mesh = am
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	return mi


func _build_rd_pillars(field: PackedFloat32Array, n: int, color_lo: Color, color_hi: Color, world_size: float, threshold: float) -> MultiMeshInstance3D:
	var cells: Array = []
	for iy in n:
		for ix in n:
			var value: float = field[iy * n + ix]
			if value > threshold:
				cells.append([ix, iy, value])

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	cyl.radial_segments = 6
	mm.mesh = cyl
	mm.instance_count = cells.size()

	var cell: float = world_size * 2.0 / float(n - 1)
	for i in cells.size():
		var entry: Array = cells[i]
		var ix: int = entry[0]
		var iy: int = entry[1]
		var value: float = entry[2]
		var x: float = -world_size + float(ix) * cell
		var z: float = -world_size + float(iy) * cell
		var height: float = maxf(0.06, value * 1.25)
		var t := Transform3D(Basis().scaled(Vector3(cell * 0.22, height, cell * 0.22)), Vector3(x, height * 0.5, z))
		mm.set_instance_transform(i, t)
		mm.set_instance_color(i, color_lo.lerp(color_hi, clampf(value * 2.0, 0.0, 1.0)))

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.42
	mmi.material_override = mat
	return mmi


func _build_live_lsystem(cfg: Dictionary) -> Node3D:
	var axiom := str(cfg.get("axiom", "F"))
	var rules: Dictionary = cfg.get("rules", {})
	var iterations: int = int(cfg.get("iterations", 4))
	var seed: int = int(cfg.get("seed", 0))
	var rewritten: String
	if _has_stochastic_rules(rules):
		rewritten = LSystemSim.rewrite_stochastic(axiom, rules, iterations, seed)
	else:
		rewritten = LSystemSim.rewrite(axiom, rules, iterations)

	var turtle_params := {
		"angle_deg": float(cfg.get("angle_deg", 25.7)),
		"step_len": float(cfg.get("step_len", 0.1)),
		"step_shrink": float(cfg.get("step_shrink", 0.72)),
		"base_width": float(cfg.get("base_width", 0.02)),
		"width_shrink": float(cfg.get("width_shrink", 0.75)),
		"perturb": float(cfg.get("perturb", 0.0)),
		"seed": seed,
	}
	var walk: Dictionary = LSystemTurtle.walk(rewritten, turtle_params)
	var trunk := _cfg_color(cfg.get("color_trunk", [0.45, 0.28, 0.12]), Color(0.45, 0.28, 0.12))
	var tip := _cfg_color(cfg.get("color_tip", [0.20, 0.65, 0.15]), Color(0.20, 0.65, 0.15))
	var mode := str(cfg.get("interpretation", "lines"))
	match mode:
		"tubes":
			return LSystemTurtle.to_tubes(walk, trunk, tip, int(cfg.get("tube_sides", 6)))
		_:
			return LSystemTurtle.to_lines(walk, trunk, tip)


func _has_stochastic_rules(rules: Dictionary) -> bool:
	for key in rules.keys():
		if rules[key] is Array:
			return true
	return false


func _build_live_primitive_stack(cfg: Dictionary) -> Node3D:
	var stack: Node3D = PrimitiveStackScript.build(cfg)
	var post_ops: Array = cfg.get("post_ops", [])
	if post_ops.size() > 0:
		var positions := PackedVector3Array()
		var children: Array = []
		for child in stack.get_children():
			if child is Node3D:
				children.append(child)
				positions.append((child as Node3D).position)
		positions = NoiseDisplacePS.apply_post_ops(positions, post_ops)
		for i in children.size():
			(children[i] as Node3D).position = positions[i]
	return stack


func _fit_live_node(node: Node3D, target_size: float) -> Node3D:
	var wrapper := Node3D.new()
	wrapper.name = "LiveObject"
	wrapper.add_child(node)
	var aabb := _combined_aabb(node)
	var max_dim := maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	if max_dim > 0.0001:
		var scale_factor: float = target_size / max_dim
		node.scale = Vector3.ONE * scale_factor
		aabb = _combined_aabb(node)
	var center := aabb.get_center()
	node.position -= Vector3(center.x, aabb.position.y, center.z)
	return wrapper


func _combined_aabb(node: Node3D) -> AABB:
	var first := true
	var total := AABB()
	var stack: Array = [node]
	while not stack.is_empty():
		var current = stack.pop_back()
		if current is MeshInstance3D and current.mesh:
			var ab: AABB = current.global_transform * current.get_aabb()
			if first:
				total = ab
				first = false
			else:
				total = total.merge(ab)
		elif current is MultiMeshInstance3D and current.multimesh and current.multimesh.mesh:
			var mm_mesh: Mesh = current.multimesh.mesh
			var mm_aabb: AABB = current.global_transform * mm_mesh.get_aabb()
			if first:
				total = mm_aabb
				first = false
			else:
				total = total.merge(mm_aabb)
		for child in current.get_children():
			if child is Node3D:
				stack.append(child)
	if first:
		return AABB(Vector3(-0.2, 0.0, -0.2), Vector3(0.4, 0.4, 0.4))
	return total
