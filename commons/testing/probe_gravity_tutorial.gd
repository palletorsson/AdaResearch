extends SceneTree
## VFM_07 Gravity's claims must be TRUE. The tutorial's attract() leans on a
## Body class it never defines, so the arithmetic is carried here in pure form
## and asked questions with known answers.
##
##   1  inverse square: d=2 costs three quarters of the force, d=4 fifteen sixteenths
##   2  the circular orbit speed sqrt(GM/r) really does counter the fall: integrated
##      for one period the radius stays constant
##   3  too slow falls in, too fast escapes, and escape is sqrt(2) times circular  <- the number
##   4  the well is deeper the closer you are (potential -G/r)
##   5  PREDICTION DIES WITH THREE: perturb a body by 1e-6 and integrate; with two
##      bodies the separation stays small, with three it grows by orders of magnitude
##   6  force-directed layout settles: the net force on every node shrinks toward zero

const G := 1.0

func attract(pa: Vector3, pb: Vector3, ma: float, mb: float) -> Vector3:
	var arm := pa - pb
	var d := clampf(arm.length(), 0.05, 25.0)
	var strength := G * ma * mb / (d * d)
	return arm.normalized() * strength      # force ON b, toward a

func well_depth(pos: Vector3, center: Vector3) -> float:
	return -G / maxf((pos - center).length(), 0.5)

func step_bodies(pos: Array, vel: Array, mass: Array, dt: float) -> void:
	var n := pos.size()
	var acc: Array = []
	for i in n:
		var a := Vector3.ZERO
		for j in n:
			if i != j:
				a += attract(pos[j], pos[i], mass[j], mass[i]) / mass[i]
		acc.append(a)
	for i in n:
		vel[i] = vel[i] + acc[i] * dt
		pos[i] = pos[i] + vel[i] * dt

func _init() -> void:
	var fails := 0

	# 1. inverse square
	var f1 := attract(Vector3.ZERO, Vector3(1, 0, 0), 1.0, 1.0).length()
	var f2 := attract(Vector3.ZERO, Vector3(2, 0, 0), 1.0, 1.0).length()
	var f4 := attract(Vector3.ZERO, Vector3(4, 0, 0), 1.0, 1.0).length()
	print("1  force at d=1 %.4f, d=2 %.4f (must be a quarter), d=4 %.4f (must be a sixteenth)" % [f1, f2, f4])
	if absf(f2 - f1 / 4.0) > 1e-6 or absf(f4 - f1 / 16.0) > 1e-6:
		print("   FAIL not inverse square"); fails += 1

	# 2. circular orbit: heavy central mass, light satellite at r = 1
	var M := 100.0
	var r := 1.0
	var v_circ := sqrt(G * M / r)
	var pos: Array = [Vector3.ZERO, Vector3(r, 0, 0)]
	var vel: Array = [Vector3.ZERO, Vector3(0, 0, v_circ)]
	var mass: Array = [M, 0.001]
	var period := TAU * r / v_circ
	var dt := period / 20000.0
	var rmin := INF; var rmax := 0.0
	for i in 20000:
		step_bodies(pos, vel, mass, dt)
		var rr: float = (pos[1] - pos[0]).length()
		rmin = minf(rmin, rr); rmax = maxf(rmax, rr)
	print("2  circular at v = sqrt(GM/r) = %.3f: over one period r stays in [%.4f, %.4f] (must hug 1)" % [v_circ, rmin, rmax])
	if rmin < 0.99 or rmax > 1.01:
		print("   FAIL the sideways speed did not counter the fall"); fails += 1

	# 3. too slow falls in; too fast escapes; escape = sqrt(2) * circular
	var slow_min := INF
	pos = [Vector3.ZERO, Vector3(r, 0, 0)]; vel = [Vector3.ZERO, Vector3(0, 0, 0.6 * v_circ)]
	for i in 20000:
		step_bodies(pos, vel, mass, dt)
		slow_min = minf(slow_min, (pos[1] - pos[0]).length())
	var v_esc := sqrt(2.0) * v_circ
	pos = [Vector3.ZERO, Vector3(r, 0, 0)]; vel = [Vector3.ZERO, Vector3(0, 0, 1.05 * v_esc)]
	var far := 0.0
	for i in 200000:
		step_bodies(pos, vel, mass, dt)
		far = maxf(far, (pos[1] - pos[0]).length())
	var still_going: bool = vel[1].length() > 0.0 and (pos[1] - pos[0]).dot(vel[1]) > 0.0
	print("3  at 0.6 v_circ the closest approach falls to %.3f (must dip well under 1); at 1.05 v_esc (v_esc = %.3f = sqrt2 v_circ) it reaches %.1f and is still receding: %s" % [slow_min, v_esc, far, still_going])
	if slow_min > 0.8 or not still_going or far < 5.0:
		print("   FAIL too slow did not fall in, or too fast did not escape"); fails += 1

	# 4. the well
	var near := well_depth(Vector3(1, 0, 0), Vector3.ZERO); var farw := well_depth(Vector3(4, 0, 0), Vector3.ZERO)
	print("4  well at r=1 %.3f, at r=4 %.3f (must be deeper, i.e. more negative, closer in)" % [near, farw])
	if near >= farw:
		print("   FAIL the well is not deeper closer in"); fails += 1

	# 5. prediction dies with three
	var eps := 1e-6
	# two bodies, equal masses, a bound pair
	var p2a: Array = [Vector3(-0.5, 0, 0), Vector3(0.5, 0, 0)]; var v2a: Array = [Vector3(0, 0, -0.35), Vector3(0, 0, 0.35)]
	var p2b: Array = [Vector3(-0.5, 0, 0), Vector3(0.5 + eps, 0, 0)]; var v2b: Array = [Vector3(0, 0, -0.35), Vector3(0, 0, 0.35)]
	var m2: Array = [1.0, 1.0]
	# three bodies, the pinwheel-ish start: an equilateral triangle with a little spin
	var tri: Array = []
	for k in 3:
		tri.append(Vector3.RIGHT.rotated(Vector3.UP, TAU * k / 3.0) * 0.6)
	var p3a: Array = tri.duplicate(); var v3a: Array = []
	for k in 3:
		v3a.append(Vector3(-tri[k].z, 0, tri[k].x).normalized() * 0.45)
	var p3b: Array = tri.duplicate(); p3b[1] = p3b[1] + Vector3(eps, 0, 0)
	var v3b: Array = v3a.duplicate()
	var m3: Array = [1.0, 1.0, 1.0]
	var h := 0.002
	for i in 6000:
		step_bodies(p2a, v2a, m2, h); step_bodies(p2b, v2b, m2, h)
		step_bodies(p3a, v3a, m3, h); step_bodies(p3b, v3b, m3, h)
	var sep2 := 0.0; var sep3 := 0.0
	for k in 2: sep2 = maxf(sep2, (p2a[k] - p2b[k]).length())
	for k in 3: sep3 = maxf(sep3, (p3a[k] - p3b[k]).length())
	# (no %e in GDScript: a %.2e here printed the line raw and skipped the numbers)
	print("5  nudge one body by 1e-6, run 12 time units: two bodies diverge by %.9f, three by %.4f, ratio %.0fx (three must be at least 1000x two)" % [sep2, sep3, sep3 / maxf(sep2, 1e-12)])
	if sep3 < 1000.0 * sep2 or sep3 < 1e-2:
		print("   FAIL prediction did not die with three"); fails += 1

	# 6. force-directed layout settles
	var rng := RandomNumberGenerator.new(); rng.seed = 7
	var n := 12
	var npos: Array = []
	for i in n: npos.append(Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)))
	var edges: Array = []
	for i in n: edges.append([i, (i + 1) % n])
	var k_rep := 0.02; var k_spr := 0.5; var L0 := 0.6
	var net_first := 0.0; var net_last := 0.0
	for it in 4000:
		var forces: Array = []
		for i in n: forces.append(Vector3.ZERO)
		for i in n:
			for j in n:
				if i != j:
					var d: Vector3 = npos[i] - npos[j]; var dd := maxf(d.length(), 0.05)
					forces[i] += d.normalized() * (k_rep / (dd * dd))
		for e in edges:
			var d: Vector3 = npos[e[1]] - npos[e[0]]
			var f := d.normalized() * (k_spr * (d.length() - L0))
			forces[e[0]] += f; forces[e[1]] -= f
		var net := 0.0
		for i in n: net += forces[i].length()
		if it == 0: net_first = net
		net_last = net
		for i in n: npos[i] = npos[i] + forces[i] * 0.05
	print("6  force-directed: total net force %.4f at start -> %.6f after 4000 steps (must fall by at least 100x: layout is equilibrium)" % [net_first, net_last])
	if net_last > net_first / 100.0:
		print("   FAIL the layout did not settle"); fails += 1

	print("")
	print("PROBE %s" % ("OK" if fails == 0 else "FAILED %d" % fails))
	quit(fails)
