extends "res://supplied/sheet_tools.gd"
## The Legs kit's sheet. It needs a window, so run it WITHOUT --headless, from
## this folder:
##   godot --path . --xr-mode off --script res://sheet.gd
## It writes
##   sheet.png    the creature standing on the uneven ground with 1, 2, 3 and 6
##                parts in each leg, the legs 0.8 m long every time: from the
##                side, put down and left to stand (first row); from the side,
##                at the same place after a walk of 1.2 m (second row); and
##                the first again from straight above (third row)
##   process.png  the strip: one still after each step of the making, from one
##                standpoint
##   sheet.json   every pair of values measured for those three rows and on the
##                flat floor; for each value how far each leg's end is from its
##                foot's place and the sharpest bend between two parts; the strip
## and the single stills, in stills/.

const TERRAIN := preload("res://borrowed/terrain.gd")
const CREATURE := preload("res://creature.gd")
const VALUES := [1, 2, 3, 6]                 # the axis: parts in each leg
const SPOT := Vector3(1.7, 0.0, 0.0)         # where the borrowed ground is most uneven under four feet

func run() -> void:
	await sheet()
	await process_strip()

func ground() -> StaticBody3D:
	var terrain := StaticBody3D.new()
	terrain.set_script(TERRAIN)
	terrain.name = "Terrain"
	return terrain

func creature(parts: int, at: Vector3) -> Node3D:
	var body := Node3D.new()
	body.set_script(CREATURE)
	body.name = "Creature"
	body.segments = parts
	body.heading = Vector3.ZERO      # it stands
	body.position = at
	return body

## How far each leg's end is from the place its foot was given, in metres.
func misses(body: Node3D) -> Array:
	var out := []
	for leg in body.legs:
		out.append(snappedf(leg.tip().distance_to(leg.foot), 0.001))
	return out

## The creature standing still for three seconds, then held; what it measures.
func settle(body: Node3D) -> Dictionary:
	for i in 180:
		await physics_frame
	body.process_mode = Node.PROCESS_MODE_DISABLED
	var feet := []
	var spans := []
	for leg in body.legs:
		feet.append(snappedf(leg.foot.y, 0.001))
		spans.append(snappedf(leg.global_position.distance_to(leg.foot), 0.001))
	var miss := misses(body)
	return {"body_height_m": snappedf(body.global_position.y, 0.001), "feet_height_m": feet,
		"hip_to_foot_m": spans, "leg_end_to_foot_m": miss, "worst_miss_m": miss.max(), "sharpest_bend_deg": bend(body)}

## The sharpest bend between two parts that follow each other, over the four legs, in degrees. One part: no bend.
func bend(body: Node3D) -> float:
	var sharpest := 0.0
	for leg in body.legs:
		for i in range(1, leg.chain.size()):
			var a: Vector3 = -leg.chain[i - 1].global_basis.z
			var b: Vector3 = -leg.chain[i].global_basis.z
			sharpest = maxf(sharpest, rad_to_deg(a.angle_to(b)))
	return snappedf(sharpest, 0.1)

## The comparison sheet: every value from two standpoints, every pair measured.
func sheet() -> void:
	var names := []
	for value: int in VALUES:
		names.append("%d part%s" % [value, "" if value == 1 else "s"])
	var tiles: Array[Image] = []
	var rows := {"level": [[], []], "above": [[], []], "level_flat": [[], []], "level_walked": [[], []]}
	var standing := {}
	for value: int in VALUES:
		var group := Node3D.new()
		group.add_child(ground())
		var body := creature(value, SPOT + Vector3(0, 0.6, 0))
		group.add_child(body)
		await stand(group, false)
		standing[names[VALUES.find(value)]] = await settle(body)
		for view: String in ["level", "above"]:
			_eye(view, body.global_position + Vector3(0, -0.2, 0))
			var taken: Array = await portrait(body, "parts_%d_%s" % [value, view])
			rows[view][0].append(taken[0])
			rows[view][1].append(taken[1])
			print("%s, %s: the creature covers %.2f%% of the still; worst miss %.3f m" % [names[VALUES.find(value)], view, share(taken[1]), standing[names[VALUES.find(value)]]["worst_miss_m"]])
	# The same four on the flat floor, from the side: is the order the ground's doing?
	var flat := {}
	for value: int in VALUES:
		var body := creature(value, Vector3(0, 0.4, 0))
		await stand(body, false)
		flat[names[VALUES.find(value)]] = await settle(body)
		_eye("level", body.global_position + Vector3(0, -0.2, 0))
		var taken: Array = await portrait(body, "parts_%d_level_flat" % value)
		rows["level_flat"][0].append(taken[0])
		rows["level_flat"][1].append(taken[1])
	# And on the uneven ground again, at the same place, reached by walking 1.2 m: a pose with another history.
	var walked := {}
	for value: int in VALUES:
		var group := Node3D.new()
		group.add_child(ground())
		var body := creature(value, SPOT + Vector3(-1.2, 0.6, 0))
		body.heading = Vector3.RIGHT
		group.add_child(body)
		await stand(group, false)
		for i in 200:
			await physics_frame
		body.heading = Vector3.ZERO
		walked[names[VALUES.find(value)]] = await settle(body)
		walked[names[VALUES.find(value)]]["body_at_x_m"] = snappedf(body.global_position.x, 0.001)
		_eye("level", body.global_position + Vector3(0, -0.2, 0))
		var taken: Array = await portrait(body, "parts_%d_level_walked" % value)
		rows["level_walked"][0].append(taken[0])
		rows["level_walked"][1].append(taken[1])
	report["axis"] = "segments: parts in each leg, the leg 0.8 m long every time"
	report["values"] = VALUES
	report["standing_on_the_uneven_ground"] = standing
	report["standing_on_the_flat_floor"] = flat
	report["standing_after_a_walk_of_1_2_m"] = walked
	for view: String in rows:
		print("--- ", view)
		report["pairs_" + view] = compare_all(names, rows[view][0], rows[view][1])
	for view: String in ["level", "level_walked", "above"]:      # the three rows of the sheet
		for still: Image in rows[view][0]:
			tiles.append(small(still))
	report["sheet_rows"] = ["from the side, standing from rest", "from the side, standing after a walk of 1.2 m", "from straight above, standing from rest"]
	report["sheet_png"] = await compose(tiles, VALUES.size(), names, "res://sheet.png")

## The process strip: one still after each step of the making, from one standpoint.
func process_strip() -> void:
	var names := ["1 a chain laid down the hip", "2 one part follows the hand", "3 the loop: all follow", "4 the hip holds",
		"5 four legs, rays as they came", "6 the rays look down", "7 the body follows its feet"]
	var tiles: Array[Image] = []
	var from := Vector3(0.35, 1.05, 2.5)
	var at := Vector3(0.3, 0.4, 0.0)
	# 1 to 4: one leg on a post, and a hand that carries its foot
	var group := Node3D.new()
	var post := MeshInstance3D.new()
	var rod := CylinderMesh.new()
	rod.top_radius = 0.03
	rod.bottom_radius = 0.03
	rod.height = 0.9
	post.mesh = rod
	post.material_override = Look.ghost()
	post.position.y = 0.45
	group.add_child(post)
	var leg: Node3D = load("res://leg.tscn").instantiate()
	leg.position = Vector3(0, 0.9, 0)
	group.add_child(leg)
	var hand := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.07
	ball.height = 0.14
	hand.mesh = ball
	hand.material_override = Look.paint(Look.BONE)
	hand.position = Vector3(0, 0.1, 0)
	group.add_child(hand)
	await stand(group, false)
	look_from(from, at)
	leg.get_node("Mark").visible = false
	tiles.append(small(await shot("strip_1")))
	var path := []                       # the hand's way: towards us and a little left, then across to the right
	for i in range(1, 41):
		path.append(Vector3(0, 0.1, 0).lerp(Vector3(-0.3, 0.3, 0.5), i / 40.0))
	for i in range(1, 41):
		path.append(Vector3(-0.3, 0.3, 0.5).lerp(Vector3(0.45, 0.4, 0.25), i / 40.0))
	var last: Node3D = leg.chain[-1]
	for point: Vector3 in path:          # step 2, as the lesson's first follow() does it: the last part alone
		last.look_at(point, leg.global_basis.z)
		last.global_position = point + last.global_basis.z * leg.length
	hand.position = path[-1]
	tiles.append(small(await shot("strip_2")))
	_lay(leg)
	for point: Vector3 in path:          # step 3: the whole loop, and nothing carries the chain back
		_loose(leg, point)
	var away: Vector3 = leg.led - leg.global_position
	tiles.append(small(await shot("strip_3")))
	_lay(leg)
	for point: Vector3 in path:          # step 4: the loop, and the hip holds
		leg.follow(point)
	tiles.append(small(await shot("strip_4")))
	var single := {"hip_led_away_m": snappedf(away.length(), 0.001), "leg_end_to_hand_m": snappedf(leg.tip().distance_to(path[-1]), 0.001)}
	# 5: four legs under a body on the borrowed ground, every ray left pointing along its hip's own down
	group = Node3D.new()
	group.add_child(ground())
	var body := creature(3, Vector3(-3.0, 0.4, 0))
	body.beat = 1000000.0                # no foot's turn comes: we give the targets ourselves
	group.add_child(body)
	await stand(group, false)
	look_from(from, at)
	for one in body.legs:                # what the unrepaired find_ground() did: no hit, and the point it read was (0, 0, 0)
		var start: Vector3 = one.to_global(Vector3(0, -one.reach, 0))
		one.target = Vector3.ZERO
		one.get_node("Beam").show_between(start, one.to_global(Vector3(0, -one.reach - 1.0, 0)))
	for i in 240:
		await physics_frame
		for one in body.legs:
			var start: Vector3 = one.to_global(Vector3(0, -one.reach, 0))
			one.get_node("Beam").show_between(start, one.to_global(Vector3(0, -one.reach - 1.0, 0)))
	var knot := {"body_at": [snappedf(body.global_position.x, 0.01), snappedf(body.global_position.y, 0.01), snappedf(body.global_position.z, 0.01)]}
	tiles.append(small(await shot("strip_5")))
	# 6: the rays look down in the room's own axes
	body.beat = 0.2
	for i in 240:
		await physics_frame
	var stood := {"body_height_m": snappedf(body.global_position.y, 0.001), "worst_miss_m": misses(body).max()}
	tiles.append(small(await shot("strip_6")))
	# 7: the feet reach ahead, and the body follows
	body.heading = Vector3.RIGHT
	var before: float = body.global_position.x
	for i in 90:
		await physics_frame
	body.process_mode = Node.PROCESS_MODE_DISABLED
	tiles.append(small(await shot("strip_7")))
	report["strip"] = await strip(tiles, names)
	report["strip"]["one_leg"] = single
	report["strip"]["rays_as_they_came"] = knot
	report["strip"]["rays_look_down"] = stood
	report["strip"]["walked_m_in_1_5_s"] = snappedf(body.global_position.x - before, 0.01)

## The eye of the sheet: from the side and 0.5 m above the middle, or from straight above; no shadows.
func _eye(view: String, middle: Vector3) -> void:
	if view == "above":
		look("above", 2.2, middle)
	else:
		look_from(middle + Vector3(0, 0.5, 2.2), middle)
		shadows(false)

## The loop of follow() without its last two lines: the chain is not carried back to the hip.
func _loose(leg: Node3D, to: Vector3) -> void:
	var aim := to
	for i in range(leg.chain.size() - 1, -1, -1):
		var part: Node3D = leg.chain[i]
		part.look_at(aim, leg.global_basis.z)
		part.global_position = aim + part.global_basis.z * leg.length
		aim = part.global_position
	leg.led = aim

## The chain back as _ready() laid it: along the hip's own down.
func _lay(leg: Node3D) -> void:
	for i in leg.chain.size():
		leg.chain[i].position = Vector3(0, -leg.length * i, 0)
		leg.chain[i].rotation = Vector3(-PI / 2.0, 0, 0)
