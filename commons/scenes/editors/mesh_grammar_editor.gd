# mesh_grammar_editor.gd — Wraps the real mesh grammar system at
# commons/mesh_grammar/ into a live editor.
# Uses MeshData seeds, MeshGrammar, MeshRule, MeshSelector, and real operations
# (ExtrudeFaceOp, InsetFaceOp, BulgeOp, NoiseDisplaceOp).
extends BaseGeometryEditor

const GridMaterialFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")

const SEED_NAMES: Array[String] = ["Cube", "Icosahedron", "Sphere"]


func _get_editor_name() -> String:
	return "Mesh Grammar"


func _get_parameter_groups() -> Array:
	return [
		{"name": "Seed", "params": [
			{"id": "seed_type", "label": "Seed", "options": ["Cube", "Icosahedron", "Sphere"], "default": 1.0},
			{"id": "seed_scale", "label": "Scale", "min": 0.1, "max": 1.5, "step": 0.05, "default": 0.5},
		]},
		{"name": "Grammar", "params": [
			{"id": "generations", "label": "Generations", "min": 1.0, "max": 5.0, "step": 1.0, "default": 2.0},
		]},
		{"name": "Extrude", "params": [
			{"id": "extrude_dist", "label": "Distance", "min": 0.0, "max": 1.0, "step": 0.02, "default": 0.2},
			{"id": "extrude_scale", "label": "Scale", "min": 0.3, "max": 1.0, "step": 0.02, "default": 0.7},
		]},
		{"name": "Inset", "params": [
			{"id": "inset_amount", "label": "Amount", "min": 0.0, "max": 0.8, "step": 0.02, "default": 0.0},
		]},
		{"name": "Bulge", "params": [
			{"id": "bulge_height", "label": "Height", "min": 0.0, "max": 0.5, "step": 0.02, "default": 0.0},
		]},
		{"name": "Noise Displace", "params": [
			{"id": "noise_amp", "label": "Amplitude", "min": 0.0, "max": 0.3, "step": 0.01, "default": 0.0},
			{"id": "noise_freq", "label": "Frequency", "min": 0.5, "max": 3.0, "step": 0.1, "default": 2.0},
		]},
	]


func _rebuild() -> void:
	_clear_content()

	# Create seed mesh
	var seed_idx: int = clampi(int(p("seed_type", 1)), 0, 2)
	var seed_scale: float = p("seed_scale", 0.5)
	var seed_mesh: MeshData
	match seed_idx:
		0:
			seed_mesh = MeshData.create_cube(seed_scale)
		1:
			seed_mesh = MeshData.create_icosahedron(seed_scale)
		2:
			seed_mesh = MeshData.create_sphere(seed_scale, 12, 16)
		_:
			seed_mesh = MeshData.create_icosahedron(seed_scale)

	# Build grammar
	var grammar := MeshGrammar.new()
	grammar.max_faces = 10000
	grammar.set_seed(seed_mesh)

	# Add rules based on non-zero parameters (non-zero = enabled)
	var extrude_dist: float = p("extrude_dist", 0.2)
	var extrude_scale: float = p("extrude_scale", 0.7)
	if extrude_dist > 0.01:
		var sel := MeshSelector.by_normal_direction(Vector3.UP, 60.0)
		var rule := ExtrudeFaceOp.new(sel, {
			"distance": extrude_dist,
			"scale": extrude_scale,
		})
		grammar.add_rule(rule)

	var inset_amount: float = p("inset_amount", 0.0)
	if inset_amount > 0.01:
		var sel := MeshSelector.all_faces()
		var rule := InsetFaceOp.new(sel, {"amount": inset_amount})
		grammar.add_rule(rule)

	var bulge_height: float = p("bulge_height", 0.0)
	if bulge_height > 0.01:
		var sel := MeshSelector.by_random(0.12)
		var rule := BulgeOp.new(sel, {
			"height": bulge_height,
			"ring_depth": 2,
			"smoothing": 0.5,
		})
		grammar.add_rule(rule)

	var noise_amp: float = p("noise_amp", 0.0)
	var noise_freq: float = p("noise_freq", 2.0)
	if noise_amp > 0.005:
		var sel := MeshSelector.all_faces()
		var rule := NoiseDisplaceOp.new(sel, {
			"amplitude": noise_amp,
			"frequency": noise_freq,
			"direction": "normal",
		})
		grammar.add_rule(rule)

	# Apply generations
	var gen_count: int = clampi(int(p("generations", 2)), 1, 5)
	if not grammar.rules.is_empty():
		grammar.apply_n(gen_count)

	# Convert to mesh and display
	var mesh_data: MeshData = grammar.current_mesh
	if not mesh_data:
		return

	var array_mesh: ArrayMesh = mesh_data.to_array_mesh({"double_sided": true})
	var mi := MeshInstance3D.new()
	mi.mesh = array_mesh

	var mat: Material = GridMaterialFactory.make(
		Color(0.6, 0.75, 0.85), {"double_sided": true})
	mi.material_override = mat
	content_root.add_child(mi)

	# Update info label
	var seed_name: String = SEED_NAMES[seed_idx]
	var rule_count: int = grammar.rules.size()
	info_label.text = "%s | %d rules | %d gen | %dv %df" % [
		seed_name, rule_count, grammar.get_generation(),
		mesh_data.vertex_count(), mesh_data.face_count()]
