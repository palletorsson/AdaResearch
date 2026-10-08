extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name RhizomeGrower

## @identity
## name: Rhizome Grower — No Named Root
## concept: proximity graphs, birth order, degree and connected components
## essence: new nodes sample a fixed annulus and connect to earlier neighbours.
## truth: no designated root does not imply equal degree, influence or resilience.
## Interactive placements replay the same positions with one or three links and
## permit a temporary node removal. No automatic repair or social inference.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var slate: Color = Color(0.20, 0.23, 0.30)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var grow_teal: Color = Color(0.35, 0.88, 0.80)     # warm constructive accent
@export var interactive: bool = false
@export var sample_seed: int = 47
@export var max_nodes: int = 40
@export var links_per_node: int = 3                        # connect each new shoot to several
@export var grow_period: float = 0.4                       # seconds between sprouts
@export var spread: float = 0.36                           # cloud radius

var _t: float = 0.0
var _positions: Array = []       # Vector3 node positions (local, around _origin)
var _node_field: MultiMeshInstance3D
var _edge_field: MultiMeshInstance3D
var _edges: Array = []           # {a:int, b:int}
var _node_total: int = 0
var _edge_total: int = 0
var _readout: Label3D
var _accum: float = 0.0
var _origin := Vector3(0.0, 1.05, 0.0)
var _owned: Array[Node] = []
var _samples: Array[Vector3] = []
var _active: Array[bool] = []
var _selected: int = 0
var _paused: bool = false
var _controls: Node3D
var _detail: Label3D
var _selection: MeshInstance3D
var _degrees: Array[int] = []
var _components: int = 0
var _visible_edges: int = 0



func _ready() -> void:
	_rng.randomize()
	_rebuild()
	set_process(true)


func apply_grid_config(config: Dictionary) -> void:
	for key in ["interactive", "emissive"]:
		if config.has(key): set(key,str(config[key]).to_lower() in ["true","1"])
	if config.has("max_nodes"): max_nodes = clampi(int(config.max_nodes),2,80)
	if config.has("links_per_node"): links_per_node = clampi(int(config.links_per_node),1,3)
	if config.has("grow_period"): grow_period = clampf(float(config.grow_period),.1,10)
	if config.has("spread"): spread = clampf(float(config.spread),.15,1.2)
	if config.has("sample_seed"): sample_seed = int(config.sample_seed)
	if is_node_ready(): _rebuild()


func _rebuild() -> void:
	for child in _owned:
		if is_instance_valid(child):
			remove_child(child)
			child.queue_free()
	_owned.clear()
	var external: Array[Node] = get_children()
	_controls = null
	_detail = null
	_selection = null
	_readout = null
	_build()
	for child in get_children():
		if child not in external: _owned.append(child)


func _node_mm() -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = SphereMesh.new()
	mm.instance_count = max_nodes
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = not interactive and emissive
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.6 if emissive else 0.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if interactive else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mi.material_override = mat
	return mi


func _edge_mm() -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.006
	cyl.bottom_radius = 0.006
	cyl.height = 1.0
	mm.mesh = cyl
	mm.instance_count = max_nodes * 3
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = not interactive and emissive
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.5 if emissive else 0.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if interactive else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mi.material_override = mat
	return mi


func _build() -> void:
	_positions = []
	_edges = []
	_node_total = 0
	_edge_total = 0
	_accum = 0.0
	_t = 0.0
	_active.clear()
	_samples.clear()
	_selected = 0
	_paused = false
	_origin = Vector3(0,1.22 if interactive else 1.05,0)
	if interactive: _rng.seed = sample_seed
	# The first two samples are central; later ones lie in a fixed annulus.
	for i in range(max_nodes):
		if i < 2:
			_samples.append(Vector3(_rng.randf_range(-.05,.05),0,_rng.randf_range(-.05,.05)))
		else:
			var angle: float = _rng.randf_range(0,TAU)
			var radius: float = _rng.randf_range(spread*.4,spread)
			_samples.append(Vector3(cos(angle)*radius,_rng.randf_range(-.06,.06),sin(angle)*radius))

	# --- compact device body (~1 m) ---
	add_child(_box(Vector3(0.0, 0.4, 0.0), Vector3(1.0, 0.12, 0.7), _matte_mat(slate, 0.85, 0.15)))
	add_child(_cylinder(Vector3(0.0, 0.66, 0.0), 0.05, 0.5, _steel_mat(Color(0.34, 0.36, 0.42))))
	add_child(_torus(_origin, spread + 0.03, 0.006, _glow_mat(wire_purple, 0.9)))

	# --- node + edge MultiMesh fields (never MeshInstance3D per element) ---
	_node_field = _node_mm()
	add_child(_node_field)
	_edge_field = _edge_mm()
	add_child(_edge_field)
	_clear_fields()

	_add_node(_samples[0])
	_add_node(_samples[1])
	_readout = _fixed_label("",Vector3(-1.2,1.4,.15),28,.0017)
	add_child(_readout)
	if interactive:
		_build_controls()
	else:
		_readout.position = _origin+Vector3(0,.65,0)
	_refresh_graph()


func _clear_fields() -> void:
	var nm: MultiMesh = _node_field.multimesh
	var i: int = 0
	while i < nm.instance_count:
		nm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(0.0001, 0.0001, 0.0001)), _origin))
		nm.set_instance_color(i, Color(0, 0, 0, 0))
		i += 1
	var em: MultiMesh = _edge_field.multimesh
	var k: int = 0
	while k < em.instance_count:
		em.set_instance_transform(k, Transform3D(Basis().scaled(Vector3(0.0001, 0.0001, 0.0001)), _origin))
		em.set_instance_color(k, Color(0, 0, 0, 0))
		k += 1


func _add_node(local_pos: Vector3) -> int:
	if _node_total >= max_nodes:
		return -1
	var idx: int = _node_total
	_positions.append(local_pos)
	_active.append(true)
	var nm: MultiMesh = _node_field.multimesh
	var world: Vector3 = _origin + local_pos
	var s: float = .07 if interactive else .03
	nm.set_instance_transform(idx, Transform3D(Basis().scaled(Vector3(s, s, s)), world))
	# colour by birth order: cool early -> warm teal as the mat thickens (no node is "the" root)
	var f: float = float(idx) / float(max_nodes)
	nm.set_instance_color(idx, cool_white.lerp(grow_teal, f))
	_node_total += 1
	return idx


func _add_edge(a: int, b: int) -> void:
	var em: MultiMesh = _edge_field.multimesh
	if _edge_total >= em.instance_count:
		return
	var pa: Vector3 = _origin + Vector3(_positions[a])
	var pb: Vector3 = _origin + Vector3(_positions[b])
	var mid: Vector3 = (pa + pb) * 0.5
	var len: float = maxf(pa.distance_to(pb), 0.001)
	var basis: Basis = _basis_y_to(pb - pa)
	basis = basis * Basis.from_scale(Vector3(1.0, len, 1.0))
	em.set_instance_transform(_edge_total, Transform3D(basis, mid))
	em.set_instance_color(_edge_total, wire_purple)
	_edges.append({"a": a, "b": b})
	_edge_total += 1


func _nearest_indices(from: Vector3, count: int, before: int = -1) -> Array:
	var dists: Array = []
	var m: int = 0
	while m < (_positions.size() if before < 0 else before):
		dists.append({"j": m, "d": from.distance_to(Vector3(_positions[m]))})
		m += 1
	dists.sort_custom(func(a, b): return float(a["d"]) < float(b["d"]))
	var out: Array = []
	var k: int = 0
	while k < dists.size() and k < count:
		out.append(int((dists[k] as Dictionary)["j"]))
		k += 1
	return out


func _grow_shoot() -> void:
	if _node_total >= max_nodes: return
	var pos: Vector3 = _samples[_node_total]
	# link to SEVERAL nearest existing nodes BEFORE adding (so it never picks itself)
	var targets: Array = _nearest_indices(pos, links_per_node)
	var new_idx: int = _add_node(pos)
	if new_idx < 0:
		return
	var t: int = 0
	while t < targets.size():
		_add_edge(new_idx, int(targets[t]))
		t += 1
	_refresh_graph()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _paused: return
	_t += delta
	if not interactive:
		_node_field.rotation.y = sin(_t*.3)*.07
		_edge_field.rotation.y = _node_field.rotation.y
	_accum += delta
	if _accum >= grow_period:
		_accum = 0.0
		if _node_total >= max_nodes:
			if interactive:
				_paused = true
				_refresh_graph()
			else: _rebuild()
		else: _grow_shoot()


func _fixed_label(text: String, pos: Vector3, font: int, pixel: float) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.font_size = font
	label.pixel_size = pixel
	label.modulate = cool_white
	label.outline_size = 4
	label.no_depth_test = false
	return label


func _build_controls() -> void:
	var mat := _matte_mat(slate)
	add_child(_cylinder(Vector3(0,.85,0),spread+.1,.09,mat))
	add_child(_cylinder(Vector3(0,.41,0),.15,.82,mat))
	for x in [-1.2,1.2]:
		add_child(_box(Vector3(x,1.4,.12),Vector3(1.0,.58,.04),mat))
		add_child(_cylinder(Vector3(x,.55,.12),.055,1.1,mat))
	_detail = _fixed_label("",Vector3(1.2,1.4,.15),28,.0017)
	add_child(_detail)
	var rack: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_controls = rack.create_panel("CONNECTIONS",[
		[{"type":"button","label":"GROW"},{"type":"button","label":"STEP"},{"type":"button","label":"LINKS"}],
		[{"type":"button","label":"NODE"},{"type":"button","label":"CUT"},{"type":"button","label":"REPLAY"}]
	])
	_controls.position = Vector3(0,1.02,1.02)
	_controls.rotation_degrees.x = -25
	_controls.scale = Vector3.ONE*1.6
	add_child(_controls)
	add_child(_cylinder(Vector3(0,.5,.94),.085,1,mat))
	for i in range(6):
		_controls.find_child("Btn_%d" % i,true,false).get_node("InteractableAreaButton").button_pressed.connect(_operate.bind(i))
	_selection = _torus(Vector3.ZERO,.065,.006,_glow_mat(Color(1,.7,.2),.2))
	add_child(_selection)


func _operate(_body: Variant, choice: int) -> void:
	match choice:
		0:
			if false not in _active: _paused = not _paused
		1:
			_paused = true
			if false not in _active: _grow_shoot()
		2:
			_paused = true
			links_per_node = 1 if links_per_node==3 else 3
			_rewire()
		3:
			_paused = true
			_selected = (_selected+1)%_node_total
		4:
			_paused = true
			_active[_selected] = not _active[_selected]
		5:
			# Reuse the stored sample sequence, not a newly drawn cloud.
			_positions.clear()
			_edges.clear()
			_active.clear()
			_node_total = 0
			_edge_total = 0
			_selected = 0
			_accum = 0.0
			_clear_fields()
			_add_node(_samples[0])
			_add_node(_samples[1])
			_paused = true
	_refresh_graph()


func _rewire() -> void:
	_edges.clear()
	_edge_total = 0
	for i in range(2,_positions.size()):
		for target in _nearest_indices(_positions[i],links_per_node,i):
			_add_edge(i,int(target))


func _refresh_graph() -> void:
	_degrees.clear()
	_degrees.resize(_node_total)
	_degrees.fill(0)
	var adjacency: Array = []
	for i in range(_node_total): adjacency.append([])
	var em: MultiMesh = _edge_field.multimesh
	_visible_edges = 0
	for edge in _edges:
		var a: int = edge.a
		var b: int = edge.b
		if not _active[a] or not _active[b]: continue
		adjacency[a].append(b)
		adjacency[b].append(a)
		_degrees[a] += 1
		_degrees[b] += 1
		var pa: Vector3 = _origin+_positions[a]
		var pb: Vector3 = _origin+_positions[b]
		var pose := Transform3D(_basis_y_to(pb-pa)*Basis.from_scale(Vector3(1,pa.distance_to(pb),1)),(pa+pb)*.5)
		em.set_instance_transform(_visible_edges,pose)
		em.set_instance_color(_visible_edges,Color(1,.72,.25) if a==_selected or b==_selected else wire_purple)
		_visible_edges += 1
	em.visible_instance_count = _visible_edges
	_components = 0
	var visited: Dictionary = {}
	for i in range(_node_total):
		if not _active[i] or visited.has(i): continue
		_components += 1
		var todo: Array = [i]
		visited[i] = true
		while not todo.is_empty():
			var node: int = todo.pop_back()
			for neighbour in adjacency[node]:
				if not visited.has(neighbour):
					visited[neighbour] = true
					todo.append(neighbour)
	var nm: MultiMesh = _node_field.multimesh
	nm.visible_instance_count = _node_total
	for i in range(_node_total):
		var size: float = (.07 if interactive else .03) if _active[i] else .02
		nm.set_instance_transform(i,Transform3D(Basis.from_scale(Vector3.ONE*size),_origin+_positions[i]))
		nm.set_instance_color(i,cool_white.lerp(grow_teal,float(i)/float(max_nodes)) if _active[i] else Color(.25,.25,.3))
	if is_instance_valid(_selection):
		_selection.position = _origin+_positions[_selected]
		_selection.rotation_degrees.x = 90
	if is_instance_valid(_readout):
		_readout.text = "NODES %d/%d | EDGES %d\nCOMPONENTS %d | LINKS %d\nMAX DEGREE %d\n%s" % [
			_active.count(true),_node_total,_visible_edges,_components,links_per_node,_degrees.max(),
			"RESTORE CUT NODES TO GROW" if false in _active else ("HELD" if _paused else "GROWING")]
	if is_instance_valid(_detail):
		_detail.text = "NODE %02d | BIRTH %02d\nDEGREE %d | %s\nEarly: white / Later: teal\nCUT toggles removal" % [
			_selected+1,_selected+1,_degrees[_selected],"PRESENT" if _active[_selected] else "REMOVED"]
