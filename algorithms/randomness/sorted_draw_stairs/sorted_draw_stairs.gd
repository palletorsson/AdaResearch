# sorted_draw_stairs.gd
# The same draws, sorted, as three stairs of planks: the shape of a law under the feet.
#
# @identity
# essence: one table of draws u[k] in (0, 1) goes through three rules - uniform h = u, gaussian h = probit(u),
#   exponential h = -ln(1 - u). In each lane the draws stand as posts in sorted order and planks join one to the
#   next: the walk IS the law's quantile curve. Beside every lane a row of slim poles keeps the same heights in the order they came.
# desire: to feel in the legs what a count shows the eye. An even climb. A climb that is steep, then easy, then
#   steep again. A long flat and then steps too tall to take: the tail of a law is where the legs fail.
# critical_parameter: order - how the planks are laid (sorted | drawn | reversed). `drawn` lays them as they came: no
#   stair, a jumble, and the poles and the planks agree. `reversed` starts the visitor at the tail.
# triggers: stepping on the DRAW AGAIN plate draws a new table (seed + 1). The jumble changes; the three shapes do not.
# emerges: draw again a few times and the poles never repeat, while the uniform lane stays an even stair, the
#   gaussian one keeps its S and the exponential one keeps its cliff. The shape belongs to the rule, not to the draws.
# needs: 6 x 7 m of floor [has when placed]; a body that walks [the tower's walker].
# relationships: the body-scale sibling of [[distribution_sampler]] and [[distribution_comparator]] (three laws from
#   one source) and of [[galton_board]], which it climbs toward. Made of [[plank]], counted, sorted, with heights drawn -
#   the count card (sort with sample) in something a body can stand on. Kin to [[bounded_plank_causeway]].
# truth: No single draw has a shape. Sorted, many of them are a hill you can name - and the same randomness makes a
#   different hill under each rule. (After distribution_comparator: "the same random source produces radically
#   different shapes depending on the rule that channels it", and galton_board: "the bell curve is not imposed".)
# lineage: MATH - order statistics and the quantile function: sort a sample and you have drawn its law; the Lorenz
#   curve, a sorted population as a line you can read inequality from. DESIGN - Playfair's bar chart, 1786: quantity
#   as height; a stair is the uniform law made for legs. ARCHITECTURE - Mayan and ziggurat stairs, whose rise is the
#   message; the garden ramp against the garden stair.
# measured: 2026-11-12, the tower's walker. First build - one flat plank per draw: the walker could not take the first
#   step of two lanes (a 5 cm riser stops it). Rebuilt with the planks joining the draws as slopes.
# history: 2026-11-12. Floor Random_Gaussian held four sampler cabinets, a comparator and a Galton board, all watched
#   at table or wall scale, staged with walls the day before without their code being read. Read as code, they share
#   one idea - a shape appears that no single draw has - and nothing let a body meet that shape. Built from what the
#   tower has earned by this floor: plank, array, sort, sample.

extends Node3D

const Stock := preload("res://commons/artifacts/construction_site/stock.gd")

## How the planks are laid along each lane.
@export_enum("sorted", "drawn", "reversed") var order := "sorted"
@export var seed_value := 20261141      ## a draw where two lanes can be climbed and the third cannot
@export_range(8, 40) var draws := 24
@export var tread := 0.24               ## the run between two draws: about one of the tower's planks
@export var lane_width := 1.1           ## five planks long would be 1.1 m: a plank laid across
@export var lane_pitch := 2.0           ## lane centre to lane centre
@export var height := 1.2               ## H: the full span of the uniform lane

const LAWS := ["uniform", "gaussian", "exponential"]
const BOARD_THICK := .06
var _built: Array[Node] = []
var _last_draw := -10.0
var _timber: Material
var _aged: Material
var _red: Material
var _seed_label: Label3D


func _ready() -> void:
	_read_config()
	_timber = Stock.finish("c9a978", .9)      # the plank's own colour (commons/modular/terms.json `plank`)
	_aged = Stock.finish("76695a", .95)
	_red = Stock.finish("c8452f", .6)
	_fixed()
	_draw()


func _read_config() -> void:
	if has_meta("config_order") and str(get_meta("config_order")) in ["sorted", "drawn", "reversed"]:
		order = str(get_meta("config_order"))
	for key in ["seed_value", "draws"]:
		for meta in ["config_" + key, "config_seed" if key == "seed_value" else ""]:
			if meta != "" and has_meta(meta): set(key, int(str(get_meta(meta)).to_float()))
	for key in ["tread", "lane_width", "lane_pitch", "height"]:
		if has_meta("config_" + key): set(key, str(get_meta("config_" + key)).to_float())


func apply_grid_config(config_data: Dictionary) -> void:
	for key in config_data:
		set_meta("config_" + str(key), config_data[key])
	_read_config()
	if is_inside_tree() and _timber != null:
		_draw()


## The one table every lane is built from.
func _table() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out := PackedFloat32Array()
	for k in draws:
		out.append(clampf(rng.randf(), .004, .996))
	return out


## One rule, one height. The gaussian uses the logistic approximation of the probit: close enough for legs.
func _rule(law: String, u: float) -> float:
	match law:
		"uniform":
			return maxf(.03, u * height)
		"gaussian":
			return clampf(height / 2.0 + log(u / (1.0 - u)) / 1.702 * height / 5.5, .03, height + .25)
	return clampf(-log(1.0 - u) * height / 3.2, .03, 2.3)


## The heights of one lane in the order its planks are laid.
func heights(law: String) -> Array:
	var out := []
	for u in _table():
		out.append(snappedf(_rule(law, u), .001))
	if order != "drawn":
		out.sort()
	if order == "reversed":
		out.reverse()
	return out


func _lane_x(n: int) -> float:
	return (n - (LAWS.size() - 1) / 2.0) * lane_pitch


## One stretch of a lane from a to b: a plank laid across, sloped to join two draws, with its collider.
func _span(host: Node3D, a: Vector3, b: Vector3) -> void:
	var node := Stock.box(host, "Plank", (a + b) / 2.0, Vector3(lane_width, BOARD_THICK, a.distance_to(b) + .02), _timber)
	node.basis = Basis.looking_at((b - a).normalized(), Vector3.UP)


func _lane(n: int, law: String, table: PackedFloat32Array) -> void:
	var host := Node3D.new()
	host.name = "Law_" + law
	add_child(host)
	_built.append(host)
	var x := _lane_x(n)
	var laid: Array = heights(law)
	# the draws stand as posts; the planks join one draw to the next. A body climbs a slope, not a step: the tower's
	# walker was stopped by a 5 cm riser (2026-11-12), so a flat plank per draw was a stair nobody could take.
	_span(host, Vector3(x, .02, .9), Vector3(x, laid[0], 0))
	for k in laid.size():
		var z := -k * tread
		var h: float = laid[k]
		for side in [-1.0, 1.0]:
			var post := Stock.box(host, "Post", Vector3(x + side * (lane_width / 2.0 - .05), h / 2.0, z), Vector3(.04, h, .04), _aged, false)
			post.set_meta("draw_height", h)
		if k + 1 < laid.size():
			_span(host, Vector3(x, h, z), Vector3(x, laid[k + 1], z - tread))
		# the same draw where it CAME: a slim pole at the lane's edge, in the order of the table
		var came := _rule(law, table[k])
		Stock.box(host, "Pole", Vector3(x - lane_width / 2.0 - .14, came / 2.0, z), Vector3(.035, came, .035), _red, false)
	var top: float = laid[laid.size() - 1]
	var far := -(laid.size() - 1) * tread
	_span(host, Vector3(x, top, far), Vector3(x, top, far - .7))
	for side in [-1.0, 1.0]:
		Stock.box(host, "Post", Vector3(x + side * (lane_width / 2.0 - .05), top / 2.0, far - .65), Vector3(.05, top, .05), _aged, false)
	Stock.batch_static(host)      # a few surfaces, not a draw call a plank


func _gate(text: String, x: float) -> void:
	for side in [-1.0, 1.0]:
		Stock.box(self, "GatePost", Vector3(x + side * (lane_width / 2.0 + .04), 1.25, 1.0), Vector3(.06, 2.5, .06), _aged, false)
	var board := Stock.box(self, "GateBoard", Vector3(x, 2.3, 1.0), Vector3(lane_width + .2, .4, .03), Stock.finish("d9cfbd", .9), false)
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = .0011
	label.outline_size = 0
	label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	label.modulate = Color("202329")
	label.position = Vector3(0, 0, .02)
	board.add_child(label)


func _fixed() -> void:
	var how := "sorted" if order == "sorted" else ("as they came" if order == "drawn" else "sorted, tallest first")
	for n in LAWS.size():
		_gate("%s\n%d draws, %s" % [str(LAWS[n]).to_upper(), draws, how], _lane_x(n))
	var plate := Stock.box(self, "DrawAgain", Vector3(0, .02, 2.1), Vector3(.8, .04, .8), _red, false)
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
	_seed_label.position = Vector3(0, .01, 2.75)
	add_child(_seed_label)
	var area := Area3D.new()
	area.name = "DrawAgainArea"
	area.collision_layer = 0
	area.collision_mask = 0xFFFFFFFF
	area.position = Vector3(0, .5, 2.1)
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
	for n in LAWS.size():
		_lane(n, LAWS[n], table)
	if _seed_label != null:
		_seed_label.text = "the red poles: the same %d draws as they came  /  seed %d" % [draws, seed_value]
