extends Node3D
class_name VersionControlTree

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the COMMIT TREE — history drawn not as a line but as a navigable branching SHAPE. A main branch of commit nodes marches left→right along +X (time); a feature branch peels UP (+Z) at an early commit, runs parallel for a few commits, then MERGES back DOWN into main — closing a diamond. A HEAD ring glides commit-by-commit along main, the moving "you are here" of a repository.
# desire: to make version control feel like a place you walk, not a log you scroll — to show that history is a directed graph with forks and joins, and that "where am I" (HEAD) is a position in that graph, not a row number. The branch that leaves and returns is the whole idea: work happens off to the side, then folds back in.
# critical_parameter: HEAD — the current position. Advancing it IS the lesson: a commit is not a moment frozen in a file, it is a node you stand on, with parents behind you and (maybe) children ahead. Checking out = moving the ring.
# triggers: _ready/_read_overrides/_build; _process dwells on each main commit then steps HEAD forward, looping; apply_grid_config rebuilds.
# emerges: a glowing cyan spine with one orange loop arching above it; the HEAD ring pulsing as it walks the spine; short fake hashes under every node so the graph reads as real commits.
# needs: a baseline platform [present]; a main commit row + edges [present]; a feature branch + merge edge forming a diamond [present]; a HEAD ring that animates [present]; 2D-in-3D hash labels + branch names + title [present].
# relationships: a resourcemanagement-sequence artifact (the meta layer — how software is made well); sibling to big_o_complexity (that shows what an algorithm COSTS, this shows how the work that makes it is STRUCTURED over time).
# truth: history is not a line. It branches where work diverges and merges where it rejoins, and the only thing that makes it linear is the story we tell afterwards. A commit graph is the honest shape: a DAG you can stand inside, with HEAD as your foot on one node.

@export var main_commits: int = 7
@export var feature_commits: int = 3
@export var step_seconds: float = 1.1
@export var animate: bool = true
## When >=0, park HEAD at this main commit index (for stills/captures) instead of advancing.
@export var freeze_head: int = -1
@export var emissive: bool = true

const MAIN_COL := Color(0.30, 0.70, 0.90)
const FEAT_COL := Color(0.95, 0.55, 0.20)
const NODE_R := 0.13
const COMMIT_DX := 0.42
const FEATURE_DZ := 0.7
const HEX := "0123456789abcdef"

var _main_nodes: Array = []
var _head_ring: Node3D = null
var _built := false
var _t := 0.0
var _head_idx := 0
var _last_head := -1

func _ready() -> void:
	_read_overrides()
	_build()
	set_process(animate and freeze_head < 0 and not Engine.is_editor_hint())


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_main_nodes.clear(); _head_ring = null
		_built = false
		_build()
		set_process(animate and freeze_head < 0 and not Engine.is_editor_hint())


func _read_overrides() -> void:
	if has_meta("config_main_commits"): main_commits = int(str(get_meta("config_main_commits")))
	if has_meta("config_feature_commits"): feature_commits = int(str(get_meta("config_feature_commits")))
	if has_meta("config_step_seconds"): step_seconds = float(str(get_meta("config_step_seconds")))
	if has_meta("config_freeze_head"): freeze_head = int(str(get_meta("config_freeze_head")))
	if has_meta("config_animate"): animate = str(get_meta("config_animate")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_emissive"): emissive = str(get_meta("config_emissive")).to_lower() in ["true", "1", "yes", "on"]


func _fake_hash(seed_i: int) -> String:
	# Deterministic 4-char hex-ish hash from a commit index.
	var v: int = (seed_i * 2654435761) ^ 0x9e3779b9
	var s := ""
	for k in range(4):
		s += HEX[(v >> (k * 4)) & 0xf]
	return s


func _build() -> void:
	_built = true
	var mc: int = maxi(main_commits, 2)
	var fc: int = clampi(feature_commits, 1, mc - 3)
	var total_w: float = float(mc - 1) * COMMIT_DX
	# Branch points: feature peels off at commit 1, merges back at commit (1 + fc + 1).
	var fork_main: int = 1
	var merge_main: int = mini(fork_main + fc + 1, mc - 1)

	# Baseline platform.
	add_child(_box(Vector3(0, -0.06, 0.0), Vector3(total_w + 0.9, 0.08, FEATURE_DZ + 1.0), _mat(Color(0.15, 0.16, 0.19))))

	# --- MAIN branch: nodes along z=0, marching +X ---
	for i in range(mc):
		var x: float = -total_w * 0.5 + float(i) * COMMIT_DX
		var p := Vector3(x, 0.0, 0.0)
		var node := _sphere(p, NODE_R, _emi(MAIN_COL, 0.9) if emissive else _mat(MAIN_COL))
		add_child(node)
		_main_nodes.append(node)
		if i > 0:
			var prev: Vector3 = Vector3(-total_w * 0.5 + float(i - 1) * COMMIT_DX, 0.0, 0.0)
			add_child(_edge(prev, p, MAIN_COL))
		# Fake-hash label under each commit.
		var hl: MeshInstance3D = BakedText.make_label_mesh(_fake_hash(i), Color(0.78, 0.86, 0.92), Vector2(COMMIT_DX * 0.9, 0.13), 1400, true)
		if hl:
			hl.position = Vector3(x, 0.24, 0.0)
			add_child(hl)

	# --- FEATURE branch: parallel short row at +Z, then merge back ---
	var fork_pos := Vector3(-total_w * 0.5 + float(fork_main) * COMMIT_DX, 0.0, 0.0)
	var merge_pos := Vector3(-total_w * 0.5 + float(merge_main) * COMMIT_DX, 0.0, 0.0)
	var feat_positions: Array = []
	for j in range(fc):
		var fx: float = fork_pos.x + COMMIT_DX + float(j) * COMMIT_DX
		feat_positions.append(Vector3(fx, 0.0, FEATURE_DZ))
	# Edge: main fork node UP into first feature node.
	if feat_positions.size() > 0:
		add_child(_edge(fork_pos, feat_positions[0], FEAT_COL))
	# Feature nodes + connecting edges.
	for j in range(feat_positions.size()):
		var fp: Vector3 = feat_positions[j]
		add_child(_sphere(fp, NODE_R, _emi(FEAT_COL, 0.9) if emissive else _mat(FEAT_COL)))
		if j > 0:
			add_child(_edge(feat_positions[j - 1], fp, FEAT_COL))
		var fhl: MeshInstance3D = BakedText.make_label_mesh(_fake_hash(100 + j), Color(0.96, 0.82, 0.62), Vector2(COMMIT_DX * 0.9, 0.13), 1400, true)
		if fhl:
			fhl.position = Vector3(fp.x, 0.24, FEATURE_DZ)
			add_child(fhl)
	# Merge edge: feature tip DOWN into main merge node (closes the diamond).
	if feat_positions.size() > 0:
		add_child(_edge(feat_positions[feat_positions.size() - 1], merge_pos, FEAT_COL))

	# --- HEAD ring (flattened emissive cylinder) ---
	_head_ring = _ring(_main_nodes[0].position, NODE_R * 2.1)
	add_child(_head_ring)

	# --- Branch name labels ---
	var main_lbl: MeshInstance3D = BakedText.make_label_mesh("main", MAIN_COL.lightened(0.3), Vector2(0.5, 0.16), 1400, true)
	if main_lbl:
		main_lbl.position = Vector3(-total_w * 0.5 - 0.42, 0.0, 0.0)
		add_child(main_lbl)
	var feat_lbl: MeshInstance3D = BakedText.make_label_mesh("feature", FEAT_COL.lightened(0.2), Vector2(0.62, 0.16), 1400, true)
	if feat_lbl:
		feat_lbl.position = Vector3(fork_pos.x + 0.05, 0.0, FEATURE_DZ + 0.5)
		add_child(feat_lbl)

	# --- Title ---
	var title: MeshInstance3D = BakedText.make_label_mesh("VERSION CONTROL", Color(0.95, 0.95, 0.97), Vector2(total_w * 0.7, 0.2), 1400, true)
	if title:
		title.position = Vector3(0, 0.62, 0.0)
		add_child(title)

	# Initial HEAD placement.
	_head_idx = clampi(freeze_head, 0, _main_nodes.size() - 1) if freeze_head >= 0 else 0
	_place_head(_head_idx)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	var idx: int = int(_t / maxf(step_seconds, 0.05)) % maxi(_main_nodes.size(), 1)
	if idx != _last_head:
		_place_head(idx)


func _place_head(idx: int) -> void:
	if _head_ring == null or _main_nodes.is_empty():
		return
	idx = clampi(idx, 0, _main_nodes.size() - 1)
	_head_ring.position = (_main_nodes[idx] as Node3D).position
	_last_head = idx


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


func _sphere(center: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _edge(a: Vector3, b: Vector3, c: Color) -> MeshInstance3D:
	# Thin box spanning from a to b (node-centre to node-centre).
	var d: Vector3 = b - a
	var length: float = d.length()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.035, 0.035, maxf(length, 0.001))
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _emi(c, 0.45) if emissive else _mat(c)
	mi.position = a + d * 0.5
	if length > 0.0001:
		mi.look_at_from_position(mi.position, b, Vector3.UP if absf(d.normalized().dot(Vector3.UP)) < 0.99 else Vector3.RIGHT)
	return mi


func _ring(center: Vector3, radius: float) -> MeshInstance3D:
	# Flattened emissive cylinder acting as the HEAD marker ring.
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.05
	mesh.radial_segments = 24
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _emi(Color(1.0, 0.95, 0.5), 1.6)
	mi.position = center
	mi.rotation_degrees = Vector3(90, 0, 0)
	return mi
