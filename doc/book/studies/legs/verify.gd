extends "res://supplied/verify_tools.gd"
## The Legs kit's checks. Headless, from this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## It writes verification.json; the exit code is the number of failed checks.
## With --fixed-fps 60 added it takes seconds instead of two minutes, with the same checks.

const CheckGuest := preload("res://supplied/check_guest.gd")
const VALUES := [1, 2, 3, 6]

func run() -> void:
	await project()
	await one_leg()
	await the_ray()
	await the_planted_bug()
	await the_creature()
	await the_axis()
	await the_layers()
	await the_place()
	await the_carry()
	await the_carry_scene()
	await the_guest()

# ---------------------------------------------------------------- helpers

func base() -> Node3D:
	var scene: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(scene)
	return scene

func leg_at(parent: Node, parts: int, at: Vector3, turn := Vector3.ZERO) -> Node3D:
	var leg: Node3D = load("res://leg.tscn").instantiate()
	leg.segments = parts
	leg.position = at
	leg.rotation_degrees = turn
	parent.add_child(leg)
	return leg

func kit_scene() -> Node3D:
	var scene: Node3D = load("res://legs.tscn").instantiate()
	scene.get_node("Walker").keys = false
	return scene

## How far each leg's end is from where its foot is held this frame (the foot, lifted while it is on its way).
func miss(creature: Node3D) -> float:
	var worst := 0.0
	for leg in creature.legs:
		var held: Vector3 = leg.foot + Vector3.UP * minf(0.1, leg.foot.distance_to(leg.target))
		worst = maxf(worst, leg.tip().distance_to(held))
	return worst

## Of 10 places along every part of every leg, how many lie under the ground.
func under_ground(creature: Node3D, terrain: Node) -> int:
	var count := 0
	for leg in creature.legs:
		for part: Node3D in leg.chain:
			for k in 10:
				var at: Vector3 = part.global_position - part.global_basis.z * leg.length * (k + 0.5) / 10.0
				if at.y < terrain.height_at(at.x, at.z) - 0.03:    # 3 cm: more than half the bone's thickness
					count += 1
	return count

func files_in(folder: String, ending: String) -> Array:
	var out := []
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(ending):
			out.append(folder + file)
	for inner in DirAccess.get_directories_at(folder):
		if inner != ".godot" and inner != "stills":
			out.append_array(files_in(folder + inner + "/", ending))
	return out

# ---------------------------------------------------------------- the project

func project() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "Legs", "the project is named Legs")
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://legs.tscn", "its main scene is legs.tscn")
	var supplied := DirAccess.get_files_at("res://supplied/")
	var kept := []
	for file in supplied:
		if not file.ends_with(".uid"):
			kept.append(file)
	check(kept.size() == 15, "supplied/ holds the base's 15 files: %d" % kept.size())
	var named := []
	var spaced := []
	for file: String in files_in("res://", ".gd"):
		var text := FileAccess.get_file_as_string(file)
		if RegEx.create_from_string("(?m)^class_name\\s").search(text) != null:
			named.append(file)
		if RegEx.create_from_string("(?m)^ +\\S").search(text) != null:
			spaced.append(file)
	check(named.is_empty(), "no script of the kit declares a class_name: %s" % [named])
	check(spaced.is_empty(), "every script is indented with tabs: %s" % [spaced])
	for file: String in ["res://leg.gd", "res://leg.tscn", "res://creature.gd", "res://legs.tscn", "res://carry.tscn", "res://carry.gd",
			"res://ghost_plank.gd", "res://borrowed/terrain.gd", "res://TUTORIAL.md", "res://README.md", "res://FIELD_NOTE.md"]:
		check(FileAccess.file_exists(file), "%s is in the kit" % file)

# ---------------------------------------------------------------- one leg: the follow loop

func one_leg() -> void:
	var room := base()
	await physics_frames(2)
	var totals := []
	for parts: int in VALUES:
		var leg := leg_at(room, parts, Vector3(parts * 0.5 - 2.0, 0.9, 0))
		var laid := true
		for i in parts:
			if not near(leg.chain[i].position, Vector3(0, -leg.length * i, 0), 0.0001):
				laid = false
		check(leg.chain.size() == parts and laid, "a leg of %d has %d parts, laid along the hip's own down" % [parts, leg.chain.size()])
		totals.append(snappedf(leg.length * leg.chain.size(), 0.0001))
		check(near(leg.tip(), leg.global_position + Vector3(0, -0.8, 0), 0.0001), "its end hangs 0.8 m under the hip: %s" % [leg.tip() - leg.global_position])
	check(totals == [0.8, 0.8, 0.8, 0.8], "1, 2, 3 and 6 parts make the same length: %s" % [totals])
	# a place within reach
	var hip := Vector3(0, 0.9, -1.5)
	var place := hip + Vector3(0.35, -0.4, 0.1)
	measured["follow_calls_until_1_mm"] = {}
	for parts: int in [2, 3, 6]:
		var leg := leg_at(room, parts, hip)
		var calls := 0
		while calls < 50 and leg.tip().distance_to(place) > 0.001:
			leg.follow(place)
			calls += 1
		measured["follow_calls_until_1_mm"][str(parts)] = calls
		check(calls <= 10, "a leg of %d parts has its end within 1 mm of a place %.2f m from the hip after %d calls of follow()" % [parts, hip.distance_to(place), calls])
		var kept := true
		for i in range(1, parts):
			if absf(leg.chain[i].global_position.distance_to(leg.chain[i - 1].global_position) - leg.length) > 0.0001:
				kept = false
		check(kept, "every part of it kept its length, %.3f m" % leg.length)
		check(near(leg.chain[0].global_position, hip, 0.0001), "the chain's upper end is on the hip")
		check(not near(leg.led, hip, 0.0001) or calls > 1, "the loop led the hip's end away from the hip before the chain was carried back")
		leg.free()
	# one part cannot bend
	var stick := leg_at(room, 1, hip)
	for i in 20:
		stick.follow(place)
	var short: float = stick.tip().distance_to(place)
	measured["one_part_misses_m"] = snappedf(short, 0.001)
	check(absf(short - (0.8 - hip.distance_to(place))) < 0.001, "a leg of one part points at the place and ends %.3f m past it: 0.8 m less the %.3f m to the place" % [short, hip.distance_to(place)])
	stick.free()
	# a place out of reach
	var far := hip + Vector3(0.9, -0.6, 0)
	var long := leg_at(room, 3, hip)
	for i in 50:
		long.follow(far)
	var gap: float = long.tip().distance_to(far)
	check(absf(gap - (hip.distance_to(far) - 0.8)) < 0.002, "a place %.2f m from the hip is out of reach: the leg stretches at it and ends %.3f m short" % [hip.distance_to(far), gap])
	# the foot leads and the hip follows: the loop alone, with nothing carrying the chain back
	var rope := leg_at(room, 3, Vector3(2, 0.9, -1.5))
	var before: Vector3 = rope.chain[0].global_position
	rope.follow(Vector3(2.4, 0.4, -1.5))
	measured["hip_end_led_m_by_a_foot_moved_0_5_m"] = snappedf(rope.led.distance_to(before), 0.001)
	check(rope.led.distance_to(before) > 0.01 and rope.led.distance_to(before) < 0.5, "moving the foot 0.5 m led the hip's end %.3f m: it follows, and less far" % rope.led.distance_to(before))
	# straight down: the up that look_at() is handed
	var quiet := warnings.size()
	var plumb := leg_at(room, 3, Vector3(3, 0.9, -1.5))
	for i in 5:
		plumb.follow(Vector3(3, 0.3, -1.5))
	check(warnings.size() == quiet and plumb.tip().distance_to(Vector3(3, 0.3, -1.5)) < 0.3, "a leg that hangs straight down follows a place straight under its hip and Godot logs no warning: %s" % [warnings.slice(quiet)])
	for i in 45:
		plumb.follow(Vector3(3, 0.3, -1.5))
	var past: float = plumb.tip().distance_to(Vector3(3, 0.3, -1.5))
	measured["a_straight_leg_over_a_place_0_6_m_under_its_hip_ends_past_it_m"] = snappedf(past, 0.001)
	check(absf(past - 0.2) < 0.001, "and it does not bend: after 50 calls of follow() a straight leg of 3 parts ends %.3f m past a place 0.6 m straight under its hip, as a leg of one part would" % past)
	var looker := Node3D.new()
	looker.position = Vector3(3.5, 1, -1.5)
	room.add_child(looker)
	looker.look_at(Vector3(3.5, 0, -1.5))
	var said: String = warnings[-1] if warnings.size() > quiet else ""
	measured["look_at_straight_down_with_the_rooms_up"] = said
	check(said == "WARNING: Target and up vectors are colinear. This is not advised as it may cause unwanted rotation around local Z axis.", "look_at() straight down with the room's up, its default, logs: %s" % said)
	# a longer way: the foot carried 2 m in steps of 2 cm, the loop alone
	var towed := leg_at(room, 3, Vector3(-3, 0.9, 1.5))
	var top: Vector3 = towed.chain[0].global_position
	var way := 0.0
	for i in 100:
		towed.follow(Vector3(-3 + 0.02 * (i + 1), 0.1, 1.5))
		for part: Node3D in towed.chain:           # undo the carrying back: the chain stays where the loop left it
			part.global_position += towed.led - towed.global_position
		way += towed.led.distance_to(top)
		top = towed.led
	var lies: float = towed.chain[0].global_position.y - 0.1
	measured["foot_carried_2_m"] = {"hip_end_travelled_m": snappedf(way, 0.01), "hip_end_above_the_foot_m": snappedf(lies, 0.01), "hip_end_behind_the_foot_m": snappedf(-1.0 - towed.chain[0].global_position.x, 0.01)}
	check(way > 0.5 and lies < 0.8, "the foot carried 2 m with nothing holding the hip: the hip's end travelled %.2f m after it and trails %.2f m behind, %.2f m above the foot where it began 0.80 m above" % [way, -1.0 - towed.chain[0].global_position.x, lies])
	room.free()
	await frames(1)

# ---------------------------------------------------------------- the ray

func the_ray() -> void:
	var room := base()
	var terrain := StaticBody3D.new()
	terrain.set_script(load("res://borrowed/terrain.gd"))
	room.add_child(terrain)
	await physics_frames(3)
	var flat := leg_at(room, 3, Vector3(3.2, 0.5, 1.0), Vector3(0, 45, 90))
	check(flat.find_ground(), "on a hip turned a quarter, find_ground() finds the floor")
	var rest: Vector3 = flat.to_global(Vector3(0, -flat.reach, 0))
	check(near(flat.target, Vector3(rest.x, 0, rest.z), 0.001), "the place it found is straight under the leg's rest place, on the floor: %s" % [flat.target])
	check(near(flat.get_node("Ray").to_global(flat.get_node("Ray").target_position), rest + Vector3.DOWN * 2.0, 0.001), "the ray looks 2 m straight down in the room, whatever the hip's turn")
	flat.lead = Vector3(0.2, 0, 0)
	flat.find_ground()
	check(near(flat.target, Vector3(rest.x + 0.2, 0, rest.z), 0.001), "with a lead of 0.2 m the ray starts 0.2 m further on")
	flat.lead = Vector3(2.0, 0, 0)
	var kept: Vector3 = flat.target
	check(not flat.find_ground() and flat.target == kept, "past the edge of the floor it finds nothing, says false, and keeps the place it had")
	var ray: RayCast3D = flat.get_node("Ray")
	check(not ray.is_colliding() and near(ray.get_collision_point(), kept, 0.001), "a ray that had a hit and now has none still gives a point, the last one it had: %s" % [ray.get_collision_point()])
	var fresh := leg_at(room, 3, Vector3(6, 0.5, 0), Vector3(0, 45, 90))
	var first: Vector3 = fresh.target
	check(not fresh.find_ground() and fresh.target == first and first != Vector3.ZERO, "a leg whose first look finds no ground keeps the place it had, and is not sent to (0, 0, 0)")
	var worst := 0.0
	for x: float in [-1.5, -0.7, 0.0, 0.6, 1.3]:
		var hill := leg_at(room, 3, Vector3(x, 0.9, 0.2), Vector3(0, 45, 90))
		hill.find_ground()
		worst = maxf(worst, absf(hill.target.y - terrain.height_at(hill.target.x, hill.target.z)))
		hill.free()
	measured["ray_against_height_at_worst_m"] = snappedf(worst, 0.001)
	measured["ground_height_at_the_rooms_middle_m"] = snappedf(terrain.height_at(0, 0), 0.01)
	check(worst < 0.02, "on the borrowed ground the ray's place is the ground's height there, within %.3f m at five places" % worst)
	room.free()
	await frames(1)

# ---------------------------------------------------------------- the planted bug

func the_planted_bug() -> void:
	var room := base()
	await physics_frames(3)
	var said := errors.size() + warnings.size()
	var hip := Node3D.new()
	hip.position = Vector3(1, 0.5, 0)
	room.add_child(hip)
	var ray := RayCast3D.new()
	hip.add_child(ray)
	check(ray.target_position == Vector3(0, -1, 0), "a new RayCast3D looks 1 m along its own down: %s" % [ray.target_position])
	ray.force_raycast_update()
	check(ray.is_colliding() and near(ray.get_collision_point(), Vector3(1, 0, 0), 0.001), "on a hip that is not turned it finds the floor under it")
	var turned := Node3D.new()
	turned.position = Vector3(-1, 0.5, 0)
	turned.rotation_degrees = Vector3(0, 45, 90)
	room.add_child(turned)
	var side := RayCast3D.new()
	turned.add_child(side)
	side.force_raycast_update()
	var looks: Vector3 = side.to_global(side.target_position) - side.global_position
	check(absf(looks.y) < 0.001, "on a hip turned a quarter the same ray looks sideways: %s" % [looks.snappedf(0.01)])
	check(not side.is_colliding(), "it finds nothing")
	check(side.get_collision_point() == Vector3.ZERO, "and the point it gives is (0, 0, 0), the middle of the room: %s" % [side.get_collision_point()])
	check(errors.size() + warnings.size() == said, "Godot logged nothing about it")
	measured["unrepaired_ray"] = {"colliding": side.is_colliding(), "point": str(side.get_collision_point()), "looks": str(looks.snappedf(0.01))}
	room.free()
	await frames(1)

# ---------------------------------------------------------------- the creature

func the_creature() -> void:
	var before := errors.size() + warnings.size()
	var scene := kit_scene()
	var creature: Node3D = scene.get_node("Creature")
	creature.heading = Vector3.ZERO
	root.add_child(scene)
	check(creature.legs.size() == 4, "the creature has four legs")
	var outward := true
	for i in 4:
		var out := Vector3.RIGHT.rotated(Vector3.UP, deg_to_rad(45 + 90 * i))
		if not near(-creature.legs[i].global_basis.y, out, 0.001):
			outward = false
	check(outward, "each hip is turned a quarter: its own down points out of the body, level")
	var turns := 0
	var was: int = creature.turn
	for i in 300:
		await physics_frame
		if creature.turn != was:
			turns += 1
			was = creature.turn
	measured["feet_turns_in_5_s"] = turns
	check(turns >= 20 and turns <= 25, "one foot's turn comes every fifth of a second or a little later: %d turns in 5 seconds" % turns)
	var feet_down := true
	for leg in creature.legs:
		if absf(leg.foot.y) > 0.001:
			feet_down = false
	check(feet_down, "standing on the floor for five seconds, its four feet are on the floor")
	check(absf(creature.global_position.y - 0.4) < 0.001, "and its body rides 0.4 m above them: %.3f" % creature.global_position.y)
	check(miss(creature) < 0.001, "every leg's end is within 1 mm of its foot's place: %.4f" % miss(creature))
	check(near(creature.global_position, Vector3(-3.0, 0.4, 0), 0.01), "it has not left its place: %s" % [creature.global_position.snappedf(0.01)])
	# it walks
	creature.heading = Vector3.RIGHT
	var terrain: Node = scene.get_node("Terrain")
	var off_ground := 0.0
	var ride_off := 0.0
	for i in 480:
		await physics_frame
		var middle := 0.0
		for leg in creature.legs:
			middle += leg.foot.y / 4.0
			if leg.foot == leg.target:
				off_ground = maxf(off_ground, absf(leg.foot.y - terrain.height_at(leg.foot.x, leg.foot.z)))
		ride_off = maxf(ride_off, absf(creature.global_position.y - middle - 0.4))
	var walked: float = creature.global_position.x + 3.0
	measured["walked_m_in_8_s"] = snappedf(walked, 0.01)
	check(walked > 2.0, "with a heading it walks: %.2f m to the right in 8 seconds, and nothing moved its body but its feet" % walked)
	measured["foot_against_height_at_worst_m"] = snappedf(off_ground, 0.001)
	check(off_ground < 0.03, "every foot that has arrived stands on the ground under it, within %.3f m (the ground's mesh has a corner every 0.2 m and is flat between them)" % off_ground)
	check(ride_off < 0.01, "the body is 0.4 m above the middle of its feet in every step, within %.3f m: one step behind them" % ride_off)
	check(errors.size() + warnings.size() == before, "the kit's scene ran 13 seconds and Godot logged no error and no warning: %s" % [errors + warnings])
	scene.free()
	await frames(1)
	# the end of the ground
	scene = kit_scene()
	creature = scene.get_node("Creature")
	creature.position = Vector3(2.0, 0.4, 0)
	root.add_child(scene)
	var furthest := -10.0
	for i in 480:
		await physics_frame
		furthest = maxf(furthest, creature.global_position.x)
	measured["turned_back_at_x"] = snappedf(furthest, 0.01)
	check(creature.heading == Vector3.LEFT and furthest < 4.0 and creature.global_position.x < furthest - 0.3, "where the floor ends a ray finds nothing and the creature turns round: it got to x = %.2f of a floor that ends at 4, and walks back" % furthest)
	scene.free()
	await frames(1)
	# the leash
	var room := base()
	var leashed := Node3D.new()
	leashed.set_script(load("res://creature.gd"))
	leashed.leash = 0.3
	leashed.position = Vector3(0, 0.4, 0)
	room.add_child(leashed)
	var low := 0.0
	var high := 0.0
	for i in 540:
		await physics_frame
		low = minf(low, leashed.global_position.x)
		high = maxf(high, leashed.global_position.x)
	measured["leash_0_3_paces_between"] = [snappedf(low, 0.01), snappedf(high, 0.01)]
	check(low < -0.3 and low > -0.6 and high > 0.3 and high < 0.6, "on a leash of 0.3 m it paces between x = %.2f and %.2f" % [low, high])
	room.free()
	await frames(1)

# ---------------------------------------------------------------- the axis: parts in each leg

func the_axis() -> void:
	measured["axis"] = {}
	for parts: int in VALUES:
		var scene := kit_scene()
		var creature: Node3D = scene.get_node("Creature")
		creature.segments = parts
		creature.position = Vector3(-2.5, 0.4, 0)
		root.add_child(scene)
		var terrain: Node = scene.get_node("Terrain")
		var sum := 0.0
		var worst := 0.0
		var under := 0
		var count := 0
		for i in 360:
			await physics_frame
			if creature.global_position.x > -2.0 and creature.global_position.x < 2.0:    # over the uneven ground
				var m := miss(creature)
				sum += m
				worst = maxf(worst, m)
				under += under_ground(creature, terrain)
				count += 1
		var row := {"parts_in_all": creature.legs[0].chain.size() * 4, "walked_m_in_6_s": snappedf(creature.global_position.x + 2.5, 0.01),
			"steps_over_the_uneven_ground": count, "mean_miss_m": snappedf(sum / maxi(count, 1), 0.001), "worst_miss_m": snappedf(worst, 0.001),
			"places_under_the_ground_pct": snappedf(100.0 * under / maxf(count * parts * 40.0, 1.0), 0.1)}
		measured["axis"][str(parts)] = row
		check(creature.legs[0].chain.size() == parts, "segments = %d gives legs of %d parts" % [parts, creature.legs[0].chain.size()])
		if parts == 1:
			check(row["mean_miss_m"] > 0.1, "with one part the legs' ends are %.3f m from their feet's places on average, walking the uneven ground" % row["mean_miss_m"])
		else:
			check(row["mean_miss_m"] < 0.03, "with %d parts they are %.3f m from them on average (worst %.3f), walking the uneven ground" % [parts, row["mean_miss_m"], row["worst_miss_m"]])
		scene.free()
		await frames(1)
		# the same count from a start half a metre further on: does it hold?
		scene = kit_scene()
		creature = scene.get_node("Creature")
		creature.segments = parts
		creature.position = Vector3(-2.0, 0.4, 0)
		root.add_child(scene)
		terrain = scene.get_node("Terrain")
		under = 0
		count = 0
		for i in 240:
			await physics_frame
			if creature.global_position.x > -2.0 and creature.global_position.x < 2.0:
				under += under_ground(creature, terrain)
				count += 1
		measured["axis"][str(parts)]["places_under_the_ground_pct_from_a_start_half_a_metre_on"] = snappedf(100.0 * under / maxf(count * parts * 40.0, 1.0), 0.1)
		scene.free()
		await frames(1)
	var walks := []
	for parts: int in VALUES:
		walks.append(measured["axis"][str(parts)]["walked_m_in_6_s"])
	check(walks.min() == walks.max(), "the creature walks equally far with 1, 2, 3 and 6 parts: the feet's places do not depend on the legs: %s" % [walks])

# ---------------------------------------------------------------- layers and masks

func the_layers() -> void:
	measured["plank"] = {}
	for mask: int in [1, 3]:
		var scene := kit_scene()
		var creature: Node3D = scene.get_node("Creature")
		creature.ground = mask
		creature.position = Vector3(2.0, 0.4, 0)
		root.add_child(scene)
		if mask == 1:
			var plank: StaticBody3D = scene.get_node("Plank")
			check(plank.collision_layer == 2, "the plank is on layer 2 and on no other")
		var highest := 0.0
		for i in 300:
			await physics_frame
			for leg in creature.legs:
				if absf(leg.target.x - 3.0) < 0.35:
					highest = maxf(highest, leg.target.y)
		measured["plank"]["ground_%d_highest_foot_place_m" % mask] = snappedf(highest, 0.001)
		if mask == 1:
			check(highest < 0.01, "feet that look at layer 1 find the floor under the plank: their highest place there is %.3f m" % highest)
		else:
			check(absf(highest - 0.25) < 0.01, "feet that look at layers 1 and 2 step onto the plank: their highest place there is %.3f m, its top" % highest)
		scene.free()
		await frames(1)

# ---------------------------------------------------------------- the place: a body meets the made body

func the_place() -> void:
	var scene := kit_scene()
	var creature: Node3D = scene.get_node("Creature")
	creature.heading = Vector3.ZERO
	root.add_child(scene)
	var walker: CharacterBody3D = scene.get_node("Walker")
	var terrain: Node = scene.get_node("Terrain")
	await physics_frames(30)
	# over the uneven ground
	var how := await walk(walker, [Vector3(-2.6, 0, 1.0), Vector3(0.6, 0, 0.9)])
	var at: Vector3 = walker.global_position
	var stands: float = terrain.height_at(at.x, at.z)
	measured["walker_on_the_ground"] = {"walk_ended": how, "feet_at_m": snappedf(at.y, 0.01), "ground_there_m": snappedf(stands, 0.01)}
	check(how == "arrived" and absf(at.y - stands) < 0.05, "the walker walked onto the uneven ground and stands on it: \"%s\", its feet at %.2f m where the ground is %.2f m" % [how, at.y, stands])
	# through the plank
	how = await walk(walker, [Vector3(2.4, 0, 1.6), Vector3(3.0, 0, 1.6), Vector3(3.0, 0, 0.5)])
	measured["walker_at_the_plank"] = {"walk_ended": how, "feet_at_m": snappedf(walker.global_position.y, 0.01)}
	check(how == "arrived" and walker.global_position.y < 0.01, "the walker walked to the middle of the plank and through it: \"%s\", its feet on the floor" % how)
	var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
	marble.position = Vector3(3.0, 1.5, -0.6)
	scene.add_child(marble)
	marble.drop(Vector3(3.0, 1.5, -0.6))
	var rest := await settle(marble)
	measured["marble_over_the_plank_rests_at_m"] = snappedf(rest.y, 0.01)
	check(absf(rest.y - 0.1) < 0.01, "a marble dropped over the plank falls through it to the floor: it rests at %.2f m" % rest.y)
	# against the creature
	how = await walk(walker, [Vector3(3.0, 0, 1.6), Vector3(-3.0, 0, 1.6)])
	how = await walk(walker, [creature.global_position])
	var gap := Vector2(walker.global_position.x - creature.global_position.x, walker.global_position.z - creature.global_position.z).length()
	measured["walker_at_the_creature"] = {"walk_ended": how, "metres_from_its_middle": snappedf(gap, 0.01)}
	check(how == "blocked", "the walker walked at the standing creature and was stopped by its body: \"%s\", %.2f m from its middle" % [how, gap])
	marble.drop(creature.global_position + Vector3(-0.15, 1.2, 0))
	rest = await settle(marble)
	measured["marble_on_the_creature_rests_at_m"] = snappedf(rest.y, 0.01)
	check(absf(rest.y - (creature.global_position.y + 0.18)) < 0.01, "a marble dropped on the creature's back rests on it, at %.2f m" % rest.y)
	# the walker stands where a foot's ray comes down
	var leg: Node3D = creature.legs[3]
	var under: Vector3 = leg.to_global(Vector3(0, -leg.reach, 0))
	how = await walk(walker, [Vector3(-3.0, 0, 1.6), Vector3(under.x, 0, 1.6)])
	walker.stand_at(Vector3(under.x, 0, under.z))
	await physics_frames(90)
	check(absf(leg.target.y) < 0.001 and miss(creature) < 0.001, "the walker stood where a foot's ray comes down and the foot stayed on the floor: the ray starts at hip height, inside the walker")
	var probe := RayCast3D.new()
	probe.target_position = Vector3(0, -3, 0)
	probe.position = Vector3(under.x, 2.5, under.z)
	scene.add_child(probe)
	probe.force_raycast_update()
	measured["ray_from_above_the_walker"] = {"finds": str(probe.get_collider().name), "at_height_m": snappedf(probe.get_collision_point().y, 0.01)}
	check(probe.get_collider() == walker and absf(probe.get_collision_point().y - 1.8) < 0.01, "a ray that starts above the walker's head finds the walker, %.2f m up: on layer 1 the walker is ground too" % probe.get_collision_point().y)
	probe.position.y = 0.4
	probe.force_raycast_update()
	measured["ray_from_inside_the_walker"] = {"finds": str(probe.get_collider().name), "at_height_m": snappedf(probe.get_collision_point().y, 0.01)}
	check(probe.get_collider() != walker and absf(probe.get_collision_point().y) < 0.01, "a ray that starts inside the walker does not see it and finds the floor: %s" % probe.get_collider().name)
	probe.free()
	walker.stand_at(Vector3(under.x, 0, 1.6))
	await physics_frames(30)
	scene.free()
	await frames(1)

# ---------------------------------------------------------------- the place: carry a foot, as the lesson does it

func the_carry() -> void:
	var scene := kit_scene()
	var creature: Node3D = scene.get_node("Creature")
	var walker: CharacterBody3D = scene.get_node("Walker")
	creature.hand = walker              # the lesson's two lines, set before the scene runs
	creature.heading = Vector3.ZERO
	root.add_child(scene)
	var terrain: Node = scene.get_node("Terrain")
	var start: Vector3 = creature.global_position
	await physics_frames(60)
	var first: Vector3 = creature.global_position - start
	check(near(creature.legs[0].target, walker.global_position, 0.001), "with the walker as its hand, the creature's first foot is asked to be where the walker is")
	var highest := 0.0
	walker.walk_to([walker.global_position + Vector3(2.8, 0, 0)])
	while walker.walking:
		await physics_frame
		for i in range(1, 4):
			highest = maxf(highest, creature.legs[i].target.y - terrain.height_at(creature.legs[i].target.x, creature.legs[i].target.z))
	await physics_frames(240)
	var moved: Vector3 = creature.global_position - start
	var trail: Vector3 = creature.global_position - walker.global_position
	measured["carry"] = {"body_moved_m_in_the_first_second": snappedf(first.length(), 0.01), "walker_walked_m": 2.8,
		"body_moved_m": snappedf(Vector2(moved.x, moved.z).length(), 0.01), "body_ends_m_from_the_walker": snappedf(Vector2(trail.x, trail.z).length(), 0.01),
		"body_at": str(creature.global_position.snappedf(0.01)), "worst_miss_m": snappedf(miss(creature), 0.001),
		"other_feet_highest_above_the_ground_m": snappedf(highest, 0.01)}
	check(Vector2(moved.x, moved.z).length() > 2.0, "the walker carried the foot 2.8 m and the body followed its leg: it moved %.2f m and stands %.2f m from the walker" % [Vector2(moved.x, moved.z).length(), Vector2(trail.x, trail.z).length()])
	scene.free()
	await frames(1)

# ---------------------------------------------------------------- carry.tscn

func the_carry_scene() -> void:
	var before := errors.size() + warnings.size()
	var scene: Node3D = load("res://carry.tscn").instantiate()
	scene.get_node("Hand").autopilot = true
	root.add_child(scene)
	var leg: Node3D = scene.get_node("Leg")
	var reached := 0
	var short := 0
	var clock := 0.0                         # seconds of the scene's own time, however many frames that is
	var steps := 0
	while clock < 6.5 and steps < 4000:
		await process_frame
		clock += root.get_process_delta_time()
		steps += 1
		var hand: Vector3 = scene.get_node("Hand").global_position
		if hand.distance_to(leg.global_position) < 0.75:
			reached += 1
			if leg.tip().distance_to(hand) > 0.05:
				short += 1
	check(reached >= 5 and short == 0, "in carry.tscn the leg's end stays within 5 cm of the hand while the hand is within reach of the hip (%d frames of %d, in 6.5 seconds)" % [reached, steps])
	check(scene.get_node("Readout").text.begins_with("foot to hand"), "its readout says how far the foot is from the hand")
	check(errors.size() + warnings.size() == before, "carry.tscn ran 6.5 seconds and Godot logged no error and no warning: %s" % [errors + warnings])
	scene.free()
	await frames(1)

# ---------------------------------------------------------------- the guest

func the_guest() -> void:
	var needs := CheckGuest.outside("res://guests/legs/")
	check(needs.is_empty(), "the guest names nothing outside its folder: %s" % [needs])
	check(CheckGuest.class_names("res://guests/legs/").is_empty(), "the guest declares no class_name")
	var before := errors.size() + warnings.size()
	var room := base()
	var guest: Node3D = load("res://guests/legs/legs.tscn").instantiate()
	guest.position = Vector3(1, 0, 0.5)
	room.add_child(guest)
	check(guest is Node3D and guest.get_class() == "Node3D", "the guest's first node is a Node3D")
	var low := 9.0
	var wide := 0.0
	var paced_low := 9.0
	var paced_high := -9.0
	for i in 600:
		await physics_frame
		if i < 60:
			continue
		for part: Node in guest.find_children("*", "GeometryInstance3D", true, false):
			var box: AABB = part.global_transform * part.get_aabb()
			low = minf(low, box.position.y)
			wide = maxf(wide, maxf(maxf(absf(box.position.x - 1.0), absf(box.end.x - 1.0)), maxf(absf(box.position.z - 0.5), absf(box.end.z - 0.5))))
		paced_low = minf(paced_low, guest.get_node("Creature").global_position.x - 1.0)
		paced_high = maxf(paced_high, guest.get_node("Creature").global_position.x - 1.0)
	measured["guest"] = {"lowest_point_m": snappedf(low, 0.001), "furthest_from_its_middle_m": snappedf(wide, 0.001), "paces_between_m": [snappedf(paced_low, 0.01), snappedf(paced_high, 0.01)]}
	check(near(guest.global_position, Vector3(1, 0, 0.5)), "the guest's own origin stays where it was put")
	check(low > -0.045, "it stands on the ground: its lowest point over 9 seconds is %.3f m, the underside of a foot's mark, a ball of 4 cm" % low)
	check(wide < 0.8, "it fits in a box 1.6 m wide and deep while it paces: nothing of it is further than %.3f m from its middle" % wide)
	check(paced_high - paced_low > 0.1, "it paces: its body moved between %.2f and %.2f m from its place" % [paced_low, paced_high])
	var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
	marble.position = Vector3(1.0, 1.5, 0.5)
	room.add_child(marble)
	marble.drop(guest.get_node("Creature").global_position + Vector3(0, 1.0, 0))
	await physics_frames(90)
	measured["guest"]["marble_on_it_at_m_after_1_5_s"] = snappedf(marble.global_position.y, 0.01)
	check(marble.global_position.y > 0.5, "a marble dropped on its back is held by it: at %.2f m after a second and a half" % marble.global_position.y)
	check(errors.size() + warnings.size() == before, "the guest ran 11 seconds and Godot logged no error and no warning: %s" % [errors + warnings])
	# a rider: a body for the legs to carry
	var box := MeshInstance3D.new()
	box.name = "Box"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.5, 0.5, 0.5)
	box.mesh = mesh
	box.position.y = 0.25
	var rider_root := Node3D.new()
	rider_root.add_child(box)
	box.owner = rider_root
	box.create_convex_collision()
	for inner: Node in box.find_children("*", "", true, false):
		inner.owner = rider_root
	var packed := PackedScene.new()
	packed.pack(rider_root)
	rider_root.free()
	var mount: Node3D = load("res://guests/legs/legs.tscn").instantiate()
	mount.position = Vector3(-2, 0, 0.5)
	mount.get_node("Creature").rider = packed
	room.add_child(mount)
	await physics_frames(60)
	var carried: Node3D = mount.get_node("Creature").get_child(1)
	marble.drop(mount.get_node("Creature").global_position + Vector3(0, 1.5, 0))
	await physics_frames(120)
	measured["guest"]["rider_bottom_at_m"] = snappedf(carried.global_position.y, 0.01)
	measured["guest"]["marble_on_the_rider_at_m"] = snappedf(marble.global_position.y, 0.01)
	check(carried.get_parent() == mount.get_node("Creature") and absf(carried.global_position.y - 0.48) < 0.01, "with a rider, a box of 0.5 m, the legs carry it: it stands on the trunk's back, at %.2f m" % carried.global_position.y)
	check(absf(marble.global_position.y - 1.08) < 0.02, "and a marble dropped on the rider rests on it, at %.2f m" % marble.global_position.y)
	room.free()
	await frames(1)
