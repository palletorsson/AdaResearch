## LibraryRack — Universal collection display wall.
## Reads any artifact registry JSON and builds a grid of cubes,
## each containing a scaled-down artifact scene or a shader cube.
##
## Config keys (via map JSON #hash syntax):
##   collection     – registry filename without .json (e.g. "shaders", "primitives")
##   filter         – substring to match in name, category, or tags
##   sort           – "alpha", "category", or "default" (registry order)
##   cols / columns – cubes across (default 6)
##   rows           – cubes high (default 4)
##   cube_size      – size of each slot (default 0.7)
##   gap            – spacing between slots (default 0.12)
##   title          – override display title
##   label_visible  – show labels (default true)

# @identity
# essence: library[i] = registry.artifacts[i].scene — a physical index of computational objects
# desire: stand before a wall of everything the system can make, organized and labeled
# critical_parameter: the collection key — one word selects which registry to display
# triggers: apply_grid_config reads collection, loads registry, builds wall of instanced scenes
# emerges: a periodic table for any domain — shaders, primitives, patterns, hazards, math objects
# truth: a library is not the objects — it is the act of organizing them so they can be found

extends Node3D
class_name LibraryRack


# Spine-corridor contract — the library rack instantiates an entire artifact
# registry as children (default 6x4 = 24 scenes), each a full artifact scene
# with its own init cost. ~14m tall, hundreds of nodes. Never fits a corridor.
func spine_hints() -> Dictionary:
	return {
		"role":         "primary",
		"footprint":    Vector2i(3, 4),
		"approach":     "south",
		"reading_dist": 2.0,
		"budget_ms":    8.0,
		"tags":         ["oversized", "corridor_incompatible", "gallery"],
	}


@export var columns: int = 6
@export var rows: int = 4
@export var cube_size: float = 1.0
@export var gap: float = 0.0
@export var label_visible: bool = true

var _collection_name: String = ""
var _filter: String = ""
var _sort_mode: String = "default"
var _title_override: String = ""
var _layout_file: String = ""  # Override layout filename (default: rack_layout.json)
var _entries: Array[Dictionary] = []  # [{name, lookup_name, category, scene, tags, description}]
var _slot_nodes: Array[Node3D] = []


func _ready() -> void:
	# Wall is built after apply_grid_config sets the collection
	pass


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("collection"):
		_collection_name = str(config_data["collection"]).strip_edges()
	if config_data.has("filter"):
		_filter = str(config_data["filter"]).strip_edges().to_lower()
	if config_data.has("sort"):
		_sort_mode = str(config_data["sort"]).strip_edges().to_lower()
	if config_data.has("title"):
		_title_override = str(config_data["title"]).strip_edges()
	if config_data.has("cols"):
		columns = clampi(int(config_data["cols"]), 1, 12)
	if config_data.has("columns"):
		columns = clampi(int(config_data["columns"]), 1, 12)
	if config_data.has("rows"):
		rows = clampi(int(config_data["rows"]), 1, 8)
	if config_data.has("cube_size"):
		cube_size = clampf(float(config_data["cube_size"]), 0.3, 2.0)
	if config_data.has("gap"):
		gap = clampf(float(config_data["gap"]), 0.0, 1.0)
	if config_data.has("label_visible"):
		label_visible = str(config_data["label_visible"]).to_lower() != "false"
	if config_data.has("layout"):
		_layout_file = str(config_data["layout"]).strip_edges()

	if _collection_name != "":
		# Try to load a rack_layout.json from the current map directory
		var layout_loaded := _try_load_layout()
		if not layout_loaded:
			_load_collection()
		_build_wall()
	else:
		print("[LibraryRack] No collection specified")


# ═══════════════════════════════════════════════════════════════════
# LOAD LAYOUT FILE (curated selection with nulls for holes)
# ═══════════════════════════════════════════════════════════════════

func _try_load_layout() -> bool:
	# Find the current map name from the GridSystem parent
	var map_name := ""
	var parent := get_parent()
	while parent:
		if parent.get("map_name") != null:
			map_name = str(parent.get("map_name"))
			break
		parent = parent.get_parent()
	if map_name == "":
		return false

	var layout_filename := _layout_file if _layout_file != "" else "rack_layout.json"
	var layout_path := "res://commons/maps/%s/%s" % [map_name, layout_filename]
	if not FileAccess.file_exists(layout_path):
		return false

	var file := FileAccess.open(layout_path, FileAccess.READ)
	if not file:
		return false
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return false

	var data: Dictionary = json.data

	# Override config from layout
	if data.has("collection"):
		_collection_name = str(data["collection"])
	if data.has("cols"):
		columns = int(data["cols"])
	if data.has("rows"):
		rows = int(data["rows"])
	if data.has("title"):
		_title_override = str(data["title"])

	var slots: Array = data.get("slots", [])
	if slots.is_empty():
		return false

	# Load the full registry to resolve lookup names
	var all_artifacts: Dictionary = _load_registry_dict()

	# Build entries from layout — null = empty slot (hole)
	_entries.clear()
	for row_idx in range(slots.size()):
		var row: Array = slots[row_idx] if slots[row_idx] is Array else []
		for col_idx in range(row.size()):
			var val = row[col_idx]
			if val == null or val == "":
				_entries.append({"name": "", "lookup_name": "", "category": "", "scene": "", "description": "", "tags": [], "is_shader": false, "_empty": true})
			elif str(val).begins_with("res://") and str(val).ends_with(".gdshader"):
				# Direct shader path
				var shader_path := str(val)
				var shader_name := shader_path.get_file().get_basename()
				_entries.append({"name": shader_name, "lookup_name": shader_name, "category": "shader", "scene": shader_path, "description": "", "tags": [], "is_shader": true, "_empty": false, "_shader_path": shader_path})
			else:
				var lookup := str(val)
				if all_artifacts.has(lookup):
					var art: Dictionary = all_artifacts[lookup]
					_entries.append({
						"name": str(art.get("name", lookup)),
						"lookup_name": lookup,
						"category": str(art.get("category", "")),
						"scene": str(art.get("scene", "")),
						"description": str(art.get("description", "")),
						"tags": art.get("tags", []),
						"is_shader": _collection_name == "shaders" or str(art.get("scene", "")).ends_with(".gdshader"),
						"_empty": false,
					})
				else:
					# Lookup name not found — show as colored placeholder
					_entries.append({"name": lookup, "lookup_name": lookup, "category": "unknown", "scene": "", "description": "", "tags": [], "is_shader": false, "_empty": false})

	columns = int(data.get("cols", columns))
	rows = int(data.get("rows", rows))
	print("[LibraryRack] Layout loaded: %dx%d from %s (%d entries)" % [columns, rows, layout_path, _entries.size()])
	return true


func _load_registry_dict() -> Dictionary:
	var registry_path := "res://commons/artifacts/registry/%s.json" % _collection_name
	if not FileAccess.file_exists(registry_path):
		return {}
	var file := FileAccess.open(registry_path, FileAccess.READ)
	if not file:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	return json.data.get("artifacts", {})


# ═══════════════════════════════════════════════════════════════════
# LOAD REGISTRY (full collection, no layout file)
# ═══════════════════════════════════════════════════════════════════

func _load_collection() -> void:
	_entries.clear()

	var registry_path := "res://commons/artifacts/registry/%s.json" % _collection_name
	if not FileAccess.file_exists(registry_path):
		print("[LibraryRack] Registry not found: %s" % registry_path)
		return

	var file := FileAccess.open(registry_path, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		print("[LibraryRack] Failed to parse: %s" % registry_path)
		return

	var data: Dictionary = json.data
	var artifacts: Dictionary = data.get("artifacts", {})

	for key in artifacts:
		var art: Dictionary = artifacts[key]
		var entry: Dictionary = {
			"name": str(art.get("name", key)),
			"lookup_name": str(art.get("lookup_name", key)),
			"category": str(art.get("category", "")),
			"scene": str(art.get("scene", "")),
			"description": str(art.get("description", "")),
			"tags": art.get("tags", []),
			"is_shader": _collection_name == "shaders" or str(art.get("scene", "")).ends_with(".gdshader"),
		}

		# Apply filter
		if _filter != "":
			var found := false
			if _filter in entry["name"].to_lower(): found = true
			if _filter in entry["category"].to_lower(): found = true
			if _filter in entry["lookup_name"].to_lower(): found = true
			for tag in entry["tags"]:
				if _filter in str(tag).to_lower(): found = true
			if not found:
				continue

		_entries.append(entry)

	# Sort
	match _sort_mode:
		"alpha":
			_entries.sort_custom(func(a, b): return a["name"].to_lower() < b["name"].to_lower())
		"category":
			_entries.sort_custom(func(a, b): return a["category"] + a["name"] < b["category"] + b["name"])

	print("[LibraryRack] Loaded %d artifacts from %s (filter='%s')" % [_entries.size(), _collection_name, _filter])


# ═══════════════════════════════════════════════════════════════════
# BUILD WALL
# ═══════════════════════════════════════════════════════════════════

func _build_wall() -> void:
	# Clear existing
	for child in get_children():
		child.queue_free()
	_slot_nodes.clear()

	var step := cube_size + gap
	var total_w := float(columns) * step - gap
	var x_offset := -total_w * 0.5 + cube_size * 0.5
	var max_slots := columns * rows

	for idx in range(max_slots):
		var col := idx % columns
		var row := idx / columns
		var x := x_offset + float(col) * step + 0.5
		var y := cube_size * 0.5 + float(row) * step - 0.5
		var z := 0.5

		var slot := Node3D.new()
		slot.name = "Slot_%d" % idx
		slot.position = Vector3(x, y, z)
		add_child(slot)
		_slot_nodes.append(slot)

		if idx < _entries.size():
			var entry: Dictionary = _entries[idx]
			if entry.get("_empty", false):
				_build_empty_slot(slot)
			elif entry.get("_shader_path", "") != "":
				# Direct shader path — load .gdshader onto a 0.8 cube
				_build_shader_cube(slot, entry)
			else:
				_build_filled_slot(slot, entry)
		else:
			_build_empty_slot(slot)

	# Backplate
	_build_backplate()
	# Title
	_build_title()


func _build_filled_slot(slot: Node3D, entry: Dictionary) -> void:
	var scene_path: String = entry["scene"]
	var inner_size: float = cube_size * 0.8

	# For .tscn scenes — instantiate the actual artifact scaled down.
	# Only Node3D roots can live in a 3D shelf slot. Control/Node2D-rooted
	# artifacts (e.g. colorsheets.gd extends Control) would crash on the
	# Vector3 `scale` assignment, so they fall through to the placeholder cube.
	if scene_path.ends_with(".tscn") and ResourceLoader.exists(scene_path):
		var scene := load(scene_path) as PackedScene
		if scene:
			var instance := scene.instantiate()
			if instance is Node3D:
				instance.scale = Vector3.ONE * inner_size
				instance.name = "ArtifactInstance"
				slot.add_child(instance)
				return
			else:
				push_warning("[library_rack] '%s' root is %s, not Node3D — using placeholder cube" % [scene_path, instance.get_class()])
				instance.free()

	# For .gdshader — apply to a cube
	if scene_path.ends_with(".gdshader") and ResourceLoader.exists(scene_path):
		var cube := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * inner_size
		cube.mesh = box
		cube.name = "ShaderCube"
		var shader := load(scene_path) as Shader
		if shader:
			var mat := ShaderMaterial.new()
			mat.shader = shader
			_try_set_param(mat, "emission_strength", 0.6)
			_try_set_param(mat, "u_resolution", Vector2(256, 256))
			cube.material_override = mat
		else:
			_apply_colored_cube(cube, entry)
		slot.add_child(cube)
		return

	# No scene — colored placeholder
	var cube := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * inner_size
	cube.mesh = box
	cube.name = "PlaceholderCube"
	_apply_colored_cube(cube, entry)
	slot.add_child(cube)

	# Collision on the slot itself
	var body := StaticBody3D.new()
	var col_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3.ONE * cube_size
	col_shape.shape = shape
	body.add_child(col_shape)
	slot.add_child(body)

	# Labels
	if label_visible:
		var label := Label3D.new()
		label.text = entry["name"]
		label.font_size = 42
		label.pixel_size = 0.0018
		label.position = Vector3(0, -cube_size * 0.5 - 0.06, cube_size * 0.5 + 0.01)
		label.modulate = Color(0.85, 0.9, 0.85)
		label.outline_modulate = Color(0, 0, 0, 0.8)
		label.outline_size = 6
		slot.add_child(label)

		var cat_label := Label3D.new()
		cat_label.text = entry["category"]
		cat_label.font_size = 28
		cat_label.pixel_size = 0.0014
		cat_label.position = Vector3(0, -cube_size * 0.5 - 0.13, cube_size * 0.5 + 0.01)
		cat_label.modulate = Color(0.4, 0.7, 0.5, 0.6)
		cat_label.outline_modulate = Color(0, 0, 0, 0.5)
		cat_label.outline_size = 4
		slot.add_child(cat_label)


func _build_shader_cube(slot: Node3D, entry: Dictionary) -> void:
	# 0.8 BoxMesh cube with the .gdshader applied directly
	var inner_size: float = cube_size * 0.8
	var shader_path: String = entry.get("_shader_path", "")

	var cube := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * inner_size
	cube.mesh = box
	cube.name = "ShaderCube"

	if shader_path != "" and ResourceLoader.exists(shader_path):
		var shader := load(shader_path) as Shader
		if shader:
			var mat := ShaderMaterial.new()
			mat.shader = shader
			_try_set_param(mat, "emission_strength", 0.6)
			_try_set_param(mat, "u_resolution", Vector2(256, 256))
			cube.material_override = mat
			print("[LibraryRack] Shader cube: %s" % shader_path.get_file())
		else:
			_apply_colored_cube(cube, entry)
	else:
		_apply_colored_cube(cube, entry)

	slot.add_child(cube)

	# Label
	if label_visible:
		var label := Label3D.new()
		label.text = entry["name"]
		label.font_size = 42
		label.pixel_size = 0.0018
		label.position = Vector3(0, -cube_size * 0.5 - 0.06, cube_size * 0.5 + 0.01)
		label.modulate = Color(0.85, 0.9, 0.85)
		label.outline_modulate = Color(0, 0, 0, 0.8)
		label.outline_size = 6
		slot.add_child(label)


func _build_empty_slot(slot: Node3D) -> void:
	# Grid cube at full size (1.0) with the grid shader — matches the grid system
	var cube := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * cube_size  # 1.0 full cell
	cube.mesh = box
	cube.name = "GridCube"

	# Apply the grid shader
	var grid_shader := load("res://commons/resourses/shaders/SimpleGrid.gdshader") as Shader
	if grid_shader:
		var mat := ShaderMaterial.new()
		mat.shader = grid_shader
		mat.set_shader_parameter("modelColor", Color(0.0, 0.0, 0.0, 1.0))
		mat.set_shader_parameter("emissionColor", Color(0.9, 0.9, 0.85, 1.0))
		mat.set_shader_parameter("wireframeColor", Color(0.9, 0.9, 0.85, 1.0))
		mat.set_shader_parameter("emission_strength", 1.5)
		cube.material_override = mat
	else:
		# Fallback if shader not found
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.18, 0.18, 0.22)
		mat.roughness = 0.7
		cube.material_override = mat

	slot.add_child(cube)

	# Collision
	var body := StaticBody3D.new()
	var col_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3.ONE * cube_size
	col_shape.shape = shape
	body.add_child(col_shape)
	cube.add_child(body)


func _apply_colored_cube(mesh: MeshInstance3D, entry: Dictionary) -> void:
	# Generate a deterministic color from the artifact name
	var h := float(hash(entry["name"]) % 360) / 360.0
	var col := Color.from_hsv(h, 0.5, 0.6)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col * 0.5
	mat.emission_energy_multiplier = 0.4
	mat.roughness = 0.3
	mesh.material_override = mat


func _build_backplate() -> void:
	# No backplate — shelf is open from both sides
	pass


func _build_title() -> void:
	var step := cube_size + gap
	var total_h := float(rows) * step
	var display_title: String = _title_override if _title_override != "" else _collection_name.to_upper() + " LIBRARY"
	var title := Label3D.new()
	title.text = display_title
	title.font_size = 64
	title.pixel_size = 0.0028
	title.position = Vector3(0, total_h + 0.12, cube_size * 0.5 + 0.01)
	title.modulate = Color(0.4, 1.0, 0.6)
	title.outline_modulate = Color(0, 0, 0, 0.9)
	title.outline_size = 10
	title.name = "Title"
	add_child(title)

	# Subtitle: count
	var sub := Label3D.new()
	sub.text = "%d / %d slots" % [_entries.size(), columns * rows]
	sub.font_size = 36
	sub.pixel_size = 0.002
	sub.position = Vector3(0, total_h + 0.02, cube_size * 0.5 + 0.01)
	sub.modulate = Color(0.4, 0.6, 0.5, 0.6)
	sub.outline_modulate = Color(0, 0, 0, 0.5)
	sub.outline_size = 6
	sub.name = "Subtitle"
	add_child(sub)


func _try_set_param(mat: ShaderMaterial, param_name: String, value: Variant) -> void:
	if mat.shader:
		for uniform in mat.shader.get_shader_uniform_list():
			if uniform["name"] == param_name:
				mat.set_shader_parameter(param_name, value)
				return


## Extract the first ShaderMaterial from a scene tree
func _extract_shader_material(node: Node) -> Material:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.material_override is ShaderMaterial:
			return mi.material_override.duplicate()
		if mi.mesh and mi.mesh.get_surface_count() > 0:
			var surf_mat: Material = mi.mesh.surface_get_material(0)
			if surf_mat is ShaderMaterial:
				return surf_mat.duplicate()
	for child in node.get_children():
		var result := _extract_shader_material(child)
		if result:
			return result
	return null
