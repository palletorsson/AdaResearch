# rd_sim.gd — Gray-Scott reaction-diffusion simulator as reusable DNA substrate.
#
# A thin wrapper around the existing _simulate_rd helper in
# graph_grammar/operations/rd_displace_op.gd, exposing it as a standalone
# RefCounted for the RD gallery and for cross-substrate bridges.
#
# DNA = (F, K, iterations, grid_size, seed). Gray-Scott's behavior is
# entirely determined by (F, K) — spots, stripes, mazes, coral, mitosis
# all emerge from the same two-equation system at different parameters.

extends RefCounted

const RDDisplaceOpScript = preload("res://commons/graph_grammar/operations/rd_displace_op.gd")

const PRESETS: Dictionary = {
	"spots":    {"F": 0.037, "K": 0.06},
	"stripes":  {"F": 0.022, "K": 0.051},
	"mazes":    {"F": 0.029, "K": 0.057},
	"coral":    {"F": 0.062, "K": 0.061},
	"mitosis":  {"F": 0.0367, "K": 0.0649},
	"chaos":    {"F": 0.026, "K": 0.051},
	"bacteria": {"F": 0.014, "K": 0.054},
	"holes":    {"F": 0.039, "K": 0.058},
}


## Simulate Gray-Scott on an NxN grid. Returns a flat PackedFloat32Array of
## length N*N, values in [0, 1] representing the V chemical concentration.
static func simulate(cfg: Dictionary) -> PackedFloat32Array:
	var preset: String = String(cfg.get("preset", "spots"))
	var default_fk: Dictionary = PRESETS.get(preset, PRESETS["spots"])
	var F: float = float(cfg.get("F", default_fk["F"]))
	var K: float = float(cfg.get("K", default_fk["K"]))
	var N: int = int(cfg.get("grid_size", 96))
	var iters: int = int(cfg.get("iterations", 3000))
	var seed_val: int = int(cfg.get("seed", 7))
	return RDDisplaceOpScript._simulate_rd(N, F, K, iters, seed_val)


## Sample the field at normalized (u, v) in [0, 1]^2.
static func sample(field: PackedFloat32Array, N: int, u: float, v: float) -> float:
	var ix: int = clampi(int(u * float(N)), 0, N - 1)
	var iy: int = clampi(int(v * float(N)), 0, N - 1)
	return field[iy * N + ix]


## Threshold the field — return PackedByteArray where 1 = above threshold.
static func threshold(field: PackedFloat32Array, thresh: float) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(field.size())
	for i in field.size():
		out[i] = 1 if field[i] > thresh else 0
	return out
