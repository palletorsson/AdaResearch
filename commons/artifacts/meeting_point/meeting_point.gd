extends Node3D
## WHERE DO THEY MEET? (floor Euclid_Parallel; the pass, 2026-11-15)
##
## The hall asks what was already accepted when the first triangle appeared, and makes one assumption
## conspicuous: the fifth postulate. "The visible line ends. The statement about its extension does not."
## This is that sentence at the size of the floor - a PLAYGROUND form, and the body chooses the line.
##
## Euclid's fifth, as he wrote it: if a line falling on two lines makes the two angles on one side together less
## than two right angles, the two lines meet on that side. Laid out here, the whole length of the slab:
##   the FIRST LINE, on text tape from the west edge to the east edge;
##   a point P, a metre and a half off it, and the line that falls across both at P;
##   the GOLD line through P with no shortfall at all - the one the postulate says nothing brings to a meeting;
##   four lines through P that fall 20, 10, 5 and 3 degrees short, each with a cone where it meets the first
##   line: 4, 9, 17 and 29 metres along. Every one of those can be walked to.
## Step into the lane between the first line and the gold one, east of P: a pink line runs from P through you,
## and a stake stands where it meets the first line. Stand on the first line and the stake is at your feet. Step
## toward the gold line and it runs away east, faster and faster, off the edge of the building and out over the
## clouds. On the gold line there is nothing to walk to. Beyond it the line leans the other way and the meeting
## is behind P, to the west.
##
## Nothing here shows that the gold line never meets the first one: the floor is 42 metres and the statement is
## about all the metres there are. The reading stops telling the pink line from the gold one at TOLERANCE degrees,
## and says so: that edge is the instrument's (the hall: "The threshold belongs to the instrument").
##
## `shortfall` is the axis: where the pink line rests when nobody is in the lane - wide (8 degrees: meets after
## 10.7 m), narrow (2.5 degrees: 34.4 m), none (it lies on the gold line and there is no stake).
##
## The row stands at x 0 of its floor with facing 0: the lines run to the slab's east and west edges (EDGE).
## Lines are the tape rolls' printed strip and flat tape; cones, balls and the stake are the tower's prefabs
## through prefab_city.gd.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const Strip := preload("res://commons/artifacts/tape_roll/strip.gd")
const BASE_Z := -1.1
const GOLD_Z := 0.4
const P := Vector3(-18.0, 0.0, GOLD_Z)
const WEST := -20.4
const EAST := 20.6
const EDGE := 21.0
const FIXED: Array[float] = [20.0, 10.0, 5.0, 3.0]
const REST := {"wide": 8.0, "narrow": 2.5, "none": 0.0}
const TOLERANCE := 0.05                 # degrees: closer to the gold line than this, the reading is withheld
const FAR := 400.0                      # metres from P: farther than this the stake is not drawn
const LANE_BEYOND := 1.3                 # how far beyond the gold line (away from the first) the lane still reads a body
const GOLD := Color("e2b33c")
const PINK := Color("ff5fa8")
const PAPER := Color("efe9dc")

@export_enum("wide", "narrow", "none") var shortfall := "narrow"

var _city = City.new()
var _line: MeshInstance3D
var _stake: Node3D
var _stake_tag: Label3D
var _board: Label3D
var _body: CharacterBody3D
var _in_lane := false
var _angle := 0.0                       # degrees short of two right angles on the east side; negative leans away
var _drawn := 999.0
var _fixed := []
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_shortfall"): _take({"shortfall": get_meta("config_shortfall")})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_set_angle(float(REST[shortfall]))


func _take(config_data: Dictionary) -> void:
	if config_data.has("shortfall") and REST.has(str(config_data["shortfall"])): shortfall = str(config_data["shortfall"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := shortfall
	_take(config_data)
	if is_inside_tree() and _board != null and shortfall != before and not _in_lane:
		_drawn = 999.0
		_set_angle(float(REST[shortfall]))


## ---- the rule ----

static func gap() -> float:
	return GOLD_Z - BASE_Z


## Metres from P, along the first line's direction, to where a line through P that falls `degrees` short meets
## the first line. Positive: east of P. Negative: west of P (the line leans away on the east side). INF: within
## the tolerance of the gold line.
static func meets_at(degrees: float) -> float:
	if absf(degrees) < TOLERANCE: return INF
	return gap() / tan(deg_to_rad(degrees))


## The shortfall of the line from P through a place in the lane (local x, z).
static func shortfall_at(x: float, z: float) -> float:
	return rad_to_deg(atan2(GOLD_Z - z, x - P.x))


## The line through P that falls `degrees` short, `east` metres east of P (the first line lies toward -z).
func _on_line(east: float, degrees: float) -> Vector3:
	return Vector3(P.x + east, 0.03, P.z - east * tan(deg_to_rad(degrees)))


func _set_angle(degrees: float) -> void:
	_angle = degrees
	if absf(degrees - _drawn) < 0.004: return
	_drawn = degrees
	var along: float = meets_at(degrees)
	var shown: bool = along != INF and absf(along) <= FAR
	var from := _on_line(0.0, degrees)
	var to := _on_line(EAST - P.x + 30.0, 0.0)
	if along != INF and degrees > 0.0:
		to = _on_line(minf(along, FAR), degrees)
	elif along != INF:
		# it leans away on the east side: drawn from its meeting in the west, through P, to the lane's far side
		from = _on_line(maxf(along, -FAR), degrees)
		to = _on_line(minf(EDGE - P.x, (LANE_BEYOND + 0.3) / tan(deg_to_rad(-degrees))), degrees)
	_line.position = (from + to) * 0.5
	_line.basis = Basis(Quaternion(Vector3.UP, (to - from).normalized())).scaled(Vector3(1, from.distance_to(to), 1))
	_stake.visible = shown
	if shown:
		_stake.position = Vector3(P.x + along, 0, BASE_Z)
		# past the edge of the floor it grows with its distance, so that it can still be seen leaving
		var past: float = maxf(0.0, absf(P.x + along) - EDGE)
		_stake.scale = Vector3.ONE * minf(8.0, 1.0 + past / 12.0)
		_stake_tag.text = "they meet here\n%.1f m from P" % absf(along)
	_tell()


func _physics_process(_delta: float) -> void:
	var here := _body != null and is_instance_valid(_body)
	var p := to_local(_body.global_position) if here else Vector3.ZERO
	var inside: bool = here and p.x > P.x + 0.8 and p.x < EDGE and p.z > BASE_Z - 0.35 and p.z < GOLD_Z + LANE_BEYOND and absf(p.y) < 1.5
	if inside:
		_in_lane = true
		_set_angle(shortfall_at(p.x, p.z))
	elif _in_lane:
		_in_lane = false
		_drawn = 999.0
		_set_angle(float(REST[shortfall]))


func _where(along: float) -> String:
	var x: float = P.x + along
	if x > EDGE: return " - %.1f m past the east edge of this floor, in the air" % (x - EDGE)
	if x < -EDGE: return " - %.1f m past the west edge of this floor, in the air" % (-EDGE - x)
	return ""


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["WHERE DO THEY MEET?"])
	lines.append("Euclid's fifth: a line falls across two lines; if the two angles on one side are together less than two right angles, the two lines meet on that side. Laid out north of this board: the first line, a point P off it, and lines through P that fall 20°, 10°, 5° and 3° short. A cone stands where each meets the first line. All four can be walked to.")
	var along: float = meets_at(_angle)
	var who := "Your line through P" if _in_lane else "At rest the pink line"
	if along == INF:
		if _in_lane: lines.append("I cannot tell your line from the gold one: closer than %.2f° my reading stops. That threshold is this instrument's. The postulate has none - any shortfall at all, and they meet." % TOLERANCE)
		else: lines.append("At rest the pink line lies on the gold one: no shortfall, and no stake to walk to.")
	elif along > 0.0:
		if along <= FAR: lines.append("%s falls %.2f° short. It meets the first line %.1f m from P%s." % [who, _angle, along, _where(along)])
		else: lines.append("%s falls %.2f° short. They meet %.0f m out. Nobody will walk there to look." % [who, _angle, along])
	else:
		lines.append("%s leans away on this side: here the two angles are together MORE than two right angles, by %.2f°. The lines meet on the other side, %.1f m west of P%s." % [who, -_angle, -along, _where(along)])
	if not _in_lane: lines.append("Walk into the lane between the first line and the gold one, east of P: the pink line follows you. Stand on the first line, then step toward the gold.")
	lines.append("The gold line is the one with no shortfall. Nothing laid on this floor shows that it never meets the first line: the floor ends, the statement does not. It is accepted, not walked. One floor down, the triangle that leans on it is walked on a dome, and its angles no longer add to two right angles.")
	_board.text = "\n".join(lines)


## ---- building, once ----

func _tape(from: Vector3, to: Vector3, phrase: String, paper: Color, wide: float = 0.1) -> void:
	# the printed strip holds 8192 px of print: laid in pieces of eight metres, so the words keep their size
	var length: float = from.distance_to(to)
	var pieces: int = maxi(1, int(ceil(length / 8.0)))
	for i in pieces:
		var a: Vector3 = from.lerp(to, float(i) / float(pieces))
		var b: Vector3 = from.lerp(to, float(i + 1) / float(pieces))
		var strip: MeshInstance3D = Strip.new()
		strip.set("tape_width", wide)
		strip.set("print_paper", paper)
		strip.set("print_source", func(_a: Vector3, _b: Vector3, _length: float) -> String: return phrase)
		add_child(strip)
		strip.set("print_reader", to_global((a + b) * 0.5 + Vector3(0, 1.6, 4.0)))
		strip.set("print_reader_set", true)
		strip.call("draw_surface_path", PackedVector3Array([a, b]), Vector3.UP)


func _flat_line(from: Vector3, to: Vector3, colour: Color, wide: float) -> MeshInstance3D:
	var strip := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(wide, 0.006, 1.0)
	strip.mesh = box
	strip.material_override = _city.flat(colour, 0.6)
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	strip.position = (from + to) * 0.5
	strip.scale = Vector3(1, 1, maxf(0.02, from.distance_to(to)))
	strip.rotation.y = atan2(to.x - from.x, to.z - from.z)
	add_child(strip)
	return strip


func _build_once() -> void:
	# the first line and the gold line, the length of the slab
	_tape(Vector3(WEST, 0.004, BASE_Z), Vector3(EAST, 0.004, BASE_Z), "the first line   ·   ", PAPER)
	_tape(Vector3(WEST, 0.006, GOLD_Z), Vector3(EAST, 0.006, GOLD_Z), "through P, no shortfall   ·   accepted, not walked   ·   ", GOLD)
	# the line that falls across both, at P
	_flat_line(Vector3(P.x, 0.01, BASE_Z - 0.45), Vector3(P.x, 0.01, GOLD_Z + 0.9), Color("3a3d45"), 0.06)
	_city.part(self, "trace_point_ball", Vector3(P.x, 0.0, P.z), 0, Vector3(0.3, 0.3, 0.3), false)
	var name_p: Label3D = _city.sign_post(self, Vector3(P.x, 1.25, P.z))
	name_p.text = "P\na point off the first line"
	name_p.modulate = Color(1.0, 0.93, 0.7)
	_city.floor_words(self, Vector3(P.x - 1.25, 0.014, GOLD_Z - 0.75), "90° + 90°\ntwo right angles", 30, GOLD.lightened(0.3))
	# four lines that fall short, and where each meets the first line
	for degrees in FIXED:
		var along: float = meets_at(degrees)
		var foot := Vector3(P.x + along, 0.0, BASE_Z)
		_flat_line(Vector3(P.x, 0.012, P.z), Vector3(foot.x, 0.012, foot.z), Color("c8402c"), 0.045)
		var cone: Node3D = _city.part(self, "traffic_pyramid_5", foot + Vector3(0, 0, -0.32), 0, Vector3(0.36, 0.56, 0.36), false)
		cone.name = "Met_%d" % int(degrees)
		var tag: Label3D = _city.sign_post(self, foot + Vector3(0, 0.95, -0.32))
		tag.text = "%d° short\nmet after %.1f m" % [int(degrees), along]
		tag.pixel_size = 0.0028
		tag.modulate = Color(1.0, 0.86, 0.82)
		_fixed.append({"degrees": degrees, "along": along, "cone": cone})
	# the pink line and its stake
	_line = MeshInstance3D.new()
	var rod := CylinderMesh.new()
	rod.top_radius = 0.02
	rod.bottom_radius = 0.02
	rod.height = 1.0
	rod.radial_segments = 6
	rod.rings = 1
	_line.mesh = rod
	_line.material_override = _city.flat(PINK, 0.4)
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_line.name = "PinkLine"
	add_child(_line)
	_stake = Node3D.new()
	_stake.name = "Stake"
	add_child(_stake)
	var pole := MeshInstance3D.new()
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.018
	shaft.bottom_radius = 0.018
	shaft.height = 1.7
	shaft.radial_segments = 6
	pole.mesh = shaft
	pole.material_override = _city.flat(PINK, 0.4)
	pole.position = Vector3(0, 0.85, 0)
	_stake.add_child(pole)
	var ball: Node3D = _city.part(_stake, "trace_point_ball", Vector3(0, 1.62, 0), 0, Vector3(0.34, 0.34, 0.34), false)
	var pink: StandardMaterial3D = _city.flat(PINK, 0.4)
	for mesh in ball.find_children("*", "MeshInstance3D", true, false): (mesh as MeshInstance3D).material_override = pink
	_stake_tag = _city.sign_post(_stake, Vector3(0, 2.2, 0))
	_stake_tag.pixel_size = 0.0034
	_stake_tag.modulate = Color(1.0, 0.8, 0.9)
	# where the floor ends
	_city.floor_words(self, Vector3(EAST - 3.2, 0.014, GOLD_Z + 0.42), "the floor ends here. the statement does not.", 30, GOLD.lightened(0.3))
	# the body, and the board south of the lane turned to the arrival
	var sensor := Area3D.new()
	sensor.name = "Reach"
	sensor.collision_layer = 0
	sensor.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = Vector3(EDGE * 2.0 + 2.0, 3.4, 6.0)
	var area := CollisionShape3D.new()
	area.shape = room
	area.position = Vector3(0, 1.7, 0.2)
	sensor.add_child(area)
	add_child(sensor)
	sensor.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _body = b)
	sensor.body_exited.connect(func(b: Node) -> void:
		if b == _body: _body = null)
	_board = _city.board(self, Vector3(0, 0, 2.7), 4.0, 1.45)


## ---- for a test ----

func state() -> Dictionary:
	var along: float = meets_at(_angle)
	var fixed := []
	for row in _fixed:
		var cone: Node3D = row["cone"]
		fixed.append({"degrees": float(row["degrees"]), "along": snappedf(float(row["along"]), 0.001), "cone_x": snappedf(cone.position.x, 0.001), "cone_z": snappedf(cone.position.z, 0.001)})
	return {"shortfall": shortfall, "in_lane": _in_lane, "degrees": snappedf(_angle, 0.001), "withheld": along == INF, "meets_m": (-1.0 if along == INF else snappedf(along, 0.01)),
		"stake_shown": _stake.visible, "stake_x": snappedf(_stake.position.x, 0.01), "on_floor": along != INF and absf(P.x + along) <= EDGE, "gap": gap(), "p": [P.x, P.z], "base_z": BASE_Z,
		"fixed": fixed, "board": _board.text if _board != null else "", "prefab_parts": int(_city.parts), "build_ms": _build_ms}


## A place in the lane: `x` metres east of P, `toward_first` metres from the gold line toward the first line.
func lane_point(x: float, toward_first: float) -> Vector3:
	return to_global(Vector3(P.x + x, 0, GOLD_Z - toward_first))
