extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name VerletWorkbench

## @identity
## name: "Verlet & the soft-body sim"
## tier: applied
## lineage: Loup Verlet (1967) — integrate position straight from position; velocity is implied
##   by where you just were. Constraints are not solved, only nudged, pass after pass.
## essence: A workbench running the actual integrator. A cloth hangs and relaxes; a dial sets
##   the number of constraint passes per frame and a readout reports it. Crank the passes up
##   and the cloth stiffens; drop them and it sags — yet no linear system is ever solved.
##   The springs hold because we keep correcting, never because we computed an answer.
## truth: "INTEGRATE POSITION FROM POSITION — THE CONSTRAINTS HOLD WITHOUT BEING SOLVED"
## applications: every game cloth, rope, and ragdoll — Verlet is the cheap, stable workhorse.

const SBShapes = preload("res://commons/soft_body/soft_body_shapes.gd")

@export var cloth_cols: int = 10
@export var cloth_rows: int = 8
@export var cell: float = 0.085
@export var constraint_passes: int = 4
@export var stiffness: float = 0.75
@export var cloth_col: Color = Color(0.85, 0.40, 0.78)
@export var panel_col: Color = Color(0.10, 0.11, 0.14)
@export var readout_col: Color = Color(0.55, 0.95, 0.70)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

var _t: float = 0.0
var _sway: Node3D = null
var _sim = null
var _cloth_mi: MeshInstance3D = null
var _cloth_mat: StandardMaterial3D = null
var _readout: Label3D = null
var _dial: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("cloth_cols"):
		cloth_cols = clampi(int(config["cloth_cols"]), 4, 16)
	if config.has("cloth_rows"):
		cloth_rows = clampi(int(config["cloth_rows"]), 4, 14)
	if config.has("constraint_passes"):
		constraint_passes = clampi(int(config["constraint_passes"]), 1, 12)
	if config.has("stiffness"):
		stiffness = clampf(float(config["stiffness"]), 0.2, 0.95)
	if config.has("cloth_col"):
		cloth_col = _parse_color(config["cloth_col"], cloth_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sway = null
	_sim = null
	_cloth_mi = null
	_cloth_mat = null
	_readout = null
	_dial = null
	_build()


func _make_sim() -> void:
	# A cloth pinned along its top row, hung in front of the bench (XY plane, +Z out).
	var sim = SBShapes.make_cloth(cloth_cols, cloth_rows, cell, "top_corners", stiffness)
	sim.constraint_passes = constraint_passes
	sim.gravity = Vector3(0.0, -3.0, 0.0)
	sim.damping = 0.99
	sim.floor_y = -10.0
	_sim = sim
	# Pre-settle so the very first frame shows a relaxed drape, not a flat sheet.
	for _i in 60:
		_sim.step()


func _rebuild_cloth_mesh() -> ArrayMesh:
	# Build the cloth surface from the current particle positions.
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for i in _sim.positions.size():
		verts.append(_sim.positions[i])
		normals.append(Vector3.UP)
	for r in cloth_rows - 1:
		for c in cloth_cols - 1:
			var i0: int = r * cloth_cols + c
			var i1: int = r * cloth_cols + c + 1
			var i2: int = (r + 1) * cloth_cols + c + 1
			var i3: int = (r + 1) * cloth_cols + c
			indices.append_array([i0, i1, i2, i0, i2, i3])
	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am


func _build() -> void:
	# Bench
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(1.2, 0.2, 0.7), _matte_mat(Color(0.16, 0.17, 0.20), 0.85)))
	add_child(_cylinder(Vector3(0.0, 0.45, 0.0), 0.07, 0.5, _steel_mat(Color(0.34, 0.36, 0.40))))
	# A frame the cloth hangs from
	add_child(_box(Vector3(0.0, 1.32, -0.05), Vector3(cloth_cols * cell + 0.12, 0.04, 0.06), _matte_mat(Color(0.30, 0.32, 0.36), 0.6)))
	add_child(_cylinder_between(Vector3(-(cloth_cols * cell) * 0.5, 0.86, -0.05), Vector3(-(cloth_cols * cell) * 0.5, 1.32, -0.05), 0.02, _matte_mat(Color(0.30, 0.32, 0.36), 0.6)))
	add_child(_cylinder_between(Vector3((cloth_cols * cell) * 0.5, 0.86, -0.05), Vector3((cloth_cols * cell) * 0.5, 1.32, -0.05), 0.02, _matte_mat(Color(0.30, 0.32, 0.36), 0.6)))

	var sway := Node3D.new()
	sway.name = "ClothSway"
	add_child(sway)
	_sway = sway

	_make_sim()
	# Cloth sits at the top of the frame, draping forward and down.
	var cloth_holder := Node3D.new()
	cloth_holder.position = Vector3(0.0, 1.3, 0.06)
	sway.add_child(cloth_holder)

	_cloth_mat = StandardMaterial3D.new()
	_cloth_mat.albedo_color = cloth_col
	_cloth_mat.roughness = 0.5
	_cloth_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cloth_mat.emission_enabled = true
	_cloth_mat.emission = cloth_col
	_cloth_mat.emission_energy_multiplier = 0.35 if emissive else 0.0

	_cloth_mi = MeshInstance3D.new()
	_cloth_mi.mesh = _rebuild_cloth_mesh()
	_cloth_mi.material_override = _cloth_mat
	cloth_holder.add_child(_cloth_mi)

	# Constraint-pass dial + readout panel (the applied control surface)
	var dial := Node3D.new()
	dial.position = Vector3(0.62, 0.95, 0.28)
	add_child(dial)
	_dial = dial
	dial.add_child(_cylinder(Vector3.ZERO, 0.07, 0.04, _steel_mat(Color(0.4, 0.42, 0.46))))
	# A pointer notch on the dial so its rotation is legible.
	dial.add_child(_box(Vector3(0.0, 0.03, 0.045), Vector3(0.012, 0.012, 0.05), _glow_mat(readout_col, 1.6)))

	add_child(_box(Vector3(0.55, 1.18, 0.25), Vector3(0.34, 0.18, 0.02), _matte_mat(panel_col, 0.4)))
	_readout = _billboard_label(_readout_text(), Vector3(0.55, 1.18, 0.27), 16, readout_col)
	add_child(_readout)

	add_child(_billboard_label("INTEGRATE POSITION FROM POSITION", Vector3(0.0, 1.62, 0.0), 22, label_col))


func _readout_text() -> String:
	return "VERLET\npasses: %d\nstiffness: %.2f\n(constraints held, never solved)" % [_sim.constraint_passes, stiffness]


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Live cloth: re-run the integrator and rebuild only the surface positions.
	if _sim != null:
		# A faint breeze so the drape keeps moving (and the relaxation stays visible).
		var gust: float = sin(_t * 0.8) * 0.6
		_sim.gravity = Vector3(gust, -3.0, 0.3 * sin(_t * 0.5))
		_sim.step()
		if _cloth_mi != null:
			_cloth_mi.mesh = _rebuild_cloth_mesh()
	if _dial != null:
		_dial.rotation.y = sin(_t * 0.3) * 0.6
	if _sway != null:
		_sway.rotation.y = sin(_t * 0.25) * 0.06
