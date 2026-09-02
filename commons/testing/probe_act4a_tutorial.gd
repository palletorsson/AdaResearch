extends SceneTree
## Act IVa's forces must be TRUE. Functions copied verbatim from
## Vectors_Act4a_KineticForces/tutorial.md and asked questions with known answers.
##
##   1  work: a push square to the motion does zero work however hard   <- negative
##   2  push_split conserves the push: |along|^2 + |into|^2 = F^2, and along shrinks as the handle rises
##   3  drag only shrinks a velocity and never reverses it
##   4  distance_under_drag has a finite reach: v0/b, and never exceeds it
##   5  slides: tan(theta) > mu decides -- with mu 0.28 the block holds at 15 degrees and goes at 16
##   6  centripetal is square to the tangent (never changes speed) and quadruples when speed doubles
##   7  barycenter: m1 d1 = m2 d2, and it sits closer to the heavier body
##   8  mutual_pull: equal and opposite, and four times stronger at half the distance

func work_done(force: Vector3, displacement: Vector3) -> float:
	return force.dot(displacement)

func push_split(magnitude: float, theta: float) -> Array[Vector3]:
	var along := Vector3(magnitude * cos(theta), 0.0, 0.0)
	var into_ground := Vector3(0.0, -magnitude * sin(theta), 0.0)
	return [along, into_ground]

func drag_step(velocity: Vector3, b: float, delta: float) -> Vector3:
	return velocity * (1.0 - clampf(b * delta, 0.0, 0.6))

func distance_under_drag(v0: float, b: float, t: float) -> float:
	return (v0 / b) * (1.0 - exp(-b * t))

func slope_components(theta: float) -> Vector2:
	return Vector2(sin(theta), cos(theta))

func slides(theta: float, mu: float) -> bool:
	var down_slope := sin(theta)
	var friction := minf(mu * cos(theta), down_slope)
	return down_slope - friction > 0.0

func centripetal(speed: float, radius: float, angle: float) -> Vector3:
	var pos := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
	return -pos.normalized() * (speed * speed / radius)

func barycenter_offsets(m1: float, m2: float, separation: float) -> Vector2:
	var total := m1 + m2
	return Vector2(separation * m2 / total, separation * m1 / total)

func mutual_pull(star: Vector3, planet: Vector3, g_m1_m2: float) -> Array[Vector3]:
	var to_planet := planet - star
	var f := g_m1_m2 / maxf(to_planet.length_squared(), 0.01)
	var dir := to_planet.normalized()
	return [dir * f, -dir * f]

func _init() -> void:
	var fails := 0

	var w0 := work_done(Vector3(0, -50, 0), Vector3(3, 0, 0))
	var w1 := work_done(Vector3(50, 0, 0), Vector3(3, 0, 0))
	print("1  push square to the motion: work %.1f (must be 0); along it: %.1f (must be 150)" % [w0, w1])
	if absf(w0) > 1e-6 or absf(w1 - 150.0) > 1e-6:
		print("   FAIL work is not the dot product"); fails += 1

	var lo := push_split(60.0, deg_to_rad(20.0))
	var hi := push_split(60.0, deg_to_rad(50.0))
	var kept_lo := lo[0].length_squared() + lo[1].length_squared()
	var kept_hi := hi[0].length_squared() + hi[1].length_squared()
	print("2  60 N at 20 deg: along %.2f; at 50 deg: along %.2f (must shrink); total kept %.1f / %.1f (must be 3600)" % [lo[0].x, hi[0].x, kept_lo, kept_hi])
	if hi[0].x >= lo[0].x or absf(kept_lo - 3600.0) > 1e-3 or absf(kept_hi - 3600.0) > 1e-3:
		print("   FAIL effort was not conserved, or usefulness did not fall"); fails += 1

	var v := Vector3(4, 0, 0)
	var reversed := false
	var last := v.length()
	for i in 200:
		v = drag_step(v, 3.0, 0.05)
		if v.x < 0.0:
			reversed = true
		last = v.length()
	print("3  200 drag steps from 4 m/s: speed now %.5f, ever reversed %s (must be tiny / false)" % [last, reversed])
	if reversed or last > 0.01:
		print("   FAIL drag reversed or failed to tax the speed"); fails += 1

	var reach := distance_under_drag(4.0, 0.5, 1000.0)
	var d1 := distance_under_drag(4.0, 0.5, 1.0)
	print("4  v0 4, b 0.5: at 1 s %.3f m, after long coasting %.3f m (must approach v0/b = 8 and never pass it)" % [d1, reach])
	if reach > 8.0 + 1e-6 or absf(reach - 8.0) > 1e-3 or d1 >= reach:
		print("   FAIL the reach is not finite at v0/b"); fails += 1

	var hold := slides(deg_to_rad(15.0), 0.28)
	var go := slides(deg_to_rad(16.0), 0.28)
	print("5  mu 0.28 (tan^-1 = %.1f deg): slides at 15 = %s, at 16 = %s (must be false / true)" % [rad_to_deg(atan(0.28)), hold, go])
	if hold or not go:
		print("   FAIL the angle does not decide at tan(theta) = mu"); fails += 1

	var a1 := centripetal(2.0, 3.4, 0.7)
	var a2 := centripetal(4.0, 3.4, 0.7)
	var tangent := Vector3(-sin(0.7), 0.0, cos(0.7))
	print("6  |a| at 2 m/s %.3f, at 4 m/s %.3f (ratio must be 4); a . tangent = %.6f (must be 0)" % [a1.length(), a2.length(), a1.dot(tangent)])
	if absf(a2.length() / a1.length() - 4.0) > 1e-4 or absf(a1.dot(tangent)) > 1e-6:
		print("   FAIL centripetal is not v^2/r toward the centre"); fails += 1

	var off := barycenter_offsets(3.0, 1.0, 3.6)
	print("7  masses 3 and 1, 3.6 m apart: centre %.2f from the heavy one, %.2f from the light (m1 d1 = %.2f, m2 d2 = %.2f)" % [off.x, off.y, 3.0 * off.x, 1.0 * off.y])
	if absf(3.0 * off.x - 1.0 * off.y) > 1e-6 or off.x >= off.y or absf(off.x + off.y - 3.6) > 1e-6:
		print("   FAIL the barycenter does not balance the masses"); fails += 1

	var near := mutual_pull(Vector3.ZERO, Vector3(2, 0, 0), 10.0)
	var far := mutual_pull(Vector3.ZERO, Vector3(4, 0, 0), 10.0)
	var opposite: bool = near[0].is_equal_approx(-near[1])
	print("8  pull at 2 m %.3f, at 4 m %.3f (ratio must be 4); equal and opposite %s" % [near[0].length(), far[0].length(), opposite])
	if absf(near[0].length() / far[0].length() - 4.0) > 1e-4 or not opposite:
		print("   FAIL gravity is not inverse-square, or not mutual"); fails += 1

	print("")
	print("PROBE %s" % ("OK" if fails == 0 else "FAILED %d" % fails))
	quit(fails)
