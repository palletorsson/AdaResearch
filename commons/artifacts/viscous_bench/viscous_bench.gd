extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ViscousBench

## @identity
## name: "Viscous & flowing"
## tier: medium
## lineage: The same Verlet jelly, but with the stiffness turned right down and the damping
##   right up. Springs barely pull back; motion is sluggish and lossy. The result stops
##   behaving like a solid and starts to ooze — soft slides into fluid by a single parameter.
## essence: A bench-top tray of viscous blobs, sitting on the bench in front of you. The blobs
##   slump, ooze toward each other and merge into low domes — none of them spring back. Drop the
##   stiffness far enough and "soft" becomes "flowing": this bench shows the crossover.
## truth: "TURN DOWN THE STIFFNESS AND SOFT BECOMES FLUID"
## applications: honey, lava, magma, melted glass, mud — materials that flow because they barely resist.

const SBShapes = preload("res://commons/soft_body/soft_body_shapes.gd")

@export var blob_count: int = 4
@export var stiffness: float = 0.22
@export var damping: float = 0.86
@export var tray_col: Color = Color(0.18, 0.19, 0.23)
@export var blob_a: Color = Color(0.95, 0.55, 0.20)
@export var blob_b: Color = Color(0.92, 0.30, 0.42)
@export var label_col: Color = Color(0.95, 0.92, 0.85)

var _t: float = 0.0
var _blobs: Array = []   # each: { node, sim, mm:MultiMesh, base:Vector3 }
var _top_y: float = 0.85


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("blob_count"):
		blob_count = int(clampf(float(config["blob_count"]), 2, 7))
	if config.has("stiffness"):
		stiffness = clampf(float(config["stiffness"]), 0.08, 0.5)
	if config.has("damping"):
		damping = clampf(float(config["damping"]), 0.7, 0.95)
	if config.has("blob_a"):
		blob_a = _parse_color(config["blob_a"], blob_a)
	if config.has("blob_b"):
		blob_b = _parse_color(config["blob_b"], blob_b)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_blobs.clear()
	_build()


func _build() -> void:
	# Bench top + a shallow tray the blobs ooze across (body ON TOP, facing +Z).
	add_child(_box(Vector3(0.0, _top_y - 0.02, 0.0), Vector3(1.4, 0.04, 0.7), _matte_mat(Color(0.30, 0.31, 0.34), 0.8)))
	add_child(_box(Vector3(0.0, _top_y + 0.01, 0.0), Vector3(1.2, 0.02, 0.55), _matte_mat(tray_col, 0.6)))
	# Tray lip so the ooze reads as contained.
	for lx in [-0.6, 0.6]:
		add_child(_box(Vector3(lx, _top_y + 0.04, 0.0), Vector3(0.02, 0.08, 0.55), _matte_mat(tray_col, 0.6)))
	for lz in [-0.27, 0.27]:
		add_child(_box(Vector3(0.0, _top_y + 0.04, lz), Vector3(1.2, 0.08, 0.02), _matte_mat(tray_col, 0.6)))

	for b in range(blob_count):
		var fx: float = (float(b) / float(maxi(blob_count - 1, 1)) - 0.5) * 0.8
		var base := Vector3(fx, _top_y + 0.02, _rng.randf_range(-0.08, 0.08))
		var col: Color = blob_a if b % 2 == 0 else blob_b
		_add_blob(base, col)

	add_child(_billboard_label("TURN DOWN THE STIFFNESS AND SOFT BECOMES FLUID", Vector3(0.0, 1.6, 0.0), 18, label_col))


func _add_blob(base: Vector3, col: Color) -> void:
	# A small dense jelly grid with very low stiffness — it slumps instead of holding shape.
	var sim = SBShapes.make_jelly_grid(3, 2, 3, 0.07, stiffness, base)
	sim.floor_y = base.y
	sim.gravity = Vector3(0.0, -2.6, 0.0)
	sim.damping = damping
	# Pre-settle long enough to let it slump into a low viscous dome.
	for _i in 60:
		sim.step()

	var node := Node3D.new()
	node.position = base
	add_child(node)
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 0.07
	sm.height = 0.14
	sm.radial_segments = 8
	sm.rings = 4
	mm.mesh = sm
	mm.instance_count = sim.positions.size()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.25
	mat.metallic = 0.1
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.4 if emissive else 0.0
	mmi.material_override = mat
	node.add_child(mmi)
	_blobs.append({ "node": node, "sim": sim, "mm": mm, "base": base })
	_refresh_blob(_blobs.size() - 1)


func _refresh_blob(idx: int) -> void:
	var blob: Dictionary = _blobs[idx]
	var sim = blob["sim"]
	var mm: MultiMesh = blob["mm"]
	var base: Vector3 = blob["base"]
	for i in sim.positions.size():
		var t := Transform3D.IDENTITY
		t.origin = sim.positions[i] - base
		mm.set_instance_transform(i, t)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Slow ooze: a gentle horizontal drift nudges blobs to slump and creep, so the bench
	# never freezes. Low stiffness means they keep flowing rather than springing back.
	for idx in range(_blobs.size()):
		var blob: Dictionary = _blobs[idx]
		var sim = blob["sim"]
		var drift: float = sin(_t * 0.6 + float(idx) * 1.3) * 0.0015
		for i in sim.positions.size():
			sim.positions[i].x += drift
		sim.step()
		_refresh_blob(idx)
