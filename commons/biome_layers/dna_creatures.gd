# dna_creatures.gd
# Seq 12: proceduralgeneration. DNA-driven critters — small bodies composed of
# a body, head, and pair of appendages whose parameters come from a seeded hash.

extends Node3D

var _critters: Array = []


func apply(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	var count_range: Array = params.get("creature_count_range", [8, 20])
	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = ctx.get("cube_size", 1.0)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(ctx.get("rng_seed", 0)) + 12
	var count: int = rng.randi_range(int(count_range[0]), int(count_range[1]))

	var radius: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.6 + 5.0
	var exclude: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.5 + 0.5

	for i in count:
		var angle: float = rng.randf() * TAU
		var r: float = rng.randf_range(exclude, radius)
		var pos: Vector3 = grid_center + Vector3(cos(angle) * r, 0.3, sin(angle) * r)
		var critter := _build_critter(rng, pos)
		add_child(critter)
		_critters.append({"root": critter, "phase": rng.randf() * TAU, "home": pos})


func _build_critter(rng: RandomNumberGenerator, pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	# DNA params
	var body_size: float = rng.randf_range(0.18, 0.35)
	var head_size: float = body_size * rng.randf_range(0.5, 0.8)
	var hue: float = rng.randf()
	var col: Color = Color.from_hsv(hue, 0.55, 0.9)

	var body := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = body_size
	bm.height = body_size * 1.6
	bm.radial_segments = 6
	bm.rings = 4
	body.mesh = bm
	_apply_mat(body, col)
	root.add_child(body)

	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = head_size
	hm.height = head_size * 2.0
	hm.radial_segments = 6
	hm.rings = 4
	head.mesh = hm
	head.position = Vector3(0, body_size * 0.9, body_size * 0.8)
	_apply_mat(head, col.lightened(0.2))
	root.add_child(head)

	# Appendages
	for side in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var lm := CylinderMesh.new()
		lm.top_radius = 0.03
		lm.bottom_radius = 0.03
		lm.height = body_size * 1.3
		lm.radial_segments = 5
		leg.mesh = lm
		leg.position = Vector3(side * body_size * 0.7, -body_size * 0.8, 0)
		_apply_mat(leg, col.darkened(0.15))
		root.add_child(leg)

	return root


func _apply_mat(mi: MeshInstance3D, col: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.4
	mi.material_override = mat


func _process(_delta: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	for c in _critters:
		var root: Node3D = c.root
		if not is_instance_valid(root):
			continue
		# Tiny idle hop
		root.position.y = c.home.y + absf(sin(t * 2.0 + c.phase)) * 0.12
