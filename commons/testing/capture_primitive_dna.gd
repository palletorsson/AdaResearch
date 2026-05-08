extends SceneTree

## Batch capture for primitive DNA exploration.
##
## Reads a manifest of variants (one primitive class, many parameter sets),
## renders each into the same lit scene with the SimpleGrid edge-highlight
## material, and saves a single hero-angle screenshot per variant.
##
## Usage:
##   godot --xr-mode off --no-window \
##     --script res://commons/testing/capture_primitive_dna.gd -- \
##     --manifest=user://dna_in/TorusMesh.json \
##     --out=user://primitive_dna_out/TorusMesh
##
## Manifest schema:
## {
##   "primitive": "TorusMesh",
##   "material": { "base_color": [r, g, b, a] },     // optional; defaults to gray
##   "camera": { "yaw_deg": 25.0, "pitch_deg": 25.0, "pad": 1.4 },  // optional
##   "image": { "width": 512, "height": 512 },       // optional; default 512x512
##   "variants": [
##     { "id": "r3_s3", "params": { "rings": 3, "ring_segments": 3, ... } },
##     ...
##   ]
## }
##
## Output: <out>/<variant_id>.png for each variant + summary.json.

const GRID_FACTORY := preload("res://commons/primitives/shared/grid_material_factory.gd")
const PARAMETRIC_GRID_SHADER_PATH := "res://commons/resourses/shaders/ParametricGrid.gdshader"

var _manifest_path: String = ""
var _output_dir: String = "user://primitive_dna_out"
var _yaw_deg: float = 25.0
var _pitch_deg: float = 25.0
var _pad: float = 1.6
var _width: int = 512
var _height: int = 512
var _base_color: Color = Color(0.65, 0.68, 0.74, 1.0)
var _line_color: Color = Color(0.95, 0.40, 0.45, 1.0)
# Shader strategy: "edges" = SimpleGrid (mesh-edge highlighting), "parametric"
# = ParametricGrid (UV-space grid with caller-supplied line counts). Default
# to parametric for the DNA gallery so high-tessellation variants stay
# legible.
var _shader_mode: String = "parametric"
# When using the parametric shader, the manifest can specify which axes
# of the variant feed lines_u and lines_v on the shader. Falls back to
# fixed defaults if not supplied.
var _line_count_axes: Dictionary = {}     # {"u": "rings", "v": "ring_segments"}
var _line_count_defaults: Dictionary = {"u": 8, "v": 8}


func _initialize() -> void:
	_parse_args()
	if _manifest_path.is_empty():
		push_error("capture_primitive_dna: --manifest=<path> is required")
		quit(1)
		return

	var manifest := _read_manifest(_manifest_path)
	if manifest.is_empty():
		push_error("capture_primitive_dna: failed to read manifest at %s" % _manifest_path)
		quit(1)
		return

	if manifest.has("camera"):
		var cam: Dictionary = manifest["camera"]
		_yaw_deg = float(cam.get("yaw_deg", _yaw_deg))
		_pitch_deg = float(cam.get("pitch_deg", _pitch_deg))
		_pad = float(cam.get("pad", _pad))
	if manifest.has("image"):
		var img: Dictionary = manifest["image"]
		_width = int(img.get("width", _width))
		_height = int(img.get("height", _height))
	if manifest.has("material"):
		var mat: Dictionary = manifest["material"]
		var bc = mat.get("base_color", null)
		if bc is Array and bc.size() >= 3:
			var a: float = float(bc[3]) if bc.size() > 3 else 1.0
			_base_color = Color(float(bc[0]), float(bc[1]), float(bc[2]), a)
		var lc = mat.get("line_color", null)
		if lc is Array and lc.size() >= 3:
			var la: float = float(lc[3]) if lc.size() > 3 else 1.0
			_line_color = Color(float(lc[0]), float(lc[1]), float(lc[2]), la)
		_shader_mode = String(mat.get("shader", _shader_mode))
		var lca = mat.get("line_count_axes", null)
		if lca is Dictionary:
			_line_count_axes = lca
		var lcd = mat.get("line_count_defaults", null)
		if lcd is Dictionary:
			_line_count_defaults = lcd

	var primitive_name: String = String(manifest.get("primitive", ""))
	if primitive_name.is_empty():
		push_error("capture_primitive_dna: manifest missing 'primitive' field")
		quit(1)
		return

	var variants: Array = manifest.get("variants", [])
	if variants.is_empty():
		push_error("capture_primitive_dna: manifest has no variants")
		quit(1)
		return

	var output_abs: String = ProjectSettings.globalize_path(_output_dir)
	DirAccess.make_dir_recursive_absolute(output_abs)

	_run_batch(primitive_name, variants, output_abs)


func _parse_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for arg in args:
		var eq: int = arg.find("=")
		if eq < 0:
			continue
		var key: String = arg.substr(0, eq).lstrip("-")
		var val: String = arg.substr(eq + 1)
		match key:
			"manifest": _manifest_path = val
			"out", "output": _output_dir = val
			"yaw_deg": _yaw_deg = float(val)
			"pitch_deg": _pitch_deg = float(val)
			"pad": _pad = float(val)


func _read_manifest(path: String) -> Dictionary:
	var abs: String = path
	if path.begins_with("user://") or path.begins_with("res://"):
		abs = ProjectSettings.globalize_path(path)
	var f := FileAccess.open(abs, FileAccess.READ)
	if f == null:
		return {}
	var text: String = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}


func _build_mesh(primitive_name: String, params: Dictionary) -> PrimitiveMesh:
	var mesh: PrimitiveMesh = null
	match primitive_name:
		"BoxMesh": mesh = BoxMesh.new()
		"SphereMesh": mesh = SphereMesh.new()
		"CapsuleMesh": mesh = CapsuleMesh.new()
		"CylinderMesh": mesh = CylinderMesh.new()
		"TorusMesh": mesh = TorusMesh.new()
		"PrismMesh": mesh = PrismMesh.new()
		"PlaneMesh": mesh = PlaneMesh.new()
		"QuadMesh": mesh = QuadMesh.new()
		_:
			push_error("capture_primitive_dna: unsupported primitive '%s'" % primitive_name)
			return null
	for key in params.keys():
		var raw = params[key]
		var value = _coerce_param_value(mesh, key, raw)
		mesh.set(key, value)
	return mesh


# Build a fresh ShaderMaterial with the parametric grid shader and lines_u
# / lines_v derived from this variant's params (via the manifest's
# line_count_axes mapping). This is what makes the gallery's visual
# encoding stay legible across the parameter sweep.
func _build_parametric_material(shader: Shader, params: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("fill_color", _base_color)
	m.set_shader_parameter("line_color", _line_color)

	var lines_u: int = int(_line_count_defaults.get("u", 8))
	var lines_v: int = int(_line_count_defaults.get("v", 8))
	var u_axis: String = String(_line_count_axes.get("u", ""))
	var v_axis: String = String(_line_count_axes.get("v", ""))
	if u_axis != "" and params.has(u_axis):
		lines_u = int(params[u_axis])
	if v_axis != "" and params.has(v_axis):
		lines_v = int(params[v_axis])
	# Clamp to shader's hint_range (1, 64).
	lines_u = clamp(lines_u, 1, 64)
	lines_v = clamp(lines_v, 1, 64)
	m.set_shader_parameter("lines_u", lines_u)
	m.set_shader_parameter("lines_v", lines_v)
	return m


# JSON arrays come through as GDScript Arrays; some PrimitiveMesh properties
# are typed (Vector3, Vector2). Coerce based on the property type Godot
# reports so silent set-failures don't produce empty meshes (which is what
# happens when, e.g., PrismMesh.size receives an Array instead of Vector3).
func _coerce_param_value(target: Object, key: String, raw):
	if not (raw is Array):
		return raw
	# Find the property's expected type in the object's property list.
	var expected_type: int = -1
	for prop in target.get_property_list():
		if prop.get("name") == key:
			expected_type = int(prop.get("type", -1))
			break
	match expected_type:
		TYPE_VECTOR3:
			if raw.size() >= 3:
				return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
		TYPE_VECTOR2:
			if raw.size() >= 2:
				return Vector2(float(raw[0]), float(raw[1]))
		TYPE_VECTOR3I:
			if raw.size() >= 3:
				return Vector3i(int(raw[0]), int(raw[1]), int(raw[2]))
		TYPE_VECTOR2I:
			if raw.size() >= 2:
				return Vector2i(int(raw[0]), int(raw[1]))
		TYPE_COLOR:
			if raw.size() >= 3:
				var a: float = float(raw[3]) if raw.size() > 3 else 1.0
				return Color(float(raw[0]), float(raw[1]), float(raw[2]), a)
	return raw


func _run_batch(primitive_name: String, variants: Array, output_abs: String) -> void:
	# Ensure the main viewport is the right size for capture.
	root.size = Vector2i(_width, _height)

	var scene_root := Node3D.new()
	scene_root.name = "PrimitiveDnaScene"
	root.add_child(scene_root)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.10, 0.10, 0.12, 1.0)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.35, 0.36, 0.40, 1.0)
	e.ambient_light_energy = 1.0
	env.environment = e
	scene_root.add_child(env)

	var dir_light := DirectionalLight3D.new()
	dir_light.rotation_degrees = Vector3(-50.0, 35.0, 0.0)
	dir_light.light_energy = 1.2
	scene_root.add_child(dir_light)

	var camera := Camera3D.new()
	camera.fov = 35.0
	scene_root.add_child(camera)
	camera.current = true

	# Pre-load the parametric shader if we're in parametric mode; falls back
	# to GridMaterialFactory for "edges" mode (mesh-triangle highlighting).
	var parametric_shader: Shader = null
	if _shader_mode == "parametric":
		parametric_shader = load(PARAMETRIC_GRID_SHADER_PATH) as Shader
		if parametric_shader == null:
			push_warning("capture_primitive_dna: parametric shader missing, falling back to edges")
			_shader_mode = "edges"
	# Material reused across variants only when not parametric (parametric
	# wants per-variant uniform values).
	var shared_edge_material: Material = null
	if _shader_mode == "edges":
		shared_edge_material = GRID_FACTORY.make(_base_color)

	var saved_ids: Array = []
	var failed: int = 0

	var yaw: float = deg_to_rad(_yaw_deg)
	var pitch: float = deg_to_rad(_pitch_deg)

	print("capture_primitive_dna: %s — %d variants -> %s" % [
		primitive_name, variants.size(), output_abs
	])

	for variant in variants:
		if not variant is Dictionary:
			failed += 1
			continue
		var vid: String = String(variant.get("id", ""))
		var params: Dictionary = variant.get("params", {})
		if vid.is_empty():
			failed += 1
			continue

		var pmesh := _build_mesh(primitive_name, params)
		if pmesh == null:
			failed += 1
			continue

		var mi := MeshInstance3D.new()
		mi.mesh = pmesh
		# Per-variant material: in parametric mode, the line counts come
		# from this variant's params (or fall back to defaults). The
		# rendered grid then literally shows the parametric structure
		# the variant claims, regardless of mesh tessellation.
		if _shader_mode == "parametric":
			mi.material_override = _build_parametric_material(parametric_shader, params)
		else:
			mi.material_override = shared_edge_material
		scene_root.add_child(mi)

		# Let the mesh build its AABB.
		await process_frame

		var aabb: AABB = mi.get_aabb()
		var center: Vector3 = mi.global_transform.origin + aabb.get_center()
		var max_dim: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
		if max_dim < 0.01:
			max_dim = 0.5
		# Distance to fit AABB vertically given camera FOV.
		var half_fov: float = deg_to_rad(camera.fov * 0.5)
		var dist: float = (max_dim * 0.5 / tan(half_fov)) * _pad

		var cam_offset := Vector3(
			sin(yaw) * cos(pitch),
			sin(pitch),
			cos(yaw) * cos(pitch)
		) * dist
		camera.global_position = center + cam_offset
		camera.look_at(center, Vector3.UP)

		await process_frame
		await process_frame
		await create_timer(0.05).timeout
		await process_frame

		var img: Image = root.get_texture().get_image()
		if img == null:
			failed += 1
			mi.queue_free()
			await process_frame
			continue

		var out_path: String = output_abs.path_join(vid + ".png")
		var err := img.save_png(out_path)
		if err == OK:
			saved_ids.append(vid)
			print("  ✓ %s" % vid)
		else:
			failed += 1
			print("  ✗ %s (save error %d)" % [vid, err])

		mi.queue_free()
		await process_frame

	var summary := {
		"primitive": primitive_name,
		"saved": saved_ids.size(),
		"failed": failed,
		"ids": saved_ids,
		"image_size": [_width, _height],
	}
	var summary_path: String = output_abs.path_join("summary.json")
	var sf := FileAccess.open(summary_path, FileAccess.WRITE)
	if sf != null:
		sf.store_string(JSON.stringify(summary, "\t"))
		sf.close()

	print("capture_primitive_dna: done — %d saved, %d failed" % [saved_ids.size(), failed])
	quit(0)
