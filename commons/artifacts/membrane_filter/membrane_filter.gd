extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MembraneFilter

## @identity
## name: "The membrane"
## tier: applied
## lineage: The membrane put to work as a dialysis filter. A mixed stream enters one chamber;
##   only the small molecules diffuse through the semi-permeable wall; the large ones stay
##   behind. A readout counts what passed and what was blocked.
## truth: "THE BOUNDARY THAT MAKES AN INSIDE, WHILE LETTING THE WORLD ACROSS — NOW METERED"
## applications: dialysis, reverse osmosis, water purification, blood filtration — the membrane
##   as an engineered sorter of the world.

const N_MIX: int = 24

@export var chamber_w: float = 0.34
@export var small_col: Color = Color(0.55, 0.95, 0.62)
@export var big_col: Color = Color(0.95, 0.50, 0.42)
@export var membrane_col: Color = Color(0.50, 0.80, 0.96)
@export var body_col: Color = Color(0.18, 0.19, 0.23)
@export var readout_col: Color = Color(0.98, 0.82, 0.50)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

var _t: float = 0.0
var _mm: MultiMesh = null
var _parts: Array = []   # each: { pos, vel, big:bool, passed:bool }
var _passed: int = 0
var _blocked: int = 0
var _readout: Label3D = null
var _wall_x: float = 0.0
var _y0: float = 0.55


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("membrane_col"):
		membrane_col = _parse_color(config["membrane_col"], membrane_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_mm = null
	_parts.clear()
	_readout = null
	_passed = 0
	_blocked = 0
	_build()


func _build() -> void:
	# Device housing — a ~1m benchtop dialysis box.
	add_child(_box(Vector3(0.0, 0.06, 0.0), Vector3(1.0, 0.12, 0.5), _matte_mat(body_col, 0.8)))
	add_child(_box(Vector3(0.0, _y0, 0.0), Vector3(0.95, 0.5, 0.42), _glass_mat(Color(0.6, 0.7, 0.85), 0.10)))

	# Two chambers split by the membrane at x = 0.
	# Left (feed, +x... actually x<0) holds the mixed input; right is the filtrate side.
	add_child(_box(Vector3(_wall_x, _y0, 0.0), Vector3(0.012, 0.46, 0.40), _glass_mat(membrane_col, 0.4)))
	for i in range(5):
		var py: float = _y0 - 0.18 + float(i) * 0.09
		add_child(_torus(Vector3(_wall_x, py, 0.0), 0.028, 0.006, _glow_mat(membrane_col, 0.7)))

	# Inlet pipe (left) and two outlets (retentate left-up, filtrate right).
	add_child(_cylinder_between(Vector3(-0.6, _y0 + 0.1, 0.0), Vector3(-0.45, _y0 + 0.1, 0.0), 0.03, _steel_mat(Color(0.5, 0.5, 0.55))))
	add_child(_cylinder_between(Vector3(0.45, _y0, 0.0), Vector3(0.6, _y0, 0.0), 0.025, _steel_mat(small_col)))

	# Mixed feed particles, all starting in the left chamber.
	_mm = _make_field(N_MIX, small_col)
	for i in range(N_MIX):
		var is_big: bool = (i % 3 == 0)
		_parts.append({
			"pos": Vector3(_rng.randf_range(-0.42, -0.05), _y0 + _rng.randf_range(-0.18, 0.18), _rng.randf_range(-0.16, 0.16)),
			"vel": Vector3(_rng.randf_range(0.02, 0.07), 0, 0),
			"big": is_big,
			"passed": false,
		})
	_refresh()

	# Readout panel.
	add_child(_box(Vector3(0.0, _y0 + 0.36, 0.0), Vector3(0.5, 0.16, 0.02), _matte_mat(Color(0.08, 0.09, 0.12), 0.4)))
	_readout = _billboard_label(_readout_text(), Vector3(0.0, _y0 + 0.36, 0.02), 15, readout_col)
	add_child(_readout)

	add_child(_billboard_label("DIALYSIS MEMBRANE — SMALL PASS, LARGE HELD BACK", Vector3(0.0, _y0 + 0.6, 0.0), 18, label_col))


func _make_field(n: int, _col: Color) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 8
	sm.rings = 4
	mm.mesh = sm
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.6 if emissive else 0.0
	mi.material_override = mat
	add_child(mi)
	return mm


func _refresh() -> void:
	for i in range(_parts.size()):
		var p: Dictionary = _parts[i]
		var r: float = 0.05 if bool(p["big"]) else 0.018
		var t := Transform3D(Basis().scaled(Vector3(r, r, r)), p["pos"])
		_mm.set_instance_transform(i, t)
		_mm.set_instance_color(i, big_col if bool(p["big"]) else small_col)


func _readout_text() -> String:
	return "MEMBRANE FILTER\npassed:  %d\nblocked: %d\nsorting: live" % [_passed, _blocked]


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	for i in range(_parts.size()):
		var p: Dictionary = _parts[i]
		var pos: Vector3 = p["pos"]
		var vel: Vector3 = p["vel"]
		pos += vel
		# At the membrane: big particles bounce back into the feed, small ones pass once.
		if pos.x >= _wall_x - 0.01 and not bool(p["passed"]):
			if bool(p["big"]):
				vel.x = -absf(vel.x) * 0.8
				pos.x = _wall_x - 0.02
				if not p.get("_counted_block", false):
					_blocked += 1
					p["_counted_block"] = true
			else:
				p["passed"] = true
				_passed += 1
		# Confine within the box; recycle particles that exit far right or settle.
		if pos.x > 0.45:
			pos.x = -0.42
			pos.y = _y0 + _rng.randf_range(-0.18, 0.18)
			p["passed"] = false
			p["_counted_block"] = false
			vel.x = absf(vel.x)
		if pos.x < -0.45:
			vel.x = absf(vel.x)
		pos.y = _y0 + sin(_t * 0.9 + float(i)) * 0.16
		p["pos"] = pos
		p["vel"] = vel
	_refresh()
	if _readout != null:
		_readout.text = _readout_text()
