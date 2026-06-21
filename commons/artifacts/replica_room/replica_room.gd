extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ReplicaRoom

## @identity
## name: Replica Room — The System Runs Anyway
## concept: Paraconsistent engineering
## tier: large
## lineage: after the foundations crisis, distributed systems became the practical home of
##   paraconsistency. A globe-spanning database cannot be perfectly consistent AND always
##   available across an unreliable network (CAP), so real systems choose EVENTUAL
##   consistency: replicas are allowed to disagree for a while, links flicker, writes
##   propagate lazily — and the system keeps serving the whole time. Contradiction is not
##   an outage; it is a managed, temporary state the engineering is built to tolerate.
## essence: a room you walk into full of distributed replica nodes. Several server pillars
##   each hold a DIFFERENT value (v=3, v=5, v=4...). Links between them flicker on and off
##   as the network partitions and heals. A central "client" beacon keeps getting served
##   answers — sometimes stale, never refused. The disagreement is visible and the room
##   stays lit.
## truth: the replicas disagree and the system runs anyway. Perfect consistency is traded
##   for liveness; correctness becomes a process (they converge eventually) rather than a
##   guarantee held at every instant.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var slate: Color = Color(0.16, 0.18, 0.24)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var serve_color: Color = Color(0.40, 0.95, 0.80)   # the system still serving — teal
@export var disagree_color: Color = Color(0.98, 0.66, 0.30) # divergent values — amber
@export var node_count: int = 5

var _t: float = 0.0
var _node_pos: Array[Vector3] = []
var _node_mats: Array[StandardMaterial3D] = []
var _node_values: Array[int] = []
var _link_mats: Array[StandardMaterial3D] = []
var _link_pairs: Array[Vector2i] = []
var _value_labels: Array[Label3D] = []
var _client_mat: StandardMaterial3D
var _client_pos: Vector3 = Vector3(0.0, 1.2, 0.0)


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("node_count"):
		node_count = int(config["node_count"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_node_pos = []
	_node_mats = []
	_node_values = []
	_link_mats = []
	_link_pairs = []
	_value_labels = []

	# --- room floor (large tier: 7x7, y = -0.05) ---
	var floor_mat: StandardMaterial3D = _matte_mat(Color(0.11, 0.12, 0.15), 0.92)
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(7.0, 0.1, 7.0), floor_mat))
	# faint perimeter wire frame — the formal, cool enclosure
	_floor_frame(3.4, 0.03, _glow_mat(wire_purple, 0.5))

	# --- replica nodes: server pillars around a ring ---
	var n: int = maxi(node_count, 3)
	var radius: float = 2.4
	var steel: StandardMaterial3D = _steel_mat(Color(0.30, 0.32, 0.37))
	var i: int = 0
	while i < n:
		var ang: float = float(i) * TAU / float(n) - PI / 2.0
		var base_p: Vector3 = Vector3(cos(ang) * radius, 0.0, sin(ang) * radius)
		_node_pos.append(base_p + Vector3(0.0, 1.6, 0.0))
		# server pillar
		add_child(_box(base_p + Vector3(0.0, 0.8, 0.0), Vector3(0.5, 1.6, 0.5), _matte_mat(slate, 0.7)))
		# rack rungs (server look)
		var r: int = 0
		while r < 4:
			add_child(_box(base_p + Vector3(0.0, 0.45 + float(r) * 0.32, 0.26), Vector3(0.42, 0.05, 0.02), steel))
			r += 1
		# the value sphere on top — each replica holds a DIFFERENT value
		var val: int = 3 + i % 4   # 3,4,5,6,3,...
		_node_values.append(val)
		var col: Color = disagree_color
		var nm: StandardMaterial3D = _glow_mat(col, 1.0)
		_node_mats.append(nm)
		add_child(_sphere(base_p + Vector3(0.0, 1.75, 0.0), 0.22, nm))
		# value label
		var vl: Label3D = _billboard_label("v=" + str(val), base_p + Vector3(0.0, 2.15, 0.0), 30, cool_white)
		_value_labels.append(vl)
		add_child(vl)
		add_child(_billboard_label("replica " + str(i + 1), base_p + Vector3(0.0, 0.2, 0.0), 18, Color(0.72, 0.78, 0.92)))
		i += 1

	# --- links between adjacent replicas (and a couple of cross links) ---
	i = 0
	while i < n:
		_add_link(i, (i + 1) % n)
		i += 1
	if n >= 5:
		_add_link(0, 2)
		_add_link(1, 3)

	# --- central client beacon: keeps getting served ---
	_client_mat = _glow_mat(serve_color, 1.6)
	add_child(_cylinder(Vector3(0.0, 0.4, 0.0), 0.18, 0.8, _steel_mat(Color(0.34, 0.36, 0.40))))
	add_child(_sphere(_client_pos, 0.26, _client_mat))
	add_child(_torus(_client_pos, 0.42, 0.012, _glow_mat(serve_color, 0.8)))
	add_child(_billboard_label("client", _client_pos + Vector3(0.0, -0.45, 0.0), 20, serve_color))
	add_child(_billboard_label("served", _client_pos + Vector3(0.0, 0.42, 0.0), 18, serve_color))

	# --- overhead label (large tier: y ~ 3.6) ---
	add_child(_billboard_label("REPLICAS DISAGREE — THE SYSTEM RUNS ANYWAY", Vector3(0.0, 3.6, 0.0), 34, cool_white))
	add_child(_billboard_label("eventual consistency, not perfect consistency", Vector3(0.0, 3.25, 0.0), 18, Color(0.80, 0.86, 0.98)))


func _add_link(a: int, b: int) -> void:
	if a >= _node_pos.size() or b >= _node_pos.size():
		return
	var lm: StandardMaterial3D = _glow_mat(wire_purple, 0.7)
	_link_mats.append(lm)
	_link_pairs.append(Vector2i(a, b))
	# drop the link slightly below the value spheres so it reads as a network cable
	var pa: Vector3 = _node_pos[a] - Vector3(0.0, 0.25, 0.0)
	var pb: Vector3 = _node_pos[b] - Vector3(0.0, 0.25, 0.0)
	add_child(_cylinder_between(pa, pb, 0.018, lm))


func _floor_frame(half: float, rad: float, mat: Material) -> void:
	var y: float = 0.02
	var c0: Vector3 = Vector3(-half, y, -half)
	var c1: Vector3 = Vector3(half, y, -half)
	var c2: Vector3 = Vector3(half, y, half)
	var c3: Vector3 = Vector3(-half, y, half)
	add_child(_cylinder_between(c0, c1, rad, mat))
	add_child(_cylinder_between(c1, c2, rad, mat))
	add_child(_cylinder_between(c2, c3, rad, mat))
	add_child(_cylinder_between(c3, c0, rad, mat))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# links flicker — the network partitions and heals
	var li: int = 0
	while li < _link_mats.size():
		var phase: float = _t * 1.3 + float(li) * 1.7
		var up: bool = sin(phase) > -0.2     # partitioned when below threshold
		var lm: StandardMaterial3D = _link_mats[li]
		if lm != null:
			if up:
				lm.emission_energy_multiplier = (0.7 + 0.4 * sin(_t * 5.0 + float(li))) if emissive else 0.3
				lm.albedo_color = wire_purple
				lm.emission = wire_purple
			else:
				# partition: link dims toward dark, value drifts
				lm.emission_energy_multiplier = 0.06 if emissive else 0.02
		li += 1

	# replica values occasionally drift apart, then nudge toward convergence
	var ni: int = 0
	while ni < _node_mats.size():
		var nm: StandardMaterial3D = _node_mats[ni]
		var divergence: float = 0.5 + 0.5 * sin(_t * 0.7 + float(ni) * 1.1)
		if nm != null:
			# more divergence -> warmer/brighter amber; convergence -> cooler
			var col: Color = disagree_color.lerp(serve_color, 1.0 - divergence)
			nm.albedo_color = col
			nm.emission = col
			nm.emission_energy_multiplier = (0.8 + 0.7 * divergence) if emissive else 0.3
		ni += 1

	# client beacon keeps pulsing — it is always being served, even amid disagreement
	if _client_mat != null:
		var serve_pulse: float = 1.3 + 0.5 * sin(_t * 2.2)
		_client_mat.emission_energy_multiplier = serve_pulse if emissive else serve_pulse * 0.3
