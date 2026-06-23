extends Node3D
class_name RealtimeVsOffline

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: TWIN PIPELINES, one problem, two clocks. Two conveyor lanes run side by side along +X. The TOP lane is REAL-TIME: work items flow toward a glowing red deadline line, and any item that hasn't finished processing by the time it reaches the line is DROPPED — it flashes red and falls away below the belt. The BOTTOM lane is OFFLINE: the same items, no deadline, each given the time it actually needs — every one completes and exits whole. The deadline does not change the work; it changes which answers you are allowed to keep.
# desire: to make the clock visible as an algorithm-shaping force — to take the dry distinction "render it live vs render it overnight" and turn it into a thing you watch, where the same input stream produces a leaky green-and-red mess on top and a slower, complete, fully-saturated stream on the bottom, so a viewer feels the tradeoff in the body: fast-but-lossy against slow-but-whole.
# critical_parameter: the deadline (realtime_budget) — the fraction of items the top lane is allowed to finish in time. Tightening it is the lesson: a frame budget that drops 40% of work is not a worse algorithm, it is a DIFFERENT one, one that has traded completeness for the right to answer now.
# triggers: _ready/_read_overrides/_build; _process flows every item along its lane and resolves it against the deadline; apply_grid_config rebuilds.
# emerges: on top, a stutter of green survivors punctuated by red items peeling off and dropping; on the bottom, a patient unbroken procession of items filling and exiting. The top lane is never full; the bottom lane never leaks.
# needs: two lane platforms [present]; a red emissive deadline bar on the top lane [present]; flowing work items with a per-item progress fill [present]; 2D-in-3D title + per-lane captions [present].
# relationships: a sibling in the resourcemanagement sequence to big_o_complexity (which shows what an algorithm COSTS) — this shows what a DEADLINE costs; the real-time/offline split is the same cut that separates a game frame from a film frame, a live inference from a batch job.
# truth: there is no single best algorithm — there is the algorithm the clock will allow. Give a problem a deadline and it stops being the same problem; the answer you can compute in time is a different answer than the one you could compute given all the time there is.

@export var item_rate: float = 1.2
## Fraction of real-time items that make the deadline (0..1). Lower = more drops.
@export var realtime_budget: float = 0.6
@export var animate: bool = true
## When true, lay out a static representative frame for stills (no _process).
@export var freeze: bool = false
@export var emissive: bool = true

const LANE_LEN: float = 3.0
const LANE_Z: float = 0.62
const ITEM_SIZE: float = 0.18
const SPAWN_X: float = -1.5
const EXIT_X: float = 1.5
const DEADLINE_X: float = 1.1
const FLOW_SPEED: float = 0.55           # metres/sec an item travels along its lane
const RT_PROC: float = 1.0               # real-time processing "need" baseline
const OFF_PROC: float = 1.9              # offline takes longer per item
const MAX_ITEMS: int = 64

const C_LANE := Color(0.15, 0.16, 0.19)
const C_PENDING := Color(0.62, 0.66, 0.74)
const C_DONE := Color(0.30, 0.78, 0.45)
const C_OFFLINE := Color(0.32, 0.62, 0.90)
const C_DROP := Color(0.92, 0.24, 0.30)
const C_DEADLINE := Color(0.95, 0.20, 0.24)
const C_FILL := Color(0.95, 0.86, 0.45)

var _items: Array = []                   # each: {node, fill, lane:int, x, vy, proc, prog, state:int, deadline:bool}
var _built := false
var _t := 0.0
var _spawn_acc := 0.0
var _seq := 0                            # deterministic per-item index

# state ids
const ST_RUN := 0
const ST_DONE := 1
const ST_DROP := 2


func _ready() -> void:
	_read_overrides()
	_build()
	set_process(animate and not freeze and not Engine.is_editor_hint())


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_items.clear()
		_built = false
		_t = 0.0
		_spawn_acc = 0.0
		_seq = 0
		_build()
		set_process(animate and not freeze and not Engine.is_editor_hint())


func _read_overrides() -> void:
	if has_meta("config_item_rate"): item_rate = float(str(get_meta("config_item_rate")))
	if has_meta("config_realtime_budget"): realtime_budget = clampf(float(str(get_meta("config_realtime_budget"))), 0.0, 1.0)
	if has_meta("config_animate"): animate = str(get_meta("config_animate")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_freeze"): freeze = str(get_meta("config_freeze")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_emissive"): emissive = str(get_meta("config_emissive")).to_lower() in ["true", "1", "yes", "on"]


func _lane_y(lane: int) -> float:
	# top lane (0) sits in +Z, bottom lane (1) in -Z; both at belt height.
	return 0.0


func _lane_z(lane: int) -> float:
	return LANE_Z * 0.5 if lane == 0 else -LANE_Z * 0.5


# Deterministic "does this real-time item make the deadline?" — varies per index,
# no RNG. About realtime_budget fraction return true, spread evenly.
func _rt_survives(idx: int) -> bool:
	var phase: float = fmod(float(idx) * 0.61803398875, 1.0)
	return phase < realtime_budget


# Deterministic processing time per item — small variation by index so items
# don't all resolve at the same point. Real-time survivors need less than the
# deadline allows; real-time drops need more; offline always needs OFF_PROC-ish.
func _proc_time(lane: int, idx: int) -> float:
	var jitter: float = 0.7 + 0.6 * fmod(float(idx) * 0.41421356, 1.0)
	if lane == 0:
		if _rt_survives(idx):
			return RT_PROC * (0.55 + 0.30 * fmod(float(idx) * 0.2718, 1.0))
		return RT_PROC * (1.4 + 0.5 * fmod(float(idx) * 0.3142, 1.0))
	return OFF_PROC * jitter


func _build() -> void:
	_built = true

	# Two lane platforms running along +X.
	for lane in 2:
		var z: float = _lane_z(lane)
		add_child(_box(Vector3(0, -0.06, z), Vector3(LANE_LEN + 0.4, 0.06, LANE_Z * 0.42), _mat(C_LANE)))
		# Low rails to read the belt direction.
		add_child(_box(Vector3(0, -0.02, z + LANE_Z * 0.20), Vector3(LANE_LEN + 0.4, 0.025, 0.02), _mat(Color(0.22, 0.24, 0.28))))
		add_child(_box(Vector3(0, -0.02, z - LANE_Z * 0.20), Vector3(LANE_LEN + 0.4, 0.025, 0.02), _mat(Color(0.22, 0.24, 0.28))))

	# Red emissive deadline bar on the TOP lane (lane 0).
	var dz: float = _lane_z(0)
	add_child(_box(Vector3(DEADLINE_X, 0.18, dz), Vector3(0.03, 0.46, LANE_Z * 0.46),
		_emi(C_DEADLINE, 1.6) if emissive else _mat(C_DEADLINE)))

	# Labels (2D-in-3D).
	var title: MeshInstance3D = BakedText.make_label_mesh("REAL-TIME vs OFFLINE", Color(0.95, 0.95, 0.97), Vector2(1.9, 0.24), 1400, true)
	if title:
		title.position = Vector3(0, 0.74, 0)
		add_child(title)

	var top_cap: MeshInstance3D = BakedText.make_label_mesh("REAL-TIME  deadline 16 ms  drops frames", Color(0.95, 0.80, 0.50), Vector2(1.85, 0.13), 1400, true)
	if top_cap:
		top_cap.position = Vector3(0, 0.40, _lane_z(0) + LANE_Z * 0.30)
		add_child(top_cap)

	var bot_cap: MeshInstance3D = BakedText.make_label_mesh("OFFLINE  no deadline  full quality", Color(0.62, 0.80, 0.98), Vector2(1.85, 0.13), 1400, true)
	if bot_cap:
		bot_cap.position = Vector3(0, 0.40, _lane_z(1) - LANE_Z * 0.30)
		add_child(bot_cap)

	# A small "deadline" tag above the bar.
	var dl_lbl: MeshInstance3D = BakedText.make_label_mesh("deadline", Color(0.98, 0.55, 0.55), Vector2(0.5, 0.11), 1400, true)
	if dl_lbl:
		dl_lbl.position = Vector3(DEADLINE_X, 0.50, _lane_z(0))
		add_child(dl_lbl)

	if freeze:
		_build_frozen_frame()


# Static representative frame for stills: a few items mid-lane, one dropping red,
# one green exiting (top), and the offline lane mid-flow + one exiting.
func _build_frozen_frame() -> void:
	# Top lane: a pending item, a green survivor near the exit, a red drop falling.
	_spawn_frozen(0, -0.7, ST_RUN, 0.35)
	_spawn_frozen(0, 1.35, ST_DONE, 1.0)
	_spawn_frozen(0, DEADLINE_X, ST_DROP, 0.6, -0.55)
	# Bottom lane: two mid-flow, one exiting whole.
	_spawn_frozen(1, -0.5, ST_RUN, 0.45)
	_spawn_frozen(1, 0.4, ST_RUN, 0.8)
	_spawn_frozen(1, 1.4, ST_DONE, 1.0)


func _spawn_frozen(lane: int, x: float, state: int, prog: float, drop_y: float = 0.0) -> void:
	var col: Color = _state_color(lane, state)
	var node := _box(Vector3(x, drop_y, _lane_z(lane)), Vector3(ITEM_SIZE, ITEM_SIZE, ITEM_SIZE),
		_emi(col, 0.7) if emissive else _mat(col))
	add_child(node)
	# Progress fill on +X face.
	var fill := _box(Vector3(x, ITEM_SIZE * 0.5 + drop_y, _lane_z(lane) + ITEM_SIZE * 0.55),
		Vector3(ITEM_SIZE * 0.9 * clampf(prog, 0.0, 1.0), ITEM_SIZE * 0.22, 0.01),
		_emi(C_FILL, 1.0) if emissive else _mat(C_FILL))
	add_child(fill)


func _state_color(lane: int, state: int) -> Color:
	if state == ST_DROP:
		return C_DROP
	if state == ST_DONE:
		return C_DONE if lane == 0 else C_OFFLINE
	return C_PENDING


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	_spawn_acc += delta * item_rate
	while _spawn_acc >= 1.0:
		_spawn_acc -= 1.0
		_spawn_item(0)
		_spawn_item(1)
	_advance_items(delta)


func _spawn_item(lane: int) -> void:
	if _items.size() >= MAX_ITEMS:
		return
	var idx: int = _seq
	_seq += 1
	var col: Color = C_PENDING
	var node := _box(Vector3(SPAWN_X, 0.0, _lane_z(lane)), Vector3(ITEM_SIZE, ITEM_SIZE, ITEM_SIZE),
		_emi(col, 0.7) if emissive else _mat(col))
	add_child(node)
	var fill := _box(Vector3(0, 0, 0), Vector3(0.001, ITEM_SIZE * 0.22, 0.01),
		_emi(C_FILL, 1.0) if emissive else _mat(C_FILL))
	node.add_child(fill)
	fill.position = Vector3(0, 0, ITEM_SIZE * 0.55)
	_items.append({
		"node": node,
		"fill": fill,
		"lane": lane,
		"x": SPAWN_X,
		"vy": 0.0,
		"proc": _proc_time(lane, idx),
		"prog": 0.0,
		"state": ST_RUN,
		"survives": (lane == 1) or _rt_survives(idx),
	})


func _advance_items(delta: float) -> void:
	var dead: Array = []
	for it in _items:
		var lane: int = it["lane"]
		var state: int = it["state"]

		if state == ST_DROP:
			# Falling away below the belt.
			it["vy"] -= 2.6 * delta
			var node_d: MeshInstance3D = it["node"]
			node_d.position.y += it["vy"] * delta
			node_d.rotate_z(delta * 4.0)
			if node_d.position.y < -1.4:
				dead.append(it)
			continue

		# Running or done: flow right.
		it["x"] += FLOW_SPEED * delta
		# Processing progress accumulates as the item travels.
		if state == ST_RUN:
			it["prog"] = minf(it["prog"] + (delta / maxf(it["proc"], 0.05)), 1.0)

		var node: MeshInstance3D = it["node"]
		node.position.x = it["x"]

		# Update progress fill width (base mesh is 0.001 wide; scale it to p·width).
		var fill: MeshInstance3D = it["fill"]
		var p: float = clampf(it["prog"], 0.0, 1.0)
		fill.scale.x = maxf(p * ITEM_SIZE * 0.9, 0.001) / 0.001

		if state == ST_RUN:
			if lane == 0:
				# Real-time: resolve against the deadline line.
				if it["x"] >= DEADLINE_X:
					if it["prog"] >= 0.999 and it["survives"]:
						_set_done(it)
					else:
						_set_drop(it)
				elif it["prog"] >= 0.999 and it["survives"]:
					# Finished before the line — mark green, keep flowing.
					_set_done(it)
			else:
				# Offline: complete whenever processing finishes, no deadline.
				if it["prog"] >= 0.999:
					_set_done(it)

		# Exit at the right end.
		if it["x"] > EXIT_X + 0.25:
			dead.append(it)

	for d in dead:
		_items.erase(d)
		var n: MeshInstance3D = d["node"]
		if is_instance_valid(n):
			n.queue_free()


func _set_done(it: Dictionary) -> void:
	if it["state"] != ST_RUN:
		return
	it["state"] = ST_DONE
	it["prog"] = 1.0
	var col: Color = C_DONE if it["lane"] == 0 else C_OFFLINE
	var node: MeshInstance3D = it["node"]
	node.material_override = _emi(col, 0.9) if emissive else _mat(col)


func _set_drop(it: Dictionary) -> void:
	if it["state"] != ST_RUN:
		return
	it["state"] = ST_DROP
	it["vy"] = 0.0
	var node: MeshInstance3D = it["node"]
	node.material_override = _emi(C_DROP, 1.2) if emissive else _mat(C_DROP)
	var fill: MeshInstance3D = it["fill"]
	if is_instance_valid(fill):
		fill.visible = false


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	return m


func _emi(c: Color, e: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = e
	m.roughness = 0.5
	return m


func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi
