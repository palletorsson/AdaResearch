extends Node3D
## THE ROOF WHERE EVERYONE CLIMBS (floor Escher_Impossible; the pass, 2026-11-15)
##
## Palle, 2026-11-15, shown the cardboard stairwell: "make more escher like drawing wider staire more stange".
## The same stair that only goes up and comes back (commons/artifacts/endless_stair), taken out of its box: wide
## steps round a tower in the open, drawn like a print - no light, a tone for each way a face looks, engraved
## lines - with a pavilion on every corner, robed walkers trudging up along the tower and others down along the
## parapet, and small figures that walk on the tower's walls as if the walls were floors. A PLAYGROUND form; an
## original place in the manner of an impossible print, not a copy of one.
##
## A door stands on the floor. Go in: you stand in a pavilion on the roof. Keep the tower on your left and climb.
## Every flight goes up; after four you are at the door's pavilion again, and the walkers you passed are passing
## you. A tablet on the tower keeps count: metres climbed, metres above the door, metres taken back.
##
## How, and the board says so: the roof hangs 160 m south of the tower inside a sky of its own. What stands is one
## honest lap of four flights. The body lives on two of them; at the corner where it would step onto the third it
## is set down 1.2 m and turned half about onto the first. In the open that can only go unseen if everything in
## view is the same after a half turn about the tower and a drop of 1.2 m - so the tower repeats every 1.2 m and
## on all four sides, the tones have no light in them, the clouds come in opposite pairs, the pavilions climb
## with the stair, and every walker is placed from where the body stands. Headset: the player body's
## teleport(pose) - NOT tried in a headset.
##
## `walkers` is the axis: both (up and down), up, none.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const LITHO := preload("res://commons/artifacts/roof_stair/litho.gdshader")
const H := 1.6                          # the tower's half side: a flight's run is 2 H
const W := 2.2                          # the stair's width
const RISE := 0.6
const TREADS := 4
const PARAPET := 1.0
const POST := 2.2                       # a pavilion's roof: the height of the upper landing's underside, so that every corner looks alike
const SHELL := 50.0
const FAR := Vector3(0, 0, 160.0)
const DOOR_W := 1.5
const DOOR_H := 2.3
const KEPT := [0, 1, 0, 1]
const PAPER := Color("e9e2d5")
const INK := Color("191e29")

@export_enum("both", "up", "none") var walkers := "both"

var _city = City.new()
var _door: Node3D                        # on the floor
var _site: Node3D                        # the roof
var _roof_door: Node3D
var _plug: Node3D
var _plug_shape: CollisionShape3D
var _twin: Node3D
var _twin_wall: Node3D
var _sky: Node3D
var _faces: Array[Label3D] = []
var _notes: Array[Label3D] = []
var _pilgrims := []
var _wall_bodies: MultiMesh
var _wall_heads: MultiMesh
var _board: Label3D
var _stone: ShaderMaterial
var _on := false
var _side := 0
var _count := 0
var _halves := 0
var _taken := 0.0
var _door_y := 0.0
var _plane := 0.0
var _plane_known := false
var _cool := 0.0
var _clock := 0.0
var _last := ""
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_walkers"): _take({"walkers": get_meta("config_walkers")})
	add_to_group("void_floor_extension")
	add_to_group("void_exterior_walk")
	var began := Time.get_ticks_msec()
	_build_door()
	_build_roof()
	_build_ms = Time.get_ticks_msec() - began
	_letter()


func _take(config_data: Dictionary) -> void:
	if config_data.has("walkers") and str(config_data["walkers"]) in ["both", "up", "none"]: walkers = str(config_data["walkers"])


func apply_grid_config(config_data: Dictionary) -> void:
	_take(config_data)
	if is_inside_tree() and _board != null: _letter()


func _game() -> Node:
	return get_tree().get_first_node_in_group("void_game")


func _visitor() -> Node3D:
	var game := _game()
	return game.get("body") as Node3D if game != null else null


func _home() -> Vector3:
	return to_global(FAR) if _game() != null else to_global(Vector3(0, 0, -(H + W) - 4.5))


func contains_visitor(at: Vector3) -> bool:
	return _site != null and (at - _site.global_position).length() < SHELL + 10.0


## ---- the rule ----

static func base(side: int) -> float:
	return float(posmod(side + 1, 4)) * RISE


func label(offset: int = 0) -> int:
	return posmod(_count + offset, 4) + 1


static func side_at(x: float, z: float) -> int:
	if absf(x) > absf(z): return 1 if x > 0.0 else 3
	return 0 if z > 0.0 else 2


static func upright(t: Transform3D) -> Transform3D:
	var ahead := Vector3(t.basis.z.x, 0, t.basis.z.z)
	if ahead.length() < 1e-5: ahead = Vector3(0, 0, 1)
	return Transform3D(Basis(Vector3.UP, atan2(ahead.x, ahead.z)), t.origin)


func feet() -> float:
	var body := _visitor()
	return _site.to_local(body.global_position).y if body != null and _on else 0.0


func climbed() -> float:
	return feet() - _door_y + _taken if _on else 0.0


func _shift(body: Node3D, to: Transform3D) -> void:
	var game := _game()
	if game != null and bool(game.get("vr")) and body.has_method("teleport"): body.call("teleport", to)
	else:
		body.global_transform = to
		if "velocity" in body: body.set("velocity", Vector3.ZERO)
	if game != null and game.has_method("rebase_player_motion"): game.call("rebase_player_motion")


func _enter(body: Node3D) -> void:
	_shift(body, upright(_roof_door.global_transform) * (upright(_door.global_transform).affine_inverse() * upright(body.global_transform)))
	_on = true
	_side = 0
	_count = 0
	_taken = 0.0
	_door_y = _site.to_local(body.global_position).y
	_cool = 0.6
	_plane_known = false
	_sky.visible = _game() != null
	_letter()


func _leave(body: Node3D) -> void:
	_last = "Last climb: %.1f m up, and out %.1f m above the door." % [climbed(), feet() - _door_y]
	var back: Transform3D = upright(_door.global_transform) * (upright(_roof_door.global_transform).affine_inverse() * upright(body.global_transform))
	back.origin.y = _door.global_position.y + 0.05
	if absf(_door.to_local(back.origin).z) < 0.9: back.origin = _door.to_global(Vector3(_door.to_local(back.origin).x, 0.05, 1.0))
	_shift(body, back)
	_on = false
	_side = 0
	_count = 0
	_taken = 0.0
	_cool = 0.6
	_plane_known = false
	_sky.visible = false
	_letter()


func _turn_body(body: Node3D, quarters: int, lift: float) -> void:
	var theta: float = float(quarters) * PI * 0.5
	var pose: Transform3D = body.global_transform
	var middle: Vector3 = _site.global_position
	pose.origin = middle + (pose.origin - middle).rotated(Vector3.UP, theta) + Vector3(0, lift, 0)
	pose.basis = Basis(Vector3.UP, theta) * pose.basis
	var game := _game()
	if game != null and bool(game.get("vr")) and body.has_method("teleport"): body.call("teleport", pose)
	else:
		body.global_transform = pose
		if "velocity" in body: body.set("velocity", (body.get("velocity") as Vector3).rotated(Vector3.UP, theta))
	if game != null and game.has_method("rebase_player_motion"): game.call("rebase_player_motion")
	_halves += quarters / 2
	_taken -= lift


func _through(frame: Node3D, at: Vector3, from_front_only: bool) -> bool:
	var local: Vector3 = frame.to_local(at)
	var inside: bool = absf(local.x) < DOOR_W * 0.5 and local.y > -0.6 and local.y < DOOR_H + 0.4 and absf(local.z) < 0.8
	var crossed: bool = inside and _plane_known and _cool <= 0.0 and signf(local.z) != signf(_plane) and absf(_plane) < 0.8 and (not from_front_only or _plane > 0.0)
	_plane = local.z
	_plane_known = true
	return crossed


func _physics_process(delta: float) -> void:
	_clock += delta
	_walk_the_walkers()
	var body := _visitor()
	if body == null: return
	_cool = maxf(0.0, _cool - delta)
	var at: Vector3 = body.global_position
	if not _on:
		if _through(_door, at, true): _enter(body)
		return
	var p: Vector3 = _site.to_local(at)
	var out_by_the_door: bool = _through(_roof_door, at, false)
	if (out_by_the_door and label() <= 2 and p.z > H + W - 0.2) or p.y < -6.0:
		_leave(body)
		return
	var side: int = side_at(p.x, p.z)
	if side != _side and absf(absf(p.x) - absf(p.z)) >= 0.05:
		var step: int = posmod(side - _side + 2, 4) - 2
		if absi(step) == 1:
			_count += step
			_side = side
			var kept: int = int(KEPT[label() - 1])
			if kept != side:
				_turn_body(body, posmod(kept - side + 2, 4) - 2, base(kept) - base(side))
				_side = kept
			_letter()
			return
	_read()


func _letter() -> void:
	for s in 4:
		var offset: int = posmod(s - _side + 2, 4) - 2
		_faces[s].text = str(label(offset))
	var away: bool = label() >= 3
	_plug.visible = away
	_plug_shape.set_deferred("disabled", not away)
	_roof_door.visible = not away
	_twin.visible = away
	_twin_wall.visible = not away
	_read()
	_tell()


func _read() -> void:
	var words := "climbed %.1f m\nabove the door %.1f m\ntaken back %.1f m" % [climbed(), feet() - _door_y, _taken] if _on else ""
	for note in _notes: note.text = words


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["THE ROOF WHERE EVERYONE CLIMBS"])
	lines.append("Go in by the door: you stand in a pavilion on a roof, drawn like a print. Keep the tower on your left and climb the wide steps. Every flight goes up. After four you are in the door's pavilion again, and the robed walkers you passed are passing you.")
	lines.append("It is the stair the hall's small model says cannot close, closed by the other agreement the hall names: a moved room. One honest lap stands. Twice in every round, at a corner, you are set down 1.2 m and turned half about.")
	lines.append("Out in the open that can only go unseen if everything in view is the same after a half turn and a drop of 1.2 m. So the tower repeats on all four sides and every 1.2 m, nothing is lit, the clouds come in opposite pairs, and every walker is placed from where you stand. The tablets on the tower keep count of what was taken back.")
	if _last != "": lines.append(_last)
	_board.text = "\n".join(lines)


## ---- the walkers ----

## A place on the stair, in the roof's frame: flight `q` of the story (0..4, with its corner first), `lane` metres
## out from the tower. Returns [where, which way, seen].
func on_stair(q: float, lane: float) -> Array:
	var flight: int = posmod(int(floor(q)), 4)
	var t: float = q - floor(q)
	var offset: int = posmod(flight + 2 - label(), 4) - 1
	if offset == 2: return [Vector3.ZERO, Vector3.FORWARD, false]
	var side: int = posmod(_side + offset, 4)
	var arc: float = lane * PI * 0.5
	var along: float = t * (arc + H * 2.0)
	var at := Vector3.ZERO
	var ahead := Vector3.RIGHT
	if along < arc:
		var theta: float = PI - along / lane
		at = Vector3(-H + lane * cos(theta), base(side), H + lane * sin(theta))
		ahead = Vector3(sin(theta), 0, -cos(theta))
	else:
		at = Vector3(-H + along - arc, base(side) + RISE * (along - arc) / (H * 2.0), H + lane)
	var turn: float = float(side) * PI * 0.5
	return [at.rotated(Vector3.UP, turn), ahead.rotated(Vector3.UP, turn), true]


func _walk_the_walkers() -> void:
	for walker in _pilgrims:
		var node: Node3D = walker["node"]
		var up: bool = bool(walker["up"])
		if walkers == "none" or (walkers == "up" and not up):
			node.visible = false
			continue
		var q: float = fposmod(float(walker["start"]) + _clock * float(walker["speed"]), 4.0)
		var place: Array = on_stair(q, float(walker["lane"]))
		node.visible = bool(place[2])
		if not node.visible: continue
		var ahead: Vector3 = (place[1] as Vector3) * (1.0 if up else -1.0)
		node.position = (place[0] as Vector3) + Vector3(0, 0.03 * absf(sin(_clock * 4.0 + float(walker["start"]) * 9.0)), 0)
		node.rotation.y = atan2(ahead.x, ahead.z)
	# on the tower's walls: small figures for whom the wall is the floor, the same on every side and every 1.2 m
	var i := 0
	for face in 4:
		var out := Vector3(0, 0, 1).rotated(Vector3.UP, float(face) * PI * 0.5)
		var right := Vector3.UP.cross(out)
		for level in 22:
			var way: float = 1.0 if posmod(level + face / 2, 2) == 0 else -1.0
			var u: float = 1.15 * sin(_clock * 0.45) * way
			var heading: Vector3 = right * (way * (1.0 if cos(_clock * 0.45) >= 0.0 else -1.0))
			var feet_at: Vector3 = out * H + right * u + Vector3(0, -4.2 + 1.2 * float(level), 0)
			var stood := Basis(out.cross(heading), out, heading)
			_wall_bodies.set_instance_transform(i, Transform3D(stood, feet_at + out * 0.26))
			_wall_heads.set_instance_transform(i, Transform3D(stood, feet_at + out * 0.6))
			i += 1


## ---- building ----

func _paint(depth: float = 1.0, tower: bool = false) -> ShaderMaterial:
	var paint := ShaderMaterial.new()
	paint.shader = LITHO
	paint.set_shader_parameter("depth", depth)
	paint.set_shader_parameter("tower", tower)
	paint.set_shader_parameter("origin", _site.global_position if _site != null else Vector3.ZERO)
	return paint


func _block(parent: Node3D, solid: StaticBody3D, at: Vector3, size: Vector3, paint: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = paint
	mesh.position = at
	parent.add_child(mesh)
	if solid != null: _city.wall(solid, at - Vector3(0, size.y * 0.5, 0), size)
	return mesh


func _frame(parent: Node3D, paint: Material) -> void:
	for hand in [-1.0, 1.0]: _block(parent, null, Vector3(hand * (DOOR_W * 0.5 + 0.08), (DOOR_H + 0.16) * 0.5, 0), Vector3(0.16, DOOR_H + 0.16, 0.2), paint)
	_block(parent, null, Vector3(0, DOOR_H + 0.26, 0), Vector3(DOOR_W + 0.32, 0.2, 0.2), paint)


func _tablet(parent: Node3D, at: Vector3, size: int, pixel: float) -> Label3D:
	var words := Label3D.new()
	words.font_size = size
	words.pixel_size = pixel
	words.modulate = INK
	words.outline_size = 0
	words.double_sided = false
	words.position = at
	parent.add_child(words)
	return words


func _build_door() -> void:
	_door = Node3D.new()
	_door.name = "Door"
	add_child(_door)
	var dark: StandardMaterial3D = _city.flat(INK, 0.7)
	_frame(_door, dark)
	var solid := StaticBody3D.new()
	_door.add_child(solid)
	# a wall behind it: the roof's door opens onto the sky on its other side
	_block(_door, solid, Vector3(0, (DOOR_H + 0.4) * 0.5, -0.5), Vector3(DOOR_W + 0.5, DOOR_H + 0.4, 0.12), _city.flat(PAPER, 0.9))
	for hand in [-1.0, 1.0]: _city.wall(solid, Vector3(hand * (DOOR_W * 0.5 + 0.08), 0, -0.2), Vector3(0.16, DOOR_H, 0.6))
	var sign_words: Label3D = _tablet(_door, Vector3(0, DOOR_H + 0.62, 0.11), 44, 0.0034)
	sign_words.modulate = PAPER
	sign_words.outline_size = 10
	sign_words.outline_modulate = INK
	sign_words.text = "THE ROOF WHERE EVERYONE CLIMBS"
	_board = _city.board(self, Vector3(DOOR_W * 0.5 + 2.2, 0, 0.7), 3.4, 1.5)


func _build_roof() -> void:
	_site = Node3D.new()
	_site.name = "Roof"
	_site.top_level = true
	add_child(_site)
	_site.global_transform = Transform3D(upright(_door.global_transform).basis, _home())
	_stone = _paint()
	var robe_dark: ShaderMaterial = _paint(2.2)
	var robe_pale: ShaderMaterial = _paint(0.5)
	var solid := StaticBody3D.new()
	_site.add_child(solid)
	var run: float = H * 2.0
	var slope: float = atan2(RISE, run)
	var slant: float = sqrt(run * run + RISE * RISE)
	var out: float = H + W
	var mid: float = H + W * 0.5
	var deep: float = 30.0
	_block(_site, solid, Vector3(0, 8.0, 0), Vector3(run, 60.0, run), _paint(1.0, true))
	for s in 4:
		var turned := Node3D.new()
		turned.name = "Side%d" % s
		turned.rotation.y = float(s) * PI * 0.5
		_site.add_child(turned)
		var bodies := StaticBody3D.new()
		turned.add_child(bodies)
		var low: float = base(s)
		# the landing this side starts from, and the pavilion over it
		_block(turned, null, Vector3(-mid, (low - deep) * 0.5, mid), Vector3(W, low + deep, W), _stone)
		_city.wall(bodies, Vector3(-mid, low - 0.4, mid), Vector3(W, 0.4, W))
		for corner in [Vector2(-H - 0.1, H + 0.1), Vector2(-out + 0.1, H + 0.1), Vector2(-H - 0.1, out - 0.1), Vector2(-out + 0.1, out - 0.1)]:
			_block(turned, null, Vector3(corner.x, low + POST * 0.5, corner.y), Vector3(0.16, POST, 0.16), _stone)
		if s != 3:        # the lowest corner's roof is the upper landing
			_block(turned, null, Vector3(-mid, low + POST + 0.09, mid), Vector3(W + 0.5, 0.18, W + 0.5), _stone)
			_block(turned, null, Vector3(-mid, low + POST + 0.33, mid), Vector3(W - 0.5, 0.3, W - 0.5), _stone)
		# the parapet on the landing's far edge, always; on its outer edge unless this is the door's corner
		_block(turned, bodies, Vector3(-out - 0.11, low + PARAPET * 0.5 - 0.6, mid), Vector3(0.22, PARAPET + 1.2, W + 0.44), _stone)
		var outer_at := Vector3(-mid, low + PARAPET * 0.5 - 0.6, out + 0.11)
		var outer_size := Vector3(W, PARAPET + 1.2, 0.22)
		if s == 0:
			_plug = _block(turned, null, outer_at, outer_size, _stone)
			var plug_body := StaticBody3D.new()
			turned.add_child(plug_body)
			_plug_shape = _city.wall(plug_body, outer_at - Vector3(0, outer_size.y * 0.5, 0), Vector3(W, PARAPET + 2.6, 0.22))
		elif s == 2:
			_twin_wall = _block(turned, bodies, outer_at, outer_size, _stone)
			_twin = Node3D.new()
			_twin.position = Vector3(-mid, low, out)
			turned.add_child(_twin)
			_frame(_twin, _city.flat(INK, 0.7))
		else:
			_block(turned, bodies, outer_at, outer_size, _stone)
		# the flight: four wide treads, solid far down; a slope to walk on; a parapet that climbs with it
		for i in TREADS:
			var top: float = low + RISE * float(i + 1) / float(TREADS)
			var tread: float = run / float(TREADS)
			_block(turned, null, Vector3(-H + tread * (float(i) + 0.5), (top - deep) * 0.5, mid), Vector3(tread, top + deep, W), _stone)
		var ramp := CollisionShape3D.new()
		var plank := BoxShape3D.new()
		plank.size = Vector3(slant, 0.2, W)
		ramp.shape = plank
		ramp.position = Vector3(0, low + RISE * 0.5 - 0.1 * cos(slope), mid)
		ramp.rotation.z = slope
		bodies.add_child(ramp)
		var rail: MeshInstance3D = _block(turned, null, Vector3(0, low + RISE * 0.5 + PARAPET * 0.5 - 0.6, out + 0.11), Vector3(slant, PARAPET + 1.2, 0.22), _stone)
		rail.rotation.z = slope
		var rail_shape := CollisionShape3D.new()
		var rail_box := BoxShape3D.new()
		rail_box.size = Vector3(slant, PARAPET + 3.0, 0.22)
		rail_shape.shape = rail_box
		rail_shape.position = rail.position
		rail_shape.rotation.z = slope
		bodies.add_child(rail_shape)
		# the tablet on the tower: this flight's number, and the count
		_faces.append(_tablet(turned, Vector3(0, low + RISE * 0.5 + 1.75, H + 0.012), 230, 0.003))
		_notes.append(_tablet(turned, Vector3(0, low + RISE * 0.5 + 1.2, H + 0.012), 40, 0.0024))
	# the round's far end: the upper landing over the lowest one, and a dark arch where the stair is seen to go on
	var upper: float = RISE * 4.0
	_block(_site, solid, Vector3(-mid, upper - 0.1, -mid), Vector3(W + 0.5, 0.2, W + 0.5), _stone)
	for corner in [Vector2(-H - 0.1, -H - 0.1), Vector2(-out + 0.1, -H - 0.1), Vector2(-H - 0.1, -out + 0.1), Vector2(-out + 0.1, -out + 0.1)]:
		_block(_site, null, Vector3(corner.x, upper + POST * 0.5, corner.y), Vector3(0.16, POST, 0.16), _stone)
	_block(_site, null, Vector3(-mid, upper + POST + 0.09, -mid), Vector3(W + 0.5, 0.18, W + 0.5), _stone)
	_block(_site, null, Vector3(-mid, upper + POST + 0.33, -mid), Vector3(W - 0.5, 0.3, W - 0.5), _stone)
	_block(_site, solid, Vector3(-out - 0.11, upper + PARAPET * 0.5, -mid), Vector3(0.22, PARAPET, W + 0.44), _stone)
	_block(_site, solid, Vector3(-mid, upper + PARAPET * 0.5, -out - 0.11), Vector3(W, PARAPET, 0.22), _stone)
	_block(_site, solid, Vector3(-mid, upper + 1.3, -H + 0.5), Vector3(W, 2.6, 0.1), _city.flat(INK, 0.9))
	# the door on the roof: in the first pavilion's outer arch
	_roof_door = Node3D.new()
	_roof_door.name = "RoofDoor"
	_roof_door.position = Vector3(-mid, RISE, out)
	_site.add_child(_roof_door)
	_frame(_roof_door, _city.flat(INK, 0.7))
	# the walkers: robed, dark going up along the tower, pale coming down along the parapet
	var robe := CylinderMesh.new()
	robe.top_radius = 0.05
	robe.bottom_radius = 0.3
	robe.height = 1.3
	robe.radial_segments = 10
	var hood := SphereMesh.new()
	hood.radius = 0.15
	hood.height = 0.3
	hood.radial_segments = 10
	hood.rings = 5
	for i in 12:
		var up: bool = i < 7
		var figure := Node3D.new()
		_site.add_child(figure)
		var body_mesh := MeshInstance3D.new()
		body_mesh.mesh = robe
		body_mesh.material_override = robe_dark if up else robe_pale
		body_mesh.position = Vector3(0, 0.65, 0)
		figure.add_child(body_mesh)
		var head_mesh := MeshInstance3D.new()
		head_mesh.mesh = hood
		head_mesh.material_override = robe_dark if up else robe_pale
		head_mesh.position = Vector3(0, 1.42, 0.03)
		figure.add_child(head_mesh)
		_pilgrims.append({"node": figure, "up": up, "lane": 0.5 if up else W - 0.5, "start": float(i) * (4.0 / 7.0 if up else 4.0 / 5.0) + (0.0 if up else 0.31),
			"speed": 0.085 if up else -0.07})
	# figures on the tower's walls
	var small_robe := CylinderMesh.new()
	small_robe.top_radius = 0.02
	small_robe.bottom_radius = 0.13
	small_robe.height = 0.52
	small_robe.radial_segments = 8
	var small_hood := SphereMesh.new()
	small_hood.radius = 0.07
	small_hood.height = 0.14
	small_hood.radial_segments = 8
	small_hood.rings = 4
	for pair in [[small_robe, "bodies"], [small_hood, "heads"]]:
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = pair[0]
		multi.instance_count = 88
		var node := MultiMeshInstance3D.new()
		node.multimesh = multi
		node.material_override = robe_dark
		_site.add_child(node)
		if str(pair[1]) == "bodies": _wall_bodies = multi
		else: _wall_heads = multi
	# a sky of its own: paper, with clouds in opposite pairs
	_sky = Node3D.new()
	_sky.name = "Sky"
	_sky.position = Vector3(0, 1.2, 0)
	_site.add_child(_sky)
	var dome := SphereMesh.new()
	dome.radius = SHELL
	dome.height = SHELL * 2.0
	var sheet := StandardMaterial3D.new()
	sheet.albedo_color = Color("ddd5c4")
	sheet.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sheet.cull_mode = BaseMaterial3D.CULL_FRONT
	sheet.disable_fog = true           # fifty metres off, the tower's haze would swallow it
	var dome_node := MeshInstance3D.new()
	dome_node.mesh = dome
	dome_node.material_override = sheet
	dome_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sky.add_child(dome_node)
	var stroke := BoxMesh.new()
	stroke.size = Vector3(1.0, 0.1, 0.1)
	var clouds := MultiMesh.new()
	clouds.transform_format = MultiMesh.TRANSFORM_3D
	clouds.mesh = stroke
	clouds.instance_count = 360
	var rng := RandomNumberGenerator.new()
	rng.seed = 191
	for i in 180:
		var turn: float = rng.randf() * PI
		var high: float = rng.randf_range(-0.35, 0.8)
		var long: float = rng.randf_range(3.0, 11.0)
		for twin in 2:
			var angle: float = turn + float(twin) * PI
			var out_dir := Vector3(cos(angle) * cos(high), sin(high), sin(angle) * cos(high))
			var along_dir := Vector3(-sin(angle), 0, cos(angle))
			var stood := Basis(along_dir * long, out_dir.cross(along_dir).normalized(), out_dir)
			clouds.set_instance_transform(i * 2 + twin, Transform3D(stood, out_dir * (SHELL - 2.0)))
	var cloud_node := MultiMeshInstance3D.new()
	cloud_node.multimesh = clouds
	var line := StandardMaterial3D.new()
	line.albedo_color = Color("8d8778")
	line.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line.disable_fog = true
	cloud_node.material_override = line
	cloud_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sky.add_child(cloud_node)
	_sky.visible = false
	for paint in [_stone, robe_dark, robe_pale]: paint.set_shader_parameter("origin", _site.global_position)
	for node in _site.find_children("*", "MeshInstance3D", true, false):
		var m: Material = (node as MeshInstance3D).material_override
		if m is ShaderMaterial: (m as ShaderMaterial).set_shader_parameter("origin", _site.global_position)


## ---- for a test ----

func state() -> Dictionary:
	var shown := []
	for s in 4: shown.append(int(_faces[s].text))
	var seen := 0
	for walker in _pilgrims:
		if (walker["node"] as Node3D).visible: seen += 1
	return {"walkers": walkers, "on_roof": _on, "side": _side, "count": _count, "label": label(), "half_turns": _halves, "taken_m": snappedf(_taken, 0.001), "climbed_m": snappedf(climbed(), 0.01),
		"above_door_m": snappedf(feet() - _door_y, 0.01) if _on else 0.0, "feet_m": snappedf(feet(), 0.01), "faces": shown, "door_away": _plug.visible, "walkers_seen": seen, "walkers_in_all": _pilgrims.size(),
		"roof_from_door_m": snappedf((_site.global_position - _door.global_position).length(), 0.1), "sky": _sky.visible, "board": _board.text if _board != null else "", "build_ms": _build_ms}


func ring_point(side: int, corner: bool = false) -> Vector3:
	var at := Vector3(H + W * 0.5, 0, H + W * 0.5) if corner else Vector3(0, 0, H + W * 0.5)
	return _site.to_global(at.rotated(Vector3.UP, float(side) * PI * 0.5))


## In front of the door on the floor: `by` metres on the side one comes from.
func door_point(by: float) -> Vector3:
	return _door.to_global(Vector3(0, 0, by))


## On the roof, in the door's pavilion: `by` metres inside its door (negative: out through it).
func roof_door_point(by: float) -> Vector3:
	return _roof_door.to_global(Vector3(0, 0, -by))
