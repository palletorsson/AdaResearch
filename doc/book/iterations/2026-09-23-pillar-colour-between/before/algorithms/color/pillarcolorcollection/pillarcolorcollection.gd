extends Node3D

# @identity
# essence: pillar_grid(rows, cols) colored from palette[i % palette.size()] — vertical color swatches as architectural columns
# desire: to walk a colonnade where each pillar is a different color, feeling palette relationships through spatial rhythm
# critical_parameter: current_palette_index — cycling palettes transforms the colonnade's mood while the geometry stays fixed
# triggers: cycle_to_next_palette() regenerates all pillars with the next palette; GameManager provides gradient palettes
# emerges: the grid layout creates sight-lines through columns where distant pillars optically mix with near ones
# needs: palette cycling [has]; pillar.tscn prefab [has]; VR palette selector [missing]; Label3D [missing]
# relationships: depends on color_palettes.tres and pillar.tscn; contrasts with brick_wall_factory (horizontal vs vertical); feeds into color_sets_overview (structured vs grabbable)
# truth: a column of color has gravity that a flat swatch does not — verticality makes color feel like it stands for something

const PILLAR_SCENE = preload("res://commons/primitives/pillar/pillar.tscn")
const DEFAULT_PALETTE_PATH := "res://algorithms/color/color_palettes.tres"

@export var color_palette_resource: Resource
@export var columns: int = 3
@export var rows: int = 8
@export var spacing: Vector3 = Vector3(2.0, 0.0, 2.0)
@export var origin_offset: Vector3 = Vector3.ZERO
@export var default_palette: String = "rainbow_gradient"

var palette_keys: Array = []
var current_palette_index: int = 0
var spatial_gradient := false

func _ready() -> void:
	spatial_gradient = str(get_meta("config_layout", "")) == "spatial_gradient"
	if spatial_gradient:
		_build_spatial_gradient()
		return
	_ensure_palette_resource()
	palette_keys = _collect_palette_keys()
	if palette_keys.is_empty():
		push_warning("PillarColorCollection: No color palettes available")
		return
		
	# Find default palette index
	var idx = palette_keys.find(default_palette)
	if idx != -1:
		current_palette_index = idx
		
	_spawn_pillars()

func _ensure_palette_resource() -> void:
	if color_palette_resource != null:
		return
	if ResourceLoader.exists(DEFAULT_PALETTE_PATH):
		color_palette_resource = ResourceLoader.load(DEFAULT_PALETTE_PATH)
	else:
		push_warning("PillarColorCollection: Palette resource not found at %s" % DEFAULT_PALETTE_PATH)

func _collect_palette_keys() -> Array:
	var keys = []
	
	# 1. From Resource
	var palettes_dict = _get_palettes_dict()
	if not palettes_dict.is_empty():
		keys.append_array(palettes_dict.keys())
		
	# 2. From GameManager
	var gradient_names = GameManager.get_all_gradient_names()
	keys.append_array(gradient_names)
	
	return keys

func _get_palettes_dict() -> Dictionary:
	if color_palette_resource and "palettes" in color_palette_resource:
		var palettes = color_palette_resource.palettes
		if typeof(palettes) == TYPE_DICTIONARY:
			return palettes
	return {}

func _get_palette_entry(palette_name: String) -> Dictionary:
	var palettes_dict = _get_palettes_dict()
	if palettes_dict.has(palette_name):
		return palettes_dict[palette_name]
	return {}

func _get_palette_colors(palette_name: String) -> Array:
	# 1. Check Resource
	var entry = _get_palette_entry(palette_name)
	if not entry.is_empty():
		var source = entry.get("colors", [])
		var result: Array = []
		for value in source:
			if value is Color:
				result.append(value)
		return result
		
	# 2. Check GameManager
	var gradients = GameManager.get_gradient_palette(palette_name)
	if not gradients.is_empty() and gradients[0] != Color.WHITE: # simplistic check
		return gradients
		
	return []

func _get_palette_title(palette_name: String) -> String:
	var entry = _get_palette_entry(palette_name)
	return entry.get("title", palette_name)

func _spawn_pillars() -> void:
	_clear_existing_pillars()
	if palette_keys.is_empty():
		return

	var current_key = palette_keys[current_palette_index % palette_keys.size()]
	var colors = _get_palette_colors(current_key)
	if colors.is_empty():
		push_warning("PillarColorCollection: Palette '%s' has no colors" % current_key)
		return

	var color_index := 0
	for row in range(rows):
		for column in range(columns):
			var pillar_instance = PILLAR_SCENE.instantiate()
			pillar_instance.name = "Pillar_%d_%d" % [row, column]

			var position = origin_offset + Vector3(column * spacing.x, 0.0, row * spacing.z)
			pillar_instance.position = position

			var color = colors[color_index % colors.size()]
			_apply_color_to_pillar(pillar_instance, color)
			add_child(pillar_instance)
			color_index += 1

	print("PillarColorCollection: Spawned %d pillars using palette '%s'" % [rows * columns, _get_palette_title(current_key)])

func _clear_existing_pillars() -> void:
	for child in get_children():
		if child.name.begins_with("Pillar_"):
			child.queue_free()

func _apply_color_to_pillar(pillar_instance: Node3D, color: Color) -> void:
	# Keep the footer/base black and color only the column
	var footer: MeshInstance3D = _find_named_mesh_instance(pillar_instance, "Footer")
	var column: MeshInstance3D = _find_named_mesh_instance(pillar_instance, "Column")

	if footer:
		var foot_mat := footer.get_active_material(0)
		if not (foot_mat is StandardMaterial3D):
			foot_mat = StandardMaterial3D.new()
		var base_mat := foot_mat as StandardMaterial3D
		base_mat.albedo_color = Color(0.05, 0.05, 0.05)
		base_mat.metallic = 0.3
		base_mat.roughness = 0.6
		footer.material_override = base_mat

	if column:
		var col_mat := StandardMaterial3D.new()
		col_mat.albedo_color = color
		col_mat.metallic = 0.05
		col_mat.roughness = 0.35
		col_mat.emission_enabled = true
		col_mat.emission = color * 0.1
		column.material_override = col_mat
	elif not footer:
		# fallback: color first mesh found
		var any_mesh := _find_mesh_instance(pillar_instance)
		if any_mesh:
			var material = StandardMaterial3D.new()
			material.albedo_color = color
			material.metallic = 0.05
			material.roughness = 0.35
			material.emission_enabled = true
			material.emission = color * 0.1
			any_mesh.material_override = material

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found = _find_mesh_instance(child)
		if found:
			return found
	return null

func _find_named_mesh_instance(node: Node, target_name: String) -> MeshInstance3D:
	if node is MeshInstance3D and node.name == target_name:
		return node
	for child in node.get_children():
		var found = _find_named_mesh_instance(child, target_name)
		if found:
			return found
	return null

func regenerate_pillars() -> void:
	if spatial_gradient:
		_build_spatial_gradient()
		return
	_spawn_pillars()

func cycle_to_next_palette() -> void:
	if spatial_gradient:
		return # This installation samples position, not the named palette carousel.
	if palette_keys.is_empty():
		return
	current_palette_index = (current_palette_index + 1) % palette_keys.size()
	_spawn_pillars()

func get_current_palette_name() -> String:
	if palette_keys.is_empty():
		return "No Palette"
	var current_key = palette_keys[current_palette_index % palette_keys.size()]
	return _get_palette_title(current_key)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	if str(config.get("layout", "")) == "spatial_gradient" and not spatial_gradient:
		spatial_gradient = true
		if is_node_ready(): _build_spatial_gradient()

func sample_space(p: Vector3) -> Color:
	var u := clampf(p.x / 12.8, 0.0, 1.0)
	var v := clampf(p.z / 19.2, 0.0, 1.0)
	return Color.from_hsv(u * 0.85, lerpf(0.25,1.0,v),0.95)

func _build_spatial_gradient() -> void:
	for child in get_children():
		if child is Camera3D: continue
		remove_child(child); child.queue_free()
	columns = 5; rows = 7; spacing = Vector3(3.2,0,3.2)
	for row in range(rows):
		for column in range(columns):
			var pillar := PILLAR_SCENE.instantiate()
			pillar.name = "Pillar_%d_%d" % [row,column]
			pillar.position = Vector3(column*spacing.x,0,row*spacing.z)
			pillar.scale = Vector3.ONE*1.15
			var color := sample_space(pillar.position)
			_apply_color_to_pillar(pillar,color)
			pillar.set_meta("sample_color",color)
			add_child(pillar)
			var label := Label3D.new(); label.name = "SampleAddress"
			label.text = "(%d, %d)\n#%s" % [column,row,color.to_html(false)]
			label.font_size = 30; label.pixel_size = 0.004; label.position = Vector3(0,1.1,-0.42)
			label.rotation.y = PI; pillar.add_child(label)
	# The floor and the pillars evaluate exactly the same hue/saturation field.
	var mesh := PlaneMesh.new(); mesh.size = Vector2(12.8,19.2)
	var floor := MeshInstance3D.new(); floor.name = "ContinuousGradient"; floor.mesh = mesh
	floor.position = Vector3(6.4,0.026,9.6)
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded, cull_disabled; void fragment(){ vec3 p=abs(fract(vec3(UV.x*0.85)+vec3(0.0,2.0/3.0,1.0/3.0))*6.0-3.0); ALBEDO=0.95*mix(vec3(1.0),clamp(p-1.0,0.0,1.0),mix(0.25,1.0,UV.y)); }"
	var mat := ShaderMaterial.new(); mat.shader = shader; floor.material_override = mat; add_child(floor)
	set_meta("em_visibility_bounds",AABB(Vector3(-1,0,-1),Vector3(15,5,22)))
