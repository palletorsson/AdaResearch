extends Node3D

## Shared base for Turing's bench — the QFEP / cost-of-delta instruments.
##
## Every instrument is built from simple primitives + Label3D in _build(), so it
## renders reliably in-engine. Subclasses override _build(); the helpers add
## meshes/labels as children and return them. Optional motion: register a node
## with animate_node() and it twitches/spins/pulses in _process — but the static
## build is always complete, so a capture still shows the whole instrument.

var config: Dictionary = {}
var _t: float = 0.0
var _anim: Array = []

func _ready() -> void:
	_build()

func apply_grid_config(c) -> void:
	config = c if (c is Dictionary) else {}
	for ch in get_children():
		ch.queue_free()
	_anim.clear()
	_build()

func _build() -> void:
	pass  # override

func _process(delta: float) -> void:
	if _anim.is_empty():
		return
	_t += delta
	for a in _anim:
		var n: Node3D = a["n"]
		if not is_instance_valid(n):
			continue
		match a["k"]:
			"spin":
				n.rotation = a["rot"] + a["ax"] * (_t * a["sp"])
			"bob":
				n.position = a["pos"] + Vector3.UP * sin(_t * a["sp"]) * a["amp"]
			"twitch":
				n.rotation = a["rot"] + Vector3(0, 0, 1) * sin(_t * a["sp"] * 5.0) * a["amp"] * (0.5 + 0.5 * sin(_t * 1.7))
			"pulse":
				_set_emission(n, a["amp"] * (0.4 + 0.6 * (0.5 + 0.5 * sin(_t * a["sp"]))))
			"flicker":
				_set_emission(n, a["amp"] * (0.2 + 0.8 * abs(sin(_t * a["sp"]) * sin(_t * 2.3))))

func _set_emission(n: Node3D, e: float) -> void:
	var mi := n as MeshInstance3D
	if mi == null:
		return
	var sm := mi.material_override as StandardMaterial3D
	if sm != null:
		sm.emission_energy_multiplier = e

# ── material + mesh helpers ────────────────────────────────────────────────
func mat(color: Color, emission: float = 0.0, rough: float = 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	if color.a < 0.999:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m

func _mi(mesh: Mesh, pos: Vector3, color: Color, emission: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(color, emission)
	mi.position = pos
	add_child(mi)
	return mi

func add_box(size: Vector3, pos: Vector3, color: Color, emission: float = 0.0) -> MeshInstance3D:
	var m := BoxMesh.new(); m.size = size
	return _mi(m, pos, color, emission)

func add_cyl(radius: float, height: float, pos: Vector3, color: Color, emission: float = 0.0) -> MeshInstance3D:
	var m := CylinderMesh.new(); m.top_radius = radius; m.bottom_radius = radius; m.height = height
	return _mi(m, pos, color, emission)

func add_cone(radius: float, height: float, pos: Vector3, color: Color, emission: float = 0.0) -> MeshInstance3D:
	var m := CylinderMesh.new(); m.top_radius = 0.0; m.bottom_radius = radius; m.height = height
	return _mi(m, pos, color, emission)

func add_sphere(radius: float, pos: Vector3, color: Color, emission: float = 0.0) -> MeshInstance3D:
	var m := SphereMesh.new(); m.radius = radius; m.height = radius * 2.0
	return _mi(m, pos, color, emission)

func add_torus(inner: float, outer: float, pos: Vector3, color: Color, emission: float = 0.0) -> MeshInstance3D:
	var m := TorusMesh.new(); m.inner_radius = inner; m.outer_radius = outer
	return _mi(m, pos, color, emission)

func add_label(text: String, pos: Vector3, px: float = 0.004, color: Color = Color.WHITE) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 64
	l.pixel_size = px
	l.modulate = color
	l.outline_size = 10
	l.outline_modulate = Color(0, 0, 0, 0.7)
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	l.double_sided = true
	add_child(l)
	return l

## a bench to stand an instrument on (top at top_h)
func bench(top_h: float = 0.95, color: Color = Color(0.2, 0.22, 0.26)) -> void:
	add_box(Vector3(0.7, 0.05, 0.5), Vector3(0, top_h, 0), color)
	for sx in [-0.3, 0.3]:
		for sz in [-0.2, 0.2]:
			add_box(Vector3(0.06, top_h, 0.06), Vector3(sx, top_h * 0.5, sz), color.darkened(0.35))

func add_node(pos: Vector3) -> Node3D:
	var n := Node3D.new(); n.position = pos; add_child(n); return n

## register a node for motion. kind: spin | bob | twitch | pulse | flicker
func animate_node(node: Node3D, kind: String, amp: float = 1.0, speed: float = 1.0, axis: Vector3 = Vector3.UP) -> void:
	_anim.append({
		"n": node, "k": kind, "amp": amp, "sp": speed,
		"ax": axis.normalized(), "pos": node.position, "rot": node.rotation,
	})

func cfg(key: String, default):
	return config.get("config_" + key, config.get(key, default))
