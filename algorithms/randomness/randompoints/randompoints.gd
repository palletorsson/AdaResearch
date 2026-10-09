extends Node3D

# @identity
# essence: candidates are either kept, clustered around a centre, or filtered by pair distance
# question: does a constraint act once, or keep acting after a visitor intervenes?
# boundary: finite rejection search is not a proof of maximal packing
# interaction: compare stand supplies REDRAW, NEW SEED, RULE, RESTORE and LOAD x1/x4
# relationship: the single randompoint continually clips coordinates; these shells only report

enum DistributionType {
	UNIFORM,
	GAUSSIAN,
	BLUE_NOISE,
}

@export var distribution_type: DistributionType = DistributionType.BLUE_NOISE
@export var num_points: int = 30
@export var area_size: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var gaussian_std_fraction: float = 0.25
@export var blue_noise_min_dist: float = 0.25 # Minimum distance for Blue Noise

# Opt-in sampling bench. A seed initializes one stream; the left consumes its
# first uniform draws, then the right continues it. They do not share candidates.
# Shells have radius d/2. The first 220 refusals are drawn, all refusals are counted.
# At stand:none the original unstaged point cloud remains available.
@export_enum("none", "compare") var stand: String = "none"
@export var sampling_seed: int = -1      # -1: the global stream, as shipped; >= 0 pins every draw

const BENCH_TOP: float = 0.80            # the bench's working height
const BENCH_W: float = 2.64
const BENCH_D: float = 0.96
const VOL: float = 0.90                  # each sampled volume: a square of this side...
const VOL_T: float = 0.12                # ...and this thin, so a cloud reads as a plate
const VOL_GAP: float = 0.34
const GHOST_CAP: int = 220               # display budget; the total refusal count is independent

var _rng: RandomNumberGenerator = null
var _stats: Dictionary = {}
var _rejected: Array = []                # candidates the rule refused, in the order drawn
var _attempts: int = 0
var _named_seed: int = 0
var _bench: Node3D = null
var _clouds: Dictionary = {}             # "proposed" / "admitted" -> Node3D
var _points: Dictionary = {}             # the same keys -> Array of point nodes
var _readout: Label3D = null
var _rule: String = "spaced"             # what the right volume is under: spaced | clustered
var _moved: int = 0
var _touching: int = 0
var _dist_asked: bool = false    # did the map name the rule's distance, or is it derived?
var _base_count: int = 24

var point_scene: PackedScene = preload("res://commons/primitives/point/grab_sphere_point_color_with_text.tscn")

func _ready() -> void:
	# Auto-detect type from node name if generic script is used
	var n = name.to_lower()
	if "gaussian" in n:
		distribution_type = DistributionType.GAUSSIAN
	elif "uniform" in n:
		distribution_type = DistributionType.UNIFORM
	elif "randompoints" == n or "blue" in n:
		# Default 'randompoints' is Blue Noise (structured randomness)
		distribution_type = DistributionType.BLUE_NOISE
		
	if sampling_seed >= 0:
		_rng = RandomNumberGenerator.new()
		_rng.seed = sampling_seed
	else:
		randomize()
	if stand == "compare":
		_prepare_bench()
		_build_bench()
		_fill_volumes()
		_update_readout()
		return
	spawn_points()

func spawn_points() -> void:
	var points = []
	var half_extents = area_size * 0.5
	
	match distribution_type:
		DistributionType.UNIFORM:
			points = _generate_uniform(num_points, half_extents)
		DistributionType.GAUSSIAN:
			points = _generate_gaussian(num_points, half_extents)
		DistributionType.BLUE_NOISE:
			points = _generate_blue_noise(num_points, half_extents)
	
	
	for i in range(points.size()):
		var p = point_scene.instantiate()
		p.name = "Point_%d" % i
		add_child(p)
		p.position = points[i]

func _generate_uniform(count: int, extents: Vector3) -> Array:
	var pts = []
	for i in range(count):
		var pos = Vector3(
			_rf(-extents.x, extents.x),
			_rf(-extents.y, extents.y),
			_rf(-extents.z, extents.z)
		)
		pts.append(pos)
	return pts

func _generate_gaussian(count: int, extents: Vector3) -> Array:
	var pts = []
	var sx = extents.x * gaussian_std_fraction
	var sy = extents.y * gaussian_std_fraction
	var sz = extents.z * gaussian_std_fraction
	
	for i in range(count):
		var pos = Vector3(
			clamp(_randn(0.0, sx), -extents.x, extents.x),
			clamp(_randn(0.0, sy), -extents.y, extents.y),
			clamp(_randn(0.0, sz), -extents.z, extents.z)
		)
		pts.append(pos)
	return pts

func _generate_blue_noise(count: int, extents: Vector3) -> Array:
	var pts: Array[Vector3] = []
	var max_attempts = 100
	
	# Attempt to place 'count' points with Dart Throwing
	for i in range(count):
		var placed = false
		
		for attempt in range(max_attempts):
			var candidate = Vector3(
				_rf(-extents.x, extents.x),
				_rf(-extents.y, extents.y),
				_rf(-extents.z, extents.z)
			)
			_attempts += 1
			
			var min_dist = INF
			if pts.is_empty():
				min_dist = INF
			else:
				for existing in pts:
					var d = candidate.distance_to(existing)
					if d < min_dist:
						min_dist = d
			
			# Enforce minimum distance
			if min_dist >= blue_noise_min_dist:
				pts.append(candidate)
				placed = true
				break
			# Retain a bounded visual sample; _attempts counts every candidate.
			if _rejected.size() < GHOST_CAP:
				_rejected.append(candidate)
		
		if not placed:
			# This slot exhausted 100 attempts. Later slots still get their own
			# attempts; failure here proves neither saturation nor optimal packing.
			pass
			
	return pts

## Every draw in this file goes through here. With no seed `_rng` is null and the
## call falls through to the global stream — the same call in the same order as
## before — so an unseeded placement draws exactly what it always drew.
func _rf(a: float, b: float) -> float:
	return _rng.randf_range(a, b) if _rng != null else randf_range(a, b)


func _randn(mean: float, std: float) -> float:
	var u1 = clamp(_rf(0.0, 1.0), 1e-6, 1.0 - 1e-6)
	var u2 = _rf(0.0, 1.0)
	var z = sqrt(-2.0 * log(u1)) * cos(TAU * u2)
	return mean + std * z

## The map's own hand. `stand` asks for the bench, `seed` names the draws, `count`
## the requested population, `size` the sampled volume's side, `dist` the rule's
## minimum distance, `mode` the shipped distribution. Shipped placements send none
## of these, reach none of this, and draw what they always drew.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	var restage: bool = false

	if config.has("stand"):
		var sv: String = str(config["stand"]).strip_edges().to_lower()
		var want: String = "compare" if sv in ["compare", "bench", "pair", "cabinet"] else "none"
		if want != stand:
			stand = want
			restage = true

	if config.has("seed"):
		var sd: int = int(config["seed"])
		if sd != sampling_seed:
			sampling_seed = sd
			restage = true

	if config.has("count"):
		var c: int = int(config["count"])
		if c > 0 and c != num_points:
			num_points = c
			restage = true

	if config.has("size"):
		var sz: float = float(config["size"])
		if sz > 0.05 and not is_equal_approx(sz, area_size.x):
			area_size = Vector3(sz, sz, sz)
			restage = true

	# `radius` is in the grid's CONFIG_PARAM_NAMES; `dist` is not, and #dist:0.22 would be
	# read as a rotation. Either spelling sets the rule's minimum distance explicitly.
	for key in ["radius", "dist"]:
		if config.has(key):
			var d: float = float(config[key])
			if d > 0.0:
				blue_noise_min_dist = d
				_dist_asked = true
				restage = true

	if config.has("mode"):
		var m: String = str(config["mode"]).strip_edges().to_lower()
		if m in ["uniform", "white"]: distribution_type = DistributionType.UNIFORM
		elif m in ["gaussian", "clustered", "pink"]: distribution_type = DistributionType.GAUSSIAN
		elif m in ["blue", "spaced", "distance"]: distribution_type = DistributionType.BLUE_NOISE
		restage = true

	if not restage or not is_inside_tree():
		return
	if stand == "compare":
		_teardown_bench()
		_prepare_bench()
		_build_bench()
		_fill_volumes()
		_update_readout()
	else:
		_teardown_bench()
		for c in get_children():
			if str(c.name).begins_with("Point_"):
				remove_child(c)
				c.queue_free()
		spawn_points()


# ═════════════════════════════════════════════════════════════════════
# THE BENCH — stand:compare. Nothing below runs at stand:none.
# ═════════════════════════════════════════════════════════════════════

## A five-digit name for the draws, so a visitor can say the number out loud and
## get the same two clouds back. Called before anything is generated.
func _prepare_bench() -> void:
	_base_count = num_points
	if sampling_seed < 0:
		var namer := RandomNumberGenerator.new()
		namer.randomize()
		sampling_seed = namer.randi_range(10000, 99999)
	_named_seed = sampling_seed
	_rng = RandomNumberGenerator.new()
	_rng.seed = sampling_seed
	# Derive a default once for this configuration; LOAD keeps that distance fixed.
	# A thin standing slab lets the visitor distinguish individual neighbours.
	area_size = Vector3(area_size.x, area_size.x, VOL_T)
	if not _dist_asked:
		var mean_gap: float = pow(max(0.001, area_size.x * area_size.y * area_size.z) / float(max(1, num_points)), 1.0 / 3.0)
		blue_noise_min_dist = snappedf(0.8 * mean_gap, 0.005)


func _teardown_bench() -> void:
	for k in _points.keys():
		for p in _points[k]:
			if is_instance_valid(p):
				(p as Node).get_parent().remove_child(p)
				(p as Node).queue_free()
	_points.clear()
	_clouds.clear()
	if _bench != null and is_instance_valid(_bench):
		remove_child(_bench)
		_bench.queue_free()
	_bench = null
	_readout = null


## The bench: a table, two equal volumes drawn as frames so nobody has to take
## "matched" on trust, a caption under each, the cased readout, and the panel.
func _build_bench() -> void:
	var HangarKit := load("res://commons/artifacts/_hangar/hangar_kit.gd")
	var pal: Dictionary = HangarKit.finish_palette("rams")
	var shell: StandardMaterial3D = HangarKit.finish_body("rams", pal["body"], 0.10)
	var steel: StandardMaterial3D = HangarKit.worn_metal((pal["body"] as Color).darkened(0.25))
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.11, 0.115, 0.13)
	dark.roughness = 0.85
	_bench = Node3D.new()
	_bench.name = "Bench"
	add_child(_bench)

	var body := StaticBody3D.new()
	body.name = "Table"
	_bench.add_child(body)
	var top: MeshInstance3D = HangarKit.box(Vector3(0, BENCH_TOP - 0.02, 0), Vector3(BENCH_W, 0.04, BENCH_D), steel)
	top.name = "Top"
	body.add_child(top)
	var post: MeshInstance3D = HangarKit.box(Vector3(0, (BENCH_TOP - 0.04) * 0.5, 0), Vector3(BENCH_W * 0.92, BENCH_TOP - 0.04, BENCH_D * 0.62), shell)
	post.name = "Post"
	body.add_child(post)
	var col := CollisionShape3D.new()
	col.name = "Collider"
	var shape := BoxShape3D.new()
	shape.size = Vector3(BENCH_W, BENCH_TOP, BENCH_D)
	col.shape = shape
	col.position = Vector3(0, BENCH_TOP * 0.5, 0)
	body.add_child(col)

	var face: float = BENCH_D * 0.5
	var sign_mesh: MeshInstance3D = HangarKit.stencil("ONE SEED · TWO RULES · ONE VOLUME", Vector2(0.78, 0.038), (pal["accent"] as Color).darkened(0.25))
	if sign_mesh:
		sign_mesh.position = Vector3(0.0, BENCH_TOP + 0.20, face - 0.03)
		_bench.add_child(sign_mesh)

	var vol_size: Vector3 = area_size
	var half: float = vol_size.x * 0.5
	var offs: float = (vol_size.x + VOL_GAP) * 0.5
	for entry in [["proposed", -offs, "AS PROPOSED · every candidate kept"], ["admitted", offs, "AS ADMITTED · no pair under %.2f m" % blue_noise_min_dist]]:
		var key: String = entry[0]
		var cx: float = entry[1]
		var root := Node3D.new()
		root.name = "Volume_%s" % key
		root.position = Vector3(cx, BENCH_TOP + half + 0.06, 0)
		_bench.add_child(root)
		_clouds[key] = root
		# the frame: twelve edges, so the two volumes are visibly the same box
		var edge := StandardMaterial3D.new()
		edge.albedo_color = Color(0.62, 0.66, 0.72)
		edge.roughness = 0.4
		var edge_n: int = 0
		for axis in range(3):
			for a in [-1.0, 1.0]:
				for b in [-1.0, 1.0]:
					var size := Vector3(0.008, 0.008, 0.008)
					var at := Vector3.ZERO
					size[axis] = vol_size[axis]
					at[(axis + 1) % 3] = a * vol_size[(axis + 1) % 3] * 0.5
					at[(axis + 2) % 3] = b * vol_size[(axis + 2) % 3] * 0.5
					var e: MeshInstance3D = HangarKit.box(at, size, edge)
					e.name = "Edge_%d" % edge_n      # every edge its own name: a matched
					edge_n += 1                      # volume has to be measurable, and
					root.add_child(e)                # Godot renames duplicates away
		var cap: MeshInstance3D = HangarKit.stencil(entry[2], Vector2(0.86, 0.042), Color(0.14, 0.15, 0.17))
		if cap:
			cap.name = "Caption_%s" % key
			cap.position = Vector3(cx, BENCH_TOP + 0.085, face - 0.03)
			_bench.add_child(cap)

	# the readout, cased on the bench's front, leaning back for a standing eye
	var plate_root := Node3D.new()
	plate_root.name = "Readout"
	plate_root.set_meta("em_local_instrument", true)
	plate_root.position = Vector3(-0.40, BENCH_TOP - 0.08, face + 0.06)
	plate_root.rotation_degrees = Vector3(-14, 0, 0)
	_bench.add_child(plate_root)
	var plate: MeshInstance3D = HangarKit.box(Vector3.ZERO, Vector3(1.65, 0.46, 0.024), dark)
	plate.name = "Plate"
	plate_root.add_child(plate)
	_readout = Label3D.new()
	_readout.name = "Text"
	_readout.pixel_size = 0.0016
	_readout.font_size = 20
	_readout.line_spacing = 0.5
	_readout.modulate = Color(0.88, 0.94, 1.0)
	_readout.outline_size = 3
	_readout.outline_modulate = Color(0, 0, 0, 1)
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_readout.position = Vector3(-0.785, 0.205, 0.018)
	plate_root.add_child(_readout)

	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	if RackTpl != null:
		var panel: Node3D = RackTpl.create_panel("", [
			[{"type": "button", "label": "REDRAW"}, {"type": "button", "label": "NEW SEED"}],
			[{"type": "button", "label": "RULE"}, {"type": "button", "label": "RESTORE"}],
			[{"type": "button", "label": "LOAD x1 / x4"}],
		], true)
		panel.name = "Panel"
		panel.set_meta("em_local_instrument", true)
		panel.position = Vector3(0.86, BENCH_TOP + 0.22, face + 0.10)
		panel.rotation_degrees = Vector3(-26, 0, 0)
		panel.scale = Vector3(1.4, 1.4, 1.4)
		_bench.add_child(panel)
		var actions := {"Btn_0": func(): redraw(), "Btn_1": func(): new_seed(), "Btn_2": func(): cycle_rule(), "Btn_3": func(): restore(), "Btn_4": func(): cycle_load()}
		for btn_name in actions.keys():
			var btn: Node = panel.find_child(btn_name, true, false)
			if btn == null:
				continue
			var area: Node = btn.get_node_or_null("InteractableAreaButton")
			if area != null and area.has_signal("button_pressed"):
				var action: Callable = actions[btn_name]
				area.button_pressed.connect(func(_b): action.call())

	var watch := Timer.new()
	watch.name = "NeighbourWatch"
	watch.wait_time = 0.25
	watch.autostart = true
	watch.timeout.connect(_watch_neighbours)
	_bench.add_child(watch)


## Both volumes, from the one named seed: the left keeps every candidate the
## uniform draw proposes, the right runs the shipped dart thrower over its own
## draws and keeps what the rule admits, with the refusals left where they fell.
func _fill_volumes() -> void:
	_attempts = 0
	_rejected.clear()
	var extents: Vector3 = area_size * 0.5
	var proposed: Array = _generate_uniform(num_points, extents)
	var admitted: Array = []
	if _rule == "clustered":
		admitted = _generate_gaussian(num_points, extents)
		_attempts = admitted.size()
	else:
		admitted = _generate_blue_noise(num_points, extents)
	_stats = {
		"seed": _named_seed,
		"rule": _rule,
		"requested": num_points,
		"volume": snappedf(area_size.x, 0.01),
		"min_dist": snappedf(blue_noise_min_dist, 0.001),
		"proposed": {"accepted": proposed.size(), "closest": _closest_pair(proposed)},
		"admitted": {"accepted": admitted.size(), "closest": _closest_pair(admitted),
			"refused": _attempts - admitted.size(), "attempts": _attempts,
			"ghosts_shown": _rejected.size(),
			"short": max(0, num_points - admitted.size())},
	}
	for entry in [["proposed", proposed], ["admitted", admitted]]:
		var key: String = entry[0]
		var list: Array = entry[1]
		var root: Node3D = _clouds.get(key)
		if root == null:
			continue
		var made: Array = []
		for i in range(list.size()):
			var p: Node3D = point_scene.instantiate()
			p.name = "%s_%d" % [key.capitalize(), i]
			p.set_meta("home", list[i])
			p.set_meta("cloud", key)
			root.add_child(p)
			p.position = list[i]
			var lbl: Node = p.get_node_or_null("MeshInstance3DSphere/Label3D")
			if lbl != null:
				(lbl as Node3D).visible = false   # the readout carries the numbers; eighty
			_add_shell(p, key)                    # coordinate labels carry only fog
			made.append(p)
		_points[key] = made
	_draw_ghosts()
	_watch_neighbours()


## The refused candidates, drawn small and grey where they fell: the excluded
## neighbourhood made visible without anybody being told what it means.
func _draw_ghosts() -> void:
	var root: Node3D = _clouds.get("admitted")
	if root == null:
		return
	var old: Node = root.get_node_or_null("Refused")
	if old != null:
		root.remove_child(old)
		old.queue_free()
	if _rejected.is_empty():
		return
	var holder := MultiMeshInstance3D.new()
	holder.name = "Refused"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var s := SphereMesh.new()
	s.radius = 0.011
	s.height = 0.022
	s.radial_segments = 8
	s.rings = 4
	mm.mesh = s
	mm.instance_count = _rejected.size()
	for i in range(_rejected.size()):
		mm.set_instance_transform(i, Transform3D(Basis(), _rejected[i]))
	holder.multimesh = mm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.55, 0.56, 0.60, 0.55)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	holder.material_override = gm
	root.add_child(holder)


## The excluded neighbourhood: a shell of HALF the rule's distance, so two legal
## points' shells touch at the limit and never overlap. It rides with the point.
func _add_shell(p: Node3D, key: String) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = "Shell"
	var s := SphereMesh.new()
	s.radius = blue_noise_min_dist * 0.5
	s.height = blue_noise_min_dist
	s.radial_segments = 14
	s.rings = 7
	mesh.mesh = s
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.35, 0.85, 1.0, 0.13) if key == "admitted" else Color(1.0, 0.72, 0.30, 0.13)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = m
	p.add_child(mesh)


## Was the rule kept after birth? Nothing here enforces it: this only looks, a
## few times a second, and says what it sees. A point carried into somebody's
## shell turns both red and is counted.
func _watch_neighbours() -> void:
	var list: Array = _points.get("admitted", [])
	if list.is_empty():
		return
	var bad: Dictionary = {}
	var moved: int = 0
	var touching: int = 0
	for i in range(list.size()):
		var a: Node3D = list[i]
		if not is_instance_valid(a):
			continue
		if (a.position - (a.get_meta("home") as Vector3)).length() > 0.01:
			moved += 1
		for j in range(i + 1, list.size()):
			var b: Node3D = list[j]
			if not is_instance_valid(b):
				continue
			if a.position.distance_to(b.position) < blue_noise_min_dist - 0.001:
				touching += 1
				bad[i] = true
				bad[j] = true
	for i in range(list.size()):
		var p: Node3D = list[i]
		if not is_instance_valid(p):
			continue
		var sh: MeshInstance3D = p.get_node_or_null("Shell")
		if sh == null or sh.material_override == null:
			continue
		var m: StandardMaterial3D = sh.material_override
		m.albedo_color = Color(1.0, 0.22, 0.22, 0.30) if bad.has(i) else Color(0.35, 0.85, 1.0, 0.16)
	if moved != _moved or touching != _touching:
		_moved = moved
		_touching = touching
		_update_readout()


## Every point back to the position it was generated at.
func restore() -> void:
	for k in _points.keys():
		for p in _points[k]:
			if not is_instance_valid(p) or not (p as Node3D).has_meta("home"):
				continue
			# a point that has been carried is a live body again, and a live body puts
			# itself back where physics wants it: freeze first, then place it.
			if p is RigidBody3D:
				var rb: RigidBody3D = p
				rb.freeze = true
				rb.linear_velocity = Vector3.ZERO
				rb.angular_velocity = Vector3.ZERO
			(p as Node3D).position = (p as Node3D).get_meta("home")
	_moved = 0
	_touching = 0
	_watch_neighbours()
	_update_readout()


## The same two clouds again, from the same name.
func redraw() -> void:
	if stand != "compare":
		return
	_rng = RandomNumberGenerator.new()
	_rng.seed = sampling_seed
	_named_seed = sampling_seed
	for k in _points.keys():
		for p in _points[k]:
			if is_instance_valid(p):
				(p as Node).get_parent().remove_child(p)
				(p as Node).queue_free()
	_points.clear()
	_moved = 0
	_touching = 0
	_fill_volumes()
	_update_readout()


## Another pair of clouds, named.
func new_seed() -> void:
	if stand != "compare":
		return
	var namer := RandomNumberGenerator.new()
	namer.randomize()
	sampling_seed = namer.randi_range(10000, 99999)
	while sampling_seed == _named_seed:
		sampling_seed = namer.randi_range(10000, 99999)
	redraw()


## Increase the request without shrinking the spacing to accommodate it.
func cycle_load() -> void:
	if stand != "compare":
		return
	num_points = _base_count * 4 if num_points == _base_count else _base_count
	redraw()


## What the right volume is under: the minimum-distance rule, or the shipped
## gaussian, which crowds the middle instead of spacing anything.
func cycle_rule() -> void:
	if stand != "compare":
		return
	_rule = "clustered" if _rule == "spaced" else "spaced"
	redraw()
	_relabel_admitted()


func _relabel_admitted() -> void:
	if _bench == null:
		return
	var HangarKit := load("res://commons/artifacts/_hangar/hangar_kit.gd")
	for c in _bench.get_children():
		if c is MeshInstance3D and str(c.name) == "Caption_admitted":
			_bench.remove_child(c)
			c.queue_free()
	var text: String = "AS ADMITTED · no pair under %.2f m" % blue_noise_min_dist
	if _rule == "clustered":
		text = "AS ADMITTED · gaussian, no distance rule"
	var cap: MeshInstance3D = HangarKit.stencil(text, Vector2(0.86, 0.042), Color(0.14, 0.15, 0.17))
	if cap:
		cap.name = "Caption_admitted"
		cap.position = Vector3((area_size.x + VOL_GAP) * 0.5, BENCH_TOP + 0.085, BENCH_D * 0.5 - 0.03)
		_bench.add_child(cap)


func _closest_pair(pts: Array) -> float:
	var best: float = INF
	for i in range(pts.size()):
		for j in range(i + 1, pts.size()):
			var d: float = (pts[i] as Vector3).distance_to(pts[j])
			if d < best:
				best = d
	return best if best < INF else -1.0


func _update_readout() -> void:
	if _readout == null or not is_instance_valid(_readout):
		return
	var pr: Dictionary = _stats.get("proposed", {})
	var ad: Dictionary = _stats.get("admitted", {})
	var lines: PackedStringArray = PackedStringArray()
	lines.append("SEED %d · REQUEST %d · %.2f x %.2f x %.2f m" % [
		int(_stats.get("seed", 0)), num_points, area_size.x, area_size.y, area_size.z])
	lines.append("LEFT  kept %d · closest %.3f m" % [int(pr.get("accepted", 0)), float(pr.get("closest", -1.0))])
	lines.append("RIGHT %s · kept %d · closest %.3f m" % [
		_rule, int(ad.get("accepted", 0)), float(ad.get("closest", -1.0))])
	lines.append("%d candidates = %d kept + %d refused" % [
		int(ad.get("attempts", 0)), int(ad.get("accepted", 0)), int(ad.get("refused", 0))])
	lines.append("Ghosts: first %d of %d refusals · spacing %.3f m" % [
		int(ad.get("ghosts_shown", 0)), int(ad.get("refused", 0)), blue_noise_min_dist])
	if int(ad.get("short", 0)) > 0:
		lines.append("%d unfilled: attempt budget exhausted (100 / slot)" % int(ad.get("short", 0)))
	if _rule == "clustered":
		lines.append("moved %d · %d pairs < d - 1 mm; spacing not applied" % [_moved, _touching])
	else:
		lines.append("moved %d · %d pairs < d - 1 mm" % [_moved, _touching])
		lines.append("Spacing applied at birth, not since")
	_readout.text = "\n".join(lines)


## The bench as the room can read it: the seed, the rule, both columns, what the
## rule refused, and what a visitor has done to it since.
func sampling_state() -> Dictionary:
	var out: Dictionary = _stats.duplicate(true)
	out["moved"] = _moved
	out["under_distance"] = _touching
	out["rule_now"] = _rule
	out["shells"] = blue_noise_min_dist * 0.5
	out["dimensions"] = [area_size.x, area_size.y, area_size.z]
	out["candidate_budget_per_slot"] = 100
	out["ghost_positions"] = _rejected.map(func(v): return [v.x, v.y, v.z])
	out["points"] = {}
	out["homes"] = {}
	for k in _points.keys():
		var ps: Array = []
		var homes: Array = []
		for p in _points[k]:
			if is_instance_valid(p):
				ps.append([(p as Node3D).position.x, (p as Node3D).position.y, (p as Node3D).position.z])
				var home: Vector3 = (p as Node3D).get_meta("home")
				homes.append([home.x, home.y, home.z])
		out["points"][k] = ps
		out["homes"][k] = homes
	return out
