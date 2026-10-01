extends "res://supplied/verify_tools.gd"
## Headless checks of the Soft body study. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; the exit code is the number of
## checks that failed. No import step is needed: nothing here has a class_name.
## It checks the two classes and what inheritance does and does not do, the
## cloth at 1, 4, 16 and 64 passes, four things we followed, the scene with
## the hand, the walker and the soft body of Godot, the guest, and the numbers
## the lesson quotes from sheet.json. Our cloth is stepped by this script, so
## its numbers are the same on every run. Headless draws no frames: what the
## eye gets is measured by sheet.gd.

const Look := preload("res://supplied/look.gd")
const CheckGuest := preload("res://supplied/check_guest.gd")
const Cloth := preload("res://cloth.gd")
const GuestCloth := preload("res://guests/soft-body/cloth.gd")
const VALUES := [1, 4, 16, 64]
const STEP := 1.0 / 60.0
const TAUT := 0.8      # metres: where the lowest point would be if no link gave
const FLOOR := [Vector3(0.0, -1000.0, 0.0), Vector3(0.0, -1000.0, 0.0), 1000.01]

## A subclass that forgets super() in its _init: the planted bug, kept here so
## that what Godot does with it is checked on every run.
class Forgetful extends Cloth.Particle:
	var holder: Node3D

	func _init(at: Vector3, by: Node3D = null) -> void:
		holder = by

## A subclass with no _init of its own.
class Plain extends Cloth.Particle:
	pass

## A PinnedParticle without its nudge(): what the lesson has for one run, between two blocks.
class Dragged extends Cloth.PinnedParticle:
	func nudge(by: Vector3) -> void:
		position += by

func run() -> void:
	project()
	classes()
	build()
	faults()
	hang()
	followed()
	place_alone()
	await scene()
	await godots_alone()
	await walker_and_godots()
	await guest()
	sheet_numbers()
	check(errors.is_empty(), "Godot logged no error in the whole run: %s" % [errors])

func text_of(path: String) -> String:
	return FileAccess.get_file_as_string(path)

## Our cloth, hung at 2 m over the origin, not stepping by itself, with a Hand if asked.
func hung(passes: int, size := 11, with_hand := false) -> MeshInstance3D:
	var cloth: MeshInstance3D = Cloth.new()
	cloth.iterations = passes
	cloth.across = size
	cloth.down = size
	cloth.spacing = 1.2 / (size - 1)
	cloth.position = Vector3(0.0, 2.0, 0.0)
	cloth.process_mode = Node.PROCESS_MODE_DISABLED   # it steps when this script steps it, and at no other time
	if with_hand:
		var hand := Node3D.new()
		hand.name = "Hand"
		hand.position = Vector3(0.6, 0.0, 0.0)
		cloth.add_child(hand)
	root.add_child(cloth)
	return cloth

## `steps` steps of a cloth; `bodies` are told to it before each. Returns the milliseconds one step took.
func stepped(cloth: MeshInstance3D, steps: int, bodies := [], delta := STEP) -> float:
	var began := Time.get_ticks_usec()
	for i in steps:
		for body: Array in bodies:
			cloth.meet(body[0], body[1], body[2])
		cloth.step(delta)
	return (Time.get_ticks_usec() - began) / 1000.0 / steps

func carry(cloth: MeshInstance3D, to: Vector3, bodies: Array) -> void:
	var hand: Node3D = cloth.get_node("Hand")
	while hand.position.distance_to(to) > 0.0001:
		hand.position = hand.position.move_toward(to, 1.2 * STEP)
		stepped(cloth, 1, bodies)

func measure(cloth: Node3D) -> Dictionary:
	var lowest := INF
	for particle in cloth.particles:
		lowest = minf(lowest, cloth.to_global(particle.position).y)
	var total := 0.0
	var worst := 0.0
	for k in range(0, cloth.links.size(), 2):
		var length: float = cloth.particles[cloth.links[k]].position.distance_to(cloth.particles[cloth.links[k + 1]].position)
		total += absf(length - cloth.spacing) / cloth.spacing
		worst = maxf(worst, length / cloth.spacing)
	return {
		"lowest_point_m": snappedf(lowest, 0.0001), "below_taut_cm": snappedf((TAUT - lowest) * 100.0, 0.01),
		"mean_link_error_pct": snappedf(100.0 * total / (cloth.links.size() / 2.0), 0.01), "longest_link_pct_of_its_length": snappedf(100.0 * worst, 0.1),
	}

## Two lists of numbers, the same to within `slack`.
func alike(got: Array, wanted: Array, slack := 0.00005) -> bool:
	if got.size() != wanted.size():
		return false
	for i in got.size():
		if absf(got[i] - wanted[i]) > slack:
			return false
	return true

func out_of_plane(cloth: Node3D) -> float:
	var far := 0.0
	for particle in cloth.particles:
		far = maxf(far, absf(particle.position.z))
	return far

func highest(cloth: Node3D) -> float:
	var high := -INF
	for particle in cloth.particles:
		high = maxf(high, cloth.to_global(particle.position).y)
	return high

func above(cloth: Node3D, height: float) -> int:
	var count := 0
	for particle in cloth.particles:
		if cloth.to_global(particle.position).y > height:
			count += 1
	return count

func pinned(cloth: Node3D) -> Array:
	var which := []
	for i in cloth.particles.size():
		if cloth.particles[i] is Cloth.PinnedParticle:
			which.append(i)
	return which

func project() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "Soft body" and ProjectSettings.get_setting("application/run/main_scene") == "res://soft_body.tscn"
		and ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility",
		"the project is named Soft body, its main scene is soft_body.tscn, its renderer Compatibility")
	var supplied := []
	for file in DirAccess.get_files_at("res://supplied"):
		if not file.ends_with(".uid"):
			supplied.append(file)
	check(supplied == ["base.tscn", "base_look.gd", "check_guest.gd", "look.gd", "marble.gd", "marble.tscn", "mover.gd", "segment.gd", "sheet_tools.gd", "sweep_sheet.gd", "sweep_sheet.tscn", "trace_strip.gd", "verify_tools.gd", "walker.gd", "walker.tscn"]
		and ProjectSettings.get_global_class_list().is_empty(), "supplied/ holds the 15 files of the base, and the project lists no named class: nothing needs an import")
	var spaced := []
	var named := []
	for folder: String in ["res://", "res://supplied/", "res://guests/soft-body/"]:
		for file in DirAccess.get_files_at(folder):
			if not file.ends_with(".gd"):
				continue
			if RegEx.create_from_string("(?m)^ +\\S").search(text_of(folder + file)) != null:
				spaced.append(file)
			if RegEx.create_from_string("(?m)^\\s*class_name\\s").search(text_of(folder + file)) != null:
				named.append(file)
	check(spaced.is_empty() and named.is_empty(), "every script is indented with tabs and none declares a class_name: %s %s" % [spaced, named])

## The two classes, and what a subclass gets and does not get from its parent.
func classes() -> void:
	var drop: RefCounted = Cloth.Particle.new(Vector3.ZERO)
	drop.step(STEP)
	var first: float = drop.position.y
	var heights := []
	for i in range(1, 60):
		drop.step(STEP)
		if i % 20 == 19:
			heights.append(snappedf(drop.position.y, 0.001))
	measured["a_particle_falls_m"] = {"after_1_step": snappedf(first, 0.00001), "after_20_40_60_steps": heights}
	check(is_equal_approx(first, -9.8 * STEP * STEP) and alike(heights, [-0.537, -1.968, -4.129], 0.0005),
		"a Particle falls: %.5f m in its first step, gravity times the step squared, and %s m after 20, 40 and 60 steps; it stores no speed, only where it was" % [first, heights])
	var pin: RefCounted = Cloth.PinnedParticle.new(Vector3(1.0, 2.0, 3.0))
	var free_one: RefCounted = Cloth.Particle.new(Vector3(1.0, 2.0, 3.0))
	check(pin is Cloth.Particle and pin is Cloth.PinnedParticle and not free_one is Cloth.PinnedParticle,
		"a PinnedParticle is a Particle; a Particle is not a PinnedParticle")
	check(pin.position == Vector3(1.0, 2.0, 3.0) and pin.previous == Vector3(1.0, 2.0, 3.0) and pin.holder == null,
		"PinnedParticle's _init calls super(at): it has the position it was made with, %s" % pin.position)
	pin.step(STEP)
	pin.nudge(Vector3(0.5, 0.5, 0.5))
	pin.push_out(Vector3(1.0, 2.0, 3.0), Vector3(1.0, 2.0, 3.1), 0.5)
	free_one.push_out(Vector3(1.0, 2.0, 3.0), Vector3(1.0, 2.0, 3.1), 0.5)
	check(pin.position == Vector3(1.0, 2.0, 3.0), "a nailed PinnedParticle stays where it is through step(), nudge() and push_out(), which it inherits and which calls its own nudge()")
	var hand := Node3D.new()
	hand.position = Vector3(4.0, 5.0, 6.0)
	var held: RefCounted = Cloth.PinnedParticle.new(Vector3(1.0, 2.0, 3.0), hand)
	held.step(STEP)
	check(held.position == Vector3(4.0, 5.0, 6.0), "a PinnedParticle with a holder goes where the holder is at every step")
	var ball: RefCounted = Cloth.Particle.new(Vector3(0.1, 0.0, 0.0))
	ball.push_out(Vector3.ZERO, Vector3.ZERO, 0.5)
	var capsule: RefCounted = Cloth.Particle.new(Vector3(0.1, 0.7, 0.0))
	capsule.push_out(Vector3.ZERO, Vector3(0.0, 1.0, 0.0), 0.5)
	check(near(ball.position, Vector3(0.5, 0.0, 0.0), 0.0001) and ball.previous == ball.position and near(capsule.position, Vector3(0.5, 0.7, 0.0), 0.0001),
		"push_out() puts a Particle on the skin of a ball and of a capsule, and stops it there")
	# The planted bug, as Godot 4.6 does it.
	var before := [errors.size(), warnings.size()]
	var forgetful := Forgetful.new(Vector3(1.0, 2.0, 3.0), hand)
	check(forgetful.position == Vector3.ZERO and forgetful.previous == Vector3.ZERO and forgetful.holder == hand and before == [errors.size(), warnings.size()],
		"a subclass whose _init forgets super() is made at %s, not where it was told, and Godot says nothing: no error, no warning" % forgetful.position)
	check(Plain.new(Vector3(1.0, 2.0, 3.0)).position == Vector3(1.0, 2.0, 3.0), "a subclass with no _init of its own is made by its parent's")
	hand.free()

func build() -> void:
	var cloth := hung(4, 11, true)
	var m := measure(cloth)
	check(cloth.particles.size() == 121 and cloth.links.size() == 440 and cloth.corners.size() == 600 and m["longest_link_pct_of_its_length"] == 100.0,
		"the cloth is 121 particles, 220 links and 200 triangles, and every link starts at its own length")
	check(pinned(cloth) == [0, 10] and cloth.particles[0].holder == null and cloth.particles[10].holder == cloth.get_node("Hand"),
		"two particles are pinned, the two ends of the top row: particle 0 by a nail, particle 10 by the Hand")
	check(cloth.particles[0].position == Vector3(-0.6, 0.0, 0.0) and cloth.particles[10].position == Vector3(0.6, 0.0, 0.0),
		"the nailed corner is at (-0.6, 0, 0) of the cloth, not at its origin")
	check(cloth.mesh != null and cloth.mesh.get_surface_count() == 1 and cloth.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() == 121
		and cloth.material_override.albedo_color.is_equal_approx(Look.BODY) and cloth.material_override.cull_mode == BaseMaterial3D.CULL_DISABLED,
		"draw() makes one surface of 121 corners, painted BODY and seen from both sides")
	# No links relaxed: the pinned two stay and the rest falls away.
	cloth.iterations = 0
	stepped(cloth, 25)
	var lowest: float = measure(cloth)["lowest_point_m"]
	check(cloth.particles[0].position == Vector3(-0.6, 0.0, 0.0) and lowest < 0.1, "with no pass over the links the two pinned particles stay and the rest falls: after 25 steps the lowest is at %.2f m" % lowest)
	cloth.free()
	# The same build twice gives the same cloth.
	var one := hung(4)
	var two := hung(4)
	stepped(one, 300)
	stepped(two, 300)
	var same := true
	for i in one.particles.size():
		same = same and one.particles[i].position == two.particles[i].position
	check(same, "two cloths built and stepped alike are alike to the last digit: nothing in the cloth is left to chance")
	one.free()
	two.free()

## Two faults the lesson names, each as the readout shows it after 11 seconds.
func faults() -> void:
	# The planted bug: super() forgotten, so the nailed corner is made at the origin of the cloth.
	var cloth := hung(4, 11, true)
	cloth.particles[0].position = Vector3.ZERO
	cloth.particles[0].previous = Vector3.ZERO
	stepped(cloth, 660)
	var bug := measure(cloth)
	measured["planted_bug_super_forgotten"] = bug
	check(cloth.particles[0].position == Vector3.ZERO and alike([bug["lowest_point_m"]], [0.22], 0.006) and alike([bug["longest_link_pct_of_its_length"]], [141.0], 0.6),
		"with the nailed corner made at the origin the cloth hangs from the middle of its own top edge: lowest point %.2f m, longest link %.0f%% of its length" % [bug["lowest_point_m"], bug["longest_link_pct_of_its_length"]])
	cloth.free()
	# nudge() not overridden: the links drag the pinned particles.
	cloth = hung(4, 11, true)
	cloth.particles[0] = Dragged.new(cloth.particles[0].position)
	cloth.particles[10] = Dragged.new(cloth.particles[10].position, cloth.get_node("Hand"))
	stepped(cloth, 660)
	var nail: Vector3 = cloth.particles[0].position
	var dragged := measure(cloth)
	dragged["nailed_corner_is_at"] = "(%.2f, %.2f, %.2f)" % [nail.x, nail.y, nail.z]
	measured["pinned_without_nudge"] = dragged
	check(nail.y < -1.0 and nail.x > 0.3 and dragged["lowest_point_m"] < 0.0,
		"a PinnedParticle that overrides step() and not nudge() is dragged by its links: after 11 seconds the nailed corner is at %s of the cloth, and the lowest point at %.2f m, under the floor" % [dragged["nailed_corner_is_at"], dragged["lowest_point_m"]])
	cloth.free()

## The argument: the cloth at rest at 1, 4, 16 and 64 passes.
func hang() -> void:
	var rows := {}
	var lows := []
	var longest := []
	var costs := []
	var on_a_pin := true
	for value: int in VALUES:
		var cloth := hung(value)
		var cost := stepped(cloth, 600)
		stepped(cloth, 600)
		var row := measure(cloth)
		row["ms_a_step"] = snappedf(cost, 0.001)
		var ends := [0, 0]
		var most := 0.0
		for k in range(0, cloth.links.size(), 2):
			var length: float = cloth.particles[cloth.links[k]].position.distance_to(cloth.particles[cloth.links[k + 1]].position)
			if length > most:
				most = length
				ends = [cloth.links[k], cloth.links[k + 1]]
		row["longest_link_joins_particles"] = ends
		on_a_pin = on_a_pin and (cloth.particles[ends[0]] is Cloth.PinnedParticle or cloth.particles[ends[1]] is Cloth.PinnedParticle)
		rows[str(value)] = row
		lows.append(row["lowest_point_m"])
		longest.append(row["longest_link_pct_of_its_length"])
		costs.append(cost)
		cloth.free()
	measured["hang"] = rows
	check(alike(lows, [0.1162, 0.4264, 0.5603, 0.6465]), "at rest after 1200 steps the lowest point is at %s m for 1, 4, 16 and 64 passes; with links that did not give it would be at 0.80 m" % [lows])
	check(longest[0] > 280.0 and longest[1] > 140.0 and longest[2] > 115.0 and longest[3] > 105.0 and longest[3] < 110.0,
		"the longest link is %s%% of its length: at 1 pass nearly three times, at 64 still 8%% too long" % [longest])
	check(on_a_pin, "at every count the longest link is one that ends on a pinned corner: at 4 passes it joins particles %s" % [rows["4"]["longest_link_joins_particles"]])
	var gain: float = (lows[3] - lows[2]) * 100.0
	measured["from_16_to_64_passes_the_lowest_point_rises_cm"] = snappedf(gain, 0.01)
	check(gain > 8.0 and gain < 9.0 and TAUT - lows[3] > 0.15, "from 16 to 64 passes the lowest point rises %.2f cm, not less than one; at 64 it is still %.2f cm below taut" % [gain, (TAUT - lows[3]) * 100.0])
	check(costs[3] > costs[2] and costs[2] > costs[1] and costs[1] > costs[0] and costs[3] > costs[0] * 16.0,
		"a step costs more with every pass: %.2f, %.2f, %.2f and %.2f ms on this machine" % costs)

## What we followed after the sheet, each one thing changed.
func followed() -> void:
	var out := {}
	# A coarser and a finer net of the same size, at the same 16 passes.
	var grain := {}
	var lows := []
	for size: int in [6, 11, 21]:
		var cloth := hung(16, size)
		var cost := stepped(cloth, 600)
		var row := measure(cloth)
		row["ms_a_step"] = snappedf(cost, 0.001)
		row["particles"] = cloth.particles.size()
		row["links"] = cloth.links.size() / 2
		grain["%d by %d" % [size, size]] = row
		lows.append(row["lowest_point_m"])
		cloth.free()
	out["grain_at_16_passes"] = grain
	check(lows[0] > lows[1] and lows[1] > lows[2], "the same cloth as a net of 6 by 6, 11 by 11 and 21 by 21 points, at 16 passes: the lowest point is at %s m; the finer net is the softer one" % [lows])
	# The whole top row pinned, not only its two corners.
	var row_pinned := {}
	lows = []
	for value: int in VALUES:
		var cloth := hung(value)
		for i in cloth.across:
			cloth.particles[i] = Cloth.PinnedParticle.new(cloth.particles[i].position)
		stepped(cloth, 600)
		row_pinned[str(value)] = measure(cloth)
		lows.append(row_pinned[str(value)]["lowest_point_m"])
		cloth.free()
	out["top_row_pinned"] = row_pinned
	check((lows[3] - lows[2]) * 100.0 < 1.0 and lows[0] < lows[1], "with the whole top row pinned the lowest point is at %s m: from 16 to 64 passes it rises %.2f cm" % [lows, (lows[3] - lows[2]) * 100.0])
	# Another rule for a link with one end held: the free end takes the whole correction.
	var whole := {}
	lows = []
	for value: int in VALUES:
		var cloth := hung(value)
		for i in 600:
			for particle in cloth.particles:
				particle.step(STEP)
			for pass_number in value:
				for k in range(0, cloth.links.size(), 2):
					var a: RefCounted = cloth.particles[cloth.links[k]]
					var b: RefCounted = cloth.particles[cloth.links[k + 1]]
					var between: Vector3 = b.position - a.position
					var error: Vector3 = between.normalized() * (between.length() - cloth.spacing)
					var share := 1.0 if (a is Cloth.PinnedParticle or b is Cloth.PinnedParticle) else 0.5
					a.nudge(error * share)
					b.nudge(-error * share)
		whole[str(value)] = measure(cloth)
		lows.append(whole[str(value)]["lowest_point_m"])
		cloth.free()
	out["free_end_takes_the_whole_correction"] = whole
	check(lows[2] > 0.5603 and lows[3] > 0.6465, "when the free end of a held link takes the whole correction the lowest point is at %s m: higher than with our rule at every count" % [lows])
	# The same budget spent another way: 4 steps of 1/240 s with 4 passes each, for one step of 1/60 s with 16.
	var small_steps := hung(4)
	var cost := stepped(small_steps, 2400, [], STEP / 4.0) * 4.0
	out["four_steps_of_four_passes"] = measure(small_steps)
	out["four_steps_of_four_passes"]["ms_for_one_sixtieth_of_a_second"] = snappedf(cost, 0.001)
	var low: float = out["four_steps_of_four_passes"]["lowest_point_m"]
	check(absf(low - 0.6465) < 0.005, "16 passes spent as 4 steps of 1/240 s with 4 passes each leave the lowest point at %.4f m: within half a centimetre of 64 passes in one step, 0.6465 m, and 8.5 cm above 16 passes in one step" % low)
	small_steps.free()
	measured["followed"] = out

## The place, with the cloth stepped here and its bodies told by hand.
func place_alone() -> void:
	var out := {}
	# Carried: the hand takes its corner 1.2 m toward us in one second.
	var cloth := hung(4, 11, true)
	stepped(cloth, 600, [FLOOR])
	carry(cloth, Vector3(0.6, 0.0, 1.2), [FLOOR])
	out["carried_1.2_m_in_1_s"] = measure(cloth)
	stepped(cloth, 240, [FLOOR])
	out["held_there_4_s"] = measure(cloth)
	check(near(cloth.particles[10].position, Vector3(0.6, 0.0, 1.2)) and cloth.particles[0].position == Vector3(-0.6, 0.0, 0.0) and out["held_there_4_s"]["longest_link_pct_of_its_length"] > 170.0,
		"the corner goes with the hand, the nailed one stays; 1.2 m toward us the longest link is %.0f%% of its length" % out["held_there_4_s"]["longest_link_pct_of_its_length"])
	carry(cloth, Vector3(0.6, 0.0, 0.0), [FLOOR])
	stepped(cloth, 600, [FLOOR])
	# Let go, once: the nail.
	cloth.let_go()
	check(pinned(cloth) == [10] and not cloth.particles[0] is Cloth.PinnedParticle and cloth.particles.size() == 121,
		"let_go() puts a new Particle in the place of the first pinned one: the nail is gone, the hand still holds, and there are still 121")
	stepped(cloth, 900, [FLOOR])
	var widest := 0.0
	var in_the_air := 0
	for particle in cloth.particles:
		if cloth.to_global(particle.position).y > 0.1:
			in_the_air += 1
			widest = maxf(widest, Vector2(particle.position.x - 0.6, particle.position.z).length())
	out["hung_from_the_hand_alone"] = measure(cloth)
	out["hung_from_the_hand_alone"]["particles_above_0.1_m"] = in_the_air
	out["hung_from_the_hand_alone"]["their_farthest_from_the_line_under_the_hand_m"] = snappedf(widest, 0.001)
	check(widest < 0.1 and in_the_air > 60 and out["hung_from_the_hand_alone"]["lowest_point_m"] < 0.02,
		"held by one corner the cloth hangs as a rope down to the floor: %d particles are in the air, none more than %.3f m from the line under the hand; the rest lie on the floor" % [in_the_air, widest])
	# Let go, twice: it lies on the floor.
	cloth.let_go()
	stepped(cloth, 300, [FLOOR])
	check(pinned(cloth).is_empty() and above(cloth, 0.03) == 0, "let go a second time, nothing holds it: all 121 particles lie on the floor it was told about")
	cloth.free()
	# Laid over a standing body: the hand drags the cloth over a capsule the size of the walker and lets go.
	var counts := {}
	for value: int in [4, 16]:
		cloth = hung(value, 11, true)
		var bodies := [FLOOR, [Vector3(0.0, 0.3, 0.07), Vector3(0.0, 1.5, 0.07), 0.34]]
		stepped(cloth, 600, bodies)
		cloth.let_go()
		stepped(cloth, 240, bodies)
		carry(cloth, Vector3(-1.2, 0.0, 0.0), bodies)
		stepped(cloth, 240, bodies)
		var held := above(cloth, 0.5)
		cloth.let_go()
		stepped(cloth, 300, bodies)
		counts["%d passes" % value] = {"above_0.5_m_while_the_hand_holds": held, "above_0.5_m_after_it_let_go": above(cloth, 0.5)}
		cloth.free()
	out["dragged_over_a_standing_body"] = counts
	check(counts["4 passes"]["above_0.5_m_after_it_let_go"] == 0 and counts["16 passes"]["above_0.5_m_after_it_let_go"] == 0,
		"dragged over a standing capsule and let go, the cloth does not stay on it: 0 of 121 particles above 0.5 m, at 4 and at 16 passes")
	measured["place"] = out

## The scene as the learner runs it.
func scene() -> void:
	var before := errors.size()
	var study: Node3D = load("res://soft_body.tscn").instantiate()
	root.add_child(study)
	await physics_frames(300)
	var cloth: Node3D = study.get_node("Cloth")
	var soft: SoftBody3D = study.get_node("SoftCloth")
	var readout: String = study.get_node("Readout").text
	check(errors.size() == before and warnings.is_empty(), "soft_body.tscn ran 300 steps and Godot logged no error and no warning: %s %s" % [errors, warnings])
	check(readout.begins_with("4 passes: lowest point 0.43 m, longest link 144% of its length, ") and readout.contains(" ms a step"), "the readout shows the report of the cloth: %s" % readout.get_slice("\n", 0))
	check(printed.has("pinned point 110 at (0.6, 0.6, 0.0)") and printed.has("pinned point 120 at (-0.6, 0.6, 0.0)") and soft.is_point_pinned(110) and soft.is_point_pinned(120) and not soft.is_point_pinned(0),
		"soft_cloth.gd pinned the two top corners of the soft body, points 110 and 120, and printed which")
	var soft_low := INF
	for i in 121:
		soft_low = minf(soft_low, soft.get_point_transform(i).y)
	measured["godots_soft_body_in_the_scene"] = {"lowest_point_m": snappedf(soft_low, 0.0001), "simulation_precision": soft.simulation_precision, "linear_stiffness": soft.linear_stiffness}
	check(near(soft.get_point_transform(110), Vector3(1.8, 2.0, 0.0), 0.001) and soft_low > 0.6 and soft_low < 0.8 and soft.simulation_precision == 5,
		"the soft body hangs from its pinned points at 2 m; at its own 5 passes its lowest point is at %.3f m" % soft_low)
	# The hand: one second of S.
	var hand: Node3D = cloth.get_node("Hand")
	await hold("move_backward", 60)
	await physics_frames(2)
	check(hand.position.z > 1.0 and hand.position.z < 1.4 and cloth.particles[10].position == hand.position,
		"S held for a second carries the Hand %.2f m toward us, and the corner of the cloth is where the Hand is" % hand.position.z)
	await hold("move_forward", 90)
	hand.position = Vector3(0.6, 0.0, 0.0)
	await physics_frames(240)
	# The walker: Space sends it into the cloth.
	var walker: CharacterBody3D = study.get_node("Walker")
	await press("pause")
	var how: String = await walker.walk_ended
	await physics_frames(60)
	var pushed := out_of_plane(cloth)
	measured["walker_in_the_cloth"] = {"walk_ended": how, "walker_z": snappedf(walker.global_position.z, 0.001), "cloth_out_of_its_plane_m": snappedf(pushed, 0.001)}
	check(how == "arrived" and absf(walker.global_position.z) < 0.1 and walker.global_position.y < 0.01 and pushed > 0.2,
		"Space: the walker %s in the cloth, not stopped by it, and the cloth is pushed %.2f m out of its plane" % [how, pushed])
	await press("pause")
	how = await walker.walk_ended
	await physics_frames(600)
	var back := out_of_plane(cloth)
	measured["walker_in_the_cloth"]["out_of_its_plane_10_s_after_it_walked_on_m"] = snappedf(back, 0.001)
	check(how == "arrived" and back < pushed, "Space again: the walker walked on, and ten seconds later the cloth is %.3f m out of its plane, coming back" % back)
	# M: the nail, then the hand.
	await press("drop")
	check(pinned(cloth) == [10], "M lets go of the nail")
	await press("drop")
	await physics_frames(480)
	check(pinned(cloth).is_empty() and above(cloth, 0.1) == 0, "M again lets go of the hand, and the cloth lies on the floor: the highest particle is at %.2f m" % highest(cloth))
	check(errors.size() == before, "and Godot logged no error to the end of the scene: %s" % [errors])
	study.free()
	await frames(2)

func godots(precision: int) -> SoftBody3D:
	var soft: SoftBody3D = load("res://soft_cloth.gd").new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.2, 1.2)
	plane.subdivide_width = 9
	plane.subdivide_depth = 9
	plane.orientation = PlaneMesh.FACE_Z
	soft.mesh = plane
	soft.simulation_precision = precision
	soft.position = Vector3(0.0, 1.4, 0.0)
	return soft

## The soft body of Godot alone, at the four counts, as this headless run has it.
## The clock runs four times as fast and the physics ticks four times as often:
## a step is still 1/60 s, and 600 of them take two and a half seconds.
func godots_alone() -> void:
	var base: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(base)
	Engine.physics_ticks_per_second = 240
	Engine.time_scale = 4.0
	var rows := {}
	var lows := []
	for value: int in VALUES:
		var soft := godots(value)
		base.add_child(soft)
		await physics_frames(600)
		var low := INF
		for i in 121:
			low = minf(low, soft.get_point_transform(i).y)
		var lean: float = (soft.get_point_transform(0).x + soft.get_point_transform(10).x) / 2.0
		rows[str(value)] = {"lowest_point_m": snappedf(low, 0.0001), "below_taut_cm": snappedf((TAUT - low) * 100.0, 0.01), "bottom_edge_leans_m": snappedf(lean, 0.0001)}
		lows.append(low)
		soft.free()
		await frames(2)
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	measured["godots_soft_body_alone_headless"] = rows
	check(lows[0] < lows[1] and lows[1] < lows[2] and lows[2] < lows[3] and lows[3] < TAUT and lows[0] > 0.5,
		"the soft body of Godot alone, at precision 1, 4, 16 and 64: its lowest point is at %.4f, %.4f, %.4f and %.4f m in this run" % lows)
	check((lows[3] - lows[2]) * 100.0 > 0.5 and (lows[3] - lows[2]) * 100.0 < 3.0, "from precision 16 to 64 its lowest point rises %.2f cm" % ((lows[3] - lows[2]) * 100.0))
	base.free()
	await frames(2)

## A walker meets the soft body of Godot; and what that soft body does with nothing pinned.
func walker_and_godots() -> void:
	var base: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(base)
	var soft := godots(5)
	base.add_child(soft)
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.position = Vector3(0.0, 0.0, 2.0)
	base.add_child(walker)
	await physics_frames(120)
	var how := await walk(walker, [Vector3(0.0, 0.0, 0.0)])
	var pushed := 0.0
	for i in 121:
		pushed = maxf(pushed, absf(soft.get_point_transform(i).z))
	measured["walker_in_godots_soft_body"] = {"walk_ended": how, "soft_body_out_of_its_plane_m": snappedf(pushed, 0.0001)}
	check(how == "arrived" and pushed < 0.001, "a walker walks into the soft body of Godot and %s; the soft body is pushed %.4f m: it does not meet the walker at all" % [how, pushed])
	soft.set_point_pinned(110, false)
	soft.set_point_pinned(120, false)
	await physics_frames(180)
	var low := INF
	for i in 121:
		low = minf(low, soft.get_point_transform(i).y)
	measured["godots_soft_body_unpinned_lowest_point_after_3_s_m"] = snappedf(low, 0.01)
	check(low < -1.0, "with its two points let go, the soft body of Godot falls through the supplied floor: 3 s later its lowest point is at %.1f m" % low)
	base.free()
	await frames(2)

## The body handed to the room.
func guest() -> void:
	var needs := CheckGuest.outside("res://guests/soft-body/")
	check(needs.is_empty(), "the guest names nothing outside its folder: %s" % [needs])
	check(CheckGuest.class_names("res://guests/soft-body/").is_empty(), "the guest declares no class_name")
	var before := errors.size()
	var base: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(base)
	var body: Node3D = load("res://guests/soft-body/soft-body.tscn").instantiate()
	body.position = Vector3(1.0, 0.0, -0.5)
	base.add_child(body)
	await physics_frames(120)
	var cloth: Node3D = body.get_node("Cloth")
	var box := AABB()
	var first := true
	for part: GeometryInstance3D in body.find_children("*", "GeometryInstance3D", true, false):
		var here: AABB = part.global_transform * part.get_aabb()
		box = here if first else box.merge(here)
		first = false
	check(errors.size() == before and body is Node3D and box.size.x <= 1.6 and box.size.z <= 1.6 and absf(box.position.y) < 0.001 and absf(box.get_center().x - 1.0) < 0.001,
		"the guest loads and runs 120 steps with no error; it is %.2f m wide, %.2f m deep and %.2f m high, and stands on the ground at its own origin" % [box.size.x, box.size.z, box.size.y])
	var steps := 120
	while cloth.awake and steps < 1200:
		await physics_frame
		steps += 1
	var rest: float = measure(cloth)["lowest_point_m"]
	check(not cloth.awake and steps < 1200, "with nobody near it comes to rest and stops stepping, %d steps after it was made; its lowest point is at %.2f m" % [steps, rest])
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.position = Vector3(1.0, 0.0, 2.0)
	base.add_child(walker)
	await physics_frames(30)
	var how := await walk(walker, [Vector3(1.0, 0.0, -0.5)])
	var pushed := out_of_plane(cloth)
	measured["guest"] = {"asleep_after_steps": steps, "lowest_point_m": rest, "walk_ended": how, "cloth_out_of_its_plane_m": snappedf(pushed, 0.001), "width_m": snappedf(box.size.x, 0.01), "depth_m": snappedf(box.size.z, 0.01), "height_m": snappedf(box.size.y, 0.01)}
	check(how == "arrived" and cloth.awake and pushed > 0.2, "a walker walks between the posts and %s in the middle; the cloth wakes and is pushed %.2f m out of its plane" % [how, pushed])
	how = await walk(walker, [Vector3(1.0, 0.0, 2.0)])
	how = await walk(walker, [Vector3(1.7, 0.0, 2.0), Vector3(1.7, 0.0, -1.5)])
	check(how == "blocked" and walker.global_position.z > -0.5, "a post stops the walker: \"%s\" at z = %.2f" % [how, walker.global_position.z])
	# The guest's cloth is the lesson's: the same numbers at the same count.
	var ours := hung(8)
	stepped(ours, 900)
	var theirs: MeshInstance3D = GuestCloth.new()
	theirs.position = Vector3(0.0, 2.0, 0.0)
	theirs.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(theirs)
	for i in 900:
		theirs.step(STEP)
	check(is_equal_approx(measure(ours)["lowest_point_m"], measure(theirs)["lowest_point_m"]), "the guest's cloth.gd steps as the lesson's does: at 8 passes both have their lowest point at %.4f m" % measure(theirs)["lowest_point_m"])
	ours.free()
	theirs.free()
	base.free()
	await frames(2)
	# Not measured by this run: the room is another project. Run once, on 1 October 2026, in a
	# scratch copy of my-room, with guest_trial.gd and a probe; kept here so that the lesson
	# quotes nothing that is not in this file.
	measured["room_trial_recorded"] = {
		"how": "a scratch copy of my-room, this guest copied in at place 2; guest_trial.gd, then a probe that walked the walker through and waited",
		"guest_trial_checks": 8, "guest_trial_failed": 0, "walk_ended": "arrived", "metres_from_the_middle_of_the_place": 0.07,
		"cloth_pushed_out_of_its_plane_m": 0.29, "walked_on_through": "arrived", "rests_again_after_steps": 983, "out_of_its_plane_at_rest_m": 0.0006,
		"a_soft_part_on_a_copy_of_the_example_guest": {"points": "6 by 5", "spacing_m": 0.1, "at": "(0, 1.3, 0.35)", "walk_ended": "blocked", "metres_from_the_middle_of_the_place": 0.56, "pushed_out_of_its_plane_m": 0.13},
	}

## The numbers the lesson quotes from the sheet, read back.
func sheet_numbers() -> void:
	if not FileAccess.file_exists("res://sheet.json"):
		check(false, "sheet.json is there (it is not: run sheet.gd, with a window, first)")
		return
	var sheet: Dictionary = JSON.parse_string(text_of("res://sheet.json"))
	var lows := []
	for value: int in VALUES:
		lows.append(sheet["ours"][str(value)]["lowest_point_m"])
	check(alike(lows, [0.1162, 0.4264, 0.5603, 0.6465]), "sheet.json has our cloth where this run has it: %s m" % [lows])
	var ours: Dictionary = sheet["pairs_ours"]
	check(ours["closest"] == "16 vs 64" and ours["farthest"] == "1 vs 64" and ours["pairs"]["16 vs 64"]["differ_pct"] < ours["pairs"]["4 vs 16"]["differ_pct"],
		"on the sheet the closest pair of our cloth is %s (%.2f%% of the still) and the farthest %s (%.2f%%)" % [ours["closest"], ours["pairs"][ours["closest"]]["differ_pct"], ours["farthest"], ours["pairs"][ours["farthest"]]["differ_pct"]])
	var theirs: Dictionary = sheet["pairs_godots"]
	var soft_lows := []
	for value: int in VALUES:
		soft_lows.append(sheet["godots"][str(value)]["lowest_point_m"])
	check(theirs["closest"] == "16 vs 64" and soft_lows[3] > lows[3] and soft_lows[0] > lows[0],
		"the soft body of Godot on the sheet: lowest point at %s m, higher than ours at every count; its closest pair is %s (%.2f%%)" % [soft_lows, theirs["closest"], theirs["pairs"][theirs["closest"]]["differ_pct"]])
	var strip: Dictionary = sheet["strip"]
	check(strip["steps"].size() == 7 and strip["png"]["bytes"] < 300000 and sheet["sheet_png"]["bytes"] < 300000 and FileAccess.file_exists("res://sheet.png") and FileAccess.file_exists("res://process.png"),
		"sheet.png and process.png are there, each under 300 KB; the strip has 7 steps, and \"%s\" changed its tile most" % strip["changed_most"])
