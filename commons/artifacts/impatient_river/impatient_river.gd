extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ImpatientRiver

## Same banks, stones and spark. Compare BFS, Dijkstra and A* using the
## tutorial's printed search code. AStar3D retains topology and availability;
## its native path remains an independent distance-cost oracle in the tests.
## Sinking replans immediately. Changing search rule preserves disabled stones.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const BUTTON_SCENE := preload("res://commons/interactables/push_button.tscn")
const Search := preload("res://doc/book/studies/graphs-through-the-hands/GT_Pathfinding/weighted_route.gd")
const MODES := ["BFS", "DIJKSTRA", "A*"]
var search_mode := 0
var _search = Search.new()
var _route_ids: Array[int] = []
var _places: Array[Vector3] = []

@export var seed: int = 47
@export var pace: float = 0.9           # spark metres per second
@export var link_r: float = 1.05        # stones this close are neighbours

var _astar := AStar3D.new()
var _stones: Array = []                 # {pos, mesh, mat, sunk: bool}
var _bank_a := 0
var _bank_b := 0
var _spark: Node3D
var _route := PackedVector3Array()
var _leg := 0
var _t := 0.0
var _going := true
var _sunk_queue: Array = []
var _readout: Node3D

func _ready() -> void:
	_rng.seed = seed
	_build_water()
	_build_stones()
	_build_spark()
	_build_button()
	_build_plaque()
	_replan()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "pace"]:
		if config_data.has(key):
			set(key, config_data[key])

# --- the river ----------------------------------------------------------------------

func _build_water() -> void:
	var water := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(4.6, 0.05, 2.8)
	water.mesh = wm
	water.position = Vector3(0.0, 0.025, 0.0)
	var mat := _glow_mat(Color(0.04, 0.08, 0.13), 0.3)
	mat.roughness = 0.08
	mat.metallic = 0.5
	water.material_override = mat
	add_child(water)
	for sx in [-2.15, 2.15]:
		var bank := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.5, 0.22, 2.8)
		bank.mesh = bm
		bank.position = Vector3(sx, 0.11, 0.0)
		bank.material_override = _matte_mat(Color(0.14, 0.13, 0.12), 0.9)
		add_child(bank)

func _build_stones() -> void:
	# two bank pads plus a seeded scatter between them, joined where near — the graph
	var pts: Array = [Vector3(-2.0, 0.24, 0.0), Vector3(2.0, 0.24, 0.0)]
	for i in range(11):
		pts.append(Vector3(_rng.randf_range(-1.6, 1.6), 0.16, _rng.randf_range(-1.1, 1.1)))
	for i in range(pts.size()):
		var p: Vector3 = pts[i]
		var stone := MeshInstance3D.new()
		var sm := CylinderMesh.new()
		sm.top_radius = 0.2
		sm.bottom_radius = 0.24
		sm.height = 0.1
		stone.mesh = sm
		stone.position = p
		var mat := _matte_mat(Color(0.55, 0.53, 0.5), 0.8)
		stone.material_override = mat
		add_child(stone)
		_stones.append({"pos": p, "mesh": stone, "mat": mat, "sunk": false})
		_astar.add_point(i, p)
		_places.append(p)
	_bank_a = 0
	_bank_b = 1
	for i in range(pts.size()):
		for j in range(i + 1, pts.size()):
			if pts[i].distance_to(pts[j]) <= link_r:
				_astar.connect_points(i, j)
	# guarantee the banks join the field even if the scatter ran thin near them
	for bank in [0, 1]:
		var best := -1
		var best_d := 99.0
		for j in range(2, pts.size()):
			var d: float = pts[bank].distance_to(pts[j])
			if d < best_d:
				best_d = d
				best = j
		if best >= 0 and not _astar.are_points_connected(bank, best):
			_astar.connect_points(bank, best)

func _build_spark() -> void:
	_spark = Node3D.new()
	add_child(_spark)
	var orb := MeshInstance3D.new()
	var om := SphereMesh.new()
	om.radius = 0.07
	om.height = 0.14
	orb.mesh = om
	orb.material_override = _glow_mat(Color(0.95, 0.85, 0.4), 2.6)
	_spark.add_child(orb)

# --- the commute --------------------------------------------------------------------

func _replan() -> void:
	var from := _bank_a if _going else _bank_b
	var to := _bank_b if _going else _bank_a
	# Reuse exactly the same stones, links and disabled flags for every rule.
	_search.neighbours.clear()
	var blocked: Array[int] = []
	for id in range(_places.size()):
		_search.neighbours.append(Array(_astar.get_point_connections(id)))
		if _astar.is_point_disabled(id):
			blocked.append(id)
	_route_ids = _search.find_path(from, to, blocked) if search_mode == 0 else _search.find_weighted_path(from, to, blocked, _places, search_mode == 2)
	_route.clear()
	for id in _route_ids:
		_route.append(_places[id])
	_leg = 0
	_t = 0.0
	if _route.size() > 0:
		_spark.position = _route[0] + Vector3(0.0, 0.16, 0.0)
	if _readout and _readout.has_method("set_text"):
		var distance := 0.0
		for i in range(_route.size() - 1):
			distance += _route[i].distance_to(_route[i + 1])
		_readout.set_text(MODES[search_mode],
			"%d edges / %.2f m\nexpanded: %s" % [_route.size() - 1, distance, str(_search.visited)] if not _route.is_empty() else "NO ROUTE - restore a stone")

func _on_search_rule() -> void:
	search_mode = (search_mode + 1) % 3
	_replan()

func _process(delta: float) -> void:
	if _route.size() < 2:
		_t += delta
		if _t > 1.5:
			_replan()               # keep asking — a resurfacing stone may reopen the river
		return
	var a := _route[_leg] + Vector3(0.0, 0.16, 0.0)
	var b := _route[_leg + 1] + Vector3(0.0, 0.16, 0.0)
	_t += delta * pace / maxf(a.distance_to(b), 0.05)
	if _t >= 1.0:
		_t = 0.0
		_leg += 1
		if _leg >= _route.size() - 1:
			_going = not _going
			_replan()
		return
	var hop := sin(_t * PI) * 0.14
	_spark.position = a.lerp(b, _t) + Vector3(0.0, hop, 0.0)

# --- sinking and resurfacing --------------------------------------------------------

func _build_button() -> void:
	var btn := BUTTON_SCENE.instantiate()
	btn.name = "SinkStone"
	btn.position = Vector3(-0.38, 0.85, 1.6)
	btn.rotation = Vector3(deg_to_rad(-25.0), 0.0, 0.0)
	btn.set("pressed_color", Color(0.2, 0.5, 0.9))
	btn.set("released_color", Color(0.3, 0.35, 0.4))
	add_child(btn)
	var stem := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.05
	sm.bottom_radius = 0.07
	sm.height = 0.8
	stem.mesh = sm
	stem.position = Vector3(0.0, 0.4, 1.6)
	stem.material_override = _steel_mat(Color(0.3, 0.3, 0.33))
	add_child(stem)
	var shelf := MeshInstance3D.new()
	var shelf_mesh := BoxMesh.new()
	shelf_mesh.size = Vector3(0.95, 0.05, 0.24)
	shelf.mesh = shelf_mesh
	shelf.position = Vector3(0.0, 0.79, 1.6)
	shelf.material_override = stem.material_override
	add_child(shelf)
	if btn.has_signal("pressed"):
		btn.connect("pressed", Callable(self, "_on_sink"))
	else:
		var inner := btn.get_node_or_null("InteractableAreaButton")
		if inner and inner.has_signal("button_pressed"):
			inner.connect("button_pressed", Callable(self, "_on_sink"))
	var rule := BUTTON_SCENE.instantiate()
	rule.name = "SearchRule"
	rule.position = Vector3(0.38, 0.85, 1.6)
	rule.rotation.x = deg_to_rad(-25.0)
	add_child(rule)
	rule.pressed.connect(_on_search_rule)
	for pair in [["SINK STONE", -0.38], ["SEARCH RULE", 0.38]]:
		var label := Label3D.new()
		label.text = pair[0]
		label.position = Vector3(pair[1], 1.05, 1.6)
		label.font_size = 28
		label.pixel_size = 0.002
		add_child(label)

func _on_sink() -> void:
	# sink a stone ON the current route (never a bank) — the cruellest honest choice
	var candidates: Array = []
	for i in range(_route.size()):
		var id := _astar.get_closest_point(_route[i], true)
		if id > 1 and not _stones[id]["sunk"]:
			candidates.append(id)
	if candidates.is_empty():
		for i in range(2, _stones.size()):
			if not _stones[i]["sunk"]:
				candidates.append(i)
	if candidates.is_empty():
		return
	var pick: int = candidates[_rng.randi_range(0, candidates.size() - 1)]
	_stones[pick]["sunk"] = true
	_astar.set_point_disabled(pick, true)
	var mesh: Node3D = _stones[pick]["mesh"]
	mesh.position.y = 0.02
	_stones[pick]["mat"].albedo_color = Color(0.2, 0.24, 0.28)
	_sunk_queue.append(pick)
	# the pool: after three sinkings the oldest stone surfaces again
	if _sunk_queue.size() > 3:
		var back: int = _sunk_queue.pop_front()
		_stones[back]["sunk"] = false
		_astar.set_point_disabled(back, false)
		var bmesh: Node3D = _stones[back]["mesh"]
		bmesh.position.y = _stones[back]["pos"].y
		_stones[back]["mat"].albedo_color = Color(0.55, 0.53, 0.5)
	_replan()

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "RiverPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-2.0, 0.24, 1.35)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("IMPATIENT RIVER",
			"Same river, three questions. BFS counts crossings. Dijkstra counts\ndistance. A* adds an estimate toward the bank. SEARCH RULE compares them.\nSINK STONE changes availability. Replanning does not train a model.")
	_readout = TextScreenScript.new()
	_readout.mode = 2
	_readout.width_m = 0.32
	_readout.position = Vector3(2.0, 0.24, 1.35)
	_readout.rotation.y = deg_to_rad(-38.0)
	add_child(_readout)
