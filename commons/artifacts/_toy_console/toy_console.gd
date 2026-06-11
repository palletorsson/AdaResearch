extends Node3D

## ToyConsole — the shared "one surface" rack for the embodied vector/force toys.
##
## A console body with: a monitor screen on the LEFT (the readout), the 3D demo
## standing on the TOP, and a slider_horizontal XR-tools interactable on the RIGHT
## that drives the toy's DNA parameter. The rack + slider are built ONCE; only the
## demo + readout rebuild when the slider moves (so dragging never destroys the slider).
##
## Subclasses (the toys) extend this BY PATH (extends "res://.../toy_console.gd") so
## they don't depend on a global class_name being registered for headless captures.
## They override:
##   _build_demo()        — build the demo into `demo_root`, then call set_readout(...)
##   _param_get()         — return the current DNA parameter (0..1) for the slider
##   _param_set(v)        — apply a new 0..1 value to the DNA parameter
##   _console_meta()      — {"title": "...", "slider": "..."} for the rack labels
## and call _console_ready() from their own _ready().

const SLIDER_SCENE := "res://commons/interactables/slider_horizontal.tscn"
const DIAL_SCENE := "res://commons/interactables/dial_smooth.tscn"
const PAD_SCENE := "res://commons/interactables/slider_plane.tscn"
const PAD_LIMIT := 0.07      # ±handle travel on each axis — matches the plate's track half-width
const DISPLAY_SIZE := 0.78   # the demo is scaled to sit on the console top

# --- Dieter Rams / Braun palette: light matte housing, one warm accent, calm
#     dark display, dark functional type. "Less, but better" — the housing recedes
#     so the vector is the only expressive thing.
const BRAUN_ACCENT := Color(0.86, 0.34, 0.11)    # the one warm element — the grab points
const PANEL_LIGHT := Color(0.81, 0.79, 0.75)     # warm off-white body
const PANEL_TRIM := Color(0.70, 0.68, 0.64)      # slightly darker light grey
const DISPLAY_DARK := Color(0.12, 0.12, 0.135)   # the calm anthracite screen (no glow, no green)
const TEXT_DARK := Color(0.17, 0.17, 0.19)       # functional labels on the light housing
const TEXT_DISPLAY := Color(0.90, 0.89, 0.85)    # warm off-white readout on the dark screen

@export var emissive: bool = true
## Capture/gallery mode: skip the rack entirely — just the demo at full size with a
## billboard readout. The in-map/VR artifact keeps demo_only=false (the full console).
@export var demo_only: bool = false

const DEMO_ONLY_SIZE := 1.9   # demo scale target when there's no console under it

var _rng := RandomNumberGenerator.new()
var _rack_built := false
var demo_root: Node3D
var monitor_label: Label3D
var _slider: Node
var _controls_built: Array = []


# --- to be overridden by the toy --------------------------------------------
func _build_demo() -> void:
	pass

func _param_get() -> float:
	return 0.5

func _param_set(_v: float) -> void:
	pass

func _console_meta() -> Dictionary:
	return {"title": "TOY", "slider": "PARAM"}

## Override to return an ordered MULTI-control bank instead of the single slider:
##   {"label": String, "kind": "slider"|"dial"|"pad", "get": Callable, "set": Callable}
## slider/dial: get()->float (0..1), set(float 0..1).   pad: get()->Vector2 (-1..1
## each axis), set(Vector2 -1..1). Return [] (default) to keep the single-slider path.
func _controls() -> Array:
	return []


# --- lifecycle ---------------------------------------------------------------
func _console_ready() -> void:
	_ensure_rack()
	_build_demo()


## Parse the base-level DNA keys — call from each toy's apply_grid_config
## BEFORE _ensure_rack(), since demo_only changes what the rack builds.
func apply_base_config(config_data: Dictionary) -> void:
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
	if config_data.has("demo_only"):
		var v: bool = bool(config_data["demo_only"])
		# _ready may have already built the other mode (config arrives after add-to-tree):
		# tear the console down so _ensure_rack() rebuilds in the requested mode.
		if v != demo_only and _rack_built:
			_reset_console()
		demo_only = v


func _reset_console() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_rack_built = false
	demo_root = null
	monitor_label = null
	_slider = null
	_controls_built = []


## Builds the console ONCE: body, monitor screen (left), slider (right), demo mount.
func _ensure_rack() -> void:
	if _rack_built:
		return
	_rack_built = true
	var meta: Dictionary = _console_meta()

	# demo_only: no rack — a free-standing demo with a billboard readout (gallery captures)
	if demo_only:
		monitor_label = Label3D.new()
		monitor_label.name = "BillboardReadout"
		monitor_label.font_size = 30
		monitor_label.pixel_size = 0.0011
		monitor_label.modulate = TEXT_DISPLAY
		monitor_label.outline_size = 8
		monitor_label.outline_modulate = Color(0.10, 0.10, 0.12, 0.85)
		monitor_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		monitor_label.no_depth_test = true
		monitor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		monitor_label.position = Vector3(0.0, DEMO_ONLY_SIZE + 0.30, 0.0)
		add_child(monitor_label)
		demo_root = Node3D.new()
		demo_root.name = "DemoMount"
		add_child(demo_root)
		return

	# light matte housing + top trim (Braun: the body recedes)
	add_child(_box(Vector3(0.0, 0.46, 0.0), Vector3(1.5, 0.92, 0.62), _panel_mat(PANEL_LIGHT)))
	add_child(_box(Vector3(0.0, 0.93, 0.0), Vector3(1.54, 0.04, 0.66), _panel_mat(PANEL_TRIM)))
	# one thin warm accent line along the front top edge — the single Braun gesture
	add_child(_box(Vector3(0.0, 0.885, 0.315), Vector3(1.5, 0.014, 0.012), _accent_mat()))

	# the monitor (left): a calm dark display in a light bezel (the Braun inversion)
	var scr := Vector3(-0.48, 1.16, 0.10)
	add_child(_box(scr + Vector3(0.0, 0.0, -0.02), Vector3(0.56, 0.48, 0.05), _panel_mat(PANEL_TRIM)))   # light bezel
	add_child(_box(scr, Vector3(0.48, 0.40, 0.01), _screen_mat()))                                       # dark display
	monitor_label = Label3D.new()
	monitor_label.name = "MonitorReadout"
	monitor_label.font_size = 36
	monitor_label.pixel_size = 0.0011
	monitor_label.modulate = TEXT_DISPLAY
	monitor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	monitor_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	monitor_label.position = scr + Vector3(0.0, 0.0, 0.012)
	monitor_label.text = "..."
	add_child(monitor_label)
	add_child(_label_plate(String(meta.get("title", "TOY")), Vector3(-0.48, 1.43, 0.10), 22, TEXT_DARK))

	# the control(s): a multi-control bank if _controls() is overridden, else one slider
	var specs: Array = _controls()
	if specs.is_empty():
		_build_single_slider(meta)
	else:
		_build_control_bank(specs)

	# the demo mount — the 3D demonstration stands on the console top
	demo_root = Node3D.new()
	demo_root.name = "DemoMount"
	demo_root.position = Vector3(0.12, 0.95, -0.02)
	add_child(demo_root)


## The slider drives the DNA parameter, then only the demo rebuilds.
func _on_slider_moved(_value: Variant = null) -> void:
	if _slider and _slider.has_method("get_normalized_value"):
		_param_set(clampf(_slider.call("get_normalized_value"), 0.0, 1.0))
	elif _value != null:
		_param_set(clampf(float(_value), 0.0, 1.0))
	_build_demo()


# --- the single-slider path (legacy — all the one-param toys) ---------------
func _build_single_slider(meta: Dictionary) -> void:
	if ResourceLoader.exists(SLIDER_SCENE):
		var s: Node = load(SLIDER_SCENE).instantiate()
		s.name = "ParamSlider"
		add_child(s)
		(s as Node3D).position = Vector3(0.46, 0.95, 0.16)
		if s.has_method("set_param_name"): s.call("set_param_name", String(meta.get("slider", "PARAM")))
		if s.has_method("set_range"): s.call("set_range", 0.0, 1.0)
		if s.has_method("set_normalized_value"): s.call("set_normalized_value", _param_get())
		if s.has_signal("slider_moved") and not s.is_connected("slider_moved", _on_slider_moved):
			s.connect("slider_moved", _on_slider_moved)
		_accent_handles(s)
		_slider = s
	add_child(_label_plate(String(meta.get("slider", "PARAM")) + "  (drag →)", Vector3(0.46, 1.06, 0.16), 20, TEXT_DARK))


# --- the multi-control bank (sliders / dials / 2D pads in a row) -------------
func _build_control_bank(specs: Array) -> void:
	var n: int = specs.size()
	for i in range(n):
		var spec: Dictionary = specs[i]
		var kind: String = String(spec.get("kind", "slider"))
		var t: float = 0.0 if n <= 1 else float(i) / float(n - 1)
		if kind == "pad":
			_build_pad(spec, lerpf(0.04, 0.56, t))
		else:
			_build_scalar(spec, kind, lerpf(0.0, 0.58, t))


## A control plate drawn directly (light bezel + recessed face + accent cross-hair),
## with the knob sitting ON the plate at the vector's value — guaranteed aligned. The
## plate tilts up toward the player on the front lip. (slider_plane's plate and handle
## live on separate branches and can't be kept coplanar; the live VR grab is wired
## separately as a constrained handle.)
func _build_pad(spec: Dictionary, x: float) -> void:
	var iv: Vector2 = spec["get"].call()
	var pad := Node3D.new()
	pad.name = "Pad_" + String(spec.get("label", ""))
	add_child(pad)
	pad.position = Vector3(x, 0.90, 0.32)
	pad.rotation = Vector3(deg_to_rad(-52.0), 0.0, 0.0)   # face tilts up toward the player
	pad.scale = Vector3.ONE * 1.4

	# The PLATE is its own node; the knob is parented UNDER it, so the knob inherits the
	# plate's transform and can only ever sit on its surface (this is exactly what
	# slider_plane got wrong — there the knob was a sibling on a separate branch).
	var plate := Node3D.new()
	plate.name = "Plate"
	pad.add_child(plate)
	plate.add_child(_box(Vector3.ZERO, Vector3(0.24, 0.24, 0.02), _panel_mat(PANEL_TRIM)))          # bezel
	plate.add_child(_box(Vector3(0.0, 0.0, 0.013), Vector3(0.20, 0.20, 0.004), _screen_mat()))      # recessed face
	plate.add_child(_box(Vector3(0.0, 0.0, 0.016), Vector3(0.20, 0.004, 0.001), _glow_mat(BRAUN_ACCENT, 0.18)))  # cross-hair
	plate.add_child(_box(Vector3(0.0, 0.0, 0.016), Vector3(0.004, 0.20, 0.001), _glow_mat(BRAUN_ACCENT, 0.18)))

	# the knob — a child of the plate — at the vector's value on the face (clamped)
	var knob := Node3D.new()
	knob.name = "Knob"
	knob.position = Vector3(clampf(iv.x, -1.0, 1.0) * 0.09, clampf(iv.y, -1.0, 1.0) * 0.09, 0.0)
	plate.add_child(knob)
	knob.add_child(_cylinder_between(Vector3(0, 0, 0.016), Vector3(0, 0, 0.05), 0.014, _accent_mat()))  # stem
	knob.add_child(_sphere(Vector3(0, 0, 0.056), 0.028, _accent_mat()))                                 # knob

	_controls_built.append(pad)
	add_child(_label_plate(String(spec.get("label", "")), Vector3(x, 1.04, 0.30), 18, TEXT_DARK))


func _build_scalar(spec: Dictionary, kind: String, x: float) -> void:
	var scene_path: String = DIAL_SCENE if kind == "dial" else SLIDER_SCENE
	if not ResourceLoader.exists(scene_path):
		return
	var c: Node = load(scene_path).instantiate()
	c.name = "Ctl_" + String(spec.get("label", ""))
	add_child(c)
	(c as Node3D).position = Vector3(x, 0.95, 0.18)
	if c.has_method("set_param_name"): c.call("set_param_name", String(spec.get("label", "")))
	if c.has_method("set_range"): c.call("set_range", 0.0, 1.0)
	if c.has_method("set_normalized_value"): c.call("set_normalized_value", clampf(spec["get"].call(), 0.0, 1.0))
	var sig: String = "hinge_moved" if kind == "dial" else "slider_moved"
	var handler: Callable = _make_scalar_handler(c, spec)
	if c.has_signal(sig) and not c.is_connected(sig, handler):
		c.connect(sig, handler)
	_accent_handles(c)
	_controls_built.append(c)
	add_child(_label_plate(String(spec.get("label", "")), Vector3(x, 1.06, 0.18), 18, TEXT_DARK))


# pad signal carries a Vector2 in ±PAD_LIMIT → normalize to -1..1, push, rebuild.
func _make_pad_handler(spec: Dictionary) -> Callable:
	return func(pos: Vector2):
		spec["set"].call(Vector2(pos.x / PAD_LIMIT, pos.y / PAD_LIMIT))
		_build_demo()

# slider/dial: re-read the control's own normalized value (signal arg is raw).
func _make_scalar_handler(node: Node, spec: Dictionary) -> Callable:
	return func(_a = null, _b = null):
		var v: float = 0.5
		if node.has_method("get_normalized_value"):
			v = clampf(node.call("get_normalized_value"), 0.0, 1.0)
		spec["set"].call(v)
		_build_demo()


func set_readout(text: String, color: Color = Color(0.55, 0.92, 1.0)) -> void:
	if monitor_label:
		monitor_label.text = text
		monitor_label.modulate = color.lerp(TEXT_DISPLAY, 0.55)   # calm the per-toy tint toward warm white


## Fresh demo container — call at the top of _build_demo(), build into the returned rig.
func _fresh_demo_rig(rig_name: String) -> Node3D:
	if demo_root == null:
		return Node3D.new()
	for child in demo_root.get_children():
		demo_root.remove_child(child)
		child.queue_free()
	var rig := Node3D.new()
	rig.name = rig_name
	demo_root.add_child(rig)
	return rig


# ---------------------------------------------------------------------------
# shared materials
# ---------------------------------------------------------------------------

func _panel_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.0
	m.roughness = 0.92   # matte, soft — the Braun housing
	return m


func _screen_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = DISPLAY_DARK
	m.metallic = 0.1
	m.roughness = 0.35   # a calm dark display, faintly lit for legibility — no green, no glow
	m.emission_enabled = true
	m.emission = DISPLAY_DARK
	m.emission_energy_multiplier = 0.5
	return m


func _accent_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = BRAUN_ACCENT
	m.roughness = 0.5
	m.emission_enabled = true
	m.emission = BRAUN_ACCENT
	m.emission_energy_multiplier = 0.25 if emissive else 0.0
	return m


## The one warm element: tint every grabbable handle mesh Braun-orange, so the
## thing you touch is the only saturated thing on the housing.
func _accent_handles(root: Node) -> void:
	for child in root.get_children():
		if child is MeshInstance3D and String(child.name).findn("handle") != -1:
			(child as MeshInstance3D).material_override = _accent_mat()
		_accent_handles(child)


func _label_plate(text: String, pos: Vector3, font: int, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = font
	l.pixel_size = 0.0011
	l.modulate = col
	l.outline_size = 4
	l.outline_modulate = Color(0.86, 0.84, 0.80, 0.9)   # soft light halo so dark type reads on the housing
	l.position = pos
	return l


func _parse_color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String:
		var parts: PackedStringArray = (value as String).split(",")
		if parts.size() >= 3:
			return Color(float(parts[0]), float(parts[1]), float(parts[2]), 1.0 if parts.size() < 4 else float(parts[3]))
	return fallback


func _glow_mat(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy if emissive else energy * 0.3
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return m


func _steel_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.6
	m.roughness = 0.45
	m.emission_enabled = true
	m.emission = c * 0.4
	m.emission_energy_multiplier = 0.12 if emissive else 0.0
	return m


# ---------------------------------------------------------------------------
# shared primitives
# ---------------------------------------------------------------------------

func _basis_y_to(dir: Vector3) -> Basis:
	var y: Vector3 = dir.normalized()
	if y.length() < 0.0001:
		return Basis()
	var ref: Vector3 = Vector3.UP if absf(y.dot(Vector3.UP)) < 0.985 else Vector3.RIGHT
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


func _cylinder_between(a: Vector3, b: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = maxf(a.distance_to(b), 0.001)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = Transform3D(_basis_y_to(b - a), (a + b) * 0.5)
	return mi


func _cylinder(center: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _arrow(a: Vector3, b: Vector3, radius: float, mat: Material) -> Node3D:
	var root := Node3D.new()
	var dir: Vector3 = (b - a).normalized()
	var head_len: float = 0.11
	var shaft_end: Vector3 = b - dir * head_len
	root.add_child(_cylinder_between(a, shaft_end, radius, mat))
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = radius * 2.6
	cone.height = head_len
	var tip := MeshInstance3D.new()
	tip.mesh = cone
	tip.material_override = mat
	tip.transform = Transform3D(_basis_y_to(dir), (shaft_end + b) * 0.5)
	root.add_child(tip)
	return root


func _dashed(a: Vector3, b: Vector3, radius: float, mat: Material) -> Node3D:
	var root := Node3D.new()
	var n: int = 11
	for i in range(n):
		if i % 2 == 1:
			continue
		root.add_child(_cylinder_between(a.lerp(b, float(i) / float(n)), a.lerp(b, float(i + 1) / float(n)), radius, mat))
	return root


func _sphere(center: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _torus(center: Vector3, radius: float, tube: float, mat: Material) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - tube
	mesh.outer_radius = radius + tube
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


# ---------------------------------------------------------------------------
# settle — scale the demo to the console display size, base on the mount
# ---------------------------------------------------------------------------

func _settle(rig: Node3D) -> void:
	var aabb: AABB = _subtree_aabb(rig)
	if aabb.size.length() < 0.001:
		return
	var span: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var target: float = DEMO_ONLY_SIZE if demo_only else DISPLAY_SIZE
	var s: float = 1.0 if span <= 0.001 else clampf(target / span, 0.2, 4.0)
	rig.scale = Vector3.ONE * s
	var c: Vector3 = aabb.get_center() * s
	rig.position = Vector3(-c.x, -aabb.position.y * s, -c.z)


func _subtree_aabb(node: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for child in node.get_children():
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			if mi.mesh == null:
				continue
			var local: AABB = mi.mesh.get_aabb()
			var world: AABB = mi.transform * local
			if first:
				out = world
				first = false
			else:
				out = out.merge(world)
		elif child is Node3D:
			var sub: AABB = _subtree_aabb(child as Node3D)
			if sub.size.length() > 0.0001:
				if first:
					out = sub
					first = false
				else:
					out = out.merge(sub)
	return out
