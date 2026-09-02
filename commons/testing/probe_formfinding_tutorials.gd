extends SceneTree
## The formfinding chapter's claims must be TRUE. Functions copied from the five
## FormFinding_*/tutorial.md files and asked questions with known answers.
##
##   1  the slope is MEASURED, not known: a central difference on the bowl matches
##      the analytic gradient, and the marble's spring accel points home
##   2  descent reaches the bottom, and too large a step diverges  <- the learning rate
##   3  THE CHAPTER'S SPINE, part one: on the wells landscape, gradient descent from
##      a start beside a shallow well settles in the SHALLOW one while a deeper exists
##   4  the catenoid is cosh, and the tutorial's cable is NOT a catenary: the Bezier
##      sag it draws differs from the true hanging curve  <- the honest approximation
##   5  Verlet: with pos == prev the first step falls exactly g*dt*dt, and more
##      constraint passes drive the springs closer to their rest length
##   6  the mobile balances EXACTLY: dl = arm*wr/total, dr = arm*wl/total gives
##      wl*dl == wr*dr; cutting the rod in the middle instead makes it tilt
##   7  annealing accepts worse moves often when hot and almost never when cold,
##      and logarithmic cooling is slower than exponential
##   8  THE CHAPTER'S SPINE, part two: annealing on the SAME landscape from the SAME
##      start finds the deeper well that descent could not leave

const BOWL_R := 0.18
const BOWL_D := 0.12

func bowl_height(r: float) -> float:
	var u: float = clampf(r / BOWL_R, 0.0, 1.0)
	return u * u * BOWL_D

var _centers: Array[Vector2] = [Vector2(-0.35, 0.0), Vector2(0.55, 0.10)]
var _depths: Array[float] = [0.30, 0.95]        # the far one is much deeper
var _widths: Array[float] = [0.05, 0.05]

func loss(p: Vector2) -> float:
	var v: float = 0.55 * p.length_squared()
	for i in _centers.size():
		var d2: float = (p - _centers[i]).length_squared()
		v -= _depths[i] * exp(-d2 / _widths[i])
	return v

func loss_grad(p: Vector2) -> Vector2:
	var eps := 1e-4
	return Vector2(
		(loss(p + Vector2(eps, 0)) - loss(p - Vector2(eps, 0))) / (2.0 * eps),
		(loss(p + Vector2(0, eps)) - loss(p - Vector2(0, eps))) / (2.0 * eps))

func nearest_well(p: Vector2) -> int:
	var best := 0
	for i in _centers.size():
		if p.distance_to(_centers[i]) < p.distance_to(_centers[best]): best = i
	return best

func _init() -> void:
	var fails := 0

	# 1. the slope is measured
	var eps := 0.002
	var r0 := 0.10
	var num := (bowl_height(r0 + eps) - bowl_height(r0 - eps)) / (2.0 * eps)
	var ana := 2.0 * r0 * BOWL_D / (BOWL_R * BOWL_R)
	print("1  central difference on the bowl at r=0.10: %.5f, analytic 2*r*d/R^2: %.5f" % [num, ana])
	if absf(num - ana) > 1e-4:
		print("   FAIL the measured slope is not the real slope"); fails += 1

	# 2. descent reaches the bottom; too large a step diverges
	var p := Vector2(0.15, 0.0)
	for i in 400:
		p -= Vector2(2.0 * p.x * BOWL_D / (BOWL_R * BOWL_R), 2.0 * p.y * BOWL_D / (BOWL_R * BOWL_R)) * 0.02
	var q := Vector2(0.15, 0.0)
	for i in 40:
		q -= Vector2(2.0 * q.x * BOWL_D / (BOWL_R * BOWL_R), 2.0 * q.y * BOWL_D / (BOWL_R * BOWL_R)) * 0.30
	print("2  learning rate 0.02 after 400 steps: %.6f from the centre; rate 0.30 after 40 steps: %.3f (must run away)" % [p.length(), q.length()])
	if p.length() > 1e-3 or q.length() < 1.0:
		print("   FAIL the step size does not behave as the room says"); fails += 1

	# 3. descent settles in the NEAREST well, not the deepest
	var start := Vector2(-0.55, 0.0)          # beside the shallow well
	var deepest := 1
	var pos := start
	var vel := Vector2.ZERO
	for i in 6000:
		var g := loss_grad(pos)
		vel = vel * 0.9 - g * 0.004
		pos += vel
	var landed := nearest_well(pos)
	print("3  from %s gradient descent settles at %s, nearest well %d (depth %.2f); the deeper well %d (depth %.2f) is %.2f away and it never goes" % [start, pos, landed, _depths[landed], deepest, _depths[deepest], pos.distance_to(_centers[deepest])])
	if landed == deepest:
		print("   FAIL descent did not get stuck: the room's whole setup is gone"); fails += 1

	# 4. the catenoid is cosh; the tutorial's cable is a Bezier and not a catenary
	var c := 0.5
	var waist := c * cosh(0.0 / c)
	var lip := c * cosh(1.0 / c)
	# the tutorial's laundry sag: p.y -= depth * 4t(1-t), a parabola
	var span := 2.0
	var depth := 0.45
	var worst := 0.0
	for k in 41:
		var t: float = float(k) / 40.0
		var x: float = (t - 0.5) * span
		var bez: float = -depth * 4.0 * t * (1.0 - t)
		var a: float = 1.35                                   # a catenary matched at the ends
		var cat: float = a * (cosh(x / a) - cosh(span * 0.5 / a))
		worst = maxf(worst, absf(bez - cat))
	print("4  catenoid waist %.3f at u=0 and %.3f at u=1 (cosh grows); the hall's cable is a parabola and differs from the matched catenary by up to %.4f m" % [waist, lip, worst])
	if absf(waist - c) > 1e-9 or lip <= waist or worst < 1e-4:
		print("   FAIL the curve claims are wrong"); fails += 1

	# 5. Verlet, and the passes
	var dt := 1.0 / 60.0
	var g_acc := Vector3(0, -9.8, 0)
	var pnow := Vector3.ZERO
	var pprev := Vector3.ZERO
	var v0: Vector3 = (pnow - pprev) * 0.99
	var pnext: Vector3 = pnow + v0 + g_acc * dt * dt
	print("5a Verlet first step from rest falls %.6f m, which is g*dt*dt = %.6f" % [absf(pnext.y), absf(g_acc.y * dt * dt)])
	if absf(absf(pnext.y) - absf(g_acc.y * dt * dt)) > 1e-9:
		print("   FAIL the integrator is not what the tutorial prints"); fails += 1
	# A CHAIN, not a pair: one pass fixes a lone spring outright, so a pair proves
	# nothing. Relaxation is LOCAL, and the point of the passes is how far a
	# correction travels along a chain before the frame ends.
	var rest := 1.0
	var errs: Array = []
	var worsts: Array = []
	for passes in [1, 4, 8, 12]:
		var pts: Array[Vector3] = []
		for i in 6: pts.append(Vector3(float(i) * 1.6, 0, 0))   # every link stretched 60%
		for _p in passes:
			for i in 5:
				var diff: Vector3 = pts[i + 1] - pts[i]
				var cur: float = diff.length()
				var cv: Vector3 = (diff / cur) * (cur - rest) * 0.5 * 1.0
				if i > 0: pts[i] += cv          # particle 0 is pinned
				pts[i + 1] -= cv
		var total_err := 0.0
		var worst_link := 0.0
		for i in 5:
			var e: float = absf(pts[i].distance_to(pts[i + 1]) - rest)
			total_err += e
			worst_link = maxf(worst_link, e)
		errs.append(total_err)
		worsts.append(worst_link)
	print("5b a pinned chain of six, every link stretched 60%%: after 1/4/8/12 passes the chain is out by %.4f / %.4f / %.4f / %.4f m in total" % [errs[0], errs[1], errs[2], errs[3]])
	print("   and the WORST single link goes %.4f / %.4f / %.4f / %.4f — up before it comes down, because a sweep fixes each link in turn and a fixed link pulls its neighbour out" % [worsts[0], worsts[1], worsts[2], worsts[3]])
	if not (errs[0] > errs[1] and errs[1] > errs[2] and errs[2] > errs[3]):
		print("   FAIL more passes did not get closer to rest"); fails += 1
	if worsts[1] <= worsts[0]:
		print("   NOTE the worst link did not rise on this run; the non-monotone claim needs re-checking before it is printed on a wall")

	# 6. the mobile balances exactly
	var wl := 0.42
	var wr := 1.13
	var total := wl + wr
	var arm := 0.9
	var dl := arm * wr / total
	var dr := arm * wl / total
	var tilt_cut := asin(clampf((wr * (arm * 0.5) - wl * (arm * 0.5)) / (arm * total), -1.0, 1.0))
	print("6  masses %.2f and %.2f on a %.2f arm: hang at %.4f and %.4f, moments %.6f and %.6f (must be equal); cut the rod in the middle instead and it tilts %.1f degrees" % [wl, wr, arm, dl, dr, wl * dl, wr * dr, rad_to_deg(tilt_cut)])
	if absf(wl * dl - wr * dr) > 1e-12 or absf(tilt_cut) < 0.01:
		print("   FAIL the lever placement is not exact, or the miscut does not tilt"); fails += 1

	# 7. accepting worse
	var rng := RandomNumberGenerator.new(); rng.seed = 11
	var worse := 0.05
	var hot := 0; var cold := 0
	for i in 2000:
		if rng.randf() < exp(-worse / maxf(0.20, 0.0001)): hot += 1
		if rng.randf() < exp(-worse / maxf(0.002, 0.0001)): cold += 1
	var t_exp := 1.0; var t_log := 1.0
	for i in 60:
		t_exp *= 0.95
		t_log = 1.0 / log(2.0 + i)
	print("7  a move that costs 0.05: accepted %d/2000 times at T=0.20 and %d/2000 at T=0.002; after 60 steps exponential cooling is at %.4f and logarithmic at %.4f (log must be warmer)" % [hot, cold, t_exp, t_log])
	if hot < 1000 or cold > 20 or t_log <= t_exp:
		print("   FAIL the temperature does not do what the room says"); fails += 1

	# 8. annealing escapes the well descent could not
	var best_found := 0
	var trials := 20
	for trial in trials:
		var r2 := RandomNumberGenerator.new(); r2.seed = 100 + trial
		var cur := start
		var cur_e := loss(cur)
		var T := 1.0
		for step in 4000:
			var strength: float = T * 1.2 * 0.3
			var nb := Vector2(cur.x + r2.randf_range(-strength, strength), cur.y + r2.randf_range(-strength, strength))
			var ne := loss(nb)
			var de := ne - cur_e
			if de < 0.0 or r2.randf() < exp(-de / maxf(T, 0.0001)):
				cur = nb; cur_e = ne
			T *= 0.999
		if nearest_well(cur) == deepest: best_found += 1
	print("8  simulated annealing from the same start, %d runs: %d of them end in the DEEPER well that descent never reached" % [trials, best_found])
	if best_found < trials / 2:
		print("   FAIL annealing did not beat descent, so the chapter has no ending"); fails += 1

	print("")
	print("PROBE %s" % ("OK" if fails == 0 else "FAILED %d" % fails))
	quit(fails)
