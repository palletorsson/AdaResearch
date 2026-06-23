extends Node3D
class_name BigOComplexity

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the COMPLEXITY RACE — six bars, one per Big-O class (O(1), O(log n), O(n), O(n log n), O(n²), O(2ⁿ)), that grow as the input size n sweeps up. At small n they stand nearly level; at large n they diverge violently — the cheap ones barely move, the quadratic and exponential peg the ceiling and flash OFF CHART. The same problem solved six ways, become six different worlds at scale.
# desire: to make scale visible — to take the abstract claim "this algorithm is slower" and turn it into a thing you watch tower over its neighbours, so a viewer feels in the body why the algorithm you choose decides whether the thing runs at all.
# critical_parameter: n — the input size. Sweeping it IS the lesson: small n hides every difference (all bars short), large n is where the choice between O(n) and O(n²) is the difference between instant and never.
# triggers: _ready/_read_overrides/_build; _process sweeps n and rescales every bar each frame; apply_grid_config rebuilds.
# emerges: at n=1 a flat skyline; at n=24 a cliff — O(1) a stub that never grew, O(2ⁿ) pegged and pulsing red off the top. Colour runs green (cheap) to red (ruinous).
# needs: a baseline platform [present]; six scaling bars [present]; a ceiling line + pegged caps [present]; 2D-in-3D class labels + a live n readout + title [present].
# relationships: the flagship of the resourcemanagement sequence (the meta layer — how software is made well); the cost-of-the-algorithm sibling of every other artifact, which shows WHAT an algorithm does where this shows what it COSTS.
# truth: an algorithm is not one thing — it is a curve. Two solutions that agree on every small case can disagree about whether the universe has enough time. Complexity is the shape of that disagreement.

@export var n_max: float = 24.0
@export var max_height: float = 4.0
@export var bar_w: float = 0.4
@export var spacing: float = 0.95
@export var sweep_seconds: float = 8.0
@export var animate: bool = true
## When >0, freeze at this n (for stills/captures) instead of sweeping.
@export var freeze_n: float = 0.0
@export var emissive: bool = true

const CLASSES := [
	{"name": "O(1)", "color": Color(0.30, 0.78, 0.45)},
	{"name": "O(log n)", "color": Color(0.55, 0.80, 0.40)},
	{"name": "O(n)", "color": Color(0.85, 0.80, 0.32)},
	{"name": "O(n log n)", "color": Color(0.92, 0.62, 0.30)},
	{"name": "O(n^2)", "color": Color(0.92, 0.42, 0.30)},
	{"name": "O(2^n)", "color": Color(0.92, 0.24, 0.30)},
]

var _bars: Array = []
var _caps: Array = []
var _n_labels: Dictionary = {}
var _built := false
var _t := 0.0
var _last_n := -1

func _ready() -> void:
	_read_overrides()
	_build()
	set_process(animate and freeze_n <= 0.0 and not Engine.is_editor_hint())


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_bars.clear(); _caps.clear(); _n_labels.clear()
		_built = false
		_build()
		set_process(animate and freeze_n <= 0.0 and not Engine.is_editor_hint())


func _read_overrides() -> void:
	if has_meta("config_n_max"): n_max = float(str(get_meta("config_n_max")))
	if has_meta("config_sweep_seconds"): sweep_seconds = float(str(get_meta("config_sweep_seconds")))
	if has_meta("config_freeze_n"): freeze_n = float(str(get_meta("config_freeze_n")))
	if has_meta("config_animate"): animate = str(get_meta("config_animate")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_emissive"): emissive = str(get_meta("config_emissive")).to_lower() in ["true", "1", "yes", "on"]


func _cost(i: int, n: float) -> float:
	match i:
		0: return 1.0
		1: return maxf(log(n) / log(2.0), 0.0) + 1.0
		2: return n
		3: return n * maxf(log(n) / log(2.0), 1.0)
		4: return n * n
		_: return pow(2.0, minf(n, 40.0))


func _hscale() -> float:
	# Tuned so O(n) reaches ~55% of max_height at n_max — cheap classes stay low, costly ones peg.
	return n_max / (0.55 * max_height)


func _build() -> void:
	_built = true
	var total_w: float = float(CLASSES.size() - 1) * spacing
	# Baseline platform.
	add_child(_box(Vector3(0, -0.04, 0), Vector3(total_w + 1.1, 0.08, 1.3), _mat(Color(0.15, 0.16, 0.19))))
	# Ceiling line (chart top).
	add_child(_box(Vector3(0, max_height, 0), Vector3(total_w + 0.9, 0.015, 0.02), _emi(Color(0.42, 0.44, 0.52), 0.5)))
	# Bars + caps + labels.
	for i in CLASSES.size():
		var x: float = -total_w * 0.5 + float(i) * spacing
		var col: Color = CLASSES[i]["color"]
		var bar := _box(Vector3(x, 0.5, 0.0), Vector3(bar_w, 1.0, bar_w), _emi(col, 0.6) if emissive else _mat(col))
		add_child(bar)
		_bars.append(bar)
		var cap := _box(Vector3(x, max_height + 0.12, 0.0), Vector3(bar_w * 1.15, 0.06, bar_w * 1.15), _emi(Color(1.0, 0.28, 0.3), 1.4))
		cap.visible = false
		add_child(cap)
		_caps.append(cap)
		var lbl: MeshInstance3D = BakedText.make_label_mesh(str(CLASSES[i]["name"]), Color(0.93, 0.93, 0.95), Vector2(spacing * 0.92, 0.17), 1400, true)
		if lbl:
			lbl.position = Vector3(x, -0.14, 0.68)
			add_child(lbl)
	# Title + n readout (pre-baked n labels, toggled — no per-frame re-bake).
	var title: MeshInstance3D = BakedText.make_label_mesh("ALGORITHMIC COMPLEXITY", Color(0.95, 0.95, 0.97), Vector2(total_w * 0.78, 0.22), 1400, true)
	if title:
		title.position = Vector3(0, max_height + 0.52, 0)
		add_child(title)
	for ni in range(1, int(n_max) + 1):
		var nl: MeshInstance3D = BakedText.make_label_mesh("n = %d" % ni, Color(0.92, 0.86, 0.5), Vector2(0.95, 0.2), 1400, true)
		if nl:
			nl.position = Vector3(0, max_height + 0.26, 0)
			nl.visible = false
			add_child(nl)
			_n_labels[ni] = nl
	_update_bars(freeze_n if freeze_n > 0.0 else 1.0)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	var phase: float = fmod(_t, sweep_seconds) / sweep_seconds
	_update_bars(1.0 + phase * (n_max - 1.0))


func _update_bars(n: float) -> void:
	var sc: float = _hscale()
	for i in _bars.size():
		var c: float = _cost(i, n)
		var h: float = clampf(c / sc, 0.12, max_height)
		var bar: MeshInstance3D = _bars[i]
		bar.scale.y = h
		bar.position.y = h * 0.5
		_caps[i].visible = (c / sc) >= max_height
	var ni: int = clampi(int(round(n)), 1, int(n_max))
	if ni != _last_n:
		if _n_labels.has(_last_n):
			_n_labels[_last_n].visible = false
		if _n_labels.has(ni):
			_n_labels[ni].visible = true
		_last_n = ni


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
