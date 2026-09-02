extends SceneTree
## Act IVb's clocks and balances must be TRUE. Functions copied verbatim from
## Vectors_Act4b_Oscillation/tutorial.md and asked questions with known answers.
##
##   1  the minus sign: the restoring force points back, in exact proportion
##   2  stiffer ticks faster; amplitude is nowhere in the period (it is not even an argument)
##   3  the hall's pendulum: L 4.6 m gives T = 4.30 s, and mass is nowhere in it
##   4  sin(theta) vs theta: at the hall's 24 degrees the small-angle law is 3% off  <- honest limit
##   5  the cradle: momentum before equals momentum after when one ball hands its motion on
##   6  the well: e = 1 never decays, e = 0 is dead, and the bounces take FINITE total time
##   7  the lever: 2 at 3 balances 3 at 2; place_pivot puts the heavier child on the shorter arm
##   8  wind: double the speed, four times the push

func restoring_force(displacement: float, k: float) -> float:
	return -k * displacement

func spring_period(mass: float, k: float) -> float:
	var omega := sqrt(k / mass)
	return TAU / omega

func swing(t: float, amplitude: float, arm_length: float) -> float:
	var omega := sqrt(9.8 / arm_length)
	return amplitude * cos(t * omega)

func restoring_torque(theta: float, mass: float = 1.0) -> float:
	return -mass * 9.8 * sin(theta)

func total_momentum(masses: Array[float], velocities: Array[Vector3]) -> Vector3:
	var total := Vector3.ZERO
	for i in masses.size():
		total += masses[i] * velocities[i]
	return total

func apex_after(bounces: int, drop_height: float, e: float) -> float:
	return drop_height * pow(e, bounces)

func balances(f_left: float, d_left: float, f_right: float, d_right: float) -> bool:
	return absf(f_right * d_right - f_left * d_left) < 0.06

func place_pivot(arm: float, w_left: float, w_right: float) -> Vector2:
	var total := w_left + w_right
	return Vector2(arm * w_right / total, arm * w_left / total)

func wind_drag(speed: float, rho: float, c_d: float, area: float) -> float:
	return 0.5 * rho * speed * speed * c_d * area

func _init() -> void:
	var fails := 0

	var f1 := restoring_force(0.2, 50.0); var f2 := restoring_force(-0.4, 50.0)
	print("1  x=+0.2 -> F=%.1f (must be -10); x=-0.4 -> F=%.1f (must be +20)" % [f1, f2])
	if absf(f1 + 10.0) > 1e-6 or absf(f2 - 20.0) > 1e-6:
		print("   FAIL the minus sign is not the law"); fails += 1

	var soft := spring_period(1.0, 25.0); var stiff := spring_period(1.0, 100.0)
	print("2  k 25 -> T %.3f s; k 100 -> T %.3f s (must halve: stiffer ticks faster; amplitude is not an argument)" % [soft, stiff])
	if absf(stiff * 2.0 - soft) > 1e-6:
		print("   FAIL the period does not follow sqrt(m/k)"); fails += 1

	var T_hall := TAU / sqrt(9.8 / 4.6)
	var x_light := swing(1.3, 0.42, 4.6); var x_heavy := swing(1.3, 0.42, 4.6)   # mass is not an argument at all
	print("3  L 4.6 m: T = %.2f s (must be 4.30); swing at t=1.3 is %.4f for any mass" % [T_hall, x_light])
	if absf(T_hall - 4.30) > 0.01 or x_light != x_heavy:
		print("   FAIL the hall's pendulum does not keep its stated time"); fails += 1

	var th := 0.42
	var true_t := restoring_torque(th); var small := -9.8 * th
	var off := absf((small - true_t) / true_t) * 100.0
	print("4  at 24 degrees: mg sin(theta) = %.3f, mg theta = %.3f, small-angle law %.1f%% off (must be about 3%%)" % [true_t, small, off])
	if off < 2.0 or off > 4.0:
		print("   FAIL the honest limit is not where the text says"); fails += 1

	var masses: Array[float] = [1.0, 1.0, 1.0]
	var before: Array[Vector3] = [Vector3(2, 0, 0), Vector3.ZERO, Vector3.ZERO]
	var after: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3(2, 0, 0)]
	var pb := total_momentum(masses, before); var pa := total_momentum(masses, after)
	print("5  cradle: p before %s, after %s (must be equal; the middle ball never moved)" % [pb, pa])
	if not pb.is_equal_approx(pa):
		print("   FAIL momentum was destroyed"); fails += 1

	var h6 := apex_after(6, 2.0, 0.6)
	var alive := apex_after(50, 2.0, 1.0); var dead := apex_after(1, 2.0, 0.0)
	var t_total := 0.0   # each bounce lasts 2 * sqrt(2 h / g); sum to 400 bounces
	for n in range(0, 400):
		t_total += 2.0 * sqrt(2.0 * apex_after(n, 2.0, 0.6) / 9.8)
	var t_more := t_total + 2.0 * sqrt(2.0 * apex_after(400, 2.0, 0.6) / 9.8)
	# (no %e in GDScript's format: the first draft printed this line raw while its asserts passed)
	print("6  e 0.6 from 2 m: 6th apex %.4f m; e=1 after 50 %.1f (must be 2); e=0 %.1f (must be 0); 400 bounces take %.4f s, the 401st adds %.9f s" % [h6, alive, dead, t_total, t_more - t_total])
	if absf(h6 - 2.0 * pow(0.6, 6)) > 1e-9 or absf(alive - 2.0) > 1e-9 or dead != 0.0 or (t_more - t_total) > 1e-6:
		print("   FAIL the bounce series is not geometric, or its time is not finite"); fails += 1

	var ok := balances(2.0, 3.0, 3.0, 2.0); var tip := balances(2.0, 3.0, 3.0, 3.0)
	var piv := place_pivot(1.0, 3.0, 1.0)
	print("7  2 at 3 vs 3 at 2 balances: %s; 3 at 3 tips: %s; pivot for children 3 and 1: %.2f from the heavy, %.2f from the light (torques %.2f / %.2f)" % [ok, not tip, piv.x, piv.y, 3.0 * piv.x, 1.0 * piv.y])
	if not ok or tip or piv.x >= piv.y or absf(3.0 * piv.x - 1.0 * piv.y) > 1e-6:
		print("   FAIL the lever law or the pivot placement is wrong"); fails += 1

	var w1 := wind_drag(3.0, 1.2, 1.0, 0.5); var w2 := wind_drag(6.0, 1.2, 1.0, 0.5)
	print("8  wind 3 m/s -> %.2f N; 6 m/s -> %.2f N (ratio must be 4)" % [w1, w2])
	if absf(w2 / w1 - 4.0) > 1e-6:
		print("   FAIL the force is not in the speed squared"); fails += 1

	print("")
	print("PROBE %s" % ("OK" if fails == 0 else "FAILED %d" % fails))
	quit(fails)
