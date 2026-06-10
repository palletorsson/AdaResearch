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
const PAD_LIMIT := 0.2       # slider_plane's default ±travel on each axis
const DISPLAY_SIZE := 0.78   # the demo is scaled to sit on the console top

@export var emissive: bool = true

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


## Builds the console ONCE: body, monitor screen (left), slider (right), demo mount.
func _ensure_rack() -> void:
	if _rack_built:
		return
	_rack_built = true
	var meta: Dictionary = _console_meta()

	# console body + top trim
	add_child(_box(Vector3(0.0, 0.46, 0.0), Vector3(1.5, 0.92, 0.62), _panel_mat(Color(0.10, 0.11, 0.13))))
	add_child(_box(Vector3(0.0, 0.93, 0.0), Vector3(1.54, 0.04, 0.66), _panel_mat(Color(0.17, 0.18, 0.21))))

	# the monitor (left): a dark screen with the readout on its face
	var scr := Vector3(-0.48, 1.16, 0.10)
	add_child(_box(scr + Vector3(0.0, 0.0, -0.02), Vector3(0.54, 0.46, 0.05), _panel_mat(Color(0.04, 0.04, 0.06))))
	add_child(_box(scr, Vector3(0.48, 0.40, 0.01), _screen_mat()))
	monitor_label = Label3D.new()
	monitor_label.name = "MonitorReadout"
	monitor_label.font_size = 36
	monitor_label.pixel_size = 0.0011
	monitor_label.modulate = Color(0.55, 0.92, 1.0)
	monitor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	monitor_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	monitor_label.position = scr + Vector3(0.0, 0.0, 0.012)
	monitor_label.text = "..."
	add_child(monitor_label)
	add_child(_label_plate(String(meta.get("title", "TOY")), Vector3(-0.48, 1.42, 0.10), 24, Color(0.78, 0.84, 0.94)))

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
		_slider = s
	add_child(_label_plate(String(meta.get("slider", "PARAM")) + "  (drag →)", Vector3(0.46, 1.06, 0.16), 20, Color(0.7, 0.8, 0.9)))


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


func _build_pad(spec: Dictionary, x: float) -> void:
	if not ResourceLoader.exists(PAD_SCENE):
		return
	var pad: Node = load(PAD_SCENE).instantiate()
	pad.name = "Pad_" + String(spec.get("label", ""))
	add_child(pad)
	# drafting-table angle on the front lip, below the demo so the top reads clearly
	(pad as Node3D).position = Vector3(x, 0.86, 0.34)
	(pad as Node3D).rotation = Vector3(deg_to_rad(-58.0), 0.0, 0.0)
	(pad as Node3D).scale = Vector3.ONE * 1.5
	# bind the INNER node (slider_plane.gd) — its slider_position is a true Vector2
	var inner: Node = pad.get_node_or_null("SliderOrigin/InteractableSlider")
	if inner:
		var iv: Vector2 = spec["get"].call()
		inner.set("slider_position", Vector2(clampf(iv.x, -1.0, 1.0), clampf(iv.y, -1.0, 1.0)) * PAD_LIMIT)
		var handler: Callable = _make_pad_handler(spec)
		if inner.has_signal("slider_moved") and not inner.is_connected("slider_moved", handler):
			inner.connect("slider_moved", handler)
	_controls_built.append(pad)
	add_child(_label_plate(String(spec.get("label", "")), Vector3(x, 1.02, 0.30), 18, Color(0.72, 0.82, 0.94)))


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
	_controls_built.append(c)
	add_child(_label_plate(String(spec.get("label", "")), Vector3(x, 1.06, 0.18), 18, Color(0.72, 0.82, 0.94)))


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
		monitor_label.modulate = color


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
	m.metallic = 0.25
	m.roughness = 0.8
	return m


func _screen_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.02, 0.05, 0.05)
	m.emission_enabled = true
	m.emission = Color(0.05, 0.16, 0.13)
	m.emission_energy_multiplier = 0.7
	return m


func _label_plate(text: String, pos: Vector3, font: int, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = font
	l.pixel_size = 0.0011
	l.modulate = col
	l.outline_size = 6
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
	var s: float = 1.0 if span <= 0.001 else clampf(DISPLAY_SIZE / span, 0.2, 4.0)
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
