extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BudgetOfSmoothness

## @identity
## lineage: the primitives taxonomy's "budget" rung — the SAME sphere four times on
##   one counter, at radial_segments 4, 8, 16 and 64, price tags under each: 24, 96,
##   416, 7,936 triangles. The last two look almost alike; the invoice does not.
## essence: a sphere is a polyhedron in a trench coat. SphereMesh's smoothness is not
##   a property, it is a PURCHASE — radial_segments and rings buy triangles, and past
##   a certain spend the eye stops noticing the difference while the count keeps
##   climbing. The counter is a shop, and the fourth sphere is the vanity buy.
## truth: smoothness is a budget. Every curve in this world is a bill, itemised in
##   triangles.
##
## The 2026-08-27 primitives taxonomy refinement (doc/PRIMITIVES_TAXONOMY.md).

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const STEPS := [4, 8, 16, 64]

@export var seed: int = 55
@export var spin: float = 0.18

var _spheres: Array = []

func _ready() -> void:
	_rng.seed = seed
	_build_counter()
	_build_wares()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "spin"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	for s in _spheres:
		s.rotation.y += spin * delta

func _build_counter() -> void:
	var counter := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(3.0, 0.85, 0.7)
	counter.mesh = cm
	counter.position = Vector3(0.0, 0.425, 0.0)
	counter.material_override = _matte_mat(Color(0.14, 0.13, 0.15), 0.85)
	add_child(counter)

func _build_wares() -> void:
	for i in range(STEPS.size()):
		var seg: int = STEPS[i]
		var mesh := SphereMesh.new()
		mesh.radius = 0.26
		mesh.height = 0.52
		mesh.radial_segments = seg
		mesh.rings = maxi(seg / 2, 2)
		# the invoice, computed from the same numbers the engine spends
		var tris := seg * (mesh.rings - 1) * 2 + seg * 2
		var ware := MeshInstance3D.new()
		ware.mesh = mesh
		ware.position = Vector3(-1.14 + 0.76 * float(i), 1.15, 0.0)
		ware.material_override = _matte_mat(Color.from_hsv(0.55, 0.25, 0.85), 0.35, 0.15)
		add_child(ware)
		_spheres.append(ware)
		var tag := TextScreenScript.new()
		tag.mode = 2
		tag.width_m = 0.2
		tag.position = Vector3(ware.position.x, 0.87, 0.42)
		add_child(tag)
		if tag.has_method("set_text"):
			tag.set_text("segments %d" % seg, "%d triangles" % tris)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "BudgetPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-1.75, 0.24, 0.7)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("BUDGET OF SMOOTHNESS",
			"The same sphere four times: a polyhedron in a trench coat, coat priced\nin radial_segments. The last two look alike; their invoices do not.\nEvery curve in this world is a bill, itemised in triangles.")
