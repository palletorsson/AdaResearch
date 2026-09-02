extends SceneTree
## Act III's pure functions must be TRUE. Copied verbatim from
## Vectors_Act3_FieldsAndMotion/tutorial.md (the ones that need no scene) and
## asked questions with known answers.
##
##   1  rain: the slant is the ratio -- equal down and across gives 45 degrees
##   2  height_at: the apex is at t = vy/g and the ball lands at t = 2vy/g
##   3  launch_components: vx^2 + vy^2 = v0^2 (the split loses nothing)
##   4  apex_and_range: range peaks at 45 degrees, and 30 and 60 land in the same place
##   5  the chain: integrating a constant acceleration gives p = a t^2 / 2  <- one quantity, three depths
##   6  NEGATIVE: a launch straight up has zero range and the full v0^2/2g apex

func rain_acceleration(wind: Vector3, gravity_strength: float) -> Vector3:
	var down := Vector3(0.0, -gravity_strength * 9.8, 0.0)
	var across := Vector3(wind.x, 0.0, wind.z) * 3.0
	return down + across

func launch_components(v0: float, theta: float) -> Vector2:
	return Vector2(v0 * cos(theta), v0 * sin(theta))

func height_at(vy: float, t: float, gravity: float = 9.8) -> float:
	return vy * t - 0.5 * gravity * t * t

func apex_and_range(v0: float, theta: float, gravity: float = 9.8) -> Vector2:
	var vx := v0 * cos(theta)
	var vy := v0 * sin(theta)
	var t_land := 2.0 * vy / gravity
	return Vector2(vy * vy / (2.0 * gravity), vx * t_land)

func _init() -> void:
	var fails := 0

	# 1. the slant is the ratio
	var a := rain_acceleration(Vector3(9.8 / 3.0, 0, 0), 1.0)   # across = 9.8, down = 9.8
	var slant := rad_to_deg(atan2(a.x, -a.y))
	print("1  equal down and across: rain acceleration %s, slant %.1f degrees (must be 45)" % [a, slant])
	if absf(slant - 45.0) > 0.01:
		print("   FAIL the ratio is not the angle"); fails += 1

	# 2. apex and landing from the parabola
	var vy := 9.8
	var t_apex := vy / 9.8
	var h_apex := height_at(vy, t_apex)
	var h_land := height_at(vy, 2.0 * t_apex)
	var h_before := height_at(vy, t_apex - 0.1)
	var h_after := height_at(vy, t_apex + 0.1)
	print("2  vy=9.8: height at t=1 is %.3f (apex, must exceed neighbours %.3f / %.3f); at t=2 is %.6f (must be 0)" % [h_apex, h_before, h_after, h_land])
	if h_apex <= h_before or h_apex <= h_after or absf(h_land) > 1e-6:
		print("   FAIL gravity did not write the parabola"); fails += 1

	# 3. the split loses nothing
	var c := launch_components(10.0, deg_to_rad(37.0))
	print("3  v0=10 at 37 degrees -> vx %.3f vy %.3f; vx^2+vy^2 = %.4f (must be 100)" % [c.x, c.y, c.x * c.x + c.y * c.y])
	if absf(c.x * c.x + c.y * c.y - 100.0) > 1e-4:
		print("   FAIL the components do not recompose"); fails += 1

	# 4. range peaks at 45; 30 and 60 tie
	var r30 := apex_and_range(10.0, deg_to_rad(30.0)).y
	var r45 := apex_and_range(10.0, deg_to_rad(45.0)).y
	var r60 := apex_and_range(10.0, deg_to_rad(60.0)).y
	print("4  range at 30/45/60: %.3f / %.3f / %.3f (45 must be the largest; 30 and 60 must tie)" % [r30, r45, r60])
	if not (r45 > r30 and r45 > r60 and absf(r30 - r60) < 1e-4):
		print("   FAIL range does not peak at 45"); fails += 1

	# 5. the chain, integrated: a -> v -> p
	var acc := 2.0
	var vel := 0.0
	var pos := 0.0
	var dt := 0.001
	var steps := 1000   # one second
	for i in steps:
		vel += acc * dt
		pos += vel * dt
	var exact := 0.5 * acc * 1.0 * 1.0
	print("5  a=2 for one second, integrated in %d steps: v=%.4f (must be 2), p=%.4f (must be %.1f)" % [steps, vel, pos, exact])
	if absf(vel - 2.0) > 1e-6 or absf(pos - exact) > 0.01:
		print("   FAIL position is not the running sum of the running sum"); fails += 1

	# 6. NEGATIVE: straight up
	var up := apex_and_range(10.0, deg_to_rad(90.0))
	print("6  straight up: apex %.3f (must be v0^2/2g = %.3f), range %.6f (must be 0)" % [up.x, 100.0 / 19.6, up.y])
	if absf(up.x - 100.0 / 19.6) > 1e-4 or absf(up.y) > 1e-4:
		print("   FAIL a vertical launch went somewhere"); fails += 1

	print("")
	print("PROBE %s" % ("OK" if fails == 0 else "FAILED %d" % fails))
	quit(fails)
