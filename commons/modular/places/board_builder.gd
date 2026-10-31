extends RefCounted
## THE BOARD, a word in the playground's vocabulary (Palle, 2026-10-31: "the playground structure must have a new
## vocabulary to take the configuration of rectangular boards - vertical, horizontal or rotated, repeatedly
## parameterised - to fit as pieces in the playground structure"). A board is a rectangular display plate, whole
## metres, laid on the floor, stood as a wall or hung as a ceiling, in a FRAME of the kit's own bars with posts to
## the ground, and REPEATED: count, step, a quarter turn per copy. A row of floor boards is the path of screens; a
## grid of them the array; upright boards along a path the corridor; four round a floor board the court; boards
## overhead the canopy; small boards up a wall the rack. The kit bounds the words: bars run along the axes in whole
## metres, so a board is axis-aligned and turns in quarters - no tilt.
##
## Spec (place.json "boards"):
##   {"id","at":[x,y,z] (metres, whole; the board's centre on the floor, its base line on a wall, its height overhead),
##    "size":[w,h] (whole metres), "orient":"floor"|"wall"|"ceiling", "facing":"south"|"north"|"east"|"west" (walls),
##    "frame":true, "posts":true, "repeat":{"count":n,"step":[dx,dy,dz],"turn":0|90|180|270},
##    "content":{display_plate config}, "contents":[{...},...] (one per copy, cycling), "artifact":"display_plate"}
## Compiled (build) into recipe.activities (display plates, position + rotation + config) and, with `frame`, bars
## and posts through the builder's own `bar` - assemblies of canonical rods, contract-checked like everything else.
## The same compiler runs at a hall's load from a sidecar (activities.json beside the recipe), so an approved recipe
## stays byte for byte what it was.

const YAW := {"south": 0.0, "north": 180.0, "east": 90.0, "west": -90.0}
const PLATE_LIFT := 0.08   # the plate rests on its frame's rods (.15 thick): a hair above their crowns

static func validate(spec: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var boards: Variant = spec.get("boards", [])
	if not boards is Array:return PackedStringArray(["boards must be an array"])
	var ids := {}
	for b in boards:
		if not b is Dictionary:errors.append("Each board must be an object");continue
		var id := str(b.get("id", ""))
		if id.is_empty() or not id.is_valid_identifier():errors.append("Board id must be a stable identifier: " + id)
		if ids.has(id):errors.append("Duplicate board id: " + id)
		ids[id] = true
		for key in b.keys():
			if key not in ["id", "at", "size", "orient", "facing", "frame", "posts", "repeat", "turn", "content", "contents", "artifact"]:errors.append(id + ": unknown field " + str(key))
		var at: Variant = b.get("at", null)
		if not at is Array or at.size() != 3 or not at.all(func(n): return (n is int or n is float) and is_equal_approx(float(n), roundf(float(n)))):errors.append(id + ": at needs [x,y,z] in whole metres")
		var size: Variant = b.get("size", null)
		if not size is Array or size.size() != 2 or not size.all(func(n): return (n is int or n is float) and float(n) >= 1 and float(n) <= 12 and is_equal_approx(float(n), roundf(float(n)))):errors.append(id + ": size needs [w,h] in whole metres, 1 to 12")
		if str(b.get("orient", "floor")) not in ["floor", "wall", "ceiling"]:errors.append(id + ": orient must be floor, wall or ceiling")
		if b.has("facing") and str(b.facing) not in YAW:errors.append(id + ": facing must be south, north, east or west")
		if b.has("repeat"):
			var r: Variant = b.repeat
			if not r is Dictionary:errors.append(id + ": repeat must be an object")
			else:
				if int(r.get("count", 1)) < 1 or int(r.get("count", 1)) > 64:errors.append(id + ": repeat count 1 to 64")
				var st: Variant = r.get("step", [0, 0, 0])
				if not st is Array or st.size() != 3 or not st.all(func(n): return (n is int or n is float) and is_equal_approx(float(n), roundf(float(n)))):errors.append(id + ": repeat step needs [dx,dy,dz] in whole metres")
				if int(r.get("turn", 0)) % 90 != 0:errors.append(id + ": repeat turn in quarter turns")
		if b.has("contents") and not b.contents is Array:errors.append(id + ": contents must be an array")
		if str(b.get("orient", "floor")) == "ceiling" and at is Array and at.size() == 3 and float(at[1]) < 2:errors.append(id + ": a ceiling board hangs at 2 m or more")
	return errors

## Compile every board of a spec through the builder: activities, and frames of bars.
static func build_all(builder: Object, spec: Dictionary) -> void:
	for b in spec.get("boards", []):build(builder, b)

static func build(builder: Object, b: Dictionary) -> void:
	var id := str(b.id);var at := Vector3(float(b.at[0]), float(b.at[1]), float(b.at[2]))
	var w := float(b.size[0]);var h := float(b.size[1]);var orient := str(b.get("orient", "floor"))
	var repeat: Dictionary = b.get("repeat", {});var count := int(repeat.get("count", 1))
	var step := Vector3.ZERO
	if repeat.has("step"):step = Vector3(float(repeat.step[0]), float(repeat.step[1]), float(repeat.step[2]))
	var turn := int(repeat.get("turn", 0));var base_yaw := float(YAW.get(str(b.get("facing", "south")), 0.0))
	var frame := bool(b.get("frame", true));var posts := bool(b.get("posts", true))
	var contents: Array = b.get("contents", []);var artifact := str(b.get("artifact", "display_plate"))
	for i in count:
		var c := at + step * i;var yaw := fmod(base_yaw + float(turn * i), 360.0)
		var cfg: Dictionary = ((contents[i % contents.size()] if not contents.is_empty() else b.get("content", {})) as Dictionary).duplicate(true)
		cfg.merge({"slot_size": [w, h], "mount": "wall" if orient == "wall" else "floor", "stand": false})
		if not cfg.has("title"):cfg.title = "%s %02d" % [id, i + 1]
		var sw := w;var sh := h   # the board's extent along x and z, after the turn
		if orient != "wall" and int(yaw) % 180 != 0:sw = h;sh = w
		var cid := "%s_%02d" % [id, i + 1]
		if orient == "floor":
			builder.recipe.activities.append({"id": cid, "board": id, "artifact": artifact, "position": builder.arr(c + Vector3(0, PLATE_LIFT, 0)), "rotation": [0, yaw, 0], "config": cfg})
			if frame:_rect(builder, cid, c, sw, sh)
			if posts and c.y > 0:_posts(builder, cid, c, sw, sh, 0.0, c.y)
		elif orient == "ceiling":
			builder.recipe.activities.append({"id": cid, "board": id, "artifact": artifact, "position": builder.arr(c - Vector3(0, PLATE_LIFT, 0)), "rotation": [180, yaw, 0], "config": cfg})
			if frame:_rect(builder, cid, c, sw, sh)
			if posts:_posts(builder, cid, c, sw, sh, 0.0, c.y)
		else:
			# upright: w along the wall's axis, h up from the base line; the face toward `facing` turned by the copy's turn
			var along := Vector3.RIGHT if int(yaw) % 180 == 0 else Vector3.BACK
			builder.recipe.activities.append({"id": cid, "board": id, "artifact": artifact, "position": builder.arr(c), "rotation": [0, yaw, 0], "config": cfg})
			if frame:
				var a := c - along * (w / 2.0);var e := c + along * (w / 2.0)
				builder.bar(cid + "_sill", a, e);builder.bar(cid + "_head", a + Vector3.UP * h, e + Vector3.UP * h)
				builder.bar(cid + "_jamb_a", a, a + Vector3.UP * h);builder.bar(cid + "_jamb_b", e, e + Vector3.UP * h)
				if posts and c.y > 0:
					builder.bar(cid + "_post_a", Vector3(a.x, 0, a.z), a);builder.bar(cid + "_post_b", Vector3(e.x, 0, e.z), e)
		pass   # no hall label per board: the plates carry their own titles

## Four bars round a horizontal board's edges at its height.
static func _rect(builder: Object, cid: String, c: Vector3, sw: float, sh: float) -> void:
	var hx := sw / 2.0;var hz := sh / 2.0
	builder.bar(cid + "_edge_n", Vector3(c.x - hx, c.y, c.z - hz), Vector3(c.x + hx, c.y, c.z - hz))
	builder.bar(cid + "_edge_s", Vector3(c.x - hx, c.y, c.z + hz), Vector3(c.x + hx, c.y, c.z + hz))
	builder.bar(cid + "_edge_w", Vector3(c.x - hx, c.y, c.z - hz), Vector3(c.x - hx, c.y, c.z + hz))
	builder.bar(cid + "_edge_e", Vector3(c.x + hx, c.y, c.z - hz), Vector3(c.x + hx, c.y, c.z + hz))

## Four posts from `low` to `high` at a horizontal board's corners.
static func _posts(builder: Object, cid: String, c: Vector3, sw: float, sh: float, low: float, high: float) -> void:
	if high - low < 1.0:return
	var hx := sw / 2.0;var hz := sh / 2.0;var k := 0
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			builder.bar(cid + "_post_%d" % k, Vector3(c.x + sx * hx, low, c.z + sz * hz), Vector3(c.x + sx * hx, high, c.z + sz * hz));k += 1

## A hall's sidecar: activities.json beside its recipe - {activities: [...], boards: [...]} - compiled into the
## loaded recipe before the playground builds it, so the approved recipe file is never edited.
static func merge_sidecar(builder: Object, recipe: Dictionary, path: String) -> int:
	if not FileAccess.file_exists(path):return 0
	var side: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not side is Dictionary:push_warning("board_builder: sidecar is not an object: " + path);return 0
	if not recipe.has("activities"):recipe["activities"] = []
	var n := 0
	for a in side.get("activities", []):recipe.activities.append(a);n += 1
	var problems := validate(side)
	if not problems.is_empty():push_warning("board_builder: sidecar boards refused: " + str(problems));return n
	builder.recipe = recipe
	for b in side.get("boards", []):build(builder, b);n += 1
	return n
