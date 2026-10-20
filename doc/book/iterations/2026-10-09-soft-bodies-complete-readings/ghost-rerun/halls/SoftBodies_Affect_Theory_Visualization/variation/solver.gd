# soft_body_sim.gd — Deterministic Verlet-integrator soft body simulator.
# Particles connected by springs. Fixed-timestep headless simulation —
# load a config, step N times, capture the final geometry, render.
#
# This is NOT Godot's SoftBody3D (which is visual cloth only). This is
# a research simulator: same config + same seed = exact same pose every
# time, so the rendered PNG is a reproducible artifact of the DNA.
#
# Algorithm: Verlet integration + iterative distance-constraint relaxation.
# Each step:
#   1. update each non-pinned particle position with Verlet (pos' = 2*pos - prev + accel*dt²)
#   2. apply constraint solver N times (each spring pulls endpoints toward rest_length)
#
# Materials/rendering handled by soft_body_shapes.gd, not here.

extends RefCounted

# Particle indexed fields (parallel arrays — faster than per-particle dicts)
var positions: PackedVector3Array = PackedVector3Array()
var prev_positions: PackedVector3Array = PackedVector3Array()
var pinned: Array = []                 # bool per particle
var masses: PackedFloat32Array = PackedFloat32Array()

# Springs as (a_idx, b_idx, rest_length)
var springs: Array = []
var stiffness: float = 0.8    # 0..1, applied per constraint pass
var constraint_passes: int = 4

# Environment
var gravity: Vector3 = Vector3(0, -9.8, 0)
var damping: float = 0.995    # multiplied into Verlet velocity (1.0 = none)
var floor_y: float = -10.0    # particles stopped at this y

# Topology hints — used by the renderer to know how to draw.
# For cloth: grid_cols × grid_rows, lets the renderer emit triangles.
var topology: String = "generic"    # "cloth_grid" | "jelly_box" | "blob" | "generic"
var grid_cols: int = 0
var grid_rows: int = 0


## Step simulation forward by dt seconds (usually 1/60).
func step(dt: float = 0.0166667) -> void:
	# Verlet position update
	for i in positions.size():
		if pinned[i]:
			continue
		var pos: Vector3 = positions[i]
		var prev: Vector3 = prev_positions[i]
		var vel: Vector3 = (pos - prev) * damping
		var new_pos: Vector3 = pos + vel + gravity * dt * dt
		prev_positions[i] = pos
		positions[i] = new_pos
		# Floor collision
		if positions[i].y < floor_y:
			positions[i].y = floor_y
			prev_positions[i].y = floor_y

	# Constraint relaxation — distance constraints per spring, repeated
	for _p in constraint_passes:
		for s in springs:
			var a: int = s[0]
			var b: int = s[1]
			var rest: float = s[2]
			var pa: Vector3 = positions[a]
			var pb: Vector3 = positions[b]
			var diff: Vector3 = pb - pa
			var cur: float = diff.length()
			if cur < 1e-6:
				continue
			var correction: float = (cur - rest) * 0.5 * stiffness
			var dir: Vector3 = diff / cur
			var cv: Vector3 = dir * correction
			if not pinned[a]:
				positions[a] = pa + cv
			if not pinned[b]:
				positions[b] = pb - cv


## Run N simulation steps.
func simulate(n: int, dt: float = 0.0166667) -> void:
	for _i in n:
		step(dt)


## Add a particle. Returns index.
func add_particle(pos: Vector3, is_pinned: bool = false, mass: float = 1.0) -> int:
	var idx: int = positions.size()
	positions.append(pos)
	prev_positions.append(pos)
	pinned.append(is_pinned)
	masses.append(mass)
	return idx


## Add a spring between two particles. Rest length defaults to current distance.
func add_spring(a: int, b: int, rest_length: float = -1.0) -> void:
	if rest_length < 0.0:
		rest_length = positions[a].distance_to(positions[b])
	springs.append([a, b, rest_length])
