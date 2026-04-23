# rhizome_body.gd — Random-walking rhizome of capsules.
# Ported from tools/blender/fractals/rhizome.py. Grows on the ground
# plane: each step either continues in roughly the same direction or
# branches off sideways. Unlike a tree, rhizomes have no single trunk —
# they spread horizontally by random branching.
#
# DNA used:
#   max_depth    — recursion ceiling (default 40)
#   step_length  — per-step length (default 0.5)
#   variance     — direction+length jitter (default 0.3)
#   radius       — capsule radius (default 0.06)
#   seed         — deterministic seed (default 11)

extends "res://commons/morphology/sdf/body_recipe.gd"


func _build_from_dna() -> void:
	var max_depth: int = clampi(int(dna.get("max_depth", 40)), 1, 200)
	var step_length: float = float(dna.get("step_length", 0.5))
	var variance: float = clamp(float(dna.get("variance", 0.3)), 0.0, 1.0)
	var radius: float = float(dna.get("radius", 0.06))
	var seed_val: int = int(dna.get("seed", 11))

	joint_k = clamp(radius * 0.5, 0.02, 0.15)

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var start := Vector3.ZERO
	var dir := Vector3(1, 0, 0)
	_grow(start, dir, 0, max_depth, step_length, variance, radius, rng)


func _grow(start: Vector3, direction: Vector3, depth: int, max_depth: int,
		step_length: float, variance: float, radius: float,
		rng: RandomNumberGenerator) -> void:
	if depth >= max_depth:
		return
	# Jitter direction (XZ plane — rhizomes spread horizontally)
	var new_dir := Vector3(
		direction.x + rng.randf_range(-variance, variance),
		0,
		direction.z + rng.randf_range(-variance, variance),
	).normalized()
	var new_len: float = step_length * rng.randf_range(1.0 - variance, 1.0 + variance)
	var end := start + new_dir * new_len

	var cap := _capsule_helper(start, end, radius)
	_add_part(cap, "body")

	# 50/50 continue vs branch — like the Blender version
	if rng.randi() % 2 == 0:
		_grow(end, new_dir, depth + 1, max_depth, step_length, variance, radius, rng)
	else:
		var branch_dir := Vector3(
			rng.randf_range(-1.0, 1.0),
			0,
			rng.randf_range(-1.0, 1.0),
		).normalized()
		var branch_start: Vector3 = start.lerp(end, rng.randf_range(0.3, 0.7))
		_grow(branch_start, branch_dir, depth + 1, max_depth, step_length, variance, radius, rng)
