# bounded_plank_causeway.gd
# Two plank causeways from one table of draws: on one nothing is refused, on the other the ends are held.
#
# @identity
# essence: the same draws r[s][j] in [-1, 1] build both lanes. LEFT, nothing refused: h = e + r * v at all three
#   points of every span, so a span ends where chance left it and the next begins somewhere else - a cliff at every
#   seam. RIGHT, the ends held: h[0] = h[2] = e and only the middle is e + r * v - the planks meet.
# desire: to let a body find out what a bound is for. The walk you can finish is not the one with less chance in it;
#   it is the one where somebody decided in advance where each piece would meet the next.
# critical_parameter: held - which points are agreed on the right lane (ends | middle | all). `middle` agrees a
#   point nobody steps across and the seams break again; `all` refuses everything and the walk is a rule.
# triggers: stepping on the DRAW AGAIN plate draws a new table (seed + 1). Both lanes change; the held posts do not.
# emerges: after a few draws the red posts are the only thing that has never moved, and they are the walk.
# needs: a floor to stand on, 3.6 x 11.6 m [has when placed]; a body that walks and can jump [the tower's walker].
# relationships: the body-scale sibling of [[random_edge_profile]] (five draws, the two outer ones forced equal;
#   here three, so that a span is two planks and a seam comes every 1.6 m - see `measured` below).
#   That work shows the bound as a silhouette; forty-eight of them joined edge to edge are the field on the same
#   floor. Made of [[plank]] (a distance that takes a body you can stand on), counted, with heights drawn.
# truth: a bounded random walk is a negotiation. The interior is free because somebody decided in advance where
#   the ends would be. (The truth is random_edge_profile's, 2025; this work is where a visitor can stand on it.)
# lineage: how the idea has been given form elsewhere. MATH - the Brownian bridge, a random path conditioned to
#   arrive at a fixed value; the spline, whose pieces do as they like inside and must agree at the knots. MUSIC -
#   John Cage's time brackets: a sound may begin and end anywhere inside a window whose limits are fixed. ART -
#   Francois Morellet and Vera Molnar: chance let into a system at a stated dose. DESIGN - Enzo Mari,
#   Autoprogettazione (1974): furniture anyone can build from standard boards. ARCHITECTURE - yatsuhashi, the zigzag
#   plank bridge of Japanese gardens, and stepping stones: irregular pieces, an agreed stride; Aldo van Eyck's
#   Amsterdam playgrounds: a few plain elements that a body completes.
# measured: 2026-11-12, the tower's walker (a 0.2 m capsule at 3 m/s). First build - five points a span, v = 0.28:
#   the walker crossed BOTH lanes; the cliffs were small enough to ride over, so the bound made no difference to a
#   body. Rebuilt with three points a span and v = 0.6; tools/probes/void_standable.gd --walk says what it does now.
# history: 2025-06-09 random_edge_profile is written (a random height profile, ends forced). Grid map
#   Random_Cubes tiles it 6 x 8 as the hall's last encounter, "the bounded edge field". 2026-08-02 its readout axis
#   (relief | plate | column) shows the clamp. In the Void the field became 48 placements on floor 82, black from
#   the spawn point. 2026-11-12 (Palle: "plank + playground + randomness ... as you see fit") the same idea is built
#   at the scale of a body, from what the tower has earned by this floor: plank, array, sample.

extends Node3D

const Stock := preload("res://commons/artifacts/construction_site/stock.gd")

## Which points of each span are agreed on the right lane.
@export_enum("ends", "middle", "all") var held := "ends"
@export var seed_value := 20261112
@export_range(2, 9) var spans := 5
@export var span_length := 1.6          ## metres, two planks
@export var lane_width := 1.1           ## five of the tower's boards
@export var aisle := 1.2                ## clear floor between the lanes
@export var edge_height := 0.75         ## e: the agreed height
@export var variation := 0.6            ## v: how far a draw may leave e
@export var ramp_length := 2.3

const POINTS := 3                       # per span: two ends and a middle (random_edge_profile has five)
const BOARD := Vector2(.22, .06)        # the tower's plank (commons/modular/terms.json `plank`): 22 cm wide, 6 cm thick
var _built: Array[Node] = []
var _last_draw := -10.0
var _timber: Material
var _aged: Material
var _held: Material
var _line: Material
var _seed_label: Label3D


func _ready() -> void:
	_read_config()
	_timber = Stock.finish("c9a978", .9)      # the plank's own colour
	_aged = Stock.finish("76695a", .95)
	_held = Stock.finish("c8452f", .6)
	_line = Stock.finish("c8452f", .5)
	_fixed()
	_draw()


func _read_config() -> void:
	for key in ["held", "seed_value", "spans", "span_length", "lane_width", "aisle", "edge_height", "variation", "ramp_length"]:
		for meta in ["config_" + key, "config_seed" if key == "seed_value" else ""]:
			if meta != "" and has_meta(meta):
				var value = get_meta(meta)
				if key == "held":
					if str(value) in ["ends", "middle", "all"]: held = str(value)
				elif key in ["seed_value", "spans"]:
					set(key, int(str(value).to_float()))
				else:
					set(key, str(value).to_float())


func apply_grid_config(config_data: Dictionary) -> void:
	for key in config_data:
		set_meta("config_" + str(key), config_data[key])
	_read_config()
	if is_inside_tree() and _timber != null:
		_draw()


func _lane_x(side: int) -> float:
	return side * (aisle + lane_width) / 2.0


## The table both lanes are built from: spans x three draws in [-1, 1].
func _table() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rows := []
	for s in spans:
		var row := []
		for j in POINTS:
			row.append(rng.randf_range(-1.0, 1.0))
		rows.append(row)
	return rows


func _height(r: float, j: int, refused: String) -> float:
	match refused:
		"nothing":
			return edge_height + r * variation
		"ends":
			return edge_height + r * variation * sin(PI * j / float(POINTS - 1))      # 0 at both ends
		"middle":
			return edge_height if j == POINTS / 2 else edge_height + r * variation
	return edge_height      # all: everything refused - a rule


func _is_held(j: int, refused: String) -> bool:
	return refused == "all" or (refused == "ends" and (j == 0 or j == POINTS - 1)) or (refused == "middle" and j == POINTS / 2)


## One stretch of the lane from a to b: the tower's boards laid side by side, and one collider under the feet.
func _plank(host: Node3D, title: String, a: Vector3, b: Vector3, material: Material) -> void:
	var length := a.distance_to(b) + .03
	var deck := Node3D.new()
	deck.name = title
	deck.position = (a + b) / 2.0
	deck.basis = Basis.looking_at((b - a).normalized(), Vector3.UP)
	host.add_child(deck)
	var count := maxi(1, int(round(lane_width / BOARD.x)))
	var pitch := lane_width / count
	for n in count:
		Stock.box(deck, "Board", Vector3((n - (count - 1) / 2.0) * pitch, 0, 0), Vector3(pitch - .012, BOARD.y, length), material, false)
	var shape := BoxShape3D.new()
	shape.size = Vector3(lane_width, BOARD.y, length)
	Stock.collision(deck, shape)


func _posts(host: Node3D, x: float, z: float, top: float, agreed: bool) -> void:
	for side in [-1.0, 1.0]:
		var px: float = x + side * (lane_width / 2.0 - .06)
		var thick := .08 if agreed else .05
		var post := Stock.box(host, "HeldPost" if agreed else "Post", Vector3(px, top / 2.0, z), Vector3(thick, top, thick), _held if agreed else _aged, false)
		post.set_meta("held", agreed)      # a sibling of the same name is renamed by the engine: the meta is what says it


func _lane(side: int, refused: String, table: Array) -> void:
	var host := Node3D.new()
	host.name = "Refused_" + refused
	add_child(host)
	_built.append(host)
	var x := _lane_x(side)
	var step := span_length / float(POINTS - 1)
	var first := _height(table[0][0], 0, refused)
	_plank(host, "Ramp", Vector3(x, .025, ramp_length), Vector3(x, first, 0), _timber)
	for s in spans:
		for j in POINTS:
			var z := -(s * span_length + j * step)
			var h := _height(table[s][j], j, refused)
			_posts(host, x, z - (.04 if j == 0 and s > 0 else 0.0) + (.04 if j == POINTS - 1 and s < spans - 1 else 0.0), h, _is_held(j, refused))
			if j < POINTS - 1:
				_plank(host, "Plank", Vector3(x, h, z), Vector3(x, _height(table[s][j + 1], j + 1, refused), z - step), _timber)
	# the datum: one taut line at the agreed height, on both edges of the lane - how far each end missed it
	var far := -spans * span_length
	for edge in [-1.0, 1.0]:
		Stock.tube(host, "Datum", Vector3(x + edge * (lane_width / 2.0 + .03), edge_height, 0), Vector3(x + edge * (lane_width / 2.0 + .03), edge_height, far), .012, _line, false)
	if refused != "nothing":      # only a walk that holds can be given somewhere to arrive
		var last := _height(table[spans - 1][POINTS - 1], POINTS - 1, refused)
		_plank(host, "Arrival", Vector3(x, last, far), Vector3(x, last, far - 1.2), _timber)
		for dz in [-.1, -1.1]:
			_posts(host, x, far + dz, last, true)
	Stock.batch_static(host)      # a few surfaces, not a draw call a board


## A gate at the foot of a lane: the words over the entrance, carried by two posts at the lane's edges.
func _gate(text: String, x: float) -> void:
	var z := ramp_length + .05
	for side in [-1.0, 1.0]:
		Stock.box(self, "GatePost", Vector3(x + side * (lane_width / 2.0 + .04), 1.25, z), Vector3(.06, 2.5, .06), _aged, false)
	var board := Stock.box(self, "GateBoard", Vector3(x, 2.3, z), Vector3(lane_width + .2, .4, .03), Stock.finish("d9cfbd", .9), false)
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = .00135
	label.outline_size = 0
	label.alpha_cut = Label3D.ALPHA_CUT_DISCARD      # a cut-out: no sorting against the tower's other glass and text
	label.modulate = Color("202329")
	label.position = Vector3(0, 0, .02)
	board.add_child(label)


func _fixed() -> void:
	_gate("NOTHING REFUSED\nthree heights drawn for every span", _lane_x(-1))
	_gate("THE ENDS HELD\nthe same draws, both ends at one height" if held == "ends" else
		("THE MIDDLE HELD\nthe same draws, each middle at one height" if held == "middle" else "EVERYTHING REFUSED\nno draw is let in: a rule"), _lane_x(1))
	# DRAW AGAIN: a plate in the aisle. A body that steps on it draws a new table.
	var plate := Stock.box(self, "DrawAgain", Vector3(0, .02, ramp_length - .5), Vector3(.8, .04, .8), _held, false)
	var words := Label3D.new()
	words.text = "DRAW AGAIN"
	words.font_size = 48
	words.pixel_size = .0017
	words.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	words.modulate = Color("f3ece2")
	words.rotation.x = -PI / 2
	words.position = Vector3(0, .025, 0)
	plate.add_child(words)
	_seed_label = Label3D.new()
	_seed_label.font_size = 40
	_seed_label.pixel_size = .0017
	_seed_label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	_seed_label.modulate = Color("202329")
	_seed_label.rotation.x = -PI / 2
	_seed_label.position = Vector3(0, .01, ramp_length + .15)
	add_child(_seed_label)
	var area := Area3D.new()
	area.name = "DrawAgainArea"
	area.collision_layer = 0
	area.collision_mask = 0xFFFFFFFF
	area.position = Vector3(0, .5, ramp_length - .5)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(.8, 1.0, .8)
	shape.shape = box
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_stepped)


func _stepped(body: Node) -> void:
	if not body is CharacterBody3D:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_draw < 1.5:
		return
	_last_draw = now
	seed_value += 1
	_draw()


func _draw() -> void:
	for node in _built:
		if is_instance_valid(node):
			node.queue_free()
	_built.clear()
	var table := _table()
	_lane(-1, "nothing", table)
	_lane(1, held, table)
	if _seed_label != null:
		_seed_label.text = "seed %d" % seed_value


## For probes: the heights of both lanes, as built.
func profile() -> Dictionary:
	var table := _table()
	var out := {"nothing": [], held: []}
	for refused in out:
		for s in spans:
			var row := []
			for j in POINTS:
				row.append(snappedf(_height(table[s][j], j, refused), .001))
			out[refused].append(row)
	return out
