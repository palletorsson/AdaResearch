extends Node3D
## A SMALL PLANET (floor NonEuclidean_Spaces; the pass, 2026-11-15)
##
## Palle, 2026-11-15: "can we make a non euclidean biome so we walk on a smaller curved sphere like 10 meter that
## is endless?" A world ten metres across with a biome on it, no edge and no end - a BIOME form, and a playground.
##
## A door stands on the floor. Go through it and you stand on the planet, under its own sky. Walk: there is always
## more ground ahead. Walk straight for 31.4 m and the door you came by rises over the horizon in front of you -
## you did not turn. The beetles walk straight too, each on its own line round the world, and every two of their
## lines cross twice: there are no parallels here. Go out a quarter of the way round, turn left, a quarter, turn
## left, a quarter: you are at the door after three right angles, and the door has turned by a quarter.
##
## How, and the board says so: the planet hangs 160 m north of the tower, a small ball you can see from the floor.
## The door moves the body there, as the wing's door moves it to its chambers (headset: the player body's
## teleport(pose) - NOT tried in a headset). On the planet the body is never moved again. The ground under its
## feet is flat and still; the planet, everything growing on it and its sky are turned under the body by exactly
## its steps, and follow it. From where the body stands that is walking round a world.
##
## `across` is the axis: six, ten, twenty metres. Without a tower round it (a bench, a capture) the planet stands
## just behind its door so that it can be looked at.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const RADIUS := {"six": 3.0, "ten": 5.0, "twenty": 10.0}
const FAR := Vector3(0, 0, -160.0)
const DOOR_W := 1.7
const DOOR_H := 2.4
const SKY := 60.0
const MOSS := Color("7c9a62")
const PINK := Color("ff5fa8")
const DARK := Color("191e29")
const PALE := Color("efe9dc")

@export_enum("six", "ten", "twenty") var across := "ten"

var _city = City.new()
var _door: Node3D                        # the door on the floor
var _rig: Node3D                         # follows the body; its origin is the planet's top
var _planet: Node3D                      # turns under the body; its origin is the planet's middle
var _planet_door: Node3D
var _sky: Node3D
var _ground: StaticBody3D
var _board: Label3D
var _lintel: Label3D
var _beetles := []
var _on := false
var _last := Vector3.ZERO
var _side := 0.0                         # which side of a door plane the body was on
var _side_known := false
var _cool := 0.0
var _walked := 0.0
var _last_visit := ""
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_across"): _take({"across": get_meta("config_across")})
	add_to_group("void_floor_extension")
	add_to_group("void_exterior_walk")
	var began := Time.get_ticks_msec()
	_build_door()
	_build_planet()
	_build_ms = Time.get_ticks_msec() - began
	_tell()


func _take(config_data: Dictionary) -> void:
	if config_data.has("across") and RADIUS.has(str(config_data["across"])): across = str(config_data["across"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := across
	_take(config_data)
	if is_inside_tree() and _board != null and across != before and not _on:
		_build_planet()
		_tell()


func radius() -> float:
	return float(RADIUS[across])


func _game() -> Node:
	return get_tree().get_first_node_in_group("void_game")


func _visitor() -> Node3D:
	var game := _game()
	return game.get("body") as Node3D if game != null else null


## Where the planet's top is when nobody is on it: far north of the tower, or just behind the door on a bench.
func _home() -> Vector3:
	if _game() != null: return to_global(FAR)
	return to_global(Vector3(0, radius() * 2.0, -radius() - 2.6))


## The tower keeps this floor awake while its visitor is out on the planet.
func contains_visitor(at: Vector3) -> bool:
	return _rig != null and (at - _rig.global_position).length() < SKY + 20.0


## ---- the rule ----

## The planet turned under a step: the ground at the top goes backward by the step's length.
static func rolled(turn: Basis, step: Vector3, r: float) -> Basis:
	var flat := Vector3(step.x, 0, step.z)
	var far: float = flat.length()
	if far < 1e-7: return turn
	return (Basis(flat.normalized().cross(Vector3.UP), far / r) * turn).orthonormalized()


func _shift(body: Node3D, to: Transform3D) -> void:
	var game := _game()
	if game != null and bool(game.get("vr")) and body.has_method("teleport"):
		body.call("teleport", to)
	else:
		body.global_transform = to
	if game != null and game.has_method("rebase_player_motion"): game.call("rebase_player_motion")


## Upright: a transform's place with only its turn about the vertical kept.
static func upright(t: Transform3D) -> Transform3D:
	var ahead := Vector3(t.basis.z.x, 0, t.basis.z.z)
	if ahead.length() < 1e-5: ahead = Vector3(0, 0, 1)
	return Transform3D(Basis(Vector3.UP, atan2(ahead.x, ahead.z)), t.origin)


func _enter(body: Node3D) -> void:
	# onto the planet: the door on the floor and the door on the planet are the same door
	_rig.global_transform = Transform3D(upright(_door.global_transform).basis, _home())
	_planet.basis = Basis.IDENTITY
	var there: Transform3D = _rig.global_transform * (upright(_door.global_transform).affine_inverse() * body.global_transform)
	_shift(body, there)
	_on = true
	_last = _rig.global_position
	_walked = 0.0
	_cool = 0.5
	_side_known = false
	_sky.visible = true
	_tell()


func _leave(body: Node3D) -> void:
	var back: Transform3D = upright(_door.global_transform) * (upright(_planet_door.global_transform).affine_inverse() * body.global_transform)
	back.origin.y = _door.global_position.y + (body.global_position.y - _rig.global_position.y)
	_shift(body, upright(back) if not (_game() != null and bool(_game().get("vr"))) else back)
	_on = false
	_last_visit = "Last visit: %.0f m walked on a world %.1f m round." % [_walked, TAU * radius()]
	_rig.global_transform = Transform3D(upright(_door.global_transform).basis, _home())
	_planet.basis = Basis.IDENTITY
	_sky.visible = false
	_cool = 0.5
	_side_known = false
	_tell()


func _crossed(frame: Node3D, at: Vector3) -> bool:
	var local: Vector3 = frame.to_local(at)
	var inside: bool = absf(local.x) < DOOR_W * 0.5 - 0.05 and local.y > -0.7 and local.y < DOOR_H + 0.4 and absf(local.z) < 0.7
	var crossed: bool = inside and _side_known and _cool <= 0.0 and signf(local.z) != signf(_side) and absf(_side) < 0.7
	_side = local.z
	_side_known = true
	return crossed


func _physics_process(delta: float) -> void:
	for beetle in _beetles:
		beetle["angle"] = float(beetle["angle"]) + float(beetle["speed"]) * delta
		_stand(beetle["node"], (beetle["u"] as Vector3) * cos(float(beetle["angle"])) + (beetle["v"] as Vector3) * sin(float(beetle["angle"])),
			-(beetle["u"] as Vector3) * sin(float(beetle["angle"])) + (beetle["v"] as Vector3) * cos(float(beetle["angle"])))
	var body := _visitor()
	if body == null: return
	_cool = maxf(0.0, _cool - delta)
	var at: Vector3 = body.global_position
	if not _on:
		if _crossed(_door, at): _enter(body)
		return
	var step := Vector3(at.x - _last.x, 0, at.z - _last.z)
	if step.length() > 0.0004:
		_planet.basis = rolled(_planet.basis, _rig.global_basis.inverse() * step, radius())
		_walked += step.length()
		_last = at
	_rig.global_position = Vector3(at.x, _rig.global_position.y, at.z)
	if Vector2(at.x - _ground.global_position.x, at.z - _ground.global_position.z).length() > 80.0:
		_ground.global_position = Vector3(at.x, _ground.global_position.y, at.z)
	_lintel.text = "%.0f m walked\nstraight on: %.1f m to here" % [_walked, TAU * radius()]
	if _crossed(_planet_door, at) or at.y < _rig.global_position.y - 4.0: _leave(body)


func _tell() -> void:
	if _board == null: return
	var r: float = radius()
	var lines := PackedStringArray(["A SMALL PLANET"])
	lines.append("A world %.0f metres across, with no edge and no end. Go through the door: you stand on it, under its own sky. Walk straight ahead for %.1f m and this door comes up over the horizon in front of you. You did not turn." % [r * 2.0, TAU * r])
	lines.append("Its beetles walk straight too, each on its own line round the world. Every two of those lines cross twice: there are no parallels here. Go a quarter of the way round (%.1f m), turn left, a quarter, left, a quarter: three right angles, and you are at the door - which has turned by a quarter." % (TAU * r * 0.25))
	lines.append("How: the little ball in the sky north of this floor is the planet. The door takes you there. Then the ground under your feet is flat and still, and the planet and its sky turn under you by exactly your steps.")
	if _last_visit != "": lines.append(_last_visit)
	_board.text = "\n".join(lines)


## ---- building ----

func _mesh(parent: Node3D, mesh: Mesh, at: Vector3, colour: Color, rough: float = 0.8) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _city.flat(colour, rough)
	node.position = at
	parent.add_child(node)
	return node


func _frame(parent: Node3D, solid: bool) -> void:
	var post := BoxMesh.new()
	post.size = Vector3(0.18, DOOR_H + 0.2, 0.22)
	var body: StaticBody3D = null
	if solid:
		body = StaticBody3D.new()
		parent.add_child(body)
	for hand in [-1.0, 1.0]:
		_mesh(parent, post, Vector3(hand * (DOOR_W * 0.5 + 0.09), (DOOR_H + 0.2) * 0.5, 0), DARK)
		if body != null: _city.wall(body, Vector3(hand * (DOOR_W * 0.5 + 0.09), 0, 0), post.size)
	var top := BoxMesh.new()
	top.size = Vector3(DOOR_W + 0.36, 0.2, 0.22)
	_mesh(parent, top, Vector3(0, DOOR_H + 0.3, 0), PINK, 0.5)


func _build_door() -> void:
	_door = Node3D.new()
	_door.name = "Door"
	add_child(_door)
	_frame(_door, true)
	var plate := BoxMesh.new()
	plate.size = Vector3(DOOR_W + 0.9, 0.5, 0.1)
	_mesh(_door, plate, Vector3(0, DOOR_H + 0.72, -0.02), DARK)
	for face in [1.0, -1.0]:
		var words := Label3D.new()
		words.text = "A SMALL PLANET\nthrough the door"
		words.font_size = 44
		words.pixel_size = 0.0035
		words.modulate = PALE
		words.outline_size = 0
		words.double_sided = false
		words.position = Vector3(0, DOOR_H + 0.72, -0.02 + face * 0.056)
		words.rotation.y = 0.0 if face > 0.0 else PI
		_door.add_child(words)
	_board = _city.board(self, Vector3(DOOR_W * 0.5 + 2.1, 0, 0.9), 3.2, 1.5)


func _stand(node: Node3D, out: Vector3, ahead: Vector3) -> void:
	# planet-local: a thing standing at the direction `out` from the middle, looking along `ahead`
	var up := out.normalized()
	var z := (-ahead - up * (-ahead).dot(up)).normalized()
	node.transform = Transform3D(Basis(up.cross(z).normalized(), up, z), up * radius())


func _scatter(mesh: Mesh, count: int, rng: RandomNumberGenerator, colours: Array, clear: float, size: Vector2, lift: float = 0.0) -> MultiMeshInstance3D:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = count
	var r: float = radius()
	for i in count:
		var out := Vector3.UP
		for attempt in 12:
			out = Vector3(rng.randfn(), rng.randfn(), rng.randfn()).normalized()
			if out.angle_to(Vector3.UP) * r > clear: break
		var side := out.cross(Vector3(0.31, 0.77, 0.55)).normalized()
		var stood := Basis(side, out, side.cross(out)).rotated(out, rng.randf() * TAU)
		var big: float = rng.randf_range(size.x, size.y)
		multi.set_instance_transform(i, Transform3D(stood.scaled(Vector3(big, big, big)), out * (r + lift * big)))
		multi.set_instance_color(i, colours[rng.randi() % colours.size()])
	var node := MultiMeshInstance3D.new()
	node.multimesh = multi
	var paint := StandardMaterial3D.new()
	paint.vertex_color_use_as_albedo = true
	paint.roughness = 0.85
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = paint
	_planet.add_child(node)
	return node


func _build_planet() -> void:
	if _rig != null:
		remove_child(_rig)
		_rig.queue_free()
		remove_child(_ground)
		_ground.queue_free()
	_beetles.clear()
	var r: float = radius()
	var share: float = (r / 5.0) * (r / 5.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 188
	_rig = Node3D.new()
	_rig.name = "Rig"
	_rig.top_level = true
	add_child(_rig)
	_rig.global_transform = Transform3D(upright(_door.global_transform).basis, _home())
	_planet = Node3D.new()
	_planet.name = "Planet"
	_planet.position = Vector3(0, -r, 0)
	_rig.add_child(_planet)
	var ball := SphereMesh.new()
	ball.radius = r
	ball.height = r * 2.0
	ball.radial_segments = 96
	ball.rings = 48
	_mesh(_planet, ball, Vector3.ZERO, MOSS, 0.95).name = "Ground"
	# what grows
	var blade := PrismMesh.new()
	blade.size = Vector3(0.05, 0.26, 0.01)
	_scatter(blade, int(2400 * share), rng, [Color("5f8a4a"), Color("7fa85e"), Color("a4c178"), Color("4f7440")], 0.5, Vector2(0.6, 1.5), 0.13)
	var stem := CylinderMesh.new()
	stem.top_radius = 0.008
	stem.bottom_radius = 0.01
	stem.height = 0.34
	var flower_rng := RandomNumberGenerator.new()
	flower_rng.seed = 7
	_scatter(stem, int(320 * share), flower_rng, [Color("6f9a52")], 0.7, Vector2(1.0, 1.0), 0.17)
	flower_rng.seed = 7
	var head := SphereMesh.new()
	head.radius = 0.055
	head.height = 0.09
	_scatter(head, int(320 * share), flower_rng, [PINK, Color("ffd24a"), PALE, Color("c1121c"), Color("b8a1ec")], 0.7, Vector2(1.0, 1.0), 0.36)
	var stone := SphereMesh.new()
	stone.radius = 0.22
	stone.height = 0.2
	_scatter(stone, int(80 * share), rng, [Color("8c8a86"), Color("a9a59d"), Color("6d6c6a")], 1.4, Vector2(0.4, 1.6), 0.02)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.07
	trunk.bottom_radius = 0.12
	trunk.height = 1.7
	var tree_rng := RandomNumberGenerator.new()
	tree_rng.seed = 31
	_scatter(trunk, int(18 * share), tree_rng, [Color("6b4a32"), Color("7a5a3c")], 2.0, Vector2(1.0, 1.0), 0.85)
	tree_rng.seed = 31
	var crown := SphereMesh.new()
	crown.radius = 0.75
	crown.height = 1.3
	_scatter(crown, int(18 * share), tree_rng, [Color("3f6b3a"), Color("56824a"), Color("e58fb6")], 2.0, Vector2(1.0, 1.0), 2.1)
	var cap := SphereMesh.new()
	cap.radius = 0.11
	cap.height = 0.12
	_scatter(cap, int(50 * share), rng, [Color("c1121c"), Color("e8b04a"), PALE], 1.0, Vector2(0.6, 1.5), 0.12)
	# the beetles and the straight lines they walk
	var lanes := [[Vector3(1, 0.3, 0.2), Vector3(0, 0.4, 1), PINK], [Vector3(0.2, 1, 0.1), Vector3(1, -0.2, 0.6), Color("ffd24a")], [Vector3(0.5, 0.5, 1), Vector3(-1, 0.6, 0.2), Color("70cddd")],
		[Vector3(1, -0.8, 0.3), Vector3(0.3, 0.6, -1), PALE], [Vector3(0.1, 0.2, 1), Vector3(1, 1, -0.2), Color("b8a1ec")]]
	for i in lanes.size():
		var u: Vector3 = (lanes[i][0] as Vector3).normalized()
		var v: Vector3 = ((lanes[i][1] as Vector3) - u * (lanes[i][1] as Vector3).dot(u)).normalized()
		var lane := TorusMesh.new()
		lane.inner_radius = r + 0.002
		lane.outer_radius = r + 0.03
		lane.rings = 128
		lane.ring_segments = 6
		var ring: MeshInstance3D = _mesh(_planet, lane, Vector3.ZERO, lanes[i][2], 0.5)
		var axis: Vector3 = u.cross(v).normalized()
		var side: Vector3 = axis.cross(Vector3(0.3, 0.7, 0.6)).normalized()
		ring.basis = Basis(side, axis, side.cross(axis))
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var beetle := Node3D.new()
		_planet.add_child(beetle)
		var shell := SphereMesh.new()
		shell.radius = 0.16
		shell.height = 0.2
		var body_mesh: MeshInstance3D = _mesh(beetle, shell, Vector3(0, 0.1, 0), lanes[i][2], 0.3)
		body_mesh.scale = Vector3(0.8, 1.0, 1.3)
		var face := SphereMesh.new()
		face.radius = 0.07
		face.height = 0.14
		_mesh(beetle, face, Vector3(0, 0.1, -0.22), DARK, 0.4)
		_beetles.append({"node": beetle, "u": u, "v": v, "angle": float(i) * 1.3, "speed": 0.35 / r * (1.0 + 0.2 * float(i))})
	# the door on the planet, where the body arrives: the same door
	_planet_door = Node3D.new()
	_planet_door.name = "PlanetDoor"
	_planet_door.position = Vector3(0, r, 0)
	_planet.add_child(_planet_door)
	_frame(_planet_door, false)
	_lintel = Label3D.new()
	_lintel.font_size = 40
	_lintel.pixel_size = 0.003
	_lintel.modulate = PALE
	_lintel.outline_size = 8
	_lintel.outline_modulate = DARK
	_lintel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_lintel.position = Vector3(0, DOOR_H + 0.75, 0)
	_lintel.text = "the way back"
	_planet_door.add_child(_lintel)
	# its own sky: a shell with stars on it, turning with the planet
	_sky = Node3D.new()
	_sky.name = "Sky"
	_planet.add_child(_sky)
	var dome := SphereMesh.new()
	dome.radius = SKY
	dome.height = SKY * 2.0
	dome.radial_segments = 48
	dome.rings = 24
	var night := StandardMaterial3D.new()
	night.albedo_color = Color("2c2440")
	night.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	night.cull_mode = BaseMaterial3D.CULL_FRONT
	var dome_node := MeshInstance3D.new()
	dome_node.mesh = dome
	dome_node.material_override = night
	dome_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sky.add_child(dome_node)
	var star := SphereMesh.new()
	star.radius = 0.5
	star.height = 1.0
	star.radial_segments = 8
	star.rings = 4
	var stars := MultiMesh.new()
	stars.transform_format = MultiMesh.TRANSFORM_3D
	stars.use_colors = true
	stars.mesh = star
	stars.instance_count = 520
	var band := Vector3(0.4, 0.2, 1).normalized()
	for i in 520:
		var out := Vector3(rng.randfn(), rng.randfn(), rng.randfn()).normalized()
		if i % 3 == 0: out = (out - band * out.dot(band) * 0.85).normalized()      # a band of them, so that the sky is seen to turn
		var big: float = rng.randf_range(0.9, 2.4) * (3.0 if i % 61 == 0 else 1.0)       # half a metre to a metre across, 57 m away: seen
		stars.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3(big, big, big)), out * (SKY - 3.0)))
		stars.set_instance_color(i, [PALE, PINK, Color("ffd24a"), Color("70cddd")][rng.randi() % 4])
	var stars_node := MultiMeshInstance3D.new()
	stars_node.multimesh = stars
	var glow := StandardMaterial3D.new()
	glow.vertex_color_use_as_albedo = true
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	stars_node.material_override = glow
	stars_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sky.add_child(stars_node)
	_sky.visible = false
	# the ground the body stands on: flat, still, wide, and moved under the body when it has walked far
	_ground = StaticBody3D.new()
	_ground.name = "Support"
	_ground.top_level = true
	add_child(_ground)
	var flat := CollisionShape3D.new()
	var slab := BoxShape3D.new()
	slab.size = Vector3(240, 0.4, 240)
	flat.shape = slab
	flat.position = Vector3(0, -0.2, 0)
	_ground.add_child(flat)
	_ground.global_position = _home()
	if _game() == null: flat.disabled = true


func _exit_tree() -> void:
	_on = false


## ---- for a test ----

func state() -> Dictionary:
	var body := _visitor()
	var to_door: float = -1.0
	var door_below: float = 0.0
	if _on and body != null:
		to_door = Vector2(body.global_position.x - _planet_door.global_position.x, body.global_position.z - _planet_door.global_position.z).length()
		door_below = _rig.global_position.y - _planet_door.global_position.y
	return {"across": across, "radius": radius(), "round_m": snappedf(TAU * radius(), 0.01), "on_planet": _on, "walked_m": snappedf(_walked, 0.01), "door_away_m": snappedf(to_door, 0.01), "door_below_m": snappedf(door_below, 0.01),
		"planet_from_door_m": snappedf((_rig.global_position - _door.global_position).length(), 0.1), "door_turn_deg": snappedf(rad_to_deg(atan2(_planet_door.global_basis.z.x, _planet_door.global_basis.z.z) - atan2(_rig.global_basis.z.x, _rig.global_basis.z.z)), 0.1),
		"beetles": _beetles.size(), "sky": _sky.visible, "board": _board.text if _board != null else "", "build_ms": _build_ms}


## In front of the door on the floor: `by` metres on the side one comes from (negative: beyond it).
func door_point(by: float) -> Vector3:
	return _door.to_global(Vector3(0, 0, by))
