# noise_displace.gd — Universal noise-displacement post-op.
#
# Any substrate's final position array can be perturbed by this before
# the renderer runs. Works on PackedVector3Array (graph nodes, soft-body
# particles, turtle segment endpoints, primitive positions, mesh vertices).
#
# The same DNA block is accepted by every substrate's renderer via
#   post_ops: [{op: "noise_displace", amplitude, frequency, seed, ...}]
#
# Uses Godot's built-in FastNoiseLite for determinism.

extends RefCounted


## Apply noise displacement in-place to a PackedVector3Array.
## Each position samples 3D noise (one sample per axis with offset) and
## gets pushed along a weighted direction.
##
## Params:
##   amplitude    — maximum displacement magnitude (default 0.1)
##   frequency    — noise frequency (default 1.0)
##   octaves      — fBm octaves (default 3)
##   persistence  — fBm persistence (default 0.5)
##   lacunarity   — fBm lacunarity (default 2.0)
##   seed         — RNG seed (default 0)
##   noise_type   — "perlin" | "simplex" | "cellular" | "value" (default "simplex")
##   mode         — "vector" (3 independent noise samples per axis) or
##                  "normal" (displace along surface normal / radial direction)
##                  default "vector"
static func apply(positions: PackedVector3Array, params: Dictionary) -> PackedVector3Array:
	var amplitude: float = float(params.get("amplitude", 0.1))
	var frequency: float = float(params.get("frequency", 1.0))
	var octaves: int = int(params.get("octaves", 3))
	var persistence: float = float(params.get("persistence", 0.5))
	var lacunarity: float = float(params.get("lacunarity", 2.0))
	var seed_val: int = int(params.get("seed", 0))
	var noise_type: String = String(params.get("noise_type", "simplex"))
	var mode: String = String(params.get("mode", "vector"))

	var type_enum: int = FastNoiseLite.TYPE_SIMPLEX
	match noise_type:
		"perlin":   type_enum = FastNoiseLite.TYPE_PERLIN
		"simplex":  type_enum = FastNoiseLite.TYPE_SIMPLEX
		"cellular": type_enum = FastNoiseLite.TYPE_CELLULAR
		"value":    type_enum = FastNoiseLite.TYPE_VALUE

	# Build three noise samplers for vector mode (one per axis).
	var noises: Array = []
	for i in 3:
		var n := FastNoiseLite.new()
		n.noise_type = type_enum
		n.seed = seed_val + i * 1009
		n.frequency = frequency
		n.fractal_octaves = octaves
		n.fractal_gain = persistence
		n.fractal_lacunarity = lacunarity
		noises.append(n)

	var out := PackedVector3Array()
	out.resize(positions.size())
	for i in positions.size():
		var p: Vector3 = positions[i]
		if mode == "normal":
			# Single noise sample, pushed along radial (from origin) direction
			var r: float = noises[0].get_noise_3d(p.x, p.y, p.z)
			var dir: Vector3 = p
			if dir.length() < 1e-6:
				dir = Vector3.UP
			else:
				dir = dir.normalized()
			out[i] = p + dir * r * amplitude
		else:
			# Vector mode: three independent samples per axis
			var dx: float = noises[0].get_noise_3d(p.x, p.y, p.z)
			var dy: float = noises[1].get_noise_3d(p.x, p.y, p.z)
			var dz: float = noises[2].get_noise_3d(p.x, p.y, p.z)
			out[i] = p + Vector3(dx, dy, dz) * amplitude
	return out


## Apply a list of post-ops sequentially. Each op is a dict {op: name, ...}.
## Returns the final positions. Currently supported ops: "noise_displace".
static func apply_post_ops(positions: PackedVector3Array,
		ops: Array) -> PackedVector3Array:
	var p := positions
	for o in ops:
		if not (o is Dictionary): continue
		var op_name: String = String(o.get("op", ""))
		match op_name:
			"noise_displace":
				p = apply(p, o)
			_:
				push_warning("noise_displace.apply_post_ops: unknown op '%s'" % op_name)
	return p
