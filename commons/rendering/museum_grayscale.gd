extends Node
## A hall-local presentation. Keep the live source materials: scripts still own
## their animation/state. Only their displayed copies lose chroma; other halls
## sharing those sources keep their colour. No transforms or collisions change.

var _materials: Dictionary = {}
var _live_materials: Dictionary = {}
var _shaders: Dictionary = {}
var _textures: Dictionary = {}
var _visuals: Array[GeometryInstance3D] = []
var _labels: Array[Label3D] = []
var _lights: Array[Light3D] = []
var _properties: Dictionary = {}
var _last_source: Dictionary = {}
var _last_display: Dictionary = {}
var _rescan_elapsed := 0.0
const LIVE_STANDARD := ["albedo_color", "emission", "emission_enabled", "emission_energy_multiplier", "roughness", "metallic", "albedo_texture", "emission_texture", "uv1_offset", "uv1_scale", "grow_amount"]

func _ready() -> void:
	process_priority = 10000 # After artifact updates, before rendering.
	get_tree().node_added.connect(_added)
	_scan(get_parent())

func _added(node: Node) -> void:
	if get_parent().is_ancestor_of(node):
		_register.call_deferred(node)

func _scan(node: Node) -> void:
	_register(node)
	for child in node.get_children():
		_scan(child)

func _register(node: Variant) -> void:
	if not is_instance_valid(node): return
	if node is Label3D:
		if not node in _labels: _labels.append(node)
	elif node is GeometryInstance3D:
		if _is_live_visual(node) and not node in _visuals: _visuals.append(node)
	if node is Light3D and not node in _lights: _lights.append(node)
	_update_node(node)

static func gray(colour: Color) -> Color:
	var value := colour.r * 0.2126 + colour.g * 0.7152 + colour.b * 0.0722
	return Color(value, value, value, colour.a)

func _process(_delta: float) -> void:
	# Artifacts can replace a material, regenerate a surface or update uniforms
	# without emitting Resource.changed. Keep those live links, including trails.
	for pair in _live_materials.values():
		if pair[0] is ShaderMaterial:
			_sync_shader(pair[0], pair[1])
		elif pair[0] is BaseMaterial3D:
			_sync_standard(pair[0], pair[1])
	# node_added handles construction immediately. Poll only for the uncommon
	# replacement of a material on an already existing mesh, not every VR frame.
	_rescan_elapsed += _delta
	if _rescan_elapsed < 0.2: return
	_rescan_elapsed = 0.0
	for i in range(_visuals.size() - 1, -1, -1):
		if not is_instance_valid(_visuals[i]): _visuals.remove_at(i)
		else: _update_node(_visuals[i])
	for i in range(_labels.size() - 1, -1, -1):
		if not is_instance_valid(_labels[i]): _labels.remove_at(i)
		else:
			_labels[i].modulate = gray(_labels[i].modulate)
			_labels[i].outline_modulate = gray(_labels[i].outline_modulate)
	for i in range(_lights.size() - 1, -1, -1):
		if not is_instance_valid(_lights[i]): _lights.remove_at(i)
		else: _lights[i].light_color = gray(_lights[i].light_color)

func _is_live_visual(node: Node) -> bool:
	# Architecture and the grid's thousands of stationary cube surfaces do not
	# animate their materials. Watch artifact/utility branches, not the building.
	var ancestor := node
	while ancestor != null and ancestor != get_parent():
		if ancestor.get_script() != null:
			var path: String = ancestor.get_script().resource_path
			for prefix in ["res://commons/artifacts/", "res://algorithms/", "res://commons/movement/", "res://commons/hazards/", "res://commons/utilities/", "res://commons/primitives/translation/", "res://commons/scenes/mapobjects/"]:
				if path.begins_with(prefix): return true
		ancestor = ancestor.get_parent()
	return false

func _update_node(node: Node) -> void:
	if node is Label3D: return # Font rendering belongs to Godot.
	var live := _is_live_visual(node)
	if node is GeometryInstance3D:
		if node.material_override != null:
			var material := _display(node.material_override, live)
			if material != node.material_override: node.material_override = material
		if node.material_overlay != null:
			var overlay := _display(node.material_overlay, live)
			if overlay != node.material_overlay: node.material_overlay = overlay
	if node is MeshInstance3D and node.mesh != null and node.material_override == null:
		for surface in node.mesh.get_surface_count():
			var material: Material = node.get_surface_override_material(surface)
			if material == null: material = node.mesh.surface_get_material(surface)
			if material != null:
				var display := _display(material, live)
				if display != node.get_surface_override_material(surface): node.set_surface_override_material(surface, display)
	elif node is MultiMeshInstance3D and node.multimesh != null and node.multimesh.mesh != null and node.material_override == null:
		# These batched exhibits use a single surface material.
		var mesh: Mesh = node.multimesh.mesh
		if mesh.get_surface_count() == 1:
			node.material_override = _display(mesh.surface_get_material(0), live)
	elif node is CSGPrimitive3D and node.material != null:
		var material := _display(node.material, live)
		if material != node.material: node.material = material

func _display(source: Material, live: bool = true) -> Material:
	if source == null: return source
	if source.get_meta("museum_grayscale", false):
		if live:
			var original_id: int = source.get_meta("museum_grayscale_source")
			if _materials.has(original_id): _live_materials[original_id] = _materials[original_id]
		return source
	var id := source.get_instance_id()
	if _materials.has(id):
		if live: _live_materials[id] = _materials[id]
		return _materials[id][1]
	var display: Material = source.duplicate()
	display.set_meta("museum_grayscale", true)
	display.set_meta("museum_grayscale_source", id)
	_materials[id] = [source, display]
	if live: _live_materials[id] = _materials[id]
	_last_source[id] = {}
	_last_display[id] = {}
	if source is BaseMaterial3D:
		_properties[id] = LIVE_STANDARD
		_sync_standard(source, display)
	elif source is ShaderMaterial:
		display.shader = _gray_shader(source.shader)
		_properties[id] = []
		if source.shader != null:
			for uniform in source.shader.get_shader_uniform_list(): _properties[id].append(uniform.name)
		_sync_shader(source, display)
	if source.next_pass != null: display.next_pass = _display(source.next_pass, live)
	return display

func _sync_standard(source: BaseMaterial3D, display: BaseMaterial3D) -> void:
	var id := source.get_instance_id()
	var previous_source: Dictionary = _last_source[id]
	var previous_display: Dictionary = _last_display[id]
	for key in _properties[id]:
		var source_value: Variant = source.get(key)
		var display_value: Variant = display.get(key)
		var value: Variant
		if not previous_source.has(key) or previous_source[key] != source_value:
			value = source_value
		elif previous_display[key] != display_value:
			# Some artifacts retain their source; others fetch material_override
			# each frame. Accept both without writing back to shared resources.
			value = display_value
		else: continue
		if value is Color: value = gray(value)
		elif key in ["albedo_texture", "emission_texture"] and value is Texture2D:
			value = _gray_texture(value)
		if display_value != value: display.set(key, value)
		previous_source[key] = source_value
		previous_display[key] = value

func _gray_texture(source: Texture2D) -> Texture2D:
	if source is ViewportTexture: return source # Dynamic screens use their own shader.
	var id := source.get_instance_id()
	if _textures.has(id): return _textures[id]
	var picture := source.get_image()
	if picture == null or picture.is_empty(): return source
	if picture.is_compressed(): picture.decompress()
	picture.convert(Image.FORMAT_RGBA8)
	for y in picture.get_height():
		for x in picture.get_width(): picture.set_pixel(x, y, gray(picture.get_pixel(x, y)))
	var texture := ImageTexture.create_from_image(picture)
	_textures[id] = texture
	return texture

func _sync_shader(source: ShaderMaterial, display: ShaderMaterial) -> void:
	if source.shader == null: return
	var id := source.get_instance_id()
	var previous_source: Dictionary = _last_source[id]
	for key in _properties[id]:
		var value: Variant = source.get_shader_parameter(key)
		if not previous_source.has(key) or previous_source[key] != value:
			if display.get_shader_parameter(key) != value: display.set_shader_parameter(key, value)
			previous_source[key] = value

func _gray_shader(source: Shader) -> Shader:
	if source == null: return null
	var id := source.get_instance_id()
	if _shaders.has(id): return _shaders[id]
	var code := source.code
	# Remove comments before locating braces. Preserve all operations and timing
	# inside vertex/fragment; convert only their final surface colours.
	var comments := RegEx.new()
	comments.compile("(?s)/\\*.*?\\*/|//[^\\n]*")
	code = comments.sub(code, "", true)
	var fragment := code.find("void fragment()")
	if fragment < 0: fragment = code.find("void fragment ()")
	if fragment < 0 or not "shader_type spatial" in code: return source
	var start := code.find("{", fragment)
	var end := start + 1
	var depth := 1
	while end < code.length() and depth > 0:
		if code[end] == "{": depth += 1
		elif code[end] == "}": depth -= 1
		end += 1
	var neutral := "\nALBEDO = vec3(dot(ALBEDO, vec3(0.2126, 0.7152, 0.0722)));\nEMISSION = vec3(dot(EMISSION, vec3(0.2126, 0.7152, 0.0722)));\n"
	var body := code.substr(start + 1, end - start - 2)
	body = body.replace("return;", neutral + "return;")
	var shader := Shader.new()
	shader.code = code.left(start + 1) + body + neutral + code.substr(end - 1)
	_shaders[id] = shader
	return shader
