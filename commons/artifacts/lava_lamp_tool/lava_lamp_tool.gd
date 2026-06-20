extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name LavaLampTool

## @identity
## name: "Viscous & flowing"
## tier: applied
## lineage: Viscosity as a controllable tool. Low-stiffness, high-damping blobs in a warm
##   column rise when heated from below and sink as they cool — buoyancy looped through a
##   sluggish fluid. The lamp turns "soft becomes fluid" into a slow, legible instrument.
## essence: A lava-lamp device, ~1m: a glass column over a warm base, with viscous blobs that
##   swell, lift, drift and sink in an endless slow loop. A small readout reports the viscosity
##   and heat. The flow is the point — viscosity made into a tool you can read and tune.
## truth: "HEAT LIFTS, COOL SINKS — VISCOSITY MAKES THE LOOP SLOW ENOUGH TO WATCH"
## applications: lava lamps, convection cells, magma chambers, heat engines — buoyancy through a thick fluid.

const SBShapes = preload("res://commons/soft_body/soft_body_shapes.gd")

@export var blob_count: int = 5
@export var stiffness: float = 0.20
@export var heat: float = 1.0
@export var column_h: float = 0.7
@export var column_r: float = 0.16
@export var glass_col: Color = Color(0.45, 0.70, 0.95)
@export var base_col: Color = Color(0.25, 0.22, 0.20)
@export var blob_col: Color = Color(0.98, 0.45, 0.18)
@export var readout_col: Color = Color(0.98, 0.80, 0.48)
@export var label_col: Color = Color(0.95, 0.92, 0.85)

var _t: float = 0.0
var _blobs: Array = []   # each: { node, sim, mm:MultiMesh, base:Vector3, phase:float }
var _readout: Label3D = null
var _col_base_y: float = 0.18


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("blob_count"):
		blob_count = int(clampf(float(config["blob_count"]), 3, 8))
	if config.has("stiffness"):
		stiffness = clampf(float(config["stiffness"]), 0.08, 0.4)
	if config.has("heat"):
		heat = clampf(float(config["heat"]), 0.2, 2.0)
	if config.has("blob_col"):
		blob_col = _parse_color(config["blob_col"], blob_col)
	if config.has("glass_col"):
		glass_col = _parse_color(config["glass_col"], glass_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_blobs.clear()
	_readout = null
	_build()


func _build() -> void:
	# Warm base + cap (the device housing).
	add_child(_cylinder(Vector3(0.0, 0.09, 0.0), column_r * 1.5, 0.18, _matte_mat(base_col, 0.7)))
	add_child(_cylinder(Vector3(0.0, 0.16, 0.0), column_r * 1.2, 0.04, _glow_mat(blob_col, 1.4)))   # heating element glow
	var cap_y: float = _col_base_y + column_h + 0.04
	add_child(_cylinder(Vector3(0.0, cap_y, 0.0), column_r * 1.45, 0.06, _matte_mat(base_col, 0.7)))

	# Glass column — use _glass_mat so the blobs read through it.
	add_child(_cylinder(Vector3(0.0, _col_base_y + column_h * 0.5, 0.0), column_r, column_h, _glass_mat(glass_col, 0.18)))

	# Viscous blobs stacked up the column, each with a phase so they rise/sink out of sync.
	for b in range(blob_count):
		var frac: float = float(b) / float(maxi(blob_count - 1, 1))
		var base := Vector3(_rng.randf_range(-0.04, 0.04), _col_base_y + 0.06 + frac * (column_h - 0.16), 0.0)
		_add_blob(base, float(b) * 1.1)

	# Readout panel.
	add_child(_box(Vector3(column_r * 2.4, 0.5, 0.0), Vector3(0.28, 0.18, 0.02), _matte_mat(Color(0.10, 0.11, 0.14), 0.4)))
	_readout = _billboard_label(_readout_text(), Vector3(column_r * 2.4, 0.5, 0.02), 14, readout_col)
	add_child(_readout)

	add_child(_billboard_label("HEAT LIFTS, COOL SINKS", Vector3(0.0, cap_y + 0.3, 0.0), 18, label_col))


func _add_blob(base: Vector3, phase: float) -> void:
	# Tiny low-stiffness blob — a wobbling droplet of "lava".
	var sim = SBShapes.make_jelly_box(0.085, stiffness, base - Vector3(0.0, 0.085, 0.0))
	# floor/ceiling handled manually in _process so it can rise; keep gravity gentle.
	sim.gravity = Vector3(0.0, -0.6, 0.0)
	sim.damping = 0.9
	sim.floor_y = -100.0
	for _i in 30:
		sim.step()

	var node := Node3D.new()
	add_child(node)
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.10
	sm.radial_segments = 8
	sm.rings = 5
	mm.mesh = sm
	mm.instance_count = sim.positions.size()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = blob_col
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = blob_col
	mat.emission_energy_multiplier = 0.6 if emissive else 0.15
	mmi.material_override = mat
	node.add_child(mmi)
	_blobs.append({ "node": node, "sim": sim, "mm": mm, "phase": phase })
	_refresh_blob(_blobs.size() - 1)


func _refresh_blob(idx: int) -> void:
	var blob: Dictionary = _blobs[idx]
	var sim = blob["sim"]
	var mm: MultiMesh = blob["mm"]
	for i in sim.positions.size():
		var t := Transform3D.IDENTITY
		t.origin = sim.positions[i]
		mm.set_instance_transform(i, t)


func _blob_centre_y(sim) -> float:
	var y: float = 0.0
	for i in sim.positions.size():
		y += sim.positions[i].y
	return y / float(sim.positions.size())


func _readout_text() -> String:
	return "LAVA LAMP\nviscosity: %.2f\nheat: %.2f\nblobs: %d" % [1.0 - stiffness, heat, blob_count]


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	var lo: float = _col_base_y + 0.06
	var hi: float = _col_base_y + column_h - 0.06
	for idx in range(_blobs.size()):
		var blob: Dictionary = _blobs[idx]
		var sim = blob["sim"]
		var phase: float = blob["phase"]
		# Buoyancy: a slow heat-driven sine lifts then drops each blob; viscosity (low
		# stiffness, high damping) makes the rise/fall sluggish and watchable.
		var cy: float = _blob_centre_y(sim)
		var target: float = lerp(lo, hi, 0.5 + 0.5 * sin(_t * 0.35 * heat + phase))
		var lift: float = clampf((target - cy) * 0.6, -0.01, 0.01)
		for i in sim.positions.size():
			sim.positions[i].y += lift * delta * 60.0
			# Keep blobs inside the glass column radius.
			var rx: float = sim.positions[i].x
			var rz: float = sim.positions[i].z
			var rad: float = sqrt(rx * rx + rz * rz)
			if rad > column_r - 0.04 and rad > 0.0001:
				var k: float = (column_r - 0.04) / rad
				sim.positions[i].x = rx * k
				sim.positions[i].z = rz * k
		sim.step()
		_refresh_blob(idx)
	if _readout != null:
		_readout.text = _readout_text()
