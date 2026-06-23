extends Node3D
class_name HardwareCrossSection

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the MACHINE CROSS-SECTION — a stylised cutaway of a computer laid open on a board: CPU, GPU, RAM, CACHE, DISK, each a labelled box wired to a single glowing BUS spine. Data travels the bus as small emissive cubes, and each component breathes them at its own rate — CACHE a bright fast swarm, DISK a rare crawling ember. The algorithm does not run in the abstract; it runs HERE, on parts that move bytes at wildly different speeds.
# desire: to give the algorithm a PLACE. To replace "memory access" and "disk read" as words with a thing you watch — to make the 2000x gap between cache and disk something you feel in the tempo of the tokens, so a viewer understands that WHERE the data lives is the cost.
# critical_parameter: throughput — the bandwidth of each component (CACHE ~1 TB/s … DISK ~0.5 GB/s). It sets how many tokens flow and how fast; the spread between the fastest and slowest link IS the lesson of the memory hierarchy.
# triggers: _ready/_read_overrides/_build; _process advances tokens along the bus by component-specific speed (pooled, recycled, deterministic by index); apply_grid_config rebuilds.
# emerges: a living circuit board — a dense green shimmer over CACHE and CPU, a sluggish red pulse out to DISK, RAM and GPU somewhere between. Frozen, the tokens spread evenly along the bus as a still diagram of flow.
# needs: a baseboard [present]; five labelled components [present]; a central emissive bus [present]; pooled data tokens coloured by link speed [present]; 2D-in-3D title + per-component labels [present].
# relationships: the substrate sibling of the resourcemanagement sequence — where big_o_complexity shows the COST of an algorithm as a curve, this shows the MACHINE that cost is paid on; the ground beneath every other artifact, which run somewhere.
# truth: an algorithm runs on a place, not in the abstract. The same loop is fast over cache and ruinous over disk — a thousandfold difference decided by which box the bytes sit in. Performance is geography.

@export var bus_length: float = 4.0
@export var token_count: int = 24
@export var flow_speed: float = 1.0
@export var animate: bool = true
## When true, freeze tokens spread along the bus (for stills/captures) instead of flowing.
@export var freeze: bool = false
@export var emissive: bool = true

const FAST := Color(0.32, 0.85, 0.45)
const MID := Color(0.90, 0.80, 0.34)
const SLOW := Color(0.92, 0.30, 0.32)

# Components placed along +X (fraction of bus, 0..1), each with a relative throughput.
# throughput drives token speed and how many tokens ride that link.
const COMPONENTS := [
	{"name": "DISK", "label": "DISK  1 TB  ~0.5 GB/s", "frac": 0.04, "size": Vector3(0.55, 0.12, 0.9), "throughput": 0.5, "color": Color(0.40, 0.30, 0.46)},
	{"name": "RAM", "label": "RAM  16 GB  ~25 GB/s", "frac": 0.27, "size": Vector3(0.5, 0.7, 0.55), "throughput": 25.0, "color": Color(0.34, 0.46, 0.66)},
	{"name": "GPU", "label": "GPU  2048 cores  ~500 GB/s", "frac": 0.52, "size": Vector3(1.05, 0.34, 0.7), "throughput": 500.0, "color": Color(0.46, 0.36, 0.62)},
	{"name": "CACHE", "label": "CACHE  ~1 TB/s", "frac": 0.74, "size": Vector3(0.34, 0.30, 0.5), "throughput": 1000.0, "color": Color(0.30, 0.60, 0.52)},
	{"name": "CPU", "label": "CPU  8 cores  ~50 GB/s", "frac": 0.92, "size": Vector3(0.62, 0.30, 0.62), "throughput": 50.0, "color": Color(0.52, 0.40, 0.30)},
]

var _tokens: Array = []
var _token_data: Array = []
var _built := false
var _t := 0.0

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
		_tokens.clear(); _token_data.clear()
		_built = false
		_build()
		set_process(animate and not freeze and not Engine.is_editor_hint())


func _read_overrides() -> void:
	if has_meta("config_bus_length"): bus_length = float(str(get_meta("config_bus_length")))
	if has_meta("config_token_count"): token_count = int(str(get_meta("config_token_count")))
	if has_meta("config_flow_speed"): flow_speed = float(str(get_meta("config_flow_speed")))
	if has_meta("config_animate"): animate = str(get_meta("config_animate")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_freeze"): freeze = str(get_meta("config_freeze")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_emissive"): emissive = str(get_meta("config_emissive")).to_lower() in ["true", "1", "yes", "on"]


func _x_at(frac: float) -> float:
	# Map a 0..1 fraction to a world X along the bus, centred on origin.
	return -bus_length * 0.5 + clampf(frac, 0.0, 1.0) * bus_length


func _speed_color(throughput: float) -> Color:
	# Fast links green, slow links red, log-scaled across the 0.5 .. 1000 spread.
	var lo: float = log(0.5)
	var hi: float = log(1000.0)
	var f: float = clampf((log(maxf(throughput, 0.5)) - lo) / (hi - lo), 0.0, 1.0)
	if f < 0.5:
		return SLOW.lerp(MID, f * 2.0)
	return MID.lerp(FAST, (f - 0.5) * 2.0)


func _seg_speed(throughput: float) -> float:
	# Normalised travel speed for a link of given throughput (log-scaled, kept readable).
	var lo: float = log(0.5)
	var hi: float = log(1000.0)
	var f: float = clampf((log(maxf(throughput, 0.5)) - lo) / (hi - lo), 0.0, 1.0)
	return 0.12 + f * 0.88


func _build() -> void:
	_built = true
	var seg_count: int = COMPONENTS.size() - 1
	# Baseboard (the cutaway plate).
	add_child(_box(Vector3(0, -0.06, 0), Vector3(bus_length + 0.9, 0.12, 1.5), _mat(Color(0.13, 0.14, 0.17))))
	# Bus spine — a long thin emissive channel running along +X.
	add_child(_box(Vector3(0, 0.02, 0), Vector3(bus_length + 0.3, 0.06, 0.1), _emi(Color(0.40, 0.74, 0.92), 0.9) if emissive else _mat(Color(0.40, 0.74, 0.92))))

	# Components: a labelled box each, with on-top detail (cores / sticks).
	for comp in COMPONENTS:
		var cx: float = _x_at(comp["frac"])
		var sz: Vector3 = comp["size"]
		var col: Color = comp["color"]
		var body := _box(Vector3(cx, 0.08 + sz.y * 0.5, 0.0), sz, _emi(col, 0.32) if emissive else _mat(col))
		add_child(body)
		# Stub connecting the component down to the bus.
		add_child(_box(Vector3(cx, 0.06, 0.0), Vector3(0.08, 0.08, 0.18), _emi(Color(0.40, 0.74, 0.92), 0.7)))
		_build_detail(str(comp["name"]), cx, sz, col)
		# Component label in front of each (on +Z face of the board).
		var lbl: MeshInstance3D = BakedText.make_label_mesh(str(comp["label"]), Color(0.93, 0.93, 0.95), Vector2(0.95, 0.16), 1400, true)
		if lbl:
			lbl.position = Vector3(cx, -0.02, 0.8)
			add_child(lbl)

	# Token pool — small emissive cubes that ride the bus, coloured per link speed.
	var tcount: int = maxi(token_count, 1)
	for i in tcount:
		var tk := _box(Vector3(0, 0.07, 0.0), Vector3(0.09, 0.09, 0.09), _emi(FAST, 1.4))
		add_child(tk)
		_tokens.append(tk)
		# Assign each token to a bus segment (round-robin), recording its link.
		var seg: int = i % maxi(seg_count, 1)
		var a: Dictionary = COMPONENTS[seg]
		var b: Dictionary = COMPONENTS[seg + 1] if seg + 1 < COMPONENTS.size() else COMPONENTS[seg]
		var thr: float = minf(float(a["throughput"]), float(b["throughput"]))
		var col2: Color = _speed_color(thr)
		(tk.material_override as StandardMaterial3D).albedo_color = col2
		(tk.material_override as StandardMaterial3D).emission = col2
		# Deterministic phase offset by index — no RNG.
		var phase: float = float(i) / float(tcount)
		_token_data.append({
			"x0": _x_at(float(a["frac"])),
			"x1": _x_at(float(b["frac"])),
			"speed": _seg_speed(thr),
			"phase": phase,
		})

	# Title above.
	var title: MeshInstance3D = BakedText.make_label_mesh("HARDWARE", Color(0.95, 0.95, 0.97), Vector2(bus_length * 0.5, 0.24), 1400, true)
	if title:
		title.position = Vector3(0, 1.3, 0)
		add_child(title)

	_update_tokens(0.0 if freeze else 0.0)
	if freeze:
		_update_tokens(0.0)


func _build_detail(name: String, cx: float, sz: Vector3, col: Color) -> void:
	var top_y: float = 0.08 + sz.y
	var detail_mat := _emi(col.lightened(0.25), 0.5) if emissive else _mat(col.lightened(0.25))
	match name:
		"CPU":
			# 2x2 grid of small raised cores.
			var gx := [-0.13, 0.13]
			var gz := [-0.13, 0.13]
			for dx in gx:
				for dz in gz:
					add_child(_box(Vector3(cx + dx, top_y + 0.03, dz), Vector3(0.16, 0.06, 0.16), detail_mat))
		"GPU":
			# Dense 6x3 row of tiny cores.
			for ix in range(6):
				for iz in range(3):
					var ddx: float = -0.42 + float(ix) * 0.168
					var ddz: float = -0.22 + float(iz) * 0.22
					add_child(_box(Vector3(cx + ddx, top_y + 0.02, ddz), Vector3(0.1, 0.04, 0.1), detail_mat))
		"RAM":
			# Three upright thin stick boxes (the body itself is one; add two more).
			for sx in [-0.16, 0.0, 0.16]:
				add_child(_box(Vector3(cx + sx, 0.08 + sz.y * 0.5, 0.0), Vector3(0.1, sz.y * 0.98, 0.42), detail_mat))
		"CACHE":
			# A small bright tile on top (fastest — glows hardest).
			add_child(_box(Vector3(cx, top_y + 0.02, 0.0), Vector3(0.24, 0.05, 0.36), _emi(FAST, 1.0) if emissive else _mat(FAST)))
		"DISK":
			# A flat platter ring suggestion — a thin disc line on top.
			add_child(_box(Vector3(cx, top_y + 0.02, 0.0), Vector3(sz.x * 0.7, 0.03, sz.z * 0.7), detail_mat))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta * flow_speed
	_update_tokens(_t)


func _update_tokens(t: float) -> void:
	for i in _tokens.size():
		var d: Dictionary = _token_data[i]
		var u: float
		if freeze:
			# Spread evenly along each segment for a still diagram.
			u = d["phase"]
		else:
			u = fmod(t * float(d["speed"]) + float(d["phase"]), 1.0)
		var tk: MeshInstance3D = _tokens[i]
		tk.position.x = lerpf(float(d["x0"]), float(d["x1"]), u)
		tk.position.y = 0.07


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
