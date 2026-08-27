extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TangentToboggan

## @identity
## lineage: the Rate hero — a snowless toboggan hill whose profile is a real cubic,
##   with the sled frozen at one point of it and the tangent built as a physical brass
##   rail: the exact line the sled would leave along if the hill let go of it right
##   now. A ghost of the sled hangs further down the rail, already gone.
## essence: the derivative is where you would fly off. Slope at a point is not a
##   property of the curve's drawing but of its LETTING GO - the tangent is the hill's
##   promise about the next instant, extended to a rail you can walk under.
## truth: how fast, right here? Ask the sled: its answer is a straight line, and the
##   hill agrees with it for exactly one point.
##
## The 2026-08-27 category-heroes pass, change.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 3
@export var hill_len: float = 4.2
@export var hill_h: float = 1.5
## Where the sled sits, 0..1 along the run. 0.42 puts it on the steep shoulder where
## the tangent visibly disagrees with everywhere else on the hill.
@export_range(0.05, 0.95, 0.01) var at: float = 0.42

func _curve(u: float) -> float:
	# one smooth run: starts high, a shoulder, a valley - a cubic through [0,1]
	return hill_h * (1.0 - 3.0 * u * u + 2.0 * u * u * u)

func _slope(u: float) -> float:
	return hill_h * (-6.0 * u + 6.0 * u * u) / hill_len

func _ready() -> void:
	_rng.seed = seed
	_build_hill()
	_build_sled()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "hill_len", "hill_h", "at"]:
		if config_data.has(key):
			set(key, config_data[key])

func _build_hill() -> void:
	# the profile as sled-run: segmented planks following the cubic
	var n := 26
	for i in range(n):
		var u0 := float(i) / float(n)
		var u1 := float(i + 1) / float(n)
		var p0 := Vector3(u0 * hill_len, _curve(u0), 0.0)
		var p1 := Vector3(u1 * hill_len, _curve(u1), 0.0)
		var plank := MeshInstance3D.new()
		var plank_mesh := BoxMesh.new()
		plank_mesh.size = Vector3(p0.distance_to(p1) + 0.02, 0.07, 0.9)
		plank.mesh = plank_mesh
		plank.position = (p0 + p1) * 0.5 + Vector3(0.0, -0.035, 0.0)
		plank.rotation.z = atan2(p1.y - p0.y, p1.x - p0.x)
		plank.material_override = _matte_mat(Color(0.88, 0.90, 0.94), 0.9)
		add_child(plank)
	# fenceposts under the run, so the hill stands as furniture
	for i in range(6):
		var u := (float(i) + 0.5) / 6.0
		var post := MeshInstance3D.new()
		var post_mesh := CylinderMesh.new()
		post_mesh.top_radius = 0.03
		post_mesh.bottom_radius = 0.04
		var h := maxf(_curve(u) - 0.05, 0.1)
		post_mesh.height = h
		post.mesh = post_mesh
		post.position = Vector3(u * hill_len, h * 0.5, 0.0)
		post.material_override = _matte_mat(Color(0.35, 0.22, 0.12), 0.85)
		add_child(post)

func _build_sled() -> void:
	var u := at
	var p := Vector3(u * hill_len, _curve(u), 0.0)
	# _slope already returns dy/dx (the du-derivative over dx/du = hill_len)
	var ang := atan(_slope(u))
	# THE TANGENT RAIL: brass, long both ways, touching the hill at exactly p
	var rail_len := hill_len * 1.15
	var dirv := Vector3(cos(ang), sin(ang), 0.0)
	var rail := MeshInstance3D.new()
	var rail_mesh := CylinderMesh.new()
	rail_mesh.top_radius = 0.022
	rail_mesh.bottom_radius = 0.022
	rail_mesh.height = rail_len
	rail.mesh = rail_mesh
	rail.position = p + Vector3(0.0, 0.09, 0.0)
	rail.rotation.z = ang + PI * 0.5
	rail.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
	add_child(rail)
	# the sled at the point of agreement
	var sled := _sled_body(Color(0.78, 0.16, 0.12), 1.0)
	sled.position = p + Vector3(0.0, 0.1, 0.0)
	sled.rotation.z = ang
	add_child(sled)
	# the ghost, further along the rail: the future the tangent promises
	var ghost := _sled_body(Color(0.75, 0.85, 0.95), 0.3)
	ghost.position = p + Vector3(0.0, 0.09, 0.0) + dirv * (rail_len * 0.34)
	ghost.rotation.z = ang
	add_child(ghost)
	# the point itself, marked: one glowing pin where hill and line agree
	var pin := MeshInstance3D.new()
	var pin_mesh := SphereMesh.new()
	pin_mesh.radius = 0.045
	pin_mesh.height = 0.09
	pin.mesh = pin_mesh
	pin.position = p + Vector3(0.0, 0.02, 0.0)
	pin.material_override = _glow_mat(Color(0.95, 0.85, 0.40), 1.8)
	add_child(pin)

func _sled_body(col: Color, alpha: float) -> Node3D:
	var root := Node3D.new()
	var deck := MeshInstance3D.new()
	var deck_mesh := BoxMesh.new()
	deck_mesh.size = Vector3(0.6, 0.05, 0.34)
	deck.mesh = deck_mesh
	deck.position = Vector3(0.0, 0.09, 0.0)
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(col.r, col.g, col.b, alpha)
	if alpha < 1.0:
		dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.roughness = 0.5
	deck.material_override = dm
	root.add_child(deck)
	for sz in [-0.14, 0.14]:
		var runner := MeshInstance3D.new()
		var runner_mesh := BoxMesh.new()
		runner_mesh.size = Vector3(0.72, 0.03, 0.04)
		runner.mesh = runner_mesh
		runner.position = Vector3(0.02, 0.015, sz)
		var rm := StandardMaterial3D.new()
		rm.albedo_color = Color(0.7, 0.7, 0.72, alpha)
		if alpha < 1.0:
			rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rm.metallic = 0.8
		rm.roughness = 0.3
		runner.material_override = rm
		root.add_child(runner)
	var bar := MeshInstance3D.new()
	var bar_mesh := CylinderMesh.new()
	bar_mesh.top_radius = 0.015
	bar_mesh.bottom_radius = 0.015
	bar_mesh.height = 0.3
	bar.mesh = bar_mesh
	bar.rotation.x = PI * 0.5
	bar.position = Vector3(-0.26, 0.14, 0.0)
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.35, 0.22, 0.12, alpha)
	if alpha < 1.0:
		bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bar.material_override = bm
	root.add_child(bar)
	return root

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "TangentPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(0.3, 0.24, 1.0)
	ts.rotation.y = deg_to_rad(15.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("TANGENT TOBOGGAN - d/dx",
			"The derivative is where you would fly off: the rail is the hill's promise\nabout the next instant, and the hill agrees with it for exactly one point.\nThe ghost is already gone along it. How fast, right here? Ask the sled.")
