extends Node3D
## A SIDE SLAB (Palle, 2026-11-09: "We can have an extra slab on the side but then I do not want that to be more than
## like ten meters out and then I want tangled support beams to the floor under. We can let the slab contract and
## expand, 10 meters per floor"). Placed on the building's edge, facing out: the slab runs `length` along the edge
## (local x) and `depth` out from it (local +z, at most 10 m), its top flush with the floor. Under it, tangled steel beams
## run from the slab's underside down to the edge of the floor below; they draw but do not collide, so the floor below
## keeps its edge walkable. A visitor on the slab belongs to this floor (void_floor_extension) and is inside the tower
## (void_exterior_walk). One placement per side per floor, so each floor's slab can grow or shrink on its own.
##   config: length (2..42 m), depth (1..10 m), rail (true), beams (count, default by area), seed, drop (the storey
##   below, default: the tower's own gap), colour, open (["-x"] / ["+x"]: an end that meets another slab, left without
##   its side rail - 2026-11-14, where the north slab meets the west slab reaching the north-west corner of Boolean_Verbs;
##   a rail there stood across the way from one to the other. The rails do not collide either way), feet ([min, max]:
##   the stretch of local x where the floor below has an edge to take a foot - a slab that runs past the end of the
##   building otherwise sets beams down in mid-air; a foot drawn outside is drawn again, 2026-11-14)
var length := 12.0
var depth := 6.0
var rail := true
var beams := -1
var seed_value := 7
var drop := -1.0
var colour := Color("d6d4cf")
var open_ends: Array = []
var feet_span := Vector2.ZERO
var parts: Node3D

func _ready() -> void:
	add_to_group("void_floor_extension")
	add_to_group("void_exterior_walk")
	var config := {}
	for key in ["length", "depth", "rail", "beams", "seed", "drop", "colour", "open", "feet"]:
		if has_meta("config_" + key): config[key] = get_meta("config_" + key)
	apply_grid_config(config)

func apply_grid_config(config: Dictionary) -> void:
	length = clampf(float(config.get("length", length)), 2.0, 42.0)
	depth = clampf(float(config.get("depth", depth)), 1.0, 10.0)
	rail = str(config.get("rail", rail)).to_lower() not in ["false", "0"]
	beams = int(config.get("beams", beams))
	seed_value = int(config.get("seed", seed_value))
	drop = float(config.get("drop", drop))
	if config.has("colour"): colour = Color(str(config.colour))
	if config.has("open"):
		open_ends = []
		for end in (config["open"] if config["open"] is Array else str(config["open"]).split(",", false)): open_ends.append(str(end).strip_edges())
	if config.has("feet") and config["feet"] is Array and (config["feet"] as Array).size() >= 2:
		feet_span = Vector2(float(config["feet"][0]), float(config["feet"][1]))
	_build()

func _storey_below() -> float:
	if drop > 0: return drop
	# the tower's own gap to the floor below this one
	var game := get_tree().get_first_node_in_group("void_game") if is_inside_tree() else null
	var node: Node = self
	while node != null and not node.has_meta("void_content_floor"): node = node.get_parent()
	if game != null and node != null and game.get("building") != null:
		var levels: Array = game.building.spec.levels
		var f := int(node.get_meta("void_content_floor"))
		if f + 1 < levels.size(): return float(levels[f]) - float(levels[f + 1])
	return 6.0

func _build() -> void:
	if is_instance_valid(parts): remove_child(parts); parts.queue_free()
	parts = Node3D.new(); parts.name = "SideSlab"; add_child(parts)
	var thick := .36
	# the slab, 5 cm into the building so no seam opens at the edge
	var slab := _box("Slab", Vector3(0, -thick * .5, depth * .5 - .025), Vector3(length, thick, depth + .05), colour, true)
	slab.set_meta("void_structural_slab", true)
	if rail:
		var steel := Color("5d6168")
		for side in [-1, 1]:
			if ("+x" if side > 0 else "-x") in open_ends: continue
			_box("SideRail", Vector3(side * length * .5, 1.0, depth * .5), Vector3(.05, .05, depth), steel, false)
		_box("OuterRail", Vector3(0, 1.0, depth), Vector3(length, .05, .05), steel, false)
		var x := -length * .5
		while x <= length * .5 + .01:
			_box("Post", Vector3(x, .5, depth), Vector3(.05, 1.0, .05), steel, false); x += 2.0
		for side in [-1, 1]:
			if ("+x" if side > 0 else "-x") in open_ends: continue
			var z := 2.0
			while z < depth:
				_box("Post", Vector3(side * length * .5, .5, z), Vector3(.05, 1.0, .05), steel, false); z += 2.0
	# tangled supports: each from a point on the slab's underside to a point on the edge of the floor below
	var rng := RandomNumberGenerator.new(); rng.seed = seed_value
	var gap := _storey_below()
	var n := beams if beams > 0 else clampi(int(length * depth / 5.0) + 4, 6, 60)
	var tops: Array[Vector3] = []
	var feet: Array[Vector3] = []
	for i in n:
		var top := Vector3(rng.randf_range(-length * .5 + .2, length * .5 - .2), -thick, rng.randf_range(depth * .25, depth - .15))
		var fx := clampf(top.x + rng.randf_range(-length * .45, length * .45), -length * .5 - 1.0, length * .5 + 1.0)
		if feet_span != Vector2.ZERO:
			var tries := 0
			while (fx < feet_span.x or fx > feet_span.y) and tries < 24:
				fx = clampf(top.x + rng.randf_range(-length * .45, length * .45), -length * .5 - 1.0, length * .5 + 1.0); tries += 1
			fx = clampf(fx, feet_span.x, feet_span.y)
		var foot := Vector3(fx, -gap, rng.randf_range(-.6, .05))
		tops.append(top); feet.append(foot)
	var steel_dark := Color("474b51")
	for i in n: _rod("Beam", tops[i], feet[i], .055, steel_dark)
	# cross ties between neighbouring beams at mixed heights: the tangle
	for i in n:
		var j := (i + 1 + rng.randi_range(0, 2)) % n
		var a := tops[i].lerp(feet[i], rng.randf_range(.2, .7))
		var b := tops[j].lerp(feet[j], rng.randf_range(.2, .7))
		_rod("Tie", a, b, .035, steel_dark)

func _box(id: String, at: Vector3, size: Vector3, c: Color, solid: bool) -> Node3D:
	var mesh := MeshInstance3D.new(); var shape := BoxMesh.new(); shape.size = size; mesh.mesh = shape
	var mat := StandardMaterial3D.new(); mat.albedo_color = c; mat.roughness = .85; mesh.material_override = mat
	if not solid:
		mesh.name = id; mesh.position = at; parts.add_child(mesh); return mesh
	var body := StaticBody3D.new(); body.name = id; body.position = at; parts.add_child(body); body.add_child(mesh)
	var col := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = size; col.shape = box; body.add_child(col)
	return body

func _rod(id: String, a: Vector3, b: Vector3, radius: float, c: Color) -> void:
	var mesh := MeshInstance3D.new(); mesh.name = "%s_%d" % [id, parts.get_child_count()]
	var cyl := CylinderMesh.new(); cyl.top_radius = radius; cyl.bottom_radius = radius; cyl.height = a.distance_to(b); cyl.radial_segments = 6; cyl.rings = 1
	mesh.mesh = cyl
	var mat := StandardMaterial3D.new(); mat.albedo_color = c; mat.roughness = .6; mat.metallic = .4; mesh.material_override = mat
	var up := (b - a).normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < .95 else Vector3.RIGHT).normalized()
	mesh.transform = Transform3D(Basis(side, up, side.cross(up)).orthonormalized(), (a + b) * .5)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parts.add_child(mesh)

func contains_visitor(at: Vector3) -> bool:
	var p := to_local(at)
	return absf(p.x) <= length * .5 and p.z >= 0.0 and p.z <= depth and p.y >= -.6 and p.y < 5.0
