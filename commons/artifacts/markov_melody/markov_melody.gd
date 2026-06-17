extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MarkovMelody
## @identity
## lineage: a Markov chain composing — transition probabilities made audible-as-light
## essence: a token hops note to note by the chain's edges, trailing the tune it just wrote
## truth: memory of one step back is enough to make a melody

@export var state_count: int = 6
@export var melody_cap: int = 12

var _nodes: Array[MeshInstance3D] = []
var _node_pos: Array[Vector3] = []
var _edges: Array = []
var _melody_group: Node3D
var _melody: Array[int] = []
var _cur: int = 0
var _accum: float = 0.0
const NOTE_COLORS := [Color(1.0, 0.3, 0.3), Color(1.0, 0.7, 0.2), Color(0.9, 1.0, 0.3), Color(0.3, 1.0, 0.5), Color(0.3, 0.7, 1.0), Color(0.7, 0.4, 1.0)]


func _ready() -> void:
	_rng.randomize(); _build(); set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children(): remove_child(c); c.queue_free()
	_nodes.clear(); _node_pos.clear(); _edges.clear(); _melody.clear(); _cur = 0
	_build()


func _build() -> void:
	# Ring of state nodes connected by glowing edges; a tool mid-composition.
	_node_pos.clear()
	for i in range(state_count):
		var a: float = TAU * float(i) / float(state_count)
		_node_pos.append(Vector3(cos(a) * 0.42, 0.95, sin(a) * 0.42))
	# Edges along the ring + a couple of skips for a real chain.
	for i in range(state_count):
		_add_edge(i, (i + 1) % state_count)
	_add_edge(0, 3)
	_add_edge(1, 4)
	_nodes.clear()
	for i in range(state_count):
		var node := _sphere(_node_pos[i], 0.06, _matte_mat(NOTE_COLORS[i % NOTE_COLORS.size()] * 0.4))
		add_child(node)
		_nodes.append(node)
	add_child(_billboard_label("MARKOV / one-step memory", Vector3(0, 1.55, 0), 20, Color(0.9, 0.95, 1.0)))
	_melody_group = Node3D.new()
	add_child(_melody_group)
	# Pre-roll a few steps so it reads as already composing.
	_cur = 0
	for n in range(5):
		_advance()
	_relight()
	_draw_melody()


func _add_edge(a: int, b: int) -> void:
	var mi := _cylinder_between(_node_pos[a], _node_pos[b], 0.006, _glow_mat(Color(0.3, 0.35, 0.45), 0.7))
	add_child(mi)
	_edges.append({"a": a, "b": b, "mi": mi})


func _advance() -> int:
	# Hop to a ring neighbor or an occasional skip — the chain's transition.
	var choices: Array[int] = [(_cur + 1) % state_count]
	if _rng.randf() < 0.35:
		choices.append((_cur + 2) % state_count)
	if _cur == 0 and _rng.randf() < 0.5:
		choices.append(3)
	var prev: int = _cur
	_cur = choices[_rng.randi() % choices.size()]
	_melody.append(_cur)
	while _melody.size() > melody_cap:
		_melody.remove_at(0)
	return prev


func _relight() -> void:
	var prev: int = _melody[_melody.size() - 2] if _melody.size() >= 2 else 0
	for i in range(_nodes.size()):
		var lit: bool = (i == _cur)
		_nodes[i].material_override = _glow_mat(NOTE_COLORS[i % NOTE_COLORS.size()], 2.6) if lit else _matte_mat(NOTE_COLORS[i % NOTE_COLORS.size()] * 0.4)
	for e in _edges:
		var took: bool = (e["a"] == prev and e["b"] == _cur) or (e["a"] == _cur and e["b"] == prev)
		e["mi"].material_override = _glow_mat(Color(1.0, 0.9, 0.4), 2.4) if took else _glow_mat(Color(0.3, 0.35, 0.45), 0.7)


func _draw_melody() -> void:
	# Recent notes as a row of bars — the generated tune.
	for c in _melody_group.get_children(): _melody_group.remove_child(c); c.queue_free()
	var x0: float = -0.4
	var dx: float = 0.8 / float(melody_cap)
	for i in range(_melody.size()):
		var note: int = _melody[i]
		var h: float = 0.04 + float(note + 1) / float(state_count) * 0.2
		_melody_group.add_child(_box(Vector3(x0 + (float(i) + 0.5) * dx, 0.6 + h * 0.5, 0.55), Vector3(dx * 0.7, h, 0.05), _glow_mat(NOTE_COLORS[note % NOTE_COLORS.size()], 1.8)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_accum += delta
	if _accum < 0.55: return
	_accum = 0.0
	_advance()
	_relight()
	_draw_melody()
