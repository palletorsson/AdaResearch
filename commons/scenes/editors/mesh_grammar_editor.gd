# mesh_grammar_editor.gd — Full mesh grammar editor with all operations + presets
# Wraps MeshData, MeshGrammar, MeshRule, MeshSelector, and ALL operations from
# commons/mesh_grammar/operations/. Includes 12 preset recipes from the demo gallery.
extends BaseGeometryEditor

const GridMaterialFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")

# Preset recipes — each recreates a specimen from the mesh_grammar_demo gallery
const PRESETS: Array[Dictionary] = [
	{"name": "Extruded Spire", "seed": 1, "gen": 1,
	 "extrude": 0.3, "extrude_scale": 0.7, "extrude_sel": 1},
	{"name": "Inset Pattern", "seed": 1, "gen": 1,
	 "inset": 0.35, "inset_sel": 0},
	{"name": "Nodule Sphere", "seed": 2, "gen": 1,
	 "bulge": 0.15, "bulge_prob": 0.12},
	{"name": "Coral Fingers", "seed": 2, "gen": 1,
	 "tube": 0.3, "tube_curve": 0.05},
	{"name": "Crumpled Form", "seed": 2, "gen": 1,
	 "noise": 0.15, "noise_freq": 3.0},
	{"name": "Budding Sphere", "seed": 2, "gen": 1,
	 "extrude": 0.2, "extrude_scale": 0.8, "extrude_sel": 2, "delete_top": 1.0},
	{"name": "Inset Towers", "seed": 0, "gen": 1,
	 "inset": 0.3, "inset_sel": 1, "extrude": 0.4, "extrude_scale": 0.7, "extrude_sel": 3},
	{"name": "Petal Flower", "seed": 1, "gen": 1,
	 "petal": 0.25, "petal_count": 6.0, "petal_curl": 0.4},
	{"name": "Scale Armor", "seed": 2, "gen": 1,
	 "split": 1.0, "scale_tile": 0.08},
	{"name": "Spike Ball", "seed": 1, "gen": 1,
	 "scatter": 0.6, "scatter_shape": 1.0, "scatter_size": 0.1},
	{"name": "Barnacle Sphere", "seed": 2, "gen": 1,
	 "scatter": 0.3, "scatter_shape": 0.0, "scatter_size": 0.03},
	{"name": "Branching Coral", "seed": 1, "gen": 2,
	 "tube": 0.2, "tube_curve": 0.08},
]


func _get_editor_name() -> String:
	return "Mesh Grammar"


func _get_parameter_groups() -> Array:
	return [
		{"name": "Seed", "params": [
			{"id": "preset", "label": "Preset", "options": [
				"Custom", "Extruded Spire", "Inset Pattern", "Nodule Sphere",
				"Coral Fingers", "Crumpled Form", "Budding Sphere", "Inset Towers",
				"Petal Flower", "Scale Armor", "Spike Ball", "Barnacle Sphere",
				"Branching Coral",
			], "default": 0.0},
			{"id": "seed_type", "label": "Seed Shape", "options": ["Cube", "Icosahedron", "Sphere"], "default": 1.0},
			{"id": "seed_scale", "label": "Scale", "min": 0.1, "max": 1.5, "step": 0.05, "default": 0.4},
			{"id": "generations", "label": "Generations", "min": 1.0, "max": 5.0, "step": 1.0, "default": 1.0},
		]},
		{"name": "Extrude", "params": [
			{"id": "extrude_sel", "label": "Select", "options": ["Off", "Up Faces", "Random 10%", "Inset Tag"], "default": 0.0},
			{"id": "extrude_dist", "label": "Distance", "min": 0.0, "max": 1.0, "step": 0.02, "default": 0.25},
			{"id": "extrude_scale", "label": "Scale", "min": 0.3, "max": 1.0, "step": 0.02, "default": 0.7},
		]},
		{"name": "Inset", "params": [
			{"id": "inset_sel", "label": "Select", "options": ["All Faces", "Up Faces"], "default": 0.0},
			{"id": "inset_amount", "label": "Amount", "min": 0.0, "max": 0.8, "step": 0.02, "default": 0.0},
		]},
		{"name": "Bulge", "params": [
			{"id": "bulge_height", "label": "Height", "min": 0.0, "max": 0.4, "step": 0.02, "default": 0.0},
			{"id": "bulge_prob", "label": "Probability", "min": 0.02, "max": 0.5, "step": 0.02, "default": 0.12},
		]},
		{"name": "Tube Branch", "params": [
			{"id": "tube_length", "label": "Length", "min": 0.0, "max": 0.5, "step": 0.02, "default": 0.0},
			{"id": "tube_curve", "label": "Curve", "min": 0.0, "max": 0.2, "step": 0.01, "default": 0.05},
		]},
		{"name": "Noise", "params": [
			{"id": "noise_amp", "label": "Amplitude", "min": 0.0, "max": 0.3, "step": 0.01, "default": 0.0},
			{"id": "noise_freq", "label": "Frequency", "min": 0.5, "max": 5.0, "step": 0.1, "default": 2.0},
		]},
		{"name": "Petal Splay", "params": [
			{"id": "petal_length", "label": "Length", "min": 0.0, "max": 0.4, "step": 0.02, "default": 0.0},
			{"id": "petal_count", "label": "Count", "min": 3.0, "max": 10.0, "step": 1.0, "default": 6.0},
			{"id": "petal_curl", "label": "Curl", "min": 0.0, "max": 1.0, "step": 0.05, "default": 0.4},
		]},
		{"name": "Scatter", "params": [
			{"id": "scatter_density", "label": "Density", "min": 0.0, "max": 1.0, "step": 0.05, "default": 0.0},
			{"id": "scatter_shape", "label": "Shape", "options": ["Sphere", "Spike"], "default": 0.0},
			{"id": "scatter_size", "label": "Size", "min": 0.01, "max": 0.15, "step": 0.005, "default": 0.03},
		]},
		{"name": "Other Ops", "params": [
			{"id": "split", "label": "Subdivide", "min": 0.0, "max": 1.0, "step": 1.0, "default": 0.0},
			{"id": "delete_top", "label": "Delete Top", "min": 0.0, "max": 1.0, "step": 1.0, "default": 0.0},
			{"id": "scale_tile_size", "label": "Scale Tile", "min": 0.0, "max": 0.15, "step": 0.01, "default": 0.0},
		]},
	]


func _on_param_changed(value: float, param_id: String) -> void:
	# When preset changes, load its values into the sliders
	if param_id == "preset":
		var idx: int = int(value)
		if idx > 0 and idx <= PRESETS.size():
			_load_preset_values(PRESETS[idx - 1])
			return
	super._on_param_changed(value, param_id)


func _on_dropdown_changed(index: int, param_id: String) -> void:
	if param_id == "preset":
		if index > 0 and index <= PRESETS.size():
			_load_preset_values(PRESETS[index - 1])
			return
	super._on_dropdown_changed(index, param_id)


func _load_preset_values(preset: Dictionary) -> void:
	# Reset all operation params to zero first
	var reset_ids: Array[String] = [
		"extrude_dist", "inset_amount", "bulge_height", "tube_length",
		"noise_amp", "petal_length", "scatter_density", "split",
		"delete_top", "scale_tile_size",
	]
	for rid: String in reset_ids:
		_params[rid] = 0.0

	# Set seed
	_params["seed_type"] = float(preset.get("seed", 1))
	_params["generations"] = float(preset.get("gen", 1))

	# Set operation-specific values
	if preset.has("extrude"):
		_params["extrude_dist"] = preset["extrude"] as float
		_params["extrude_sel"] = float(preset.get("extrude_sel", 1))
	if preset.has("extrude_scale"):
		_params["extrude_scale"] = preset["extrude_scale"] as float
	if preset.has("inset"):
		_params["inset_amount"] = preset["inset"] as float
		_params["inset_sel"] = float(preset.get("inset_sel", 0))
	if preset.has("bulge"):
		_params["bulge_height"] = preset["bulge"] as float
	if preset.has("bulge_prob"):
		_params["bulge_prob"] = preset["bulge_prob"] as float
	if preset.has("tube"):
		_params["tube_length"] = preset["tube"] as float
	if preset.has("tube_curve"):
		_params["tube_curve"] = preset["tube_curve"] as float
	if preset.has("noise"):
		_params["noise_amp"] = preset["noise"] as float
	if preset.has("noise_freq"):
		_params["noise_freq"] = preset["noise_freq"] as float
	if preset.has("petal"):
		_params["petal_length"] = preset["petal"] as float
	if preset.has("petal_count"):
		_params["petal_count"] = preset["petal_count"] as float
	if preset.has("petal_curl"):
		_params["petal_curl"] = preset["petal_curl"] as float
	if preset.has("scatter"):
		_params["scatter_density"] = preset["scatter"] as float
	if preset.has("scatter_shape"):
		_params["scatter_shape"] = preset["scatter_shape"] as float
	if preset.has("scatter_size"):
		_params["scatter_size"] = preset["scatter_size"] as float
	if preset.has("split"):
		_params["split"] = preset["split"] as float
	if preset.has("delete_top"):
		_params["delete_top"] = preset["delete_top"] as float
	if preset.has("scale_tile"):
		_params["scale_tile_size"] = preset["scale_tile"] as float

	_sync_sliders_to_params()
	_needs_rebuild = true
	_rebuild_timer = 0.0


func _rebuild() -> void:
	_clear_content()

	# Create seed mesh
	var seed_idx: int = clampi(int(p("seed_type", 1)), 0, 2)
	var seed_scale: float = p("seed_scale", 0.4)
	var seed_mesh: MeshData
	match seed_idx:
		0: seed_mesh = MeshData.create_cube(seed_scale)
		1: seed_mesh = MeshData.create_icosahedron(seed_scale)
		2: seed_mesh = MeshData.create_sphere(seed_scale, 12, 16)
		_: seed_mesh = MeshData.create_icosahedron(seed_scale)

	# Build grammar
	var grammar := MeshGrammar.new()
	grammar.max_faces = 10000
	grammar.set_seed(seed_mesh)

	# ── Add rules based on enabled parameters ───────────────

	# Split (subdivide) — must come first
	if p("split") > 0.5:
		grammar.add_rule(SplitFaceOp.new(
			MeshSelector.all_faces(), {"pattern": "midpoint"}))

	# Inset
	if p("inset_amount") > 0.01:
		var inset_sel: MeshSelector
		match int(p("inset_sel", 0)):
			0: inset_sel = MeshSelector.all_faces()
			1: inset_sel = MeshSelector.by_normal_direction(Vector3.UP, 60.0)
			_: inset_sel = MeshSelector.all_faces()
		grammar.add_rule(InsetFaceOp.new(inset_sel, {"amount": p("inset_amount")}))

	# Extrude
	var ext_sel_idx: int = int(p("extrude_sel", 0))
	if ext_sel_idx > 0 and p("extrude_dist") > 0.01:
		var extrude_sel: MeshSelector
		match ext_sel_idx:
			1: extrude_sel = MeshSelector.by_normal_direction(Vector3.UP, 60.0)
			2: extrude_sel = MeshSelector.by_random(0.1)
			3: extrude_sel = MeshSelector.by_tag("inset")
			_: extrude_sel = MeshSelector.by_normal_direction(Vector3.UP, 60.0)
		grammar.add_rule(ExtrudeFaceOp.new(extrude_sel, {
			"distance": p("extrude_dist"), "scale": p("extrude_scale")}))

	# Delete top (after extrude — creates openings)
	if p("delete_top") > 0.5:
		grammar.add_rule(DeleteFaceOp.new(
			MeshSelector.by_tag("extruded_top"), {}))

	# Bulge
	if p("bulge_height") > 0.01:
		grammar.add_rule(BulgeOp.new(
			MeshSelector.by_random(p("bulge_prob", 0.12)),
			{"height": p("bulge_height"), "ring_depth": 2, "smoothing": 0.5}))

	# Tube branch
	if p("tube_length") > 0.01:
		grammar.add_rule(TubeBranchOp.new(
			MeshSelector.by_normal_direction(Vector3.UP, 60.0).and_also(
				MeshSelector.by_random(0.25)),
			{"length": p("tube_length"), "curve_amount": p("tube_curve"),
			 "segments": 5, "rings": 3}))

	# Noise displace
	if p("noise_amp") > 0.005:
		grammar.add_rule(NoiseDisplaceOp.new(
			MeshSelector.all_faces(),
			{"amplitude": p("noise_amp"), "frequency": p("noise_freq"),
			 "direction": "normal"}))

	# Scale tile
	if p("scale_tile_size") > 0.005:
		grammar.add_rule(ScaleTileOp.new(
			MeshSelector.all_faces(),
			{"scale_length": p("scale_tile_size"),
			 "scale_width": p("scale_tile_size") * 0.75,
			 "tilt_degrees": 35.0, "pointed": true}))

	# Petal splay
	if p("petal_length") > 0.01:
		grammar.add_rule(PetalSplayOp.new(
			MeshSelector.by_normal_direction(Vector3.UP, 60.0),
			{"count": int(p("petal_count", 6)), "length": p("petal_length"),
			 "width": p("petal_length") * 0.5, "curl": p("petal_curl"),
			 "tilt": 0.4, "segments": 5}))

	# Surface scatter
	if p("scatter_density") > 0.01:
		var scatter_shape_name: String = "sphere" if int(p("scatter_shape")) == 0 else "spike"
		grammar.add_rule(SurfaceScatterOp.new(
			MeshSelector.all_faces(),
			{"shape": scatter_shape_name, "density": p("scatter_density"),
			 "min_size": p("scatter_size") * 0.5, "max_size": p("scatter_size"),
			 "align_to_normal": true}))

	# Apply generations
	var gen_count: int = clampi(int(p("generations", 1)), 1, 5)
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

	# Info label
	var seed_names: Array[String] = ["Cube", "Icosahedron", "Sphere"]
	if info_label:
		info_label.text = "%s | %d rules | %d gen | %dv %df" % [
			seed_names[seed_idx], grammar.rules.size(), grammar.generation,
			mesh_data.vertex_count(), mesh_data.face_count()]
