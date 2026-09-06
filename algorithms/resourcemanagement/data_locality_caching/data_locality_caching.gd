extends Node3D
class_name DataLocalityCaching

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the MEMORY HIERARCHY LADDER — six platforms stacked vertically (Registers, L1, L2, L3, RAM, Disk), the gap above each proportional to log(latency) so the climb to far memory is a literal chasm. A glowing probe token climbs from the bottom to a target level and back; because its speed is constant, the height it must climb IS the time it takes IS the cost. Reaching a near level reads HIT in green; reaching far memory reads MISS in red after a long, punishing climb. Where a thing IS costs more than what it is.
# desire: to make data locality visceral — to take the dry fact "cache misses are slow" and turn it into a body experience of distance, so a viewer feels in the legs why a tight loop over contiguous memory flies and a pointer-chase through RAM crawls. The lesson is in the gaps: Registers→L1 is a step, RAM→Disk is a cliff you watch the probe grind up.
# critical_parameter: latency — the nanoseconds to reach each level. It sets the gap heights (log-spaced) AND the climb time. Sweeping the target level up the ladder IS the lesson: the same fetch, six places, six wildly different costs.
# triggers: _ready/_read_overrides/_build; _process climbs the probe toward the cycling target level and pulses the platform on arrival; apply_grid_config rebuilds.
# emerges: a green stub of a step from Registers to L1; a towering void from RAM up to Disk where the probe takes seconds to arrive and the caption flips to MISS red. Colour runs green (near/cheap) to red (far/ruinous).
# needs: a base platform [present]; six level platforms at log-spaced heights [present]; a climbing probe token [present]; 2D-in-3D level labels (name + latency + size) + a HIT/MISS caption + title [present].
# relationships: the cache-locality sibling of big_o_complexity in the resourcemanagement sequence — where Big-O shows how cost grows with the size of the input, this shows how cost grows with the distance of the data. Both teach that an algorithm's real speed is decided by something the source code does not say out loud.
# truth: the slowest part of a program is usually not the arithmetic — it is the waiting for memory to arrive. A value's address can cost a hundred thousand times more than the value itself. Performance is geography.

@export var level_count: int = 6
@export var cycle_seconds: float = 9.0
@export var animate: bool = true
## When >=0, park the probe at this level index (for stills/captures) instead of cycling.
@export var freeze_level: int = -1
@export var emissive: bool = true

const LEVELS := [
	{"name": "Registers", "latency_ns": 0.3, "size": "1 KB", "color": Color(0.25, 0.80, 0.45), "hit": true},
	{"name": "L1", "latency_ns": 1.0, "size": "64 KB", "color": Color(0.50, 0.80, 0.40), "hit": true},
	{"name": "L2", "latency_ns": 4.0, "size": "512 KB", "color": Color(0.75, 0.80, 0.35), "hit": true},
	{"name": "L3", "latency_ns": 12.0, "size": "8 MB", "color": Color(0.90, 0.65, 0.35), "hit": false},
	{"name": "RAM", "latency_ns": 100.0, "size": "16 GB", "color": Color(0.90, 0.45, 0.30), "hit": false},
	{"name": "Disk", "latency_ns": 100000.0, "size": "1 TB", "color": Color(0.90, 0.25, 0.30), "hit": false},
]

const PLATFORM_W := 1.6
const PLATFORM_D := 1.0
const PLATFORM_T := 0.12
const PROBE_SPEED := 1.4   # metres / second — constant, so climb distance == time == cost.
const PROBE_DWELL := 0.9   # seconds paused at the target before returning.

var _platforms: Array = []
var _heights: Array = []
var _probe: MeshInstance3D = null
var _caption_root: Node3D = null
var _caption_labels: Array = []   # one baked HIT/MISS quad per level, toggled.
var _built := false
var _t := 0.0
var _target := 0
var _last_caption := -1

func _ready() -> void:
	_read_overrides()
	_build()
	set_process(animate and freeze_level < 0 and not Engine.is_editor_hint())


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_platforms.clear(); _heights.clear(); _caption_labels.clear()
		_probe = null; _caption_root = null
		_built = false
		_build()
		set_process(animate and freeze_level < 0 and not Engine.is_editor_hint())


func _read_overrides() -> void:
	if has_meta("config_cycle_seconds"): cycle_seconds = float(str(get_meta("config_cycle_seconds")))
	if has_meta("config_freeze_level"): freeze_level = int(float(str(get_meta("config_freeze_level"))))
	if has_meta("config_animate"): animate = str(get_meta("config_animate")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_emissive"): emissive = str(get_meta("config_emissive")).to_lower() in ["true", "1", "yes", "on"]


## Cumulative stack height of level i, gaps proportional to log10(latency) deltas.
## Tuned so Disk lands ~5.5 m up — the RAM->Disk gap is the chasm.
func _compute_heights() -> void:
	_heights.clear()
	var base_y := 0.35           # bottom platform sits a little above the floor.
	var scale := 1.0             # log-decades -> metres (Disk total ~5.5 decades -> ~5.5 m).
	var cum := 0.0
	var prev_log := log(LEVELS[0]["latency_ns"]) / log(10.0)
	for i in LEVELS.size():
		var cur_log: float = log(float(LEVELS[i]["latency_ns"])) / log(10.0)
		if i > 0:
			cum += (cur_log - prev_log) * scale
		prev_log = cur_log
		_heights.append(base_y + cum)


func _build() -> void:
	_built = true
	_compute_heights()
	var n: int = LEVELS.size()
	var top_y: float = float(_heights[n - 1])

	# Spine / backboard so the ladder reads as one structure from far memory down.
	var spine_h: float = top_y + 0.5
	add_child(_box(Vector3(-PLATFORM_W * 0.5 - 0.06, spine_h * 0.5, 0.0),
		Vector3(0.06, spine_h, PLATFORM_D * 0.6),
		_mat(Color(0.14, 0.15, 0.18))))
	# Ground pad under the whole stack.
	add_child(_box(Vector3(0.0, 0.04, 0.0),
		Vector3(PLATFORM_W + 0.4, 0.08, PLATFORM_D + 0.4),
		_mat(Color(0.16, 0.17, 0.20))))

	# Level platforms + labels.
	for i in n:
		var y: float = float(_heights[i])
		var col: Color = LEVELS[i]["color"]
		var plat := _box(Vector3(0.0, y, 0.0), Vector3(PLATFORM_W, PLATFORM_T, PLATFORM_D),
			_emi(col, 0.55) if emissive else _mat(col))
		add_child(plat)
		_platforms.append(plat)
		# Label to the right: "<name>   <latency> ns   <size>".
		var lat_txt: String = _fmt_latency(float(LEVELS[i]["latency_ns"]))
		var txt: String = "%s   %s   %s" % [str(LEVELS[i]["name"]), lat_txt, str(LEVELS[i]["size"])]
		var lbl: MeshInstance3D = BakedText.make_label_mesh(txt, col.lerp(Color(1, 1, 1), 0.25),
			Vector2(2.1, 0.2), 1400, true)
		if lbl:
			lbl.position = Vector3(PLATFORM_W * 0.5 + 1.15, y + 0.07, 0.0)
			add_child(lbl)

	# Probe token — a small glowing cube that climbs the ladder.
	_probe = _box(Vector3.ZERO, Vector3(0.22, 0.22, 0.22), _emi(Color(0.95, 0.97, 0.6), 1.6))
	add_child(_probe)

	# HIT/MISS caption — one baked quad per level (HIT green near, MISS red far), toggled.
	_caption_root = Node3D.new()
	add_child(_caption_root)
	for i in n:
		var is_hit: bool = bool(LEVELS[i]["hit"])
		var cap_txt: String = "HIT" if is_hit else "MISS"
		var cap_col: Color = Color(0.4, 0.9, 0.5) if is_hit else Color(0.95, 0.35, 0.35)
		var cap: MeshInstance3D = BakedText.make_label_mesh(cap_txt, cap_col, Vector2(0.55, 0.22), 1400, true)
		if cap:
			cap.visible = false
			_caption_root.add_child(cap)
		_caption_labels.append(cap)

	# Title baked above the ladder.
	var title: MeshInstance3D = BakedText.make_label_mesh("DATA LOCALITY",
		Color(0.95, 0.95, 0.97), Vector2(2.0, 0.26), 1400, true)
	if title:
		title.position = Vector3(0.0, top_y + 0.7, 0.0)
		add_child(title)

	# Initial pose.
	var start_level: int = freeze_level if freeze_level >= 0 else 0
	_target = clampi(start_level, 0, n - 1)
	_place_probe(float(_heights[_target]))
	_set_caption(_target)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	var n: int = LEVELS.size()
	# Cycle the target level: each level gets an equal slice of cycle_seconds.
	var slot: float = cycle_seconds / float(n)
	var idx: int = int(fmod(_t, cycle_seconds) / slot)
	idx = clampi(idx, 0, n - 1)
	if idx != _target:
		_target = idx

	# Climb the probe toward the target height at constant speed (distance == cost).
	var bottom: float = float(_heights[0])
	var goal: float = float(_heights[_target])
	# Phase within this level's slot, in seconds.
	var local_t: float = fmod(_t, cycle_seconds) - float(_target) * slot
	var climb_dist: float = goal - bottom
	var climb_time: float = climb_dist / PROBE_SPEED
	var y: float
	var arrived := false
	if local_t <= climb_time:
		# Ascending from the bottom.
		y = bottom + local_t * PROBE_SPEED
	elif local_t <= climb_time + PROBE_DWELL:
		# Paused at the target.
		y = goal
		arrived = true
	else:
		# Descending back to the bottom (clamped so we don't go below).
		var down_t: float = local_t - climb_time - PROBE_DWELL
		y = maxf(bottom, goal - down_t * PROBE_SPEED)
	_place_probe(y)

	# Pulse the target platform while the probe is parked on it.
	for i in _platforms.size():
		var base_e: float = 0.55
		if i == _target and arrived:
			base_e = 0.55 + 0.9 * (0.5 + 0.5 * sin(_t * 9.0))
		var mat = _platforms[i].material_override
		if mat is StandardMaterial3D and mat.emission_enabled:
			mat.emission_energy_multiplier = base_e

	_set_caption(_target)


func _place_probe(y: float) -> void:
	if _probe == null:
		return
	_probe.position = Vector3(0.0, y + PLATFORM_T * 0.5 + 0.13, 0.0)


func _set_caption(level: int) -> void:
	if level == _last_caption:
		# Still keep the caption riding the probe height.
		if _caption_root:
			_caption_root.position = Vector3(PLATFORM_W * 0.5 + 0.55, _probe.position.y if _probe else 0.0, 0.0)
		return
	for i in _caption_labels.size():
		if _caption_labels[i]:
			_caption_labels[i].visible = (i == level)
	if _caption_root:
		_caption_root.position = Vector3(PLATFORM_W * 0.5 + 0.55, _probe.position.y if _probe else 0.0, 0.0)
	_last_caption = level


func _fmt_latency(ns: float) -> String:
	if ns < 1.0:
		return "%.1f ns" % ns
	if ns >= 1000.0:
		return "%d us" % int(round(ns / 1000.0))
	return "%d ns" % int(round(ns))


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
