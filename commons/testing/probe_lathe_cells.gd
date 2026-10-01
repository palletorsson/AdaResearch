## probe_lathe_cells.gd — the gate for two mesh grammar rules added 2026-10-01:
##   MeshData.create_lathe()   a profile turned round an axis
##   CellInsetOp               inset the triangles round one vertex toward it, open the middle
##
## Run (headless is enough: this reads meshes, it draws nothing):
##   godot --headless --path . --xr-mode off --log-file <log> \
##       --script res://commons/testing/probe_lathe_cells.gd
## It also builds the artifact cyrtoid_by_rule through the grid's own token parser.
## Exit code = number of failed assertions.
extends SceneTree

const CellInsetOp = preload("res://commons/mesh_grammar/operations/cell_inset_op.gd")
const InsetFaceOp = preload("res://commons/mesh_grammar/operations/inset_face_op.gd")
const DeleteFaceOp = preload("res://commons/mesh_grammar/operations/delete_face_op.gd")
const Presets = preload("res://commons/mesh_grammar/mesh_grammar_presets.gd")
const NodeScript = preload("res://commons/mesh_grammar/mesh_grammar_node.gd")
const ArtifactScript = preload("res://commons/artifacts/mesh_grammar_artifact/mesh_grammar_artifact.gd")

var _fails: int = 0


func _init() -> void:
	call_deferred("_run")


func _say(text: String) -> void:
	print("[lathe-cells] ", text)


func _check(ok: bool, what: String) -> void:
	if ok:
		_say("ok    " + what)
	else:
		_fails += 1
		_say("FAIL  " + what)


## Six times the signed volume. Positive when the faces are wound outward.
func _volume6(md: MeshData) -> float:
	var total: float = 0.0
	for f in md.faces:
		total += md.vertices[f[0]].dot(md.vertices[f[1]].cross(md.vertices[f[2]]))
	return total


func _centres_in(md: MeshData, fi: int) -> int:
	var n: int = 0
	for v in md.faces[fi]:
		if md.vertex_tags[v].has("centre"):
			n += 1
	return n


func _bar_area(md: MeshData) -> float:
	var total: float = 0.0
	for fi in range(md.faces.size()):
		if md.face_has_tag(fi, "bar"):
			total += md.get_face_area(fi)
	return total


func _shell_triangles(artifact: Node) -> int:
	var shell: MeshInstance3D = artifact.get_node_or_null("Shell")
	if shell == null or shell.mesh == null:
		return 0
	return shell.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() / 3


func _flask() -> PackedVector2Array:
	return PackedVector2Array([Vector2(0.0, 1.0), Vector2(0.2, 0.8), Vector2(0.35, 0.5), Vector2(0.5, 0.2),
		Vector2(0.55, -0.1), Vector2(0.5, -0.4), Vector2(0.3, -0.7), Vector2(0.0, -0.8)])


func _bell() -> PackedVector2Array:
	return PackedVector2Array([Vector2(0.0, 1.0), Vector2(0.2, 0.8), Vector2(0.35, 0.5), Vector2(0.5, 0.2),
		Vector2(0.55, -0.1), Vector2(0.5, -0.4), Vector2(0.45, -0.6)])


func _run() -> void:
	# ---- the lathe ------------------------------------------------------------
	var closed: MeshData = MeshData.create_lathe(_flask(), 36)
	_check(closed.vertices.size() == 6 * 36 + 2, "closed lathe: 6 rings of 36 and 2 poles = %d vertices" % closed.vertices.size())
	_check(closed.faces.size() == 5 * 72 + 2 * 36, "closed lathe: %d faces" % closed.faces.size())
	_check(closed.is_closed(), "closed lathe: every edge has two faces")
	_check(_volume6(closed) > 0.0, "closed lathe: wound outward (signed volume %.4f)" % (_volume6(closed) / 6.0))

	var upside := PackedVector2Array(_flask())
	upside.reverse()
	var turned: MeshData = MeshData.create_lathe(upside, 36)
	_check(_volume6(turned) > 0.0 and is_equal_approx(_volume6(turned), _volume6(closed)),
		"a profile given bottom to top is wound outward too, same volume")

	var bell: MeshData = MeshData.create_lathe(_bell(), 36)
	_check(not bell.is_closed() and bell.count_boundary_loops() == 1, "open lathe: one boundary loop, the mouth")
	_check(bell.get_boundary_edges().size() == 36, "open lathe: the mouth has 36 edges")

	# Vertex 0 is the pole. Away from it every triangle has exactly one centre; the
	# colouring cannot close round a pole, so one pole triangle in three has none.
	var wall_ok: bool = true
	var pole_without: int = 0
	var with_centre: int = 0
	for fi in range(bell.faces.size()):
		var n: int = _centres_in(bell, fi)
		if n == 1:
			with_centre += 1
		if Array(bell.faces[fi]).has(0):
			if n == 0:
				pole_without += 1
		elif n != 1:
			wall_ok = false
	_check(wall_ok, "36 segments: every triangle away from the pole has exactly one centre vertex")
	_check(pole_without == 12, "36 segments: 12 of the 36 pole triangles have no centre and stay whole")

	var odd: MeshData = MeshData.create_lathe(_bell(), 28)
	var tagged: int = 0
	for tags in odd.vertex_tags:
		if tags.has("centre"):
			tagged += 1
	_check(tagged == 0, "28 segments (not a multiple of 3): no centre is tagged")
	_check(MeshData.create_lathe(PackedVector2Array([Vector2(0.0, 1.0)]), 36).faces.is_empty(), "a profile of one point builds nothing")

	# ---- the cell inset ---------------------------------------------------------
	var before_faces: int = bell.faces.size()
	var whole_cells: int = 0
	for v in range(bell.vertices.size()):
		if bell.vertex_tags[v].has("centre"):
			var on_edge: bool = false
			for edge in bell.get_boundary_edges():
				if edge.x == v or edge.y == v:
					on_edge = true
			if not on_edge:
				whole_cells += 1
	var pored: MeshData = bell.duplicate_mesh()
	CellInsetOp.new(MeshSelector.all_faces(), {"bar": 0.3}).apply(pored)
	_check(pored.faces.size() == before_faces + with_centre, "cell inset: each triangle with a centre leaves two strip triangles (%d -> %d)" % [before_faces, pored.faces.size()])
	_check(pored.count_boundary_loops() == 1 + whole_cells, "cell inset: one new hole per whole cell (%d cells, %d loops)" % [whole_cells, pored.count_boundary_loops()])
	var not_bars: int = 0
	for fi in range(pored.faces.size()):
		if not pored.face_has_tag(fi, "bar"):
			not_bars += 1
	_check(not_bars == pole_without, "cell inset: every face left is a bar, but the %d whole pole triangles" % pole_without)
	_check(_volume6(pored) > 0.0, "cell inset: the strips keep the outward winding")

	# The bite: the old inset, per triangle, makes one hole per TRIANGLE, not per cell.
	var per_triangle: MeshData = bell.duplicate_mesh()
	InsetFaceOp.new(MeshSelector.all_faces(), {"amount": 0.4, "inner_tag": "pore"}).apply(per_triangle)
	DeleteFaceOp.new(MeshSelector.by_tag("pore"), {}).apply(per_triangle)
	_check(per_triangle.count_boundary_loops() == 1 + before_faces,
		"negative: inset + delete per triangle makes %d holes where the cell inset makes %d" % [per_triangle.count_boundary_loops() - 1, whole_cells])

	var kept: MeshData = bell.duplicate_mesh()
	CellInsetOp.new(MeshSelector.all_faces(), {"bar": 0.3, "open": false}).apply(kept)
	_check(kept.faces.size() == before_faces + 2 * with_centre and kept.count_boundary_loops() == 1, "open = false keeps the middles: three faces per triangle, no new hole")

	var thin: MeshData = bell.duplicate_mesh()
	CellInsetOp.new(MeshSelector.all_faces(), {"bar": 0.1}).apply(thin)
	var thick: MeshData = bell.duplicate_mesh()
	CellInsetOp.new(MeshSelector.all_faces(), {"bar": 0.5}).apply(thick)
	var graded: MeshData = bell.duplicate_mesh()
	CellInsetOp.new(MeshSelector.all_faces(), {"bar": 0.5, "bar_end": 0.1}).apply(graded)
	_check(_bar_area(thin) < _bar_area(graded) and _bar_area(graded) < _bar_area(thick),
		"a graded bar lies between the two it is graded from (bar area %.3f < %.3f < %.3f)" % [_bar_area(thin), _bar_area(graded), _bar_area(thick)])

	var untouched: MeshData = bell.duplicate_mesh()
	CellInsetOp.new(MeshSelector.by_tag("no_such_tag"), {"bar": 0.3}).apply(untouched)
	_check(untouched.faces.size() == before_faces, "an empty selection changes nothing")

	# ---- no tags: the op chooses its own centres --------------------------------
	var ico: MeshData = MeshData.create_icosahedron(0.5)
	CellInsetOp.new(MeshSelector.all_faces(), {"bar": 0.3}).apply(ico)
	var ico_bars: int = 0
	for fi in range(ico.faces.size()):
		if ico.face_has_tag(fi, "bar"):
			ico_bars += 1
	_check(ico_bars > 0 and ico.faces.size() == 20 + ico_bars / 2, "icosahedron, no tags: cells are chosen (%d of 20 triangles in a cell)" % (ico_bars / 2))
	var sphere: MeshData = MeshData.create_sphere(0.5, 12, 16)
	CellInsetOp.new(MeshSelector.all_faces(), {"bar": 0.3}).apply(sphere)
	var pole_open: bool = false
	for edge in sphere.get_boundary_edges():
		if edge.x == 0 or edge.y == 0:
			pole_open = true
	_check(sphere.count_boundary_loops() > 0 and not pole_open, "sphere, no tags: cells are chosen, and the pole (16 faces, over max_fan) is not one")

	# ---- the names reach the rule builders ----------------------------------------
	_check(Presets.create_rule({"op": "cell_inset", "selector": "all", "params": {"bar": 0.3}}) != null, "presets rule builder knows cell_inset")
	_check(Presets.create_rule({"op": "no_such_op", "selector": "all", "params": {}}) == null, "negative: an unknown op is still refused")
	var artifact: Node = ArtifactScript.new()
	_check(artifact._build_rule({"op": "cell_inset", "selector": "all", "params": {"bar": 0.3}}) != null, "mesh_grammar_artifact rule builder knows cell_inset")
	artifact.free()

	var node: Node3D = NodeScript.new()
	node.seed_type = "lathe"
	node.seed_scale = 0.5
	node.generations = 1
	node.add_rule(Presets.create_rule({"op": "cell_inset", "selector": "all", "params": {"bar": 0.3}}))
	root.add_child(node)
	await process_frame
	await process_frame
	var built: MeshData = node.grammar.current_mesh
	_check(built != null and built.count_boundary_loops() > 1, "a node with seed lathe and one cell_inset rule builds a pored bell")
	node.queue_free()

	var plain: Node3D = NodeScript.new()
	root.add_child(plain)
	await process_frame
	await process_frame
	_check(plain.grammar.current_mesh.faces.size() == 20, "a node left alone still builds the 20-face icosahedron")
	plain.queue_free()

	# ---- the artifact, through the real token parser ------------------------------
	var parser = load("res://commons/grid/GridInteractablesComponent.gd").new()
	var scene: PackedScene = load("res://commons/artifacts/cyrtoid_by_rule/cyrtoid_by_rule.tscn")
	var triangles: Dictionary = {}
	for token in ["cyrtoid_by_rule#stage:turned", "cyrtoid_by_rule#stage:pored", "cyrtoid_by_rule#stage:footed",
			"cyrtoid_by_rule", "cyrtoid_by_rule#form:flask#stage:pored"]:
		var parsed: Dictionary = parser._parse_config_token(token)
		var config: Dictionary = parsed.get("config_data", {})
		var overrides: Dictionary = parsed.get("overrides", {})
		# The grid hands config over after the node is in the tree.
		var late: Node3D = scene.instantiate()
		root.add_child(late)
		late.apply_grid_config(config)
		await process_frame
		# The museum hands it over before.
		var early: Node3D = scene.instantiate()
		early.apply_grid_config(config)
		root.add_child(early)
		await process_frame
		var late_count: int = _shell_triangles(late)
		var early_count: int = _shell_triangles(early)
		triangles[token] = late_count
		_check(late_count > 0 and late_count == early_count and not overrides.has("rotation_y_degrees"),
			"%s: %d triangles, the same whether config comes before or after the tree, no stray yaw" % [token, late_count])
		late.queue_free()
		early.queue_free()
	_check(triangles["cyrtoid_by_rule#stage:turned"] < triangles["cyrtoid_by_rule#stage:pored"]
		and triangles["cyrtoid_by_rule#stage:pored"] < triangles["cyrtoid_by_rule#stage:footed"]
		and triangles["cyrtoid_by_rule#stage:footed"] < triangles["cyrtoid_by_rule"],
		"each stage adds triangles to the one before; the bare token is the whole list")
	_check(triangles["cyrtoid_by_rule#form:flask#stage:pored"] != triangles["cyrtoid_by_rule#stage:pored"],
		"form changes the body at one stage")
	var wrong: Node3D = scene.instantiate()
	root.add_child(wrong)
	wrong.apply_grid_config({"form": "no_such_form", "stage": "no_such_stage"})
	await process_frame
	_check(_shell_triangles(wrong) == triangles["cyrtoid_by_rule"],
		"negative: unknown names build the whole helmet (two warnings expected in the log)")
	wrong.queue_free()
	parser.free()

	_say("RESULT: %d failed assertion(s)" % _fails)
	quit(_fails)
