extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ParlourOrbits

## @identity
## lineage: a séance for gravity — a parlour rug with a bowling-ball sun at its centre,
##   and around it the museum's own things in orbit: a chladni plate flying as a saucer,
##   a fire extinguisher on a long comet ellipse, an exit sign circling like a moon.
##   The rug dips toward the middle, because that is where the mass sits.
## essence: every body pulls every body by Gm₁m₂/r² — the sun holds the parlour, but the
##   props also tug each other, so no orbit repeats exactly. Integrated semi-implicitly
##   each frame from seeded initial conditions: real attraction, not an animation loop.
## truth: orbit is not a track, it is a permanent falling-toward that keeps missing.
##   The rug's dip is the well; the props are furniture that never stops falling in.
##
## The 2026-08-27 forces brief: "object hanging in mid art … more beautiful but more
## surreal" — attraction and n-body, dressed as a living room.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

# Orbiters: cast token, bead size, gravitational mass (arbitrary units — only ratios
# matter), starting radius, and eccentricity nudge (0 = circular).
const ORBITERS := [
	{"token": "chladni_plate", "bead": 0.30, "mu": 1.0, "r": 0.85, "ecc": 0.05},
	{"token": "exit_sign", "bead": 0.26, "mu": 0.6, "r": 1.15, "ecc": 0.12},
	{"token": "fire_extinguisher", "bead": 0.34, "mu": 1.4, "r": 1.5, "ecc": 0.38},
	{"token": "control_pendulum", "bead": 0.28, "mu": 0.8, "r": 0.62, "ecc": 0.08},
]
const SUN_MU := 60.0                   # the bowling ball outweighs the parlour
const G := 0.22                        # tuned so the inner orbit takes ~4 s
const ORBIT_Y := 0.62                  # orbital plane height above the rug
const TRAIL_LEN := 90                  # ~1.5 s of ribbon at 60 fps

@export var seed: int = 9
@export var rug_r: float = 1.7

var _bodies: Array = []                # {node, vel: Vector3, mu: float, trail: Array, mesh: ImmediateMesh}

func _ready() -> void:
	_rng.seed = seed
	_build_rug()
	_build_sun()
	_build_orbiters()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "rug_r"]:
		if config_data.has(key):
			set(key, config_data[key])

func _physics_process(delta: float) -> void:
	# Semi-implicit Euler over every pair: the sun pulls the props, the props pull each
	# other. The sun stays pinned — this parlour's one concession, or the furniture
	# would walk the rug out of the hall.
	var dt: float = minf(delta, 1.0 / 30.0)
	for i in range(_bodies.size()):
		var b: Dictionary = _bodies[i]
		var pos: Vector3 = b["node"].position
		var acc: Vector3 = -pos.normalized() * (G * SUN_MU / maxf(pos.length_squared(), 0.04))
		for j in range(_bodies.size()):
			if j == i:
				continue
			var other: Dictionary = _bodies[j]
			var d: Vector3 = other["node"].position - pos
			var mu_j: float = other["mu"]
			acc += d.normalized() * (G * mu_j / maxf(d.length_squared(), 0.04))
		b["vel"] += acc * dt
	for b in _bodies:
		b["node"].position += b["vel"] * dt
		# hold the séance to its plane — the vertical component of the pulls is real
		# but the parlour is a 2D drawing of a 3D law, and says so on the placard
		b["node"].position.y = ORBIT_Y
		b["vel"].y = 0.0
		_update_trail(b)

# --- build --------------------------------------------------------------------------

func _build_rug() -> void:
	# The well, made of fabric: four concentric rings stepping down toward the sun.
	var tones := [Color(0.42, 0.16, 0.14), Color(0.55, 0.30, 0.16), Color(0.42, 0.16, 0.14), Color(0.30, 0.12, 0.12)]
	for i in range(4):
		var ring := MeshInstance3D.new()
		var ring_mesh := CylinderMesh.new()
		ring_mesh.top_radius = rug_r * (1.0 - 0.22 * float(i))
		ring_mesh.bottom_radius = rug_r * (1.0 - 0.22 * float(i))
		ring_mesh.height = 0.02
		ring.mesh = ring_mesh
		ring.position = Vector3(0.0, 0.05 - 0.012 * float(i), 0.0)
		ring.material_override = _matte_mat(tones[i], 0.95)
		add_child(ring)
	var fringe := MeshInstance3D.new()
	var fringe_mesh := TorusMesh.new()
	fringe_mesh.inner_radius = rug_r - 0.02
	fringe_mesh.outer_radius = rug_r + 0.05
	fringe.mesh = fringe_mesh
	fringe.position = Vector3(0.0, 0.05, 0.0)
	fringe.material_override = _matte_mat(Color(0.75, 0.65, 0.42), 0.9)
	add_child(fringe)

func _build_sun() -> void:
	var ball := MeshInstance3D.new()
	var ball_mesh := SphereMesh.new()
	ball_mesh.radius = 0.24
	ball_mesh.height = 0.48
	ball.mesh = ball_mesh
	ball.position = Vector3(0.0, ORBIT_Y, 0.0)
	var bm := _matte_mat(Color(0.05, 0.05, 0.07), 0.15, 0.3)
	bm.emission_enabled = true
	bm.emission = Color(0.9, 0.45, 0.12)
	bm.emission_energy_multiplier = 0.25 if emissive else 0.08
	ball.material_override = bm
	add_child(ball)
	# three finger holes, because a sun this domestic is still a bowling ball
	for k in range(3):
		var hole := MeshInstance3D.new()
		var hole_mesh := CylinderMesh.new()
		hole_mesh.top_radius = 0.022
		hole_mesh.bottom_radius = 0.022
		hole_mesh.height = 0.02
		hole.mesh = hole_mesh
		var ang := 0.5 + 0.35 * float(k)
		hole.position = Vector3(0.0, ORBIT_Y, 0.0) + Vector3(sin(ang) * 0.21, cos(ang) * 0.21, 0.09)
		hole.look_at_from_position(hole.position, Vector3(0.0, ORBIT_Y, 0.0), Vector3.UP)
		hole.material_override = _matte_mat(Color(0.0, 0.0, 0.0), 1.0)
		add_child(hole)

func _build_orbiters() -> void:
	for row in ORBITERS:
		var node := Node3D.new()
		var ang := _rng.randf_range(0.0, TAU)
		var r: float = row["r"]
		node.position = Vector3(cos(ang) * r, ORBIT_Y, sin(ang) * r)
		add_child(node)
		_dress(node, row)
		# circular speed for the sun alone, nudged by ecc — the prop pulls do the rest
		var v_circ := sqrt(G * SUN_MU / r)
		var tangent := Vector3(-sin(ang), 0.0, cos(ang))
		var ecc: float = row["ecc"]
		var vel := tangent * (v_circ * (1.0 + ecc * _rng.randf_range(-1.0, 1.0)))
		var trail := MeshInstance3D.new()
		var im := ImmediateMesh.new()
		trail.mesh = im
		var tm := _glow_mat(Color(0.85, 0.80, 0.65), 0.9)
		tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tm.albedo_color.a = 0.5
		trail.material_override = tm
		add_child(trail)
		_bodies.append({"node": node, "vel": vel, "mu": row["mu"], "trail": [], "mesh": im})

func _dress(node: Node3D, row: Dictionary) -> void:
	var path := "res://commons/artifacts/%s/%s.tscn" % [row["token"], row["token"]]
	var packed: PackedScene = load(path)
	if packed == null:
		push_warning("parlour_orbits: cast prop %s missing, bead substituted" % row["token"])
		var box := MeshInstance3D.new()
		box.mesh = BoxMesh.new()
		box.scale = Vector3.ONE * row["bead"] * 0.7
		box.material_override = _matte_mat(Color(0.6, 0.55, 0.5))
		node.add_child(box)
		return
	var inst: Node3D = packed.instantiate()
	node.add_child(inst)
	var pstack: Array = [inst]
	while not pstack.is_empty():
		var pn: Node = pstack.pop_back()
		if pn is RigidBody3D:
			(pn as RigidBody3D).freeze = true
		for pc in pn.get_children():
			pstack.append(pc)
	var aabb := _merged_aabb(inst)
	var longest: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if longest > 0.001:
		var s: float = row["bead"] / longest
		inst.scale = Vector3.ONE * s
		inst.position = -(aabb.get_center() * s)

func _merged_aabb(root: Node3D) -> AABB:
	var to_local := root.global_transform.affine_inverse()
	var merged := AABB()
	var first := true
	var stack: Array = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D:
			var mi := node as MeshInstance3D
			var box: AABB = (to_local * mi.global_transform) * mi.get_aabb()
			if first:
				merged = box
				first = false
			else:
				merged = merged.merge(box)
		for child in node.get_children():
			stack.append(child)
	return merged

func _update_trail(b: Dictionary) -> void:
	var trail: Array = b["trail"]
	trail.append(b["node"].position)
	if trail.size() > TRAIL_LEN:
		trail.pop_front()
	var im: ImmediateMesh = b["mesh"]
	im.clear_surfaces()
	if trail.size() < 2:
		return
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in trail:
		im.surface_add_vertex(p)
	im.surface_end()

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "OrbitsPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-rug_r - 0.35, 0.24, 0.9)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("PARLOUR ORBITS",
			"Everything pulls everything: Gmm/r2, integrated live - the props also tug\neach other, so no orbit ever repeats. The rug dips where the mass sits.\nOrbit is falling that keeps missing. (Drawn flat: a 2D parlour of a 3D law.)")
