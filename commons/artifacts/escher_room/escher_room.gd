extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name EscherRoom

## @identity
## name: Escher Room — Consistent at Every Corner, Impossible as a Whole
## concept: Escher & impossible objects
## tier: large
## lineage: M.C. Escher, "Relativity" (1953) and "Ascending and Descending" (1960),
##   built on the Penrose stair (Penrose & Penrose, 1958). Each junction obeys local
##   geometry; the global figure cannot exist in Euclidean space.
## essence: a room whose every wall and ceiling carries a staircase, each climbing a
##   different gravity. A Penrose loop of four flights turns in the centre — a walker
##   could climb it forever and never rise. Every corner is locally consistent; the
##   whole is impossible.
## truth: local consistency does not buy global coherence. A formal system can be sound
##   at every step and still describe a world that cannot be — incompleteness you can
##   walk through.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var accent: Color = Color(0.36, 0.95, 0.78)   # the one impossible loop glows
@export var room_size: float = 7.0
@export var climb_period: float = 5.0

var _t: float = 0.0
var _loop_steps: Array = []      # MeshInstance3D treads of the Penrose loop
var _loop_centers: Array = []    # Vector3 tread centres (local)
var _climber: MeshInstance3D
var _wall_mats: Array = []       # StandardMaterial3D of the wall flights (subtle pulse)


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("room_size"):
		room_size = float(config["room_size"])
	if config.has("climb_period"):
		climb_period = float(config["climb_period"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_loop_steps = []
	_loop_centers = []
	_wall_mats = []

	var purple_mat: StandardMaterial3D = _glow_mat(wire_purple, 0.5)
	var white_mat: StandardMaterial3D = _glow_mat(cool_white, 0.45)
	var floor_mat: StandardMaterial3D = _matte_mat(Color(0.07, 0.08, 0.13), 0.9)
	var hs: float = room_size * 0.5

	# --- floor + chalk border ---
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(room_size, 0.06, room_size), floor_mat))
	add_child(_box(Vector3(0.0, 0.01, hs - 0.1), Vector3(room_size - 0.2, 0.01, 0.02), purple_mat))
	add_child(_box(Vector3(0.0, 0.01, -hs + 0.1), Vector3(room_size - 0.2, 0.01, 0.02), purple_mat))
	add_child(_box(Vector3(hs - 0.1, 0.01, 0.0), Vector3(0.02, 0.01, room_size - 0.2), purple_mat))
	add_child(_box(Vector3(-hs + 0.1, 0.01, 0.0), Vector3(0.02, 0.01, room_size - 0.2), purple_mat))

	# --- wireframe room cage (the cube whose every face hosts a staircase) ---
	_build_cage(hs)

	# --- staircases climbing every which way (the Relativity tangle) ---
	# floor stair (normal gravity)
	_build_flight(Vector3(-hs + 1.2, 0.0, hs - 1.4), Vector3(0.0, 1.0, 0.0), Vector3(0.0, 0.0, -1.0), 8, white_mat)
	# wall stair — climbs UP a side wall (gravity points to that wall)
	_build_flight(Vector3(hs - 0.4, 0.6, -hs + 1.2), Vector3(-1.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0), 7, purple_mat)
	# back-wall stair — runs sideways along the far wall
	_build_flight(Vector3(-hs + 1.0, 0.8, -hs + 0.4), Vector3(0.0, 1.0, 0.0), Vector3(1.0, 0.0, 0.0), 7, white_mat)
	# ceiling stair — hangs from the roof, gravity inverted
	_build_flight(Vector3(hs - 1.2, room_size - 0.5, hs - 1.0), Vector3(0.0, -1.0, 0.0), Vector3(-1.0, 0.0, 0.0), 6, purple_mat)

	# --- the impossible Penrose loop in the centre (the heart) ---
	_build_penrose_loop(Vector3(0.0, room_size * 0.42, 0.0), 1.55)

	# the eternal climber on the loop
	_climber = _box(Vector3.ZERO, Vector3(0.22, 0.32, 0.22), _glow_mat(accent, 1.6))
	add_child(_climber)

	# --- overhead title ---
	add_child(_billboard_label("CONSISTENT AT EVERY CORNER", Vector3(0.0, 3.6, 0.0), 32, cool_white))
	add_child(_billboard_label("IMPOSSIBLE AS A WHOLE", Vector3(0.0, 3.3, 0.0), 32, accent))
	add_child(_billboard_label("Escher / Penrose — impossible objects", Vector3(0.0, 3.04, 0.0), 16, wire_purple))


func _build_cage(hs: float) -> void:
	var edge_mat: StandardMaterial3D = _glow_mat(wire_purple, 0.35)
	var r: float = 0.025
	var h: float = room_size
	# 4 vertical posts
	var corners: Array = [Vector3(-hs, 0.0, -hs), Vector3(hs, 0.0, -hs), Vector3(hs, 0.0, hs), Vector3(-hs, 0.0, hs)]
	for i in range(4):
		var c: Vector3 = corners[i]
		add_child(_cylinder_between(c, c + Vector3(0.0, h, 0.0), r, edge_mat))
	# top + bottom rings
	for level in [0.0, h]:
		for i in range(4):
			var a: Vector3 = corners[i] + Vector3(0.0, level, 0.0)
			var b: Vector3 = corners[(i + 1) % 4] + Vector3(0.0, level, 0.0)
			add_child(_cylinder_between(a, b, r, edge_mat))


func _build_flight(origin: Vector3, up_dir: Vector3, run_dir: Vector3, steps: int, mat: Material) -> void:
	# A staircase whose local "up" is up_dir and which advances along run_dir.
	# Each tread is a slab; risers stack along up_dir, treads march along run_dir.
	var holder := Node3D.new()
	add_child(holder)
	var u: Vector3 = up_dir.normalized()
	var run: Vector3 = run_dir.normalized()
	var tread_w: float = 0.55
	var rise: float = 0.30
	var depth: float = 0.42
	# a basis: run along local Z, up along local Y
	var z_axis: Vector3 = run
	var y_axis: Vector3 = u
	var x_axis: Vector3 = y_axis.cross(z_axis).normalized()
	if x_axis.length() < 0.001:
		x_axis = Vector3.RIGHT
	var b := Basis(x_axis, y_axis, z_axis)
	var i: int = 0
	while i < steps:
		var p: Vector3 = origin + run * (float(i) * depth) + u * (float(i) * rise)
		var slab: MeshInstance3D = _box(Vector3.ZERO, Vector3(tread_w, 0.10, depth), mat)
		slab.transform = Transform3D(b, p)
		holder.add_child(slab)
		# riser face
		var riser: MeshInstance3D = _box(Vector3.ZERO, Vector3(tread_w, rise, 0.08), mat)
		riser.transform = Transform3D(b, p - run * (depth * 0.5) + u * (rise * 0.5))
		holder.add_child(riser)
		i += 1


func _build_penrose_loop(center: Vector3, span: float) -> void:
	# Four flights chained head-to-tail around a square so the climber rises on every
	# flight yet returns to the start — the impossible loop. We cheat the geometry the
	# way Escher did: each flight rises in its own plane, the closing flight steps back
	# down through the z-gap so the figure "closes" though it cannot in 3-space.
	var holder := Node3D.new()
	holder.position = center
	add_child(holder)
	var mat: StandardMaterial3D = _glow_mat(accent, 0.9)
	var per_flight: int = 6
	var rise: float = 0.16
	var s: float = span
	# corners of the square (local), going CCW
	var corners: Array = [Vector3(-s, 0.0, -s), Vector3(s, 0.0, -s), Vector3(s, 0.0, s), Vector3(-s, 0.0, s)]
	var leg: int = 0
	while leg < 4:
		var a: Vector3 = corners[leg]
		var bc: Vector3 = corners[(leg + 1) % 4]
		var base_h: float = float(leg) * (per_flight * rise)
		var k: int = 0
		while k < per_flight:
			var f0: float = float(k) / float(per_flight)
			var pos: Vector3 = a.lerp(bc, f0)
			pos.y = base_h + float(k) * rise
			# the closing leg descends back toward 0 through the impossible z-gap
			if leg == 3:
				pos.y = base_h + float(k) * rise
				pos.z += -0.18  # the Escher offset that lets it "close"
			var run: Vector3 = (bc - a).normalized()
			var x_axis: Vector3 = Vector3.UP.cross(run).normalized()
			if x_axis.length() < 0.001:
				x_axis = Vector3.RIGHT
			var b := Basis(x_axis, Vector3.UP, run)
			var tread: MeshInstance3D = _box(Vector3.ZERO, Vector3(0.5, 0.08, 0.36), mat)
			tread.transform = Transform3D(b, pos)
			holder.add_child(tread)
			_loop_steps.append(tread)
			_loop_centers.append(holder.position + pos)
			k += 1
		leg += 1


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# the impossible loop pulses — it is the one figure that cannot be
	var pulse: float = 0.6 + 0.4 * sin(_t * 2.2)
	for s in _loop_steps:
		var mi: MeshInstance3D = s as MeshInstance3D
		if is_instance_valid(mi):
			var m: StandardMaterial3D = mi.material_override as StandardMaterial3D
			if m != null:
				m.emission_energy_multiplier = (0.9 if emissive else 0.3) * (0.7 + pulse)

	# the climber walks the loop endlessly, never rising overall
	if is_instance_valid(_climber) and _loop_centers.size() > 0:
		var phase: float = fmod(_t, climb_period) / climb_period
		var fidx: float = phase * float(_loop_centers.size())
		var i0: int = int(floor(fidx)) % _loop_centers.size()
		var i1: int = (i0 + 1) % _loop_centers.size()
		var frac: float = fidx - floor(fidx)
		var a: Vector3 = _loop_centers[i0]
		var b: Vector3 = _loop_centers[i1]
		_climber.position = a.lerp(b, frac) + Vector3(0.0, 0.22, 0.0)
		_climber.rotation.y = _t * 0.8
