extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MarkovGenerator

## @identity
## name: Markov Generator
## tier: applied
## concept: Markov & probabilistic grammars
## truth: what comes next depends only on where you are.

@export var num_states: int = 5
@export var step_seconds: float = 0.5
@export var strip_cap: int = 24
@export var device_height: float = 1.0

var _state_colors: Array[Color] = []
var _state_nodes: Array[MeshInstance3D] = []
var _transitions: Array = []           # Array[Array[float]] row-normalized probabilities
var _current_state: int = 0
var _strip_container: Node3D = null
var _strip_count: int = 0
var _marker: MeshInstance3D = null
var _readout: Label3D = null
var _accum: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_state_colors.clear()
	_state_nodes.clear()
	_transitions.clear()
	_strip_count = 0
	_current_state = 0
	_accum = 0.0

	# Housing — a small device plate
	var base_mat := _steel_mat(Color(0.18, 0.2, 0.26))
	add_child(_box(Vector3(0.0, 0.04, 0.0), Vector3(1.6, 0.08, 0.9), base_mat))

	# Label
	add_child(_billboard_label("MARKOV", Vector3(0.0, device_height * 0.95, 0.0), 26, Color(0.8, 0.9, 1.0)))

	# Palette for states
	var palette: Array[Color] = [
		Color(0.95, 0.4, 0.4),
		Color(0.45, 0.85, 0.5),
		Color(0.4, 0.65, 0.95),
		Color(0.95, 0.85, 0.4),
		Color(0.8, 0.5, 0.9),
		Color(0.5, 0.9, 0.9),
		Color(0.95, 0.65, 0.4),
	]
	var n: int = clampi(num_states, 2, palette.size())
	for i in range(n):
		_state_colors.append(palette[i])

	# State nodes in a row
	var row_y: float = 0.55
	var spacing: float = 1.4 / float(max(n - 1, 1))
	var x0: float = -0.7
	for i in range(n):
		var c: Color = _state_colors[i]
		var pos := Vector3(x0 + float(i) * spacing, row_y, -0.18)
		var node: MeshInstance3D = _sphere(pos, 0.08, _glow_mat(c, 1.4))
		add_child(node)
		_state_nodes.append(node)

	# Faint transition links between adjacent + skip neighbors
	var link_mat := _glow_mat(Color(0.4, 0.45, 0.55), 0.4)
	for i in range(n):
		for j in range(n):
			if i == j:
				continue
			if absi(i - j) <= 2:
				var a: Vector3 = _state_nodes[i].position + Vector3(0.0, -0.02, 0.0)
				var b: Vector3 = _state_nodes[j].position + Vector3(0.0, -0.02, 0.0)
				add_child(_cylinder_between(a, b, 0.004, link_mat))

	# Build random row-normalized transition matrix (biased toward forward motion)
	for i in range(n):
		var row: Array[float] = []
		var total: float = 0.0
		for j in range(n):
			var w: float = _rng.randf_range(0.05, 1.0)
			# bias forward so the chain wanders rather than sticking
			if j == (i + 1) % n:
				w += 0.8
			row.append(w)
			total += w
		for j in range(n):
			row[j] = row[j] / total
		_transitions.append(row)

	# Current-state marker (ring above active state)
	_marker = _torus(_state_nodes[_current_state].position + Vector3(0.0, 0.16, 0.0), 0.07, 0.012, _glow_mat(Color(1.0, 1.0, 1.0), 2.0))
	_marker.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	add_child(_marker)

	# Output strip container (grows along +x in front of device)
	_strip_container = Node3D.new()
	_strip_container.name = "StripContainer"
	_strip_container.position = Vector3(-0.7, 0.2, 0.32)
	add_child(_strip_container)

	# Readout
	_readout = _billboard_label("STATE: 0", Vector3(0.0, device_height * 0.78, 0.0), 18, Color(0.9, 0.95, 1.0))
	add_child(_readout)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	# gentle pulse of active node
	if _state_nodes.size() > 0 and _current_state < _state_nodes.size():
		var s: float = 1.0 + 0.15 * sin(Time.get_ticks_msec() * 0.006)
		_state_nodes[_current_state].scale = Vector3.ONE * s
	if _accum < step_seconds:
		return
	_accum = 0.0
	_step()


func _step() -> void:
	# Sample next state from current row
	if _transitions.is_empty():
		return
	var row: Array = _transitions[_current_state]
	var r: float = _rng.randf()
	var cum: float = 0.0
	var next_state: int = _current_state
	for j in range(row.size()):
		cum += float(row[j])
		if r <= cum:
			next_state = j
			break
	# reset scale of old node
	if _current_state < _state_nodes.size():
		_state_nodes[_current_state].scale = Vector3.ONE
	_current_state = next_state

	# Move marker to new active node
	if _marker != null and _current_state < _state_nodes.size():
		_marker.position = _state_nodes[_current_state].position + Vector3(0.0, 0.16, 0.0)

	# Append a colored box to the output strip
	if _strip_count >= strip_cap:
		for c in _strip_container.get_children():
			_strip_container.remove_child(c)
			c.queue_free()
		_strip_count = 0
	var col: Color = _state_colors[_current_state]
	var bx: float = float(_strip_count) * 0.06
	_strip_container.add_child(_box(Vector3(bx, 0.0, 0.0), Vector3(0.05, 0.05, 0.05), _glow_mat(col, 1.6)))
	_strip_count += 1

	# Update readout
	if _readout != null:
		_readout.text = "STATE: %d" % _current_state
