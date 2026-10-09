# rd_displace_op.gd — Reaction-diffusion pattern as displacement modulator.
# Runs a Gray-Scott sim on a 2D grid once, then samples the result at
# each node's projected (x, z) position to drive a displacement along Y
# (or any axis). Produces organic displacement patterns — spots, stripes,
# labyrinths — depending on (F, K) parameters.
#
# Because the sim is 2D and projected, this works best on tree-like graphs
# that fit roughly in a XZ footprint. For fully 3D organisms it still
# produces interesting patterns but is no longer "correct" RD.
#
# Params:
#   pattern     — "spots" | "stripes" | "mazes" (preset F/K), default "spots"
#   F           — feed rate override
#   K           — kill rate override
#   iterations  — sim steps (default 3000 — one-time cost)
#   grid_size   — resolution of the RD grid (default 96)
#   world_size  — meters the grid covers (centered on origin) (default 3.0)
#   amp         — max displacement magnitude (default 0.25)
#   displace    — Vector3-like axis to push (default [0, 1, 0])
#   seed        — RNG seed for initial perturbations (default 7)
extends "res://commons/graph_grammar/graph_rule.gd"


const PRESETS: Dictionary = {
	"spots":   {"F": 0.037, "K": 0.06},
	"stripes": {"F": 0.022, "K": 0.051},
	"mazes":   {"F": 0.029, "K": 0.057},
	"coral":   {"F": 0.062, "K": 0.061},
}


func _execute(g, selected: PackedInt32Array) -> void:
	var pattern: String = str(params.get("pattern", "spots"))
	var preset: Dictionary = PRESETS.get(pattern, PRESETS["spots"])
	var F: float = float(params.get("F", preset["F"]))
	var K: float = float(params.get("K", preset["K"]))
	var iterations: int = int(params.get("iterations", 3000))
	var N: int = int(params.get("grid_size", 96))
	var world_size: float = float(params.get("world_size", 3.0))
	var amp: float = float(params.get("amp", 0.25))
	var disp_arr = params.get("displace", [0.0, 1.0, 0.0])
	var disp := Vector3(
		float(disp_arr[0]) if disp_arr.size() > 0 else 0.0,
		float(disp_arr[1]) if disp_arr.size() > 1 else 1.0,
		float(disp_arr[2]) if disp_arr.size() > 2 else 0.0,
	)
	var seed_val: int = int(params.get("seed", 7))

	var field := _simulate_rd(N, F, K, iterations, seed_val)

	# Sample the field for each selected node
	var half: float = world_size * 0.5
	for idx in selected:
		if idx >= g.nodes.size():
			continue
		var p: Vector3 = g.nodes[idx]
		# Map (x, z) to grid [0..N]
		var u: float = clamp((p.x + half) / world_size, 0.0, 0.9999)
		var v: float = clamp((p.z + half) / world_size, 0.0, 0.9999)
		var ix: int = int(u * float(N))
		var iy: int = int(v * float(N))
		var val: float = field[iy * N + ix]
		# val ~ 0..1; center on 0.5 and map to [-1, 1]
		var signed_val: float = (val - 0.5) * 2.0
		g.nodes[idx] = p + disp * (amp * signed_val)


## Minimal Gray-Scott sim on a toroidal N×N grid.
## Returns the V concentration field as a flat PackedFloat32Array of length N*N.
static func _simulate_rd(N: int, F: float, K: float, iters: int, seed_val: int) -> PackedFloat32Array:
	var size: int = N * N
	var U := PackedFloat32Array()
	var V := PackedFloat32Array()
	U.resize(size); V.resize(size)
	for i in size:
		U[i] = 1.0
		V[i] = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	# Seed some small patches with V
	for _s in 8:
		var cx: int = rng.randi_range(N / 8, N - N / 8)
		var cy: int = rng.randi_range(N / 8, N - N / 8)
		var r: int = rng.randi_range(3, 7)
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if dx * dx + dy * dy <= r * r:
					var x: int = (cx + dx + N) % N
					var y: int = (cy + dy + N) % N
					V[y * N + x] = 1.0
					U[y * N + x] = 0.5

	# Standard stable Gray-Scott: Du/Dv diffusion, small dt
	var Du: float = 0.16
	var Dv: float = 0.08
	var dt: float = 1.0  # Small diffusion coefs keep dt=1 stable

	# Working buffers
	var U2 := U.duplicate()
	var V2 := V.duplicate()

	for _step in iters:
		for y in N:
			var ym: int = (y - 1 + N) % N
			var yp: int = (y + 1) % N
			for x in N:
				var xm: int = (x - 1 + N) % N
				var xp: int = (x + 1) % N
				var i0: int = y * N + x
				var u: float = U[i0]
				var v: float = V[i0]
				# 5-point Laplacian (toroidal)
				var lap_u: float = (
					U[y * N + xm] + U[y * N + xp] +
					U[ym * N + x] + U[yp * N + x] - 4.0 * u)
				var lap_v: float = (
					V[y * N + xm] + V[y * N + xp] +
					V[ym * N + x] + V[yp * N + x] - 4.0 * v)
				var uvv: float = u * v * v
				U2[i0] = clamp(u + (Du * lap_u - uvv + F * (1.0 - u)) * dt, 0.0, 1.0)
				V2[i0] = clamp(v + (Dv * lap_v + uvv - (K + F) * v) * dt, 0.0, 1.0)
		# Swap buffers by copying
		for i in size:
			U[i] = U2[i]
			V[i] = V2[i]

	return V
