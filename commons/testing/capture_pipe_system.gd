extends SceneTree

## Unified capture for TurtlePipeBase-derived systems (glass rack + big pipe).
##
## Both systems share the same turtle-code DNA — a path string like
## "f,f,r,f,s,f,t,f" — but differ in scale and segment library:
##   - glass  → GlassRackController  (pipe_radius 0.02, segment 0.2, lab glass)
##   - big    → BigPipeSystem         (pipe_radius 0.8,  segment 2.0, drain pipes)
##
## Config shape (matches commons/glass_rack/configs/*.json, extended)::
##
##   {
##     "rack_info": { "name": "Y manifold", "system": "glass" },
##     "layout":    { "segment_length": 0.15, "pipe_radius": 0.02 },
##     "path":      "f,s,f,r,f"
##   }
##
## system = "glass" (default) or "big_pipe"
##
## Usage::
##
##   godot --path . --xr-mode off --no-window --script \
##     res://commons/testing/capture_pipe_system.gd --no-bridges -- \
##     --config=res://commons/glass_rack/configs/simple_tube.json \
##     --out=user://pipes/simple_tube.png

const GlassRackScript  = preload("res://commons/glass_rack/GlassRackController.gd")
const BigPipeScript    = preload("res://algorithms/wavefunctions/big_pipe_system/big_pipe_system.gd")

var _config_path: String = ""
var _out_path: String = ""
var _render_size := Vector2i(900, 900)

# Optional camera overrides — used by the fixer loop to try variations.
# Default values produce the original behaviour.
var _cam_distance_mult: float = 1.6     # distance = max_dim * mult + offset
var _cam_distance_offset: float = 0.3
var _cam_elevation: float = 0.5          # y-offset relative to max_dim
var _cam_azimuth: float = 0.7            # x-offset relative to max_dim
var _cam_forward: float = 0.9            # z-offset relative to max_dim
var _ambient_boost: float = 1.0          # multiplier on ambient light
var _key_boost: float = 1.0              # multiplier on key light

func _initialize() -> void:
	_parse_args()
	if _config_path.is_empty() or _out_path.is_empty():
		push_error("capture_pipe_system: --config and --out are required")
		quit(1); return
	call_deferred("_run")

func _parse_args() -> void:
	for raw in OS.get_cmdline_user_args():
		var arg := String(raw).strip_edges()
		if not arg.begins_with("--"): continue
		var eq := arg.find("=")
		if eq <= 2: continue
		var key := arg.substr(2, eq - 2)
		var value := arg.substr(eq + 1).strip_edges()
		match key:
			"config": _config_path = value
			"out":    _out_path = value
			"size":
				var n := int(value)
				if n > 0: _render_size = Vector2i(n, n)
			"cam_distance_mult": _cam_distance_mult = float(value)
			"cam_distance_offset": _cam_distance_offset = float(value)
			"cam_elevation":     _cam_elevation = float(value)
			"cam_azimuth":       _cam_azimuth = float(value)
			"cam_forward":       _cam_forward = float(value)
			"ambient_boost":     _ambient_boost = float(value)
			"key_boost":         _key_boost = float(value)

func _load_config() -> Dictionary:
	var abs := _config_path
	if abs.begins_with("res://"):
		abs = ProjectSettings.globalize_path(abs)
	var f := FileAccess.open(abs, FileAccess.READ)
	if not f:
		push_error("can't open %s" % abs); return {}
	var parse: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parse) != TYPE_DICTIONARY:
		push_error("invalid JSON"); return {}
	return parse as Dictionary

func _run() -> void:
	var cfg := _load_config()
	if cfg.is_empty():
		quit(1); return

	var rack_info: Dictionary = cfg.get("rack_info", {})
	var layout: Dictionary = cfg.get("layout", {})
	var system: String = String(rack_info.get("system", "glass")).to_lower()

	# Accept either turtle-code (`path`) OR segments-array. load_config_from_dict
	# in TurtlePipeBase handles both — delegate to it.
	var has_path: bool = cfg.has("path") and typeof(cfg["path"]) == TYPE_STRING and not String(cfg["path"]).is_empty()
	var has_segments: bool = cfg.has("segments") and typeof(cfg["segments"]) == TYPE_ARRAY
	if not has_path and not has_segments:
		push_error("capture_pipe_system: config missing 'path' or 'segments'")
		quit(1); return

	# ── Viewport + environment ─────────────────────────────────────────
	var viewport := SubViewport.new()
	viewport.size = _render_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.07, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.70, 0.72, 0.78)
	env.ambient_light_energy = 1.2
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	viewport.add_child(we)

	# Key + fill lights (ambient + boost multipliers allow the fixer loop
	# to retry dim renders with stronger lighting)
	env.ambient_light_energy = 1.2 * _ambient_boost
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -25, 0)
	key.light_energy = 1.2 * _key_boost
	key.shadow_enabled = false
	viewport.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-5, 140, 0)
	fill.light_energy = 0.45 * _key_boost
	viewport.add_child(fill)

	# ── Build the pipe system ──────────────────────────────────────────
	var pipe: Node3D = null
	if system == "big_pipe" or system == "big" or system == "bigpipe":
		pipe = BigPipeScript.new()
	else:
		pipe = GlassRackScript.new()
	pipe.auto_build = false
	if "segment_length" in layout and (pipe as Object).has_method("set"):
		pipe.segment_length = float(layout["segment_length"])
	if "pipe_radius" in layout:
		pipe.pipe_radius = float(layout["pipe_radius"])
	viewport.add_child(pipe)

	# Use the base class's proper entry point — handles path/segments/
	# frame/materials all in one. Falls back to generate_from_code for
	# BigPipeSystem which uses generate_pipes instead.
	if pipe.has_method("load_config_from_dict"):
		pipe.load_config_from_dict(cfg)
	elif has_path and pipe.has_method("generate_from_code"):
		pipe.generate_from_code(String(cfg["path"]))
	elif has_path and pipe.has_method("generate_pipes"):
		pipe.generate_pipes(String(cfg["path"]))
	else:
		push_warning("capture_pipe_system: pipe has no config loader")

	# Let it build — turtle graphics instantiates scenes on _ready across frames
	for i in range(8):
		await process_frame

	# ── Camera — auto-frame the built network ─────────────────────────
	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 45.0
	viewport.add_child(camera)

	var aabb := _compute_aabb(pipe)
	var center := aabb.position + aabb.size * 0.5
	var max_dim: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if max_dim <= 0.001:
		max_dim = (1.0 if system != "big_pipe" else 4.0)

	# Only redirect the camera for HIGHLY elongated shapes (ratio > 2.5).
	# Compact shapes use the default diagonal view, which was working.
	# Elongated shapes get viewed perpendicular to their long axis so we
	# see the length, not the end-cap.
	var axis_x := aabb.size.x
	var axis_y := aabb.size.y
	var axis_z := aabb.size.z
	var second: float = max(min(axis_x, max(axis_y, axis_z)), min(axis_y, max(axis_x, axis_z)))
	var elongation: float = max_dim / max(second, 0.001)

	var dist: float
	var cam_off: Vector3
	if elongation > 2.5:
		# Use smaller distance — second-longest axis dominates framing
		dist = second * _cam_distance_mult * 2.5 + _cam_distance_offset
		# Pick direction perpendicular to longest axis
		if axis_z >= axis_x and axis_z >= axis_y:
			cam_off = Vector3(dist * 0.9, dist * 0.4, dist * 0.2)
		elif axis_x >= axis_y:
			cam_off = Vector3(dist * 0.2, dist * 0.4, dist * 0.9)
		else:
			cam_off = Vector3(dist * 0.7, dist * 0.1, dist * 0.9)
	else:
		# Compact shape — original diagonal view (preserves working cases)
		dist = max_dim * _cam_distance_mult + _cam_distance_offset
		cam_off = Vector3(dist * _cam_azimuth, dist * _cam_elevation, dist * _cam_forward)

	camera.transform.origin = center + cam_off
	camera.look_at(center, Vector3.UP)
	print("capture_pipe_system: aabb size=%s elongation=%.2f dist=%.2f cam=%s"
		% [aabb.size, elongation, dist, cam_off])

	# Settle camera
	for i in range(4):
		await process_frame

	# ── Capture ─────────────────────────────────────────────────────────
	var image: Image = viewport.get_texture().get_image()
	if image:
		var abs_out := _out_path
		if abs_out.begins_with("user://"):
			abs_out = ProjectSettings.globalize_path(abs_out)
		DirAccess.make_dir_recursive_absolute(abs_out.get_base_dir())
		var err := image.save_png(abs_out)
		if err == OK:
			print("capture_pipe_system: OK %s -> %s" % [system, abs_out])
		else:
			push_warning("save err=%d" % err)
	quit(0)


func _compute_aabb(root_node: Node3D) -> AABB:
	var aabb := AABB()
	var first := true
	for child in _walk_meshes(root_node):
		var mi := child as MeshInstance3D
		if not mi or mi.mesh == null:
			continue
		var local_aabb := mi.get_aabb()
		var world_xform := mi.global_transform
		var world_aabb := world_xform * local_aabb
		if first:
			aabb = world_aabb; first = false
		else:
			aabb = aabb.merge(world_aabb)
	return aabb


func _walk_meshes(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child in node.get_children():
		if child is MeshInstance3D:
			out.append(child)
		if child is Node:
			out.append_array(_walk_meshes(child))
	return out
