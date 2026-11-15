extends Node3D
## A STAIR THAT ONLY GOES UP AND COMES BACK (floor Escher_Impossible; the pass, 2026-11-15)
##
## The hall: "A staircase that goes up on all four sides and comes back to where it started. You can want to walk
## it before you have worked out whether it can exist." Its small staircase lets a marker make the journey and
## finds where the height is given back: "We cannot end higher while also ending at the very same position,
## measured against the same up." And then: "A portal, a changed gravity or a moved room would require another
## agreement - and another question about what the body experienced on the way."
## This is that other agreement, at body size - a PLAYGROUND form, and the hall's own named gap (an impossibility
## the learner undergoes instead of watching).
##
## A square stairwell round a block: four flights, each rising 0.6 m, each an honest flight. Walk up the ramp, in
## by the door, keep the block on your left and climb. Every flight goes up. After four you are at the door.
##
## How, and the board says so: what stands is ONE honest lap, rising 2.4 m from the floor. The body lives on two
## of its flights. At the corner where it would step onto the third, it is set down 1.2 m and turned half about,
## onto the first - a place built to look exactly like the one it left, in the frame in which the numbers on the
## block are re-lettered from where it stands. The other two flights are what it sees ahead and behind. The wall
## inside keeps count: metres climbed, metres above the door, metres taken back. Desktop: the walker's
## transform. Headset: the player body's teleport(pose), as the wing's adapter does - NOT tried in a headset.
##
## `agreement` is the axis: moved (the stair closes by moving the body), kept (one up, kept all the way: the four
## rising flights cannot close; the stair ends 1.8 m above its door, and the board says why).
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const H := 1.2                          # the block's half side: a flight's run is 2 H
const W := 1.2                          # the stairwell's width
const T := 0.08
const RISE := 0.6                       # a flight's rise
const TREADS := 4
const HEAD := 2.4                       # from a tread to the ceiling above it
const TOP := RISE * 4.0 + HEAD
const DOOR := 1.0
const DOOR_HIGH := 2.1
const RAMP := 2.4
## The side of the building (0 south, 1 east, 2 north, 3 west) on which each of the story's four flights is kept.
const KEPT := [0, 1, 0, 1]
const CARD := Color("c4a070")
const BLOCK := Color("3a3d45")
const PINK := Color("ff5fa8")
const PALE := Color("efe9dc")

@export_enum("moved", "kept") var agreement := "moved"

var _city = City.new()
var _faces: Array[Label3D] = []
var _notes: Array[Label3D] = []
var _plug: Node3D
var _plug_shape: CollisionShape3D
var _twin: Node3D
var _end_sign: Label3D
var _board: Label3D
var _body: Node3D
var _inside := false
var _side := 0
var _count := 0                          # flights gone forward since the door
var _halves := 0                         # half turns given to the body
var _taken := 0.0                        # metres the stair has set the body down
var _door_y := 0.0
var _last := ""
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_agreement"): _take({"agreement": get_meta("config_agreement")})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_letter()


func _take(config_data: Dictionary) -> void:
	if config_data.has("agreement") and str(config_data["agreement"]) in ["moved", "kept"]: agreement = str(config_data["agreement"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := agreement
	_take(config_data)
	if is_inside_tree() and _board != null and agreement != before and not _inside:
		_count = 0
		_taken = 0.0
		_last = ""
		_letter()


## ---- the rule ----

## The height at which side s's flight begins: the west flight starts on the floor, the south one a flight up.
static func base(side: int) -> float:
	return float(posmod(side + 1, 4)) * RISE


func label(offset: int = 0) -> int:
	return posmod(_count + offset, 4) + 1


static func side_at(x: float, z: float) -> int:
	if absf(x) > absf(z): return 1 if x > 0.0 else 3
	return 0 if z > 0.0 else 2


static func within(x: float, y: float, z: float) -> bool:
	return maxf(absf(x), absf(z)) < H + W and maxf(absf(x), absf(z)) > H - 0.05 and y > -0.3 and y < TOP


func climbed() -> float:
	if _body == null or not is_instance_valid(_body): return 0.0
	return to_local(_body.global_position).y - _door_y + _taken


func above_door() -> float:
	if _body == null or not is_instance_valid(_body): return 0.0
	return to_local(_body.global_position).y - _door_y


func _letter() -> void:
	var moved: bool = agreement == "moved"
	for s in 4:
		var offset: int = posmod(s - _side + 2, 4) - 2
		_faces[s].text = str(label(offset)) if moved else str(posmod(s + 1, 4))
	var away: bool = moved and label() >= 3
	_plug.visible = away
	_plug_shape.set_deferred("disabled", not away)
	_twin.visible = away
	_end_sign.visible = not moved
	_read()
	_tell()


func _read() -> void:
	var words := "climbed %.1f m\nabove the door %.1f m\ntaken back %.1f m" % [maxf(0.0, climbed()) if _count >= 0 else climbed(), above_door(), _taken] if _inside else ""
	for note in _notes: note.text = words


func _turn_body(quarters: int, lift: float) -> void:
	var theta: float = float(quarters) * PI * 0.5
	var pose: Transform3D = _body.global_transform
	var middle: Vector3 = global_position
	pose.origin = middle + (pose.origin - middle).rotated(Vector3.UP, theta) + Vector3(0, lift, 0)
	pose.basis = Basis(Vector3.UP, theta) * pose.basis
	var game: Node = get_tree().get_first_node_in_group("void_game")
	if game != null and bool(game.get("vr")) and _body.has_method("teleport"):
		_body.call("teleport", pose)
	else:
		_body.global_transform = pose
		if "velocity" in _body: _body.set("velocity", (_body.get("velocity") as Vector3).rotated(Vector3.UP, theta))
	if game != null and game.has_method("rebase_player_motion"): game.call("rebase_player_motion")
	_halves += quarters / 2
	_taken -= lift


func _physics_process(_delta: float) -> void:
	if _body == null or not is_instance_valid(_body):
		_inside = false
		return
	var p := to_local(_body.global_position)
	var now: bool = within(p.x, p.y, p.z)
	if now and not _inside:
		_inside = true
		_side = side_at(p.x, p.z)
		_count = 0
		_taken = 0.0
		_door_y = p.y
		_letter()
		return
	if not now:
		if _inside:
			_last = "Last walk: your feet climbed %.1f m and you left %.1f m above the door." % [climbed(), above_door()]
			_inside = false
			_side = 0
			_count = 0
			_taken = 0.0
			_letter()
		return
	var side: int = side_at(p.x, p.z)
	if side != _side and absf(absf(p.x) - absf(p.z)) >= 0.04:
		var step: int = posmod(side - _side + 2, 4) - 2
		if absi(step) == 1:
			_count += step
			_side = side
			if agreement == "moved":
				var kept: int = int(KEPT[label() - 1])
				if kept != side:
					_turn_body(posmod(kept - side + 2, 4) - 2, base(kept) - base(side))
					_side = kept
			_letter()
			return
	_read()


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray()
	if agreement == "moved":
		lines.append("A STAIR THAT ONLY GOES UP AND COMES BACK")
		lines.append("Walk up the ramp and in. Keep the block on your left and climb. Every flight goes up. After four you are at the door again.")
		lines.append("The hall's small staircase keeps one agreement - one up, measured the same all the way round - so what a closed route gains it must give back, and you can find the side that gives it back. This stair keeps the other agreement the hall names: a moved room. Twice in every round, at a corner, you are set down 1.2 m and turned half about, into a place built to look exactly like the one you left.")
		lines.append("Each flight is an honest flight and each corner an honest corner. What cannot be built is all four at once, and it was not. The wall inside keeps count of what was taken back.")
	else:
		lines.append("A STAIR THAT GOES UP AND STOPS")
		lines.append("Walk up the ramp and in. Keep the block on your left and climb. With one up kept all the way round, flights that only rise cannot close: this stair ends 1.8 m above its door. Below the door it goes down one flight to the floor.")
		lines.append("Nothing moves you here. It is the same stairwell as the one that comes back; only the agreement is different.")
	if _last != "": lines.append(_last)
	_board.text = "\n".join(lines)


## ---- building, once ----

func _box(parent: Node3D, solid: StaticBody3D, at: Vector3, size: Vector3, paint: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = paint
	mesh.position = at
	parent.add_child(mesh)
	if solid != null: _city.wall(solid, at - Vector3(0, size.y * 0.5, 0), size)   # wall() takes the base of the box
	return mesh


func _words(parent: Node3D, at: Vector3, size: int, pixel: float, colour: Color) -> Label3D:
	var label3d := Label3D.new()
	label3d.font_size = size
	label3d.pixel_size = pixel
	label3d.modulate = colour
	label3d.outline_size = 0
	label3d.double_sided = false
	label3d.position = at
	parent.add_child(label3d)
	return label3d


func _build_once() -> void:
	var solid := StaticBody3D.new()
	solid.name = "Walls"
	add_child(solid)
	var card: StandardMaterial3D = _city.flat(CARD, 0.95)
	var dark: StandardMaterial3D = _city.flat(BLOCK, 0.9)
	var pale: StandardMaterial3D = _city.flat(PALE, 0.9)
	var step_paint: StandardMaterial3D = _city.flat(Color("d9d2c2"), 0.9)
	var out: float = H + W + T * 0.5
	var span: float = (H + W + T) * 2.0
	var run: float = H * 2.0
	var slope: float = atan2(RISE, run)
	var slant: float = sqrt(run * run + RISE * RISE)
	_box(self, solid, Vector3(0, TOP * 0.5, 0), Vector3(H * 2.0, TOP, H * 2.0), dark)
	_box(self, null, Vector3(0, TOP + 0.05, 0), Vector3(span, 0.1, span), card)
	for s in 4:
		var turned := Node3D.new()
		turned.name = "Side%d" % s
		turned.rotation.y = float(s) * PI * 0.5
		add_child(turned)
		var bodies := StaticBody3D.new()
		turned.add_child(bodies)
		var low: float = base(s)
		var mid: float = H + W * 0.5
		# the outer wall, whole on three sides; on the south the door is cut into it at the corner the side starts in
		if s == 0:
			var door_x: float = -mid
			var left: float = (-H - W - T) - (door_x - DOOR * 0.5)
			_box(turned, bodies, Vector3((-H - W - T + door_x - DOOR * 0.5) * 0.5, TOP * 0.5, out), Vector3(absf(left), TOP, T), card)
			var right_from: float = door_x + DOOR * 0.5
			_box(turned, bodies, Vector3((right_from + H + W + T) * 0.5, TOP * 0.5, out), Vector3(H + W + T - right_from, TOP, T), card)
			_box(turned, bodies, Vector3(door_x, low * 0.5, out), Vector3(DOOR, low, T), card)
			var over: float = TOP - (low + DOOR_HIGH)
			_box(turned, bodies, Vector3(door_x, low + DOOR_HIGH + over * 0.5, out), Vector3(DOOR, over, T), card)
		else:
			_box(turned, bodies, Vector3(0, TOP * 0.5, out), Vector3(span, TOP, T), card)
		# the landing this side starts from, solid down to the floor, and its ceiling
		if low > 0.0: _box(turned, bodies, Vector3(-mid, low * 0.5, mid), Vector3(W, low, W), step_paint)
		if s != 3: _box(turned, null, Vector3(-mid, low + HEAD + 0.03, mid), Vector3(W, 0.06, W), card)   # the north-west corner's lower ceiling is the upper landing
		# the flight: four treads, solid down to the floor; a slope to walk on; a ceiling that climbs with it
		for i in TREADS:
			var top: float = low + RISE * float(i + 1) / float(TREADS)
			var deep: float = run / float(TREADS)
			_box(turned, null, Vector3(-H + deep * (float(i) + 0.5), top * 0.5, mid), Vector3(deep, top, W), step_paint)
			_box(turned, null, Vector3(-H + deep * float(i) + 0.012, top - RISE / float(TREADS) * 0.5, mid), Vector3(0.024, RISE / float(TREADS), W), dark)
		var ramp := CollisionShape3D.new()
		var plank := BoxShape3D.new()
		plank.size = Vector3(slant, 0.2, W)
		ramp.shape = plank
		ramp.position = Vector3(0, low + RISE * 0.5 - 0.1 * cos(slope), mid)
		ramp.rotation.z = slope
		bodies.add_child(ramp)
		var roof := MeshInstance3D.new()
		var lid := BoxMesh.new()
		lid.size = Vector3(slant, 0.06, W)
		roof.mesh = lid
		roof.material_override = card
		roof.position = Vector3(0, low + RISE * 0.5 + HEAD + 0.03, mid)
		roof.rotation.z = slope
		turned.add_child(roof)
		# the flight's number on the block, and what the wall keeps count of
		var face: Label3D = _words(turned, Vector3(0, low + RISE * 0.5 + 1.62, H + 0.012), 220, 0.003, PALE)
		_faces.append(face)
		var note: Label3D = _words(turned, Vector3(0, low + RISE * 0.5 + 1.08, H + 0.012), 38, 0.0022, PINK.lightened(0.3))
		_notes.append(note)
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(-mid, low + HEAD - 0.4, mid)
		lamp.omni_range = 3.4
		lamp.light_energy = 1.3
		lamp.shadow_enabled = false
		turned.add_child(lamp)
	# the corner the round ends in, north-west: its upper landing (the lower one is the floor), with one more tread
	# and then the dark, so that the stair is seen to go on
	var upper := RISE * 4.0
	var nw := Vector3(-(H + W * 0.5), 0, -(H + W * 0.5))
	_box(self, solid, nw + Vector3(0, upper - 0.05, 0), Vector3(W, 0.1, W), step_paint)
	_box(self, null, nw + Vector3(0, upper + HEAD + 0.03, 0), Vector3(W, 0.06, W), card)
	_box(self, solid, Vector3(-(H + W * 0.5), upper + 0.075, -H + 0.3), Vector3(W, 0.15, 0.6), step_paint)
	_box(self, solid, Vector3(-(H + W * 0.5), upper + 1.2, -H + 0.62), Vector3(W, 2.4, 0.04), dark)
	var top_lamp := OmniLight3D.new()
	top_lamp.position = nw + Vector3(0, upper + HEAD - 0.4, 0)
	top_lamp.omni_range = 3.4
	top_lamp.light_energy = 1.3
	top_lamp.shadow_enabled = false
	add_child(top_lamp)
	_end_sign = _words(self, Vector3(-(H + W * 0.5), upper + 1.45, -H + 0.59), 44, 0.0022, PALE)
	_end_sign.rotation.y = PI
	_end_sign.text = "the stair ends here,\n1.8 m above its door.\nfour flights that only rise\ncannot close."
	# the door: at the south-west corner, a flight above the floor, reached by a ramp
	var door_at := Vector3(-(H + W * 0.5), RISE, H + W)
	var screen := Node3D.new()
	screen.name = "Screen"
	screen.position = door_at + Vector3(0, 0, T * 0.5)
	add_child(screen)
	var paper := QuadMesh.new()
	paper.size = Vector2(DOOR, DOOR_HIGH)
	var outer := MeshInstance3D.new()
	outer.mesh = paper
	outer.material_override = pale
	outer.position = Vector3(0, DOOR_HIGH * 0.5, 0.045)
	screen.add_child(outer)
	var inner := MeshInstance3D.new()
	inner.mesh = paper
	inner.material_override = pale
	inner.position = Vector3(0, DOOR_HIGH * 0.5, -0.045)
	inner.rotation.y = PI
	screen.add_child(inner)
	var out_word: Label3D = _words(screen, Vector3(0, 1.5, -0.052), 90, 0.003, BLOCK)
	out_word.rotation.y = PI
	out_word.text = "OUT"
	_words(screen, Vector3(0, 1.35, 0.052), 80, 0.003, BLOCK).text = "up\nIN"
	# the plug that hides the door while the door is at the other corner, and the look of the door there
	_plug = Node3D.new()
	_plug.name = "Plug"
	_plug.position = door_at + Vector3(0, 0, -0.01)
	add_child(_plug)
	var cover := MeshInstance3D.new()
	var cover_mesh := QuadMesh.new()
	cover_mesh.size = Vector2(DOOR + 0.02, DOOR_HIGH + 0.02)
	cover.mesh = cover_mesh
	cover.material_override = card
	cover.position = Vector3(0, DOOR_HIGH * 0.5, 0)
	cover.rotation.y = PI
	_plug.add_child(cover)
	var plug_body := StaticBody3D.new()
	add_child(plug_body)
	_plug_shape = _city.wall(plug_body, door_at + Vector3(0, 0, T * 0.5), Vector3(DOOR, DOOR_HIGH, T))
	_twin = Node3D.new()
	_twin.name = "DoorLook"
	_twin.position = Vector3(H + W * 0.5, RISE * 3.0, -(H + W) + 0.004)
	add_child(_twin)
	var look := MeshInstance3D.new()
	look.mesh = paper
	look.material_override = pale
	look.position = Vector3(0, DOOR_HIGH * 0.5, 0)
	_twin.add_child(look)
	_words(_twin, Vector3(0, 1.5, 0.008), 90, 0.003, BLOCK).text = "OUT"
	# the ramp up to the door
	var ramp_body := StaticBody3D.new()
	add_child(ramp_body)
	var incline: float = atan2(RISE, RAMP)
	var length: float = sqrt(RAMP * RAMP + RISE * RISE)
	var ramp_mesh := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(DOOR + 0.3, 0.12, length)
	ramp_mesh.mesh = slab
	ramp_mesh.material_override = step_paint
	ramp_mesh.position = Vector3(door_at.x, RISE * 0.5 - 0.06 * cos(incline), H + W + T + RAMP * 0.5)
	ramp_mesh.rotation.x = incline
	add_child(ramp_mesh)
	var ramp_shape := CollisionShape3D.new()
	var ramp_box := BoxShape3D.new()
	ramp_box.size = slab.size
	ramp_shape.shape = ramp_box
	ramp_shape.position = ramp_mesh.position
	ramp_shape.rotation.x = incline
	ramp_body.add_child(ramp_shape)
	# the body, and the board beside the ramp
	var sensor := Area3D.new()
	sensor.name = "Reach"
	sensor.collision_layer = 0
	sensor.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = Vector3(span + 4.0, TOP + 1.0, span + RAMP * 2.0 + 4.0)
	var area := CollisionShape3D.new()
	area.shape = room
	area.position = Vector3(0, TOP * 0.5, RAMP * 0.5)
	sensor.add_child(area)
	add_child(sensor)
	sensor.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _body = b)
	sensor.body_exited.connect(func(b: Node) -> void:
		if b == _body: _body = null)
	_board = _city.board(self, Vector3(0.9, 0, H + W + 1.5), 3.4, 1.5)


## ---- for a test ----

func state() -> Dictionary:
	var shown := []
	for s in 4: shown.append(int(_faces[s].text))
	var feet: float = to_local(_body.global_position).y if _body != null and is_instance_valid(_body) else 0.0
	return {"agreement": agreement, "inside": _inside, "side": _side, "count": _count, "label": label(), "half_turns": _halves, "taken_m": snappedf(_taken, 0.001), "climbed_m": snappedf(climbed(), 0.01),
		"above_door_m": snappedf(above_door(), 0.01), "feet_m": snappedf(feet, 0.01), "faces": shown, "door_plugged": _plug.visible, "door_look_at_the_far_corner": _twin.visible, "top_m": TOP + 0.1, "rise": RISE,
		"board": _board.text if _board != null else "", "prefab_parts": int(_city.parts), "build_ms": _build_ms}


## The middle of a side of the stairwell (0 south, 1 east, 2 north, 3 west), or with `corner` the middle of the
## corner that side ends in going up.
func ring_point(side: int, corner: bool = false) -> Vector3:
	var at := Vector3(H + W * 0.5, 0, H + W * 0.5) if corner else Vector3(0, 0, H + W * 0.5)
	return to_global(at.rotated(Vector3.UP, float(side) * PI * 0.5))


## In front of the door: `out_by` metres south of it (on the ramp, or at its foot at 2.9), or inside with -0.6.
func door_point(out_by: float) -> Vector3:
	return to_global(Vector3(-(H + W * 0.5), 0, H + W + T * 0.5 + out_by))
