extends "res://supplied/verify_tools.gd"
## Headless checks of the bullet kit. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; the exit code is the number of
## checks that failed. No import step is needed: nothing here has a class_name.
## Headless draws no frames, so what the eye gets is measured by sheet.gd.
## Most flights here are stepped by hand, in a loop, and take no time; the
## flights in the running scene and the walker's walks take about 25 seconds.

const Look := preload("res://supplied/look.gd")
const CheckGuest := preload("res://supplied/check_guest.gd")
const RATES := [10, 30, 60, 240]            # the axis: steps per second; dt is 1 / it
const LAUNCH := Vector3(4, 6, 0)
const START := Vector3(0, 0.1, 0)
const G := 9.8
const CENTRE := Vector3(0, 1.6, 0)

## Where the formula puts the bullet after `t` seconds: no steps.
func formula(t: float) -> Vector3:
	return START + LAUNCH * t + Vector3(0, -0.5 * G * t * t, 0)

## A bullet alone, not stepped by the clock: the checks step it by hand.
func bullet(rate: int) -> Node3D:
	var b: Node3D = load("res://bullet.tscn").instantiate()
	b.steps_per_second = rate
	root.add_child(b)
	await frames(1)
	b.set_physics_process(false)
	b.fire()
	return b

## The orbit of the field trip, the same way.
func orbit(rate: int) -> Node3D:
	var scene: Node3D = load("res://orbit.tscn").instantiate()
	scene.get_node("Orbit").steps_per_second = rate
	root.add_child(scene)
	await frames(1)
	scene.get_node("Orbit").set_physics_process(false)
	scene.get_node("Orbit").fire()
	return scene

## One step in another order, done on the bullet's own fields.
##   "swapped"  the two lines the other way round: the place first, then the velocity
##   "old"      both lines read the state from before the step (explicit Euler)
func other_step(b: Node3D, order: String) -> void:
	if order == "swapped":
		b.at += b.velocity * b.dt
		b.velocity += b.pull() * b.dt
	else:
		var before: Vector3 = b.velocity
		b.velocity += b.pull() * b.dt
		b.at += before * b.dt
	if b.at.y <= 0.1:
		b.at.y = 0.1
		b.flying = false
	b.path.append(b.at)

## A whole flight in a loop. Returns what it measured.
func fly(b: Node3D, order := "") -> Dictionary:
	b.fire()
	var apex := 0.0
	var below := 0.0      # the furthest it was under the formula's bullet of the same moment, in metres
	var n := 0
	while b.flying and n < 100000:
		if order == "":
			b.step()
		else:
			other_step(b, order)
		n += 1
		apex = maxf(apex, b.at.y)
		if b.flying:
			below = maxf(below, formula(n * b.dt).y - b.at.y)
	return {"steps": n, "landed_m": snappedf(b.at.x - b.start.x, 0.0001), "seconds": snappedf(n * b.dt, 0.0001), "apex_m": snappedf(apex, 0.001), "below_formula_cm": snappedf(below * 100.0, 0.1)}

## An orbit stepped for `seconds`, or until it lands. Returns what it measured.
func turn(o: Node3D, seconds: float, order := "") -> Dictionary:
	o.fire()
	var low := INF
	var high := 0.0
	var turns := 0.0
	var angle := 0.0
	var after_one := 0.0
	var n := 0
	while o.flying and n < int(seconds / o.dt):
		if order == "":
			o.step()
		else:
			other_step(o, order)
		n += 1
		var arm: Vector3 = o.at - CENTRE
		low = minf(low, arm.length())
		high = maxf(high, arm.length())
		var now := atan2(arm.y, arm.x)
		turns += wrapf(now - angle, -PI, PI) / TAU
		angle = now
		if after_one == 0.0 and turns >= 1.0:
			after_one = arm.length()
	return {"steps": n, "seconds": snappedf(n * o.dt, 0.01), "landed": not o.flying, "turns": snappedf(turns, 0.01),
		"nearest_m": snappedf(low, 0.001), "farthest_m": snappedf(high, 0.001), "after_one_turn_m": snappedf(after_one, 0.001),
		"ends_m_from_the_launch": snappedf(o.at.x - o.start.x, 0.001)}

## Two measured numbers are the same to the millimetre.
func same(a: float, b: float) -> bool:
	return absf(a - b) < 0.0005

func text_of(path: String) -> String:
	return FileAccess.get_file_as_string(path)

func run() -> void:
	project()
	await body()
	await the_axis()
	await the_swap()
	await in_time()
	await field_trip()
	await the_engine()
	await place()
	await guest()
	check(errors.is_empty() and warnings.is_empty(), "the whole run logged no error and no warning: %s %s" % [errors, warnings])

func project() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "The bullet" and ProjectSettings.get_setting("application/run/main_scene") == "res://launch.tscn"
		and ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility",
		"the project is named The bullet, its main scene is launch.tscn, its renderer Compatibility")
	var supplied := []
	for file in DirAccess.get_files_at("res://supplied"):
		if not file.ends_with(".uid"):
			supplied.append(file)
	check(supplied == ["base.tscn", "base_look.gd", "check_guest.gd", "look.gd", "marble.gd", "marble.tscn", "mover.gd", "segment.gd", "sheet_tools.gd", "sweep_sheet.gd", "sweep_sheet.tscn", "trace_strip.gd", "verify_tools.gd", "walker.gd", "walker.tscn"], "supplied/ holds the base's 15 files: %s" % [supplied])
	var named := []
	var spaced := []
	for folder: String in ["res://", "res://supplied/", "res://guests/bullet/"]:
		for file in DirAccess.get_files_at(folder):
			if not file.ends_with(".gd"):
				continue
			if RegEx.create_from_string("(?m)^\\s*class_name\\s").search(text_of(folder + file)) != null:
				named.append(file)
			if RegEx.create_from_string("(?m)^ +\\S").search(text_of(folder + file)) != null:
				spaced.append(file)
	check(named.is_empty() and ProjectSettings.get_global_class_list().is_empty(), "no script declares a class_name, and the project lists no named class: nothing needs an import %s" % [named])
	check(spaced.is_empty(), "every script is indented with tabs: %s" % [spaced])
	check(is_equal_approx(root.get_physics_process_delta_time(), 1.0 / 60.0) and Engine.physics_ticks_per_second == 60,
		"the engine's own clock: Engine.physics_ticks_per_second is 60, and the delta of _physics_process is 1/60 s (%.6f)" % root.get_physics_process_delta_time())

## The made body: bullet.tscn alone.
func body() -> void:
	var b := await bullet(10)
	var ball: MeshInstance3D = b.get_node("Ball")
	check(b is Node3D and ball.mesh is SphereMesh and is_equal_approx((ball.mesh as SphereMesh).radius, 0.1) and b.get_node("Path").mesh is ImmediateMesh,
		"bullet.tscn is a Node3D with a Ball of 0.1 m radius and a Path whose mesh is an ImmediateMesh")
	check((ball.material_override as StandardMaterial3D).albedo_color.is_equal_approx(Look.BODY) and b.line.albedo_color.is_equal_approx(Look.LINE)
		and b.line.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and b.dots.use_point_size and not b.line.use_point_size
		and b.get_node("Path").cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
		"the ball is BODY, the path LINE and unshaded, with a second material for the dots; the path casts no shadow")
	check(b.at == START and b.velocity == LAUNCH and b.path == [START] and b.flying and is_equal_approx(b.dt, 0.1) and b.walker == null,
		"fire() puts the bullet at its start with the launch velocity, one place in its path, dt = 1 / steps_per_second, and nobody to hit")
	b.step()
	check(near(b.velocity, Vector3(4, 5.02, 0)) and near(b.at, Vector3(0.4, 0.602, 0)),
		"one step at dt 1/10: the velocity is (4, 5.02, 0) and the place (0.4, 0.602, 0): the place was moved by the NEW velocity. Got %s and %s" % [b.velocity, b.at])
	var first := ["1: velocity %s at %s" % [b.velocity, b.at]]
	b.step()
	first.append("2: velocity %s at %s" % [b.velocity, b.at])
	b.step()
	first.append("3: velocity %s at %s" % [b.velocity, b.at])
	measured["the_first_three_steps_at_1_10"] = first
	check(near(b.at, Vector3(1.2, 1.312, 0)) and b.path.size() == 4 and first[1] == "2: velocity (4.0, 4.04, 0.0) at (0.8, 1.006, 0.0)", "three steps: the bullet is at (1.2, 1.312, 0) and its path holds four places. %s" % [first])
	b.draw_path()
	var mesh: ImmediateMesh = b.get_node("Path").mesh
	var box := mesh.get_aabb()
	check(mesh.get_surface_count() == 2 and near(box.position, Vector3(0, 0.1, 0), 0.001) and near(box.end, Vector3(1.2, 1.312, 0), 0.001),
		"draw_path() makes two surfaces, a line strip and the dots, and they reach from the start to the last place: %s" % [box])
	var flight := fly(b)
	check(not b.flying and is_equal_approx(b.at.y, 0.1) and b.path[-1] == b.at and b.path.size() == flight["steps"] + 1,
		"a flight ends on the floor: the ball's middle at 0.1 m, the last place of the path is where it lies, one place for each step and one for the start")
	check(printed.has("dt 1/10 s: 12 steps, landed 4.8 m from the launch"), "landing prints one line: dt 1/10 s: 12 steps, landed 4.8 m from the launch")
	b.free()

## The argument's numbers: the same launch at four steps.
func the_axis() -> void:
	var formula_range := 2.0 * LAUNCH.x * LAUNCH.y / G
	var formula_apex := START.y + LAUNCH.y * LAUNCH.y / (2.0 * G)
	measured["formula"] = {"landed_m": snappedf(formula_range, 0.001), "seconds": snappedf(2.0 * LAUNCH.y / G, 0.0001), "apex_m": snappedf(formula_apex, 0.001)}
	var flights := {}
	for rate: int in [4, 10, 30, 60, 120, 240, 1000]:
		var b := await bullet(rate)
		flights[rate] = fly(b)
		flights[rate]["short_of_formula_cm"] = snappedf((formula_range - flights[rate]["landed_m"]) * 100.0, 0.1)
		b.free()
	measured["flights"] = flights
	check(flights[10]["steps"] == 12 and flights[30]["steps"] == 36 and flights[60]["steps"] == 73 and flights[240]["steps"] == 293,
		"the flight takes 12, 36, 73 and 293 steps at 1/10, 1/30, 1/60 and 1/240 s: %s" % [[flights[10]["steps"], flights[30]["steps"], flights[60]["steps"], flights[240]["steps"]]])
	check(same(flights[10]["landed_m"], 4.8) and same(flights[30]["landed_m"], 4.8) and same(flights[60]["landed_m"], 4.8667) and same(flights[240]["landed_m"], 4.8833),
		"it lands 4.800, 4.800, 4.867 and 4.883 m from the launch; the formula says %.3f: %s" % [formula_range, [flights[10]["landed_m"], flights[30]["landed_m"], flights[60]["landed_m"], flights[240]["landed_m"]]])
	check(same(flights[240]["landed_m"] - flights[60]["landed_m"], 0.0167) and same(flights[10]["landed_m"], flights[30]["landed_m"]),
		"1/60 and 1/240 land 1.7 cm apart; 1/10 and 1/30 land on the same spot, both at the step that ends at 1.2 s")
	check(same(flights[10]["apex_m"], 1.642) and same(flights[30]["apex_m"], 1.838) and same(flights[60]["apex_m"], 1.887) and same(flights[240]["apex_m"], 1.924),
		"its highest place is 1.642, 1.838, 1.887 and 1.924 m; the formula says %.3f: %s" % [formula_apex, [flights[10]["apex_m"], flights[30]["apex_m"], flights[60]["apex_m"], flights[240]["apex_m"]]])
	var under := true
	for rate: int in RATES:
		# Half of g, times the time flown, times dt: what the stepped bullet is under the formula's.
		var expected: float = 0.5 * G * (flights[rate]["steps"] - 1) / rate / rate * 100.0
		under = under and absf(flights[rate]["below_formula_cm"] - expected) < 0.15
	check(under, "in the air the stepped bullet is under the formula's bullet of the same moment, by g/2 x time x dt: at most %s cm" % [[flights[10]["below_formula_cm"], flights[30]["below_formula_cm"], flights[60]["below_formula_cm"], flights[240]["below_formula_cm"]]])
	check(flights[4]["steps"] == 4 and same(flights[4]["landed_m"], 4.0), "at 1/4 s it takes 4 steps and lands 4.0 m from the launch, 0.9 m short")

## The planted bug: the two lines the other way round.
func the_swap() -> void:
	var before := errors.size() + warnings.size()
	var swapped := {}
	for rate: int in RATES:
		var b := await bullet(rate)
		swapped[rate] = fly(b, "swapped")
		b.free()
	measured["flights_lines_swapped"] = swapped
	check(same(swapped[10]["landed_m"], 5.6) and same(swapped[30]["landed_m"], 5.0667) and same(swapped[60]["landed_m"], 5.0) and same(swapped[240]["landed_m"], 4.9167),
		"with the two lines swapped it lands 5.600, 5.067, 5.000 and 4.917 m from the launch: beyond the formula's point, where the right order lands short of it: %s" % [[swapped[10]["landed_m"], swapped[30]["landed_m"], swapped[60]["landed_m"], swapped[240]["landed_m"]]])
	check(swapped[60]["steps"] == 75 and same(swapped[10]["apex_m"], 2.242), "swapped, 1/60 takes 75 steps where the right order takes 73, and 1/10 rises to 2.242 m, 0.6 m above its own right order")
	check(errors.size() + warnings.size() == before, "and Godot says nothing about it: no error, no warning")

## The same body stepped by the engine's ticks, in the running scene.
func in_time() -> void:
	var before := errors.size()
	var scene: Node3D = load("res://launch.tscn").instantiate()
	root.add_child(scene)
	var b: Node3D = scene.get_node("Bullet")
	await physics_frames(2)
	check(b.flying and b.dt == 1.0 / 60.0 and b.walker == scene.get_node("Walker") and b.global_position == Vector3(-2.45, 0, 0),
		"launch.tscn fires at its start, at 60 steps a second, 2.45 m left of the middle, and the bullet has found the Walker")
	var ticks := 2
	while b.flying and ticks < 300:
		await physics_frame
		ticks += 1
	check(not b.flying and b.path.size() == 74 and same(b.at.x, 4.8667) and b.get_node("Ball").position == b.at,
		"stepped by the clock it takes the same 73 steps to the same place, 4.867 m, and the Ball is where `at` says: %d places, %.3f m, after %d ticks" % [b.path.size(), b.at.x, ticks])
	measured["ticks_of_the_flight_at_60"] = ticks
	b.steps_per_second = 10
	await press("pause")
	check(b.flying and b.path.size() < 4 and is_equal_approx(b.dt, 0.1), "Space (the action pause) fires again, with the dt of the steps_per_second it has now")
	ticks = 0
	while b.flying and ticks < 300:
		await physics_frame
		ticks += 1
	check(not b.flying and b.path.size() == 13 and same(b.at.x, 4.8), "at 10 steps a second the clock steps it 12 times, once in about six ticks, to 4.8 m: %d places after %d more ticks" % [b.path.size(), ticks])
	var stepped := []
	for i in 5:
		await press("drop")
		stepped.append(b.steps_per_second)
	check(stepped == [30, 60, 240, 4, 10] and b.flying, "M (the action drop) takes the next of 4, 10, 30, 60, 240 steps a second and fires: %s" % [stepped])
	var mark: MeshInstance3D = scene.get_node("Mark")
	var mark_paint := mark.material_override as StandardMaterial3D
	check(absf(mark.position.x - b.position.x - 2.0 * LAUNCH.x * LAUNCH.y / G) < 0.001 and mark.position.z == 0.0 and mark_paint != null and mark_paint.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA
		and Color(mark_paint.albedo_color, 1.0).is_equal_approx(Look.GHOST) and mark.find_children("*", "CollisionShape3D").is_empty(),
		"the Mark is a GHOST disc with no collider, lying where the formula says the launch comes down: %.3f m from the Bullet" % (mark.position.x - b.position.x))
	await frames(180)
	check(errors.size() == before, "launch.tscn ran more than 180 frames with no error: %s" % [errors])
	scene.free()
	await frames(1)

## The field trip: the same step() with a pull towards a centre.
func field_trip() -> void:
	var before := errors.size()
	var scene := await orbit(60)
	var o: Node3D = scene.get_node("Orbit")
	check(o.start == Vector3(1, 1.6, 0) and o.launch == Vector3(0, 2, 0) and near(o.pull(), Vector3(-4, 0, 0)) and (scene.get_node("Centre").material_override as StandardMaterial3D).albedo_color.is_equal_approx(Look.THIRD),
		"orbit.tscn: the bullet starts 1 m to the right of the centre, going up at 2 m/s, pulled towards it at 4 m/s2; the centre is THIRD")
	var orbits := {}
	orbits["velocity first, 1/60"] = turn(o, 60.0)
	orbits["lines swapped, 1/60"] = turn(o, 60.0, "swapped")
	orbits["both from the old state, 1/60"] = turn(o, 120.0, "old")
	scene.free()
	scene = await orbit(240)
	o = scene.get_node("Orbit")
	orbits["velocity first, 1/240"] = turn(o, 60.0)
	orbits["both from the old state, 1/240"] = turn(o, 120.0, "old")
	scene.free()
	scene = await orbit(10)
	o = scene.get_node("Orbit")
	orbits["velocity first, 1/10"] = turn(o, 60.0)
	orbits["both from the old state, 1/10"] = turn(o, 120.0, "old")
	scene.free()
	measured["orbits"] = orbits
	var right: Dictionary = orbits["velocity first, 1/60"]
	check(not right["landed"] and right["nearest_m"] > 0.98 and right["farthest_m"] < 1.02 and right["turns"] > 19.0,
		"our two lines keep the orbit: after 60 s and %.2f turns it has stayed between %.3f and %.3f m from the centre" % [right["turns"], right["nearest_m"], right["farthest_m"]])
	var swapped: Dictionary = orbits["lines swapped, 1/60"]
	check(not swapped["landed"] and swapped["nearest_m"] > 0.98 and swapped["farthest_m"] < 1.02,
		"the two lines swapped keep it too: between %.3f and %.3f m after 60 s. The outline said this orbit would spiral outward; it does not" % [swapped["nearest_m"], swapped["farthest_m"]])
	var old: Dictionary = orbits["both from the old state, 1/60"]
	check(old["landed"] and old["after_one_turn_m"] > 1.3 and old["seconds"] < 10.0 and old["steps"] == 479 and same(old["ends_m_from_the_launch"], -1.858),
		"with both lines reading the state from before the step the orbit opens: %.3f m after one turn, and on the floor after %.2f s, 479 steps and %.2f turns, %.3f m from the launch" % [old["after_one_turn_m"], old["seconds"], old["turns"], old["ends_m_from_the_launch"]])
	var old_fine: Dictionary = orbits["both from the old state, 1/240"]
	check(old_fine["landed"] and old_fine["seconds"] > old["seconds"] * 3.0,
		"a step four times shorter slows the leak and does not stop it: on the floor after %.2f s and %.2f turns" % [old_fine["seconds"], old_fine["turns"]])
	var coarse: Dictionary = orbits["velocity first, 1/10"]
	check(not coarse["landed"] and coarse["nearest_m"] > 0.9 and coarse["farthest_m"] < 1.15,
		"at 1/10 s our two lines still hold it, between %.3f and %.3f m: a wider band, and no leak" % [coarse["nearest_m"], coarse["farthest_m"]])
	scene = load("res://orbit.tscn").instantiate()
	root.add_child(scene)
	await frames(180)
	check(errors.size() == before and scene.get_node("Orbit").flying, "orbit.tscn ran 180 frames with no error, still in orbit")
	scene.free()
	await frames(1)

## The engine's own integrator: the supplied marble, a RigidBody3D, thrown with the same launch.
func the_engine() -> void:
	var apex := {}
	for ticks: int in [60, 10, 30, 240]:
		for damped: bool in [false, true]:
			Engine.physics_ticks_per_second = ticks
			var base: Node3D = load("res://supplied/base.tscn").instantiate()
			root.add_child(base)
			var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
			marble.position = Vector3(-2.45, 0.1, 0)
			base.add_child(marble)
			if not damped:
				marble.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
				marble.linear_damp = 0.0
			await physics_frames(2)
			marble.drop(Vector3(-2.45, 0.1, 0))
			marble.linear_velocity = LAUNCH
			var high := 0.0
			for i in ticks:
				await physics_frame
				high = maxf(high, marble.global_position.y)
			apex["%d ticks%s" % [ticks, ", damped as shipped" if damped else ""]] = snappedf(high, 0.001)
			base.free()
			await frames(1)
	Engine.physics_ticks_per_second = 60
	measured["marble_apex_m"] = apex
	measured["default_linear_damp"] = ProjectSettings.get_setting("physics/3d/default_linear_damp")
	var ours: Dictionary = measured["flights"]
	check(same(apex["60 ticks"], ours[60]["apex_m"]) and same(apex["10 ticks"], ours[10]["apex_m"]) and same(apex["30 ticks"], ours[30]["apex_m"]) and same(apex["240 ticks"], ours[240]["apex_m"]),
		"the marble thrown with the same launch and no damping rises to our bullet's own heights, to the millimetre, at 60, 10, 30 and 240 ticks a second: %s" % [apex])
	check(apex["60 ticks, damped as shipped"] < apex["60 ticks"] - 0.05, "as shipped (default_linear_damp %s) the marble rises to %.3f m, %.1f cm lower" % [measured["default_linear_damp"], apex["60 ticks, damped as shipped"], (apex["60 ticks"] - apex["60 ticks, damped as shipped"]) * 100.0])

## Place: a body stands where the formula says the bullet lands.
func place() -> void:
	var scene: Node3D = load("res://launch.tscn").instantiate()
	root.add_child(scene)
	var b: Node3D = scene.get_node("Bullet")
	var walker: CharacterBody3D = scene.get_node("Walker")
	await physics_frames(100)      # the first flight, with nobody in the way
	check(not b.hit, "with the walker where it starts, the first flight hits nobody")
	var landing: float = measured["formula"]["landed_m"]
	var how := await walk(walker, [Vector3(-2.45 + landing, 0, 0)])
	var stands: Vector3 = walker.global_position
	check(how == "arrived" and absf(stands.x + 2.45 - landing) < 0.1, "the walker's autopilot walked to the formula's landing point: \"%s\", standing %.2f m from the launch" % [how, stands.x + 2.45])
	var hits := {}
	var said := {}
	for rate: int in RATES + [4]:
		hits[rate] = await shoot(b, rate)
		said[rate] = hit_line
	measured["walker_at_the_formulas_landing"] = {"stands_m_from_launch": snappedf(stands.x + 2.45, 0.01), "hit_m_above_feet": hits, "printed": said}
	check(hits[60] > 0.3 and hits[240] > hits[60] and hits[30] < hits[60] and hits[10] <= hits[30],
		"standing there it is hit at every step of the axis, lower the longer the step: %s m above the feet at 1/10, 1/30, 1/60, 1/240" % [[hits[10], hits[30], hits[60], hits[240]]])
	check(near(walker.global_position, stands, 0.001), "the hit is soft: the walker stood where it stood, and nothing pushed it")
	check(hits[4] < 0.0, "at 1/4 s the bullet lands 4.0 m from the launch, short of the walker, and hits nobody")
	how = await walk(walker, [Vector3(-2.45 + 4.0, 0, 0)])
	var moved := await shoot(b, 4)
	check(how == "arrived" and moved > 0.0, "the walker moved to where that one lands, and is hit: %.2f m above the feet" % moved)
	# The sampling gate: a body 0.6 m wide, 3.5 m from the launch, and a step of 1 m.
	how = await walk(walker, [Vector3(-2.45 + 3.5, 0, 0)])
	var gate := {"stands_m_from_launch": snappedf(walker.global_position.x + 2.45, 0.01)}
	for rate: int in [4, 10, 60]:
		gate[rate] = await shoot(b, rate)
	measured["walker_in_the_path"] = gate
	check(how == "arrived" and gate[10] > 0.0 and gate[60] > 0.0 and gate[4] < 0.0,
		"a walker 3.5 m from the launch, in the bullet's way, is hit at 1/60 and at 1/10 and is stepped over at 1/4: the bullet was at 3.0 m and then at 4.0 m. %s" % [gate])
	scene.free()
	await frames(1)

var hit_line := ""    # what the last shoot() printed about its hit

## One flight in the running scene at `rate`. Returns how high above the walker's feet it hit, or -1.
func shoot(b: Node3D, rate: int) -> float:
	var from := printed.size()
	hit_line = "no hit"
	b.steps_per_second = rate
	b.fire()
	var ticks := 0
	while b.flying and ticks < 300:
		await physics_frame
		ticks += 1
	await physics_frames(2)
	if not b.hit:
		return -1.0
	var lines := printed
	for i in range(from, lines.size()):
		if lines[i].begins_with("hit at step "):
			hit_line = lines[i]
			return lines[i].get_slice(", ", 1).to_float()
	return -1.0

## The body handed to the room.
func guest() -> void:
	var needs := CheckGuest.outside("res://guests/bullet/")
	check(needs.is_empty(), "the guest names nothing outside its folder: %s" % [needs])
	check(CheckGuest.class_names("res://guests/bullet/").is_empty(), "the guest declares no class_name")
	var before := errors.size()
	var base: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(base)
	var guest_body: Node3D = load("res://guests/bullet/bullet.tscn").instantiate()
	base.add_child(guest_body)
	await physics_frames(2)
	var left := INF
	var right := -INF
	var low := INF
	var high := 0.0
	for i in 240:
		await physics_frame
		var ball: Vector3 = guest_body.get_node("Ball").position
		left = minf(left, ball.x - 0.1)
		right = maxf(right, ball.x + 0.1)
		low = minf(low, ball.y - 0.1)
		high = maxf(high, ball.y + 0.1)
	measured["guest"] = {"left_m": snappedf(left, 0.001), "right_m": snappedf(right, 0.001), "lowest_m": snappedf(low, 0.001), "highest_m": snappedf(high, 0.001), "flights_in_4_s": guest_body.flights}
	check(guest_body.flights >= 1 and left >= -0.8 and right <= 0.8 and absf(low) < 0.001,
		"the guest throws its ball across its place and again: in 4 s it landed %d times, the ball stayed between %.2f and %.2f m of the middle, on the ground and up to %.2f m" % [guest_body.flights, left, right, high])
	check(guest_body.walker == null and errors.size() == before, "with no Walker beside it the guest hits nobody, and it ran 240 ticks with no error")
	check(printed.has("the bullet, dt 1/60 s: 59 steps, landed 1.18 m from the launch"), "its first landing prints one line, once: the bullet, dt 1/60 s: 59 steps, landed 1.18 m from the launch")
	# The lesson's room task: the learner's own launch and step, on the guest.
	var own: Node3D = load("res://guests/bullet/bullet.tscn").instantiate()
	own.launch = Vector3(0.6, 7, 0)
	own.steps_per_second = 30
	own.position = Vector3(0, 0, 1.5)
	base.add_child(own)
	var right_own := -INF
	for i in 120:
		await physics_frame
		right_own = maxf(right_own, own.get_node("Ball").position.x + 0.1)
	measured["guest"]["with_launch_0.6_7_at_30_steps"] = {"reaches_m_from_the_middle": snappedf(right_own, 0.001), "formula_range_m": snappedf(2.0 * 0.6 * 7.0 / G, 0.001)}
	check(printed.has("the bullet, dt 1/30 s: 42 steps, landed 0.84 m from the launch") and right_own <= 0.8,
		"with the lesson's own launch (0.6, 7, 0) at 30 steps a second it prints: the bullet, dt 1/30 s: 42 steps, landed 0.84 m from the launch, and stays in its place (to %.2f m)" % right_own)
	var kit_step := text_of("res://bullet.gd").get_slice("func step()", 1).get_slice("func ", 0)
	var guest_step := text_of("res://guests/bullet/bullet.gd").get_slice("func step()", 1).get_slice("func ", 0)
	check(kit_step.find("velocity += pull() * dt") > 0 and kit_step.find("velocity += pull() * dt") < kit_step.find("at += velocity * dt")
		and guest_step.find("velocity += pull() * dt") > 0 and guest_step.find("velocity += pull() * dt") < guest_step.find("at += velocity * dt"),
		"the kit's step() and the guest's hold the same two lines in the same order: the velocity first, then the place")
	base.free()
	await frames(1)
