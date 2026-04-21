# trajectory_sim.gd — Force-integrator DNA substrate.
# Integrate a force equation over time → record the trajectory → use the
# time axis AS a spatial axis. The circle becomes a spiral, the double
# pendulum becomes a chaotic ribbon, Lorenz becomes a butterfly sculpture.
#
# DNA = (force_type, params, initial_conditions, duration, dt).
# Output = PackedVector3Array of sampled positions along the trajectory,
# which the renderer can interpret as tube / ribbon / particles / lines.
#
# Forces supported (each a closed-form or RK2 integration):
#   uniform_circular — parametric spiral (unit circle + rise)
#   lissajous_3d     — three orthogonal oscillators, interlocking curve
#   pendulum_1d      — damped 1D oscillator, extruded along time axis
#   double_pendulum  — chaotic 2-bob pendulum
#   lorenz_attractor — Lorenz system (σ, ρ, β)
#   kepler_orbit     — 2-body orbital mechanics around a central mass
#   magnetic_dipole  — charged particle drift in uniform B-field
#   damped_spring    — mass-on-spring with damping, extruded along time
#   n_body           — gravitational n-body (all bodies' trails returned)
#   fan              — multiple initial conditions run in parallel, stacked

extends RefCounted


## Integrate a force over duration and return the trajectory (or trajectories).
## Returns Dictionary:
##   "trajectories": Array[PackedVector3Array]   (one per body/initial condition)
##   "sample_count": int
static func simulate(cfg: Dictionary) -> Dictionary:
	var force: String = String(cfg.get("force", "uniform_circular"))
	var duration: float = float(cfg.get("duration", 20.0))
	var dt: float = float(cfg.get("dt", 0.02))
	var n_samples: int = int(duration / dt)
	var params: Dictionary = cfg.get("params", {})
	var initial: Dictionary = cfg.get("initial", {})

	var trajectories: Array = []

	match force:
		"uniform_circular":
			trajectories.append(_trace_uniform_circular(params, initial, n_samples, dt))
		"lissajous_3d":
			trajectories.append(_trace_lissajous_3d(params, initial, n_samples, dt))
		"pendulum_1d":
			trajectories.append(_trace_pendulum_1d(params, initial, n_samples, dt))
		"double_pendulum":
			trajectories.append(_trace_double_pendulum(params, initial, n_samples, dt))
		"lorenz_attractor":
			trajectories.append(_trace_lorenz(params, initial, n_samples, dt))
		"kepler_orbit":
			trajectories.append(_trace_kepler(params, initial, n_samples, dt))
		"magnetic_dipole":
			trajectories.append(_trace_magnetic(params, initial, n_samples, dt))
		"damped_spring":
			trajectories.append(_trace_damped_spring(params, initial, n_samples, dt))
		"bouncing_gravity":
			trajectories.append(_trace_bouncing_gravity(params, initial, n_samples, dt))
		"fan":
			var n: int = int(params.get("count", 8))
			var spread: float = float(params.get("spread", 0.3))
			var inner_force: String = String(params.get("inner_force", "uniform_circular"))
			var inner_params: Dictionary = params.get("inner_params", {})
			for i in n:
				var ic := initial.duplicate(true)
				if ic.has("phase"):
					ic["phase"] = float(ic.get("phase", 0.0)) + spread * float(i) / float(n)
				var sub: Dictionary = {
					"force": inner_force,
					"params": inner_params,
					"initial": ic,
					"duration": duration,
					"dt": dt
				}
				var result: Dictionary = simulate(sub)
				var trails: Array = result["trajectories"]
				for t in trails:
					trajectories.append(t)
		_:
			push_warning("trajectory_sim: unknown force '%s'" % force)

	return {
		"trajectories": trajectories,
		"sample_count": n_samples,
	}


# ─── Force traces ─────────────────────────────────────────────

static func _trace_uniform_circular(p: Dictionary, init: Dictionary,
		n: int, dt: float) -> PackedVector3Array:
	# (cos(ωt + φ), sin(ωt + φ)) + linear rise along Y.
	var r: float = float(p.get("radius", 1.0))
	var omega: float = float(p.get("omega", 1.0))
	var rise: float = float(p.get("rise", 0.05))
	var phase: float = float(init.get("phase", 0.0))
	var origin_arr = init.get("origin", [0.0, 0.0, 0.0])
	var origin := Vector3(float(origin_arr[0]), float(origin_arr[1]), float(origin_arr[2]))
	var out := PackedVector3Array()
	out.resize(n)
	for i in n:
		var t: float = float(i) * dt
		var a: float = omega * t + phase
		out[i] = origin + Vector3(cos(a) * r, rise * t, sin(a) * r)
	return out


static func _trace_lissajous_3d(p: Dictionary, init: Dictionary,
		n: int, dt: float) -> PackedVector3Array:
	var fx: float = float(p.get("fx", 3.0))
	var fy: float = float(p.get("fy", 2.0))
	var fz: float = float(p.get("fz", 5.0))
	var ax: float = float(p.get("ax", 1.0))
	var ay: float = float(p.get("ay", 1.0))
	var az: float = float(p.get("az", 1.0))
	var px: float = float(p.get("phase_x", 0.0))
	var py: float = float(p.get("phase_y", PI * 0.5))
	var pz: float = float(p.get("phase_z", PI * 0.25))
	var out := PackedVector3Array()
	out.resize(n)
	for i in n:
		var t: float = float(i) * dt
		out[i] = Vector3(
			ax * sin(fx * t + px),
			ay * sin(fy * t + py),
			az * sin(fz * t + pz)
		)
	return out


static func _trace_pendulum_1d(p: Dictionary, init: Dictionary,
		n: int, dt: float) -> PackedVector3Array:
	# 1D pendulum θ'' = -(g/L) sin θ + damping, extruded along Z.
	# X = L sin θ, Y = -L cos θ, Z = t * extrude_rate.
	var L: float = float(p.get("length", 1.0))
	var g: float = float(p.get("gravity", 9.8))
	var damping: float = float(p.get("damping", 0.02))
	var theta: float = float(init.get("theta", 1.2))
	var theta_dot: float = float(init.get("theta_dot", 0.0))
	var extrude: float = float(p.get("extrude_rate", 0.15))
	var out := PackedVector3Array()
	out.resize(n)
	for i in n:
		out[i] = Vector3(L * sin(theta), -L * cos(theta) + L, float(i) * dt * extrude)
		var theta_ddot: float = -(g / L) * sin(theta) - damping * theta_dot
		theta_dot += theta_ddot * dt
		theta += theta_dot * dt
	return out


static func _trace_double_pendulum(p: Dictionary, init: Dictionary,
		n: int, dt: float) -> PackedVector3Array:
	var L1: float = float(p.get("L1", 1.0))
	var L2: float = float(p.get("L2", 1.0))
	var m1: float = float(p.get("m1", 1.0))
	var m2: float = float(p.get("m2", 1.0))
	var g: float = float(p.get("gravity", 9.8))
	var t1: float = float(init.get("theta1", PI * 0.5))
	var t2: float = float(init.get("theta2", PI * 0.5))
	var w1: float = float(init.get("omega1", 0.0))
	var w2: float = float(init.get("omega2", 0.0))
	var extrude: float = float(p.get("extrude_rate", 0.08))
	var out := PackedVector3Array()
	out.resize(n)
	# Track tip of second arm
	for i in n:
		var x: float =  L1 * sin(t1) + L2 * sin(t2)
		var y: float = -L1 * cos(t1) - L2 * cos(t2) + L1 + L2
		out[i] = Vector3(x, y, float(i) * dt * extrude)
		# Double-pendulum equations of motion (standard form)
		var delta: float = t2 - t1
		var den1: float = (2.0 * m1 + m2 - m2 * cos(2.0 * delta))
		if abs(den1) < 1e-6: den1 = 1e-6
		var a1: float = (-g * (2.0 * m1 + m2) * sin(t1)
			- m2 * g * sin(t1 - 2.0 * t2)
			- 2.0 * sin(delta) * m2 * (w2 * w2 * L2 + w1 * w1 * L1 * cos(delta))) / (L1 * den1)
		var a2: float = (2.0 * sin(delta) * (w1 * w1 * L1 * (m1 + m2)
			+ g * (m1 + m2) * cos(t1)
			+ w2 * w2 * L2 * m2 * cos(delta))) / (L2 * den1)
		w1 += a1 * dt
		w2 += a2 * dt
		t1 += w1 * dt
		t2 += w2 * dt
	return out


static func _trace_lorenz(p: Dictionary, init: Dictionary,
		n: int, dt: float) -> PackedVector3Array:
	var sigma: float = float(p.get("sigma", 10.0))
	var rho: float = float(p.get("rho", 28.0))
	var beta: float = float(p.get("beta", 8.0 / 3.0))
	var pos_arr = init.get("pos", [0.1, 0.0, 0.0])
	var x: float = float(pos_arr[0])
	var y: float = float(pos_arr[1])
	var z: float = float(pos_arr[2])
	var scale: float = float(p.get("scale", 0.04))
	var out := PackedVector3Array()
	out.resize(n)
	for i in n:
		out[i] = Vector3(x * scale, z * scale, y * scale)  # Z up for visual
		var dx: float = sigma * (y - x)
		var dy: float = x * (rho - z) - y
		var dz: float = x * y - beta * z
		x += dx * dt
		y += dy * dt
		z += dz * dt
	return out


static func _trace_kepler(p: Dictionary, init: Dictionary,
		n: int, dt: float) -> PackedVector3Array:
	# Point mass orbiting a fixed central attractor at origin. GM = μ.
	var mu: float = float(p.get("mu", 1.0))
	var pos_arr = init.get("pos", [1.0, 0.0, 0.0])
	var vel_arr = init.get("vel", [0.0, 0.0, 0.9])
	var pos := Vector3(float(pos_arr[0]), float(pos_arr[1]), float(pos_arr[2]))
	var vel := Vector3(float(vel_arr[0]), float(vel_arr[1]), float(vel_arr[2]))
	var precess_rate: float = float(p.get("precess_rate", 0.0))
	var out := PackedVector3Array()
	out.resize(n)
	for i in n:
		out[i] = pos
		var r: float = pos.length()
		if r < 0.01: r = 0.01
		var a: Vector3 = -pos * (mu / (r * r * r))
		vel += a * dt
		pos += vel * dt
		# Optional precession — rotate position around Y slightly each step
		if precess_rate != 0.0:
			pos = pos.rotated(Vector3.UP, precess_rate * dt)
			vel = vel.rotated(Vector3.UP, precess_rate * dt)
	return out


static func _trace_magnetic(p: Dictionary, init: Dictionary,
		n: int, dt: float) -> PackedVector3Array:
	# Charged particle in uniform B-field (along Y) with optional E drift.
	# Produces helical motion.
	var q_over_m: float = float(p.get("q_over_m", 1.0))
	var B_arr = p.get("B", [0.0, 2.0, 0.0])
	var E_arr = p.get("E", [0.0, 0.0, 0.0])
	var B := Vector3(float(B_arr[0]), float(B_arr[1]), float(B_arr[2]))
	var E := Vector3(float(E_arr[0]), float(E_arr[1]), float(E_arr[2]))
	var pos_arr = init.get("pos", [1.0, 0.0, 0.0])
	var vel_arr = init.get("vel", [0.0, 0.1, 1.0])
	var pos := Vector3(float(pos_arr[0]), float(pos_arr[1]), float(pos_arr[2]))
	var vel := Vector3(float(vel_arr[0]), float(vel_arr[1]), float(vel_arr[2]))
	var out := PackedVector3Array()
	out.resize(n)
	for i in n:
		out[i] = pos
		var a: Vector3 = q_over_m * (E + vel.cross(B))
		vel += a * dt
		pos += vel * dt
	return out


static func _trace_damped_spring(p: Dictionary, init: Dictionary,
		n: int, dt: float) -> PackedVector3Array:
	# 2D damped harmonic oscillator, extruded along Z.
	var k: float = float(p.get("k", 4.0))
	var damping: float = float(p.get("damping", 0.1))
	var m: float = float(p.get("mass", 1.0))
	var pos_arr = init.get("pos", [1.0, 0.0])
	var vel_arr = init.get("vel", [0.0, 0.8])
	var pos := Vector2(float(pos_arr[0]), float(pos_arr[1]))
	var vel := Vector2(float(vel_arr[0]), float(vel_arr[1]))
	var extrude: float = float(p.get("extrude_rate", 0.08))
	var out := PackedVector3Array()
	out.resize(n)
	for i in n:
		out[i] = Vector3(pos.x, pos.y, float(i) * dt * extrude)
		var a: Vector2 = -pos * (k / m) - vel * damping
		vel += a * dt
		pos += vel * dt
	return out


# ─── Bouncing gravity — FROZEN PROCESSED FORM ─────────────────
#
# Point particle under constant gravity, colliding with:
#   - axis-aligned walls (infinite lines)
#   - line-segment plates (pegs / obstacles / deflectors)
# Each collision reflects velocity across the surface normal, scaled by
# restitution. Motion is 2D in the xy plane; z optionally extrudes time.
#
# This is where the trajectory substrate meets "frozen processed form":
# the sculpture IS the record of every bounce. The plate layout IS the
# choreography. Pachinko, Galton boards, pinball, steel-ball labyrinths
# — all of these are already this function with different plate configs.
static func _trace_bouncing_gravity(p: Dictionary, init: Dictionary,
		n: int, dt: float) -> PackedVector3Array:
	var g: float = float(p.get("gravity", 9.8))
	var extrude: float = float(p.get("extrude_rate", 0.0))   # 0 = flat 2D
	var pos_arr = init.get("pos", [0.0, 5.0])
	var vel_arr = init.get("vel", [0.3, 0.0])
	var pos := Vector2(float(pos_arr[0]), float(pos_arr[1]))
	var vel := Vector2(float(vel_arr[0]), float(vel_arr[1]))

	var walls: Array = p.get("walls", [])
	var plates: Array = p.get("plates", [])

	# Pre-parse walls to typed structs for speed
	var walls_parsed: Array = []
	for w in walls:
		walls_parsed.append({
			"axis":     String(w.get("axis", "y")),
			"pos":      float(w.get("pos", 0.0)),
			"side":     String(w.get("side", "below")),   # "below" = reflect when going past
			"restitution": float(w.get("restitution", 0.9)),
		})
	# Plates as 2D line segments
	var plates_parsed: Array = []
	for pl in plates:
		var a_arr = pl.get("a", [0.0, 0.0])
		var b_arr = pl.get("b", [1.0, 0.0])
		plates_parsed.append({
			"a": Vector2(float(a_arr[0]), float(a_arr[1])),
			"b": Vector2(float(b_arr[0]), float(b_arr[1])),
			"restitution": float(pl.get("restitution", 0.8)),
		})

	var out := PackedVector3Array()
	out.resize(n)
	for i in n:
		out[i] = Vector3(pos.x, pos.y, float(i) * dt * extrude)
		# Integrate
		vel.y -= g * dt
		var new_pos := pos + vel * dt

		# Wall collisions (axis-aligned)
		for w in walls_parsed:
			var axis: String = w["axis"]
			var wp: float = w["pos"]
			var side: String = w["side"]
			var restit: float = w["restitution"]
			if axis == "y":
				if side == "below" and new_pos.y < wp and vel.y < 0:
					new_pos.y = wp + (wp - new_pos.y)  # reflect
					vel.y = -vel.y * restit
				elif side == "above" and new_pos.y > wp and vel.y > 0:
					new_pos.y = wp - (new_pos.y - wp)
					vel.y = -vel.y * restit
			elif axis == "x":
				if side == "below" and new_pos.x < wp and vel.x < 0:
					new_pos.x = wp + (wp - new_pos.x)
					vel.x = -vel.x * restit
				elif side == "above" and new_pos.x > wp and vel.x > 0:
					new_pos.x = wp - (new_pos.x - wp)
					vel.x = -vel.x * restit

		# Plate collisions (line segments)
		for pl in plates_parsed:
			var hit := _segment_crossed(pos, new_pos, pl["a"], pl["b"])
			if hit["hit"]:
				var n_vec: Vector2 = hit["normal"]
				# Reflect velocity across normal, apply restitution
				var vn: float = vel.dot(n_vec)
				if vn < 0:
					vel = (vel - 2.0 * vn * n_vec) * pl["restitution"]
					# Nudge position to the hit point + small offset along normal
					new_pos = hit["point"] + n_vec * 0.005

		pos = new_pos
	return out


# ─── Segment-vs-segment intersection with normal ──────────────
#
# Returns whether moving from p0 to p1 crosses the plate segment [a,b].
# If yes, returns the hit point and the plate's normal (pointing toward p0).
static func _segment_crossed(p0: Vector2, p1: Vector2,
		a: Vector2, b: Vector2) -> Dictionary:
	var r: Vector2 = p1 - p0
	var s: Vector2 = b - a
	var denom: float = r.x * s.y - r.y * s.x
	if absf(denom) < 1e-9:
		return {"hit": false}
	var qp: Vector2 = a - p0
	var t: float = (qp.x * s.y - qp.y * s.x) / denom
	var u: float = (qp.x * r.y - qp.y * r.x) / denom
	if t >= 0.0 and t <= 1.0 and u >= 0.0 and u <= 1.0:
		var hit_point: Vector2 = p0 + r * t
		# Plate normal: perpendicular to s, pointing toward p0
		var nrm := Vector2(-s.y, s.x).normalized()
		if (p0 - hit_point).dot(nrm) < 0:
			nrm = -nrm
		return {"hit": true, "point": hit_point, "normal": nrm, "t": t}
	return {"hit": false}
