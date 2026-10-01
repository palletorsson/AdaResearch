extends "res://supplied/sheet_tools.gd"
## The Combine kit's sheet. It needs a window, so run it WITHOUT --headless,
## from this folder:
##   godot --path . --xr-mode off --script res://sheet.gd
## It writes
##   sheet.png    the argument: the four orders of the same operands and verbs,
##                each baked body alone in the studio, from the front (along the
##                tunnel), from the front right and from straight above
##   process.png  the strip: one still after each operation, from one standpoint
##   sheet.json   every pair of orders from every standpoint, the closest and
##                the farthest, by share of the still and by share of what the
##                two bodies cover; the triangles and the volume of each order; the
##                picture before and after baking; the first two orders with B
##                moved clear of the tunnel; how much each strip step changed
## and the stills, in stills/.

const Member := preload("res://borrowed/member.gd")
const Tunnel := preload("res://borrowed/tunnel.gd")
const Scan := preload("res://borrowed/scan.gd")
const Combine := preload("res://combine.gd")

const UNION := CSGShape3D.OPERATION_UNION
const MINUS := CSGShape3D.OPERATION_SUBTRACTION
const INTERSECT := CSGShape3D.OPERATION_INTERSECTION
const MIDDLE := Vector3(0.0, 1.4, 0.0)                 # the middle of the body: what every eye looks at
const VIEWS := ["front", "front right", "above"]
const QUARTER := Vector3(2.5, 2.2, 3.9)                # the eye of the front right view
const STRIP_EYE := Vector3(3.2, 2.6, 5.0)              # the eye of the strip: further off, the members are taller than the body
const STRIP_AT := Vector3(0.0, 1.6, 0.0)

func run() -> void:
	await sheet()
	await before_and_after_baking()
	await b_clear_of_the_tunnel()
	await process_strip()
	await stand(null)

## The learner's script on a node of its own: the body in one order.
func carved(order: int, baked := true, b_x := 0.2) -> Node3D:
	var node := Node3D.new()
	node.set_script(Combine)
	node.order = order
	node.baked = baked
	node.b_x = b_x
	return node

## The eye at one of the three standpoints; the body casts no shadow.
func eye_at(view: String) -> void:
	if view == "front":
		look("level", 4.8, MIDDLE)
	elif view == "above":
		look("above", 4.4, MIDDLE)
	else:
		look_from(QUARTER, MIDDLE)
		shadows(false)

func volume(mesh: Mesh) -> float:
	var corners := mesh.get_faces()
	var sum := 0.0
	for i in range(0, corners.size(), 3):
		sum += corners[i].dot(corners[i + 1].cross(corners[i + 2])) / 6.0
	return -sum     # Godot winds a triangle clockwise seen from outside

## The comparison sheet: every order from every standpoint, every pair measured.
func sheet() -> void:
	var names: Array = Combine.ORDERS
	var tiles: Array[Image] = []
	var bodies := []
	for view: String in VIEWS:
		var stills := []
		var pixels := []
		for order in names.size():
			var body := carved(order)
			await stand(body)
			eye_at(view)
			var taken: Array = await portrait(body, "order_%d_%s" % [order, view.replace(" ", "_")])
			stills.append(taken[0])
			pixels.append(taken[1])
			tiles.append(small(taken[0]))
			print("%s, %s: the body covers %.2f%% of the still" % [view, names[order], share(taken[1])])
			if view == VIEWS[0]:
				bodies.append({"order": body.verbs(), "triangles_listed": body.listed, "triangles": body.built, "volume_m3": snappedf(volume(body.body.mesh), 0.001), "covers_pct_front": share(taken[1])})
		var pairs := compare_all(names, stills, pixels)
		report["pairs_" + view.replace(" ", "_")] = pairs
		report["of_either_" + view.replace(" ", "_")] = of_either(names, pixels, pairs["pairs"])
	report["orders"] = bodies
	report["sheet_png"] = await compose(tiles, names.size(), names, "res://sheet.png")

## Every pair again, counted against the pixels that either body covers and not
## against the whole still: two small bodies in a wide still differ on little of
## the still whatever they are. Returns {"pairs": {"a vs b": {either_pct,
## differ_of_either_pct}}, "closest": "a vs b"}.
func of_either(names: Array, pixels: Array, measured: Dictionary) -> Dictionary:
	var pairs := {}
	var closest := ""
	for i in names.size():
		for j in range(i + 1, names.size()):
			var key := "%s vs %s" % [names[i], names[j]]
			var a: PackedByteArray = pixels[i]
			var b: PackedByteArray = pixels[j]
			var either := 0
			for k in a.size():
				if a[k] == 1 or b[k] == 1:
					either += 1
			var either_pct := 100.0 * either / float(a.size())
			var on_the_bodies: float = measured[key]["outline_pct"] + measured[key]["inside_pct"]
			pairs[key] = {"either_pct": snappedf(either_pct, 0.01), "differ_of_either_pct": snappedf(100.0 * on_the_bodies / either_pct, 0.1)}
			if closest == "" or pairs[key]["differ_of_either_pct"] < pairs[closest]["differ_of_either_pct"]:
				closest = key
			print("%s differ on %5.1f%% of the %5.2f%% of the still that either covers" % [key, pairs[key]["differ_of_either_pct"], pairs[key]["either_pct"]])
	return {"pairs": pairs, "closest": closest}

## Is the baked mesh the picture the combiner drew?
func before_and_after_baking() -> void:
	var stills := []
	for baked: bool in [false, true]:
		await stand(carved(0, baked))
		eye_at("front right")
		stills.append(await shot("baked_%s" % baked))
	report["not_baked_vs_baked_differ_pct"] = differ_pct(stills[0], stills[1])
	print("the combiner's picture and the baked mesh differ on %.2f%% of the still" % report["not_baked_vs_baked_differ_pct"])

## The outline's condition: with B clear of the tunnel the first two orders are one body.
func b_clear_of_the_tunnel() -> void:
	var record := {"b_x": 0.95}
	for view: String in ["front", "front right"]:
		var stills := []
		for order in 2:
			await stand(carved(order, true, 0.95))
			eye_at(view)
			stills.append(await shot("b_clear_%d_%s" % [order, view.replace(" ", "_")]))
		record["first_two_orders_differ_pct_" + view.replace(" ", "_")] = differ_pct(stills[0], stills[1])
		print("B at x 0.95, %s: the first two orders differ on %.2f%% of the still" % [view, differ_pct(stills[0], stills[1])])
	report["b_clear_of_the_tunnel"] = record

## One operand, placed and painted as combine.gd places and paints it.
func operand(mesh: Mesh, verb: int, color: Color, at := Vector3.ZERO) -> CSGMesh3D:
	var shape := CSGMesh3D.new()
	shape.mesh = mesh
	shape.material = Look.paint(color)
	shape.operation = verb
	shape.position = at
	return shape

## The first `count` operands of the lesson's body in a combiner; `closed` is the scan's foot.
func stage(count: int, closed := true) -> CSGCombiner3D:
	var a := operand(Member.make(16), UNION, Look.BODY, Vector3(-0.22, 1.2, 0.0))
	a.scale = Vector3(0.96, 4.2, 1.5)
	var b := operand(Member.make(4), UNION, Look.SECOND, Vector3(0.2, 1.2, 0.0))
	b.scale = Vector3(1.633, 4.2, 1.633)
	b.rotation.y = PI / 4.0
	var c := operand(Tunnel.make(24), MINUS, Look.THIRD, Vector3(0.0, 0.3, 0.0))
	var s := operand(Scan.make(closed), INTERSECT, Look.BONE)
	var all := [a, b, c, s]
	var carver := CSGCombiner3D.new()
	for i in all.size():
		if i < count:
			carver.add_child(all[i])
		else:
			all[i].free()
	return carver

func triangles(mesh: Mesh) -> int:
	if mesh == null:
		return 0
	@warning_ignore("integer_division")
	return mesh.get_faces().size() / 3

## The process strip: one still after each operation, from one standpoint.
func process_strip() -> void:
	var names := ["1 member A", "2 union: member B", "3 minus: the tunnel", "4 intersect a shell: nothing", "5 intersect: the foot closed", "6 a walker: through the floor", "7 baked: it stands"]
	var tiles: Array[Image] = []
	var counts := []
	for step in 5:
		var carver := stage([1, 2, 3, 4, 4][step], step != 3)
		await stand(carver)
		look_from(STRIP_EYE, STRIP_AT)
		tiles.append(small(await shot("strip_%d" % (step + 1))))
		counts.append(triangles(carver.bake_static_mesh()))
	var feet := []
	for baked: bool in [false, true]:
		var group := Node3D.new()
		group.add_child(carved(0, baked))
		await stand(group, false)      # not held: the walker has to fall, or to stand
		look_from(STRIP_EYE, STRIP_AT)
		var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
		walker.position = Vector3(0.0, 0.3, 0.45)    # on the floor of the hollow, a step inside the door
		group.add_child(walker)
		for i in 60:
			await physics_frame
		tiles.append(small(await shot("strip_%d" % (6 + int(baked)))))
		feet.append(snappedf(walker.global_position.y, 0.01))
		counts.append(group.get_child(0).built)
	report["strip"] = await strip(tiles, names)
	report["strip"]["triangles"] = counts
	report["strip"]["walker_feet_m"] = feet
	print("strip: triangles %s; the walker's feet at %s m" % [counts, feet])
