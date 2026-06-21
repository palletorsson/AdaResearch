extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ColonizationRoom

## @identity
## name: "Space colonization"
## tier: large
## lineage: Runions/Lindenmayer space colonization at room scale — the same pull-toward-food rule that
##   grows leaf venation, here grown into a standing tree you walk around.
## essence: a 7x7 room. ~320 attractors fill a tall volume; one root climbs ~2.5m, each attractor tugging
##   its nearest node, every node sprouting a step along the averaged pull, food consumed on contact.
##   ~360 nodes of trunk and branch. No designer placed a single limb — the negative space of the food
##   cloud is the tree. Built once, deterministic; tapering tubes, greener at the tips.
## truth: the tree is the shape of a hunger answered — growth pulled toward what feeds it, never pushed.

@export var room_seed: int = 13
@export var attractor_count: int = 320
@export var node_cap: int = 360
@export var influence_radius: float = 1.15
@export var kill_radius: float = 0.28
@export var step: float = 0.16
@export var cloud_size: Vector3 = Vector3(3.4, 2.4, 3.4)
@export var cloud_base: float = 0.7
@export var branch_col: Color = Color(0.5, 0.36, 0.24)
@export var tip_col: Color = Color(0.42, 0.74, 0.34)
@export var attractor_col: Color = Color(0.4, 0.78, 0.95)
@export var floor_col: Color = Color(0.15, 0.16, 0.19)
@export var label_col: Color = Color(0.82, 0.95, 0.88)


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("room_seed"):
		room_seed = int(config["room_seed"])
	if config.has("attractor_count"):
		attractor_count = clampi(int(config["attractor_count"]), 60, 800)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	# room floor + overhead truth
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(7.0, 0.1, 7.0), _matte_mat(floor_col, 0.92)))
	add_child(_billboard_label("SPACE COLONIZATION — a tree grown by hunger, not by hand", Vector3(0.0, 3.6, 0.0), 30, label_col))

	var grow := Node3D.new()
	add_child(grow)

	var rng := RandomNumberGenerator.new()
	rng.seed = room_seed

	# attractor cloud — a tall canopy of food
	var attractors: Array[Vector3] = []
	var alive: Array[bool] = []
	for _i in range(attractor_count):
		var p := Vector3(
			(rng.randf() - 0.5) * cloud_size.x,
			rng.randf() * cloud_size.y + cloud_base,
			(rng.randf() - 0.5) * cloud_size.z
		)
		attractors.append(p)
		alive.append(true)

	# nodes — single root on the floor
	var nodes: Array[Vector3] = [Vector3(0.0, 0.06, 0.0)]
	var depths: Array[int] = [0]
	var edges: Array = []

	var remaining: int = attractor_count
	var safety: int = 0
	while nodes.size() < node_cap and remaining > 0 and safety < node_cap * 4:
		safety += 1
		var pull := {}
		var pull_n := {}
		for ai in range(attractors.size()):
			if not alive[ai]:
				continue
			var a: Vector3 = attractors[ai]
			var best_i: int = -1
			var best_d: float = influence_radius
			for ni in range(nodes.size()):
				var d: float = a.distance_to(nodes[ni])
				if d < best_d:
					best_d = d
					best_i = ni
			if best_i >= 0:
				var dir: Vector3 = (a - nodes[best_i]).normalized()
				if pull.has(best_i):
					pull[best_i] += dir
					pull_n[best_i] += 1
				else:
					pull[best_i] = dir
					pull_n[best_i] = 1
		if pull.is_empty():
			break
		for ni in pull.keys():
			if nodes.size() >= node_cap:
				break
			var avg: Vector3 = (pull[ni] as Vector3) / float(pull_n[ni])
			# bias growth slightly upward so the trunk climbs like a real tree
			avg += Vector3(0.0, 0.18, 0.0)
			if avg.length() < 0.0001:
				continue
			var new_p: Vector3 = nodes[ni] + avg.normalized() * step
			var new_index: int = nodes.size()
			nodes.append(new_p)
			depths.append(depths[ni] + 1)
			edges.append([ni, new_index])
		for ai in range(attractors.size()):
			if not alive[ai]:
				continue
			for ni in range(nodes.size()):
				if attractors[ai].distance_to(nodes[ni]) < kill_radius:
					alive[ai] = false
					remaining -= 1
					break

	# render — tapering, greener with depth
	var max_depth: int = 1
	for d in depths:
		max_depth = maxi(max_depth, d)
	var trunk_mat := _matte_mat(branch_col, 0.85)
	for e in edges:
		var fi: int = e[0]
		var ti: int = e[1]
		var frac: float = float(depths[ti]) / float(max_depth)
		var radius: float = lerpf(0.06, 0.012, frac)
		var col: Color = branch_col.lerp(tip_col, clampf(frac, 0.0, 1.0))
		var mat: StandardMaterial3D = trunk_mat if frac < 0.5 else _glow_mat(col, 0.45)
		grow.add_child(_cylinder_between(nodes[fi], nodes[ti], radius, mat))

	# surviving food the tree never reached — sparse motes high in the canopy
	var glow := _glow_mat(attractor_col, 0.6)
	var shown: int = 0
	for ai in range(attractors.size()):
		if alive[ai] and shown < 60:
			grow.add_child(_sphere(attractors[ai], 0.022, glow))
			shown += 1


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
