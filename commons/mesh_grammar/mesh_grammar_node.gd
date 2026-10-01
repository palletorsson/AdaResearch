## MeshGrammarNode — Node3D that displays a MeshGrammar result.
## Owns a MeshGrammar, renders the output as MeshInstance3D.
## Supports static generation and animated evolution.
## Modeled after KreslingSpire (owns geometry solver, rebuilds mesh, @export params).
extends Node3D
class_name MeshGrammarNode

const GridMaterialFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")
const MeshGrammarPresets = preload("res://commons/mesh_grammar/mesh_grammar_presets.gd")

@export_group("Seed")
@export_enum("cube", "icosahedron", "sphere", "disk", "flower_disk", "lathe", "custom") var seed_type: String = "icosahedron"
## For the "lathe" seed: Vector2(radius, height) points, top to bottom, in units of
## seed_scale. Empty gives a plain bell. seed_segments a multiple of 3 marks the cells.
@export var seed_profile: PackedVector2Array = PackedVector2Array()
@export var seed_segments: int = 36
@export var seed_scale: float = 0.5

@export_group("Grammar")
@export var generations: int = 2
@export var max_faces: int = 10000
@export var auto_generate: bool = true

@export_group("Preset")
## Names one recipe in MeshGrammarPresets (the id is the registry name without its
## `mesh_grammar_` prefix: "extruded_spire", "lsystem_tree", ...). EMPTY — the
## default, and what every caller that builds its own rules leaves it at — changes
## nothing: no table is read and this node behaves as it always did.
## Non-empty: the recipe sets seed, seed scale, colour and generations and adds its
## rules before the first generate(). One scene per name lives in presets/, so a
## registry `scene` line is all a lane needs to read — the grid, the museum and the
## capture bench all read that line the same way, and none of them agrees with the
## others about `default_params`.
@export var preset: String = ""

@export_group("Animation")
@export var animate: bool = false
@export var animation_speed: float = 0.5
@export var animation_parameter: float = 0.0  # 0.0 to 1.0

@export_group("Appearance")
@export var base_color: Color = Color(0.6, 0.75, 0.85)
@export var use_grid_material: bool = true
@export var double_sided: bool = true
# Surface qualities — read by _update_display when face colours are baked.
# Drive these directly from CritterDNA fields for design-time previews
# that match runtime appearance.
@export_range(0.0, 1.0) var roughness: float = 0.85
@export_range(0.0, 1.0) var metallic: float = 0.0
@export_range(0.0, 1.0) var iridescence: float = 0.0
@export_range(0.0, 1.0) var transparency: float = 0.0
@export var emission_color: Color = Color(0, 0, 0, 0)
@export_range(0.0, 4.0) var emission_energy: float = 0.0

# Public
var grammar: MeshGrammar = null

# Internal
var _mesh_instance: MeshInstance3D = null
var _material: Material = null
## The preset whose rules are in the grammar right now. Guards a second arrival of
## the same name (the grid hands a config over twice) from adding every rule twice.
var _applied_preset: String = ""
## A name no recipe carries, already warned about.
var _refused_preset: String = ""

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_ensure_grammar()
	_apply_preset()          # no-op while `preset` is empty
	_setup_material()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "GrammarMesh"
	add_child(_mesh_instance)

	if auto_generate:
		generate()

func _process(delta: float) -> void:
	if animate and grammar and grammar.get_history_size() > 1:
		animation_parameter = fmod(animation_parameter + delta * animation_speed, 1.0)
		var mesh_data: MeshData = grammar.interpolate_generation(animation_parameter)
		_update_display(mesh_data)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Generate the mesh from seed through all generations.
func generate() -> void:
	_create_seed()
	grammar.apply_n(generations)
	_update_display(grammar.current_mesh)

## Apply a single grammar step and update display.
func apply_step() -> void:
	grammar.apply_step()
	_update_display(grammar.current_mesh)

## Reset to seed state.
func reset() -> void:
	grammar.reset()
	_update_display(grammar.current_mesh)

## Set a custom seed mesh (for "custom" seed_type or external meshes).
func set_seed_mesh(mesh_data: MeshData) -> void:
	seed_type = "custom"
	grammar.set_seed(mesh_data)
	_update_display(grammar.current_mesh)

## Add a rule to the grammar.
func add_rule(rule: MeshRule) -> void:
	_ensure_grammar()
	grammar.add_rule(rule)

## Clear all rules.
func clear_rules() -> void:
	_ensure_grammar()
	grammar.clear_rules()

## Take everything a recipe dictionary names: seed, seed scale, colour, generations,
## and its rules, in order. The ONE place a {"seed","color","rules","generations"}
## dictionary becomes a node — the demo gallery calls it for each of its twenty
## specimens and `preset` calls it for one. Call before the node enters the tree
## (or call generate() afterwards); it does not clear rules already present.
## [[radius, height], ...] or Vector2s -> a profile. Anything else is skipped.
func _profile_from(value: Variant) -> PackedVector2Array:
	var out := PackedVector2Array()
	if value is PackedVector2Array:
		return value
	if value is Array:
		for point in value:
			if point is Vector2:
				out.append(point)
			elif point is Array and (point as Array).size() >= 2:
				out.append(Vector2(float(point[0]), float(point[1])))
	return out

func apply_spec(spec: Dictionary) -> void:
	seed_type = spec.get("seed", "icosahedron")
	if spec.has("profile"):
		seed_profile = _profile_from(spec["profile"])
	if spec.has("seed_segments"):
		seed_segments = int(spec["seed_segments"])
	seed_scale = float(spec.get("seed_scale", MeshGrammarPresets.SEED_SCALE))
	base_color = spec.get("color", Color(0.6, 0.7, 0.8))
	generations = spec.get("generations", 1)
	for rule in MeshGrammarPresets.rules_for(spec):
		add_rule(rule)

## Configure from a dictionary (for map/grid system integration).
func configure(config: Dictionary) -> void:
	# PRESET FIRST, so the keys below can still override what the recipe set
	# (#preset:spike_ball#color:... keeps the colour the token asked for).
	# Absent key: this block does not run and nothing below it has changed.
	if config.has("preset"):
		_ensure_grammar()
		preset = str(config["preset"])
		_apply_preset()
		_setup_material()
	if config.has("seed"):
		seed_type = str(config["seed"])
	if config.has("profile"):
		seed_profile = _profile_from(config["profile"])
	if config.has("seed_segments"):
		seed_segments = int(config["seed_segments"])
	if config.has("seed_scale"):
		seed_scale = float(config["seed_scale"])
	if config.has("generations"):
		generations = int(config["generations"])
	if config.has("animate"):
		animate = bool(config["animate"])
	if config.has("speed"):
		animation_speed = float(config["speed"])
	if config.has("color"):
		base_color = config["color"]
		_setup_material()
	if config.has("max_faces"):
		max_faces = int(config["max_faces"])
		grammar.max_faces = max_faces
	# Surface qualities — accept either flat keys or a "material" sub-dict.
	var mat_cfg: Dictionary = config.get("material", {})
	if config.has("roughness"): roughness = float(config["roughness"])
	elif mat_cfg.has("roughness"): roughness = float(mat_cfg["roughness"])
	if config.has("metallic"): metallic = float(config["metallic"])
	elif mat_cfg.has("metallic"): metallic = float(mat_cfg["metallic"])
	if mat_cfg.has("iridescence"): iridescence = float(mat_cfg["iridescence"])
	if mat_cfg.has("transparency"): transparency = float(mat_cfg["transparency"])
	if mat_cfg.has("emission"):
		var em = mat_cfg["emission"]
		if em is Array and em.size() >= 3:
			emission_color = Color(float(em[0]), float(em[1]), float(em[2]))
		elif em is Color:
			emission_color = em
	if mat_cfg.has("emission_energy"): emission_energy = float(mat_cfg["emission_energy"])

func apply_grid_config(config_data: Dictionary) -> void:
	configure(config_data)
	# The endless museum hands config over BEFORE the node enters the tree (the grid
	# defers it until after). Out of the tree there is no grammar yet and nothing to
	# show: generate() here used to die on a null grammar, and with a preset it would
	# build the whole body twice. _ready() builds once, with the values just set.
	if not is_node_ready():
		return
	generate()

# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _ensure_grammar() -> void:
	if grammar == null:
		grammar = MeshGrammar.new()
		grammar.max_faces = max_faces

## Load the recipe `preset` names into this node. Empty name: nothing happens.
## A name no recipe carries is said out loud and leaves the node as it was — it
## does NOT fall back to some other recipe, so a typo shows as the bare seed plus
## a warning rather than as a confident wrong body.
func _apply_preset() -> void:
	var want: String = preset.strip_edges().to_lower()
	if want == "" or want == _applied_preset or want == _refused_preset:
		return
	var spec: Dictionary = MeshGrammarPresets.spec(want)
	if spec.is_empty():
		_refused_preset = want          # say it once, not on every handoff
		push_warning("[MeshGrammarNode] no preset named '%s' — building the bare seed. Known: %s" % [
			preset, ", ".join(MeshGrammarPresets.ids())])
		return
	_applied_preset = want
	clear_rules()            # a preset replaces the rule list, it does not append to it
	apply_spec(spec)

func _create_seed() -> void:
	var mesh_data: MeshData
	match seed_type:
		"cube":
			mesh_data = MeshData.create_cube(seed_scale)
		"sphere":
			mesh_data = MeshData.create_sphere(seed_scale, 12, 16)
		"icosahedron":
			mesh_data = MeshData.create_icosahedron(seed_scale)
		"lathe":
			var scaled := PackedVector2Array()
			var source: PackedVector2Array = seed_profile
			if source.is_empty():
				source = PackedVector2Array([Vector2(0.0, 1.0), Vector2(0.45, 0.6), Vector2(0.85, 0.0), Vector2(1.0, -0.7), Vector2(0.8, -1.0)])
			for point in source:
				scaled.append(point * seed_scale)
			mesh_data = MeshData.create_lathe(scaled, seed_segments)
		"disk":
			mesh_data = MeshData.create_disk(seed_scale, 24)
		"flower_disk":
			mesh_data = MeshData.create_flower_disk(seed_scale, 5, 24)
		"custom":
			# Seed should already be set via set_seed_mesh()
			if grammar.current_mesh != null:
				return
			mesh_data = MeshData.create_icosahedron(seed_scale)
		_:
			mesh_data = MeshData.create_icosahedron(seed_scale)

	grammar.set_seed(mesh_data)

func _update_display(mesh_data: MeshData) -> void:
	if _mesh_instance and mesh_data:
		# Detect if PaintByTagOp has written per-face colours; if so, bake
		# them into vertex colours and use a vertex-colour material.
		var has_face_colors: bool = false
		for md in mesh_data.face_metadata:
			if md is Dictionary and md.has("painted"):
				has_face_colors = true
				break
		_mesh_instance.mesh = mesh_data.to_array_mesh({
			"double_sided": double_sided,
			"face_colors": has_face_colors,
		})
		if has_face_colors:
			# Override with a vertex-colour-aware material so paint shows.
			# Surface qualities (metallic / roughness / iridescence /
			# transparency / emission) come from this node's @exports so
			# they can mirror CritterDNA values one-for-one.
			var vmat := StandardMaterial3D.new()
			vmat.vertex_color_use_as_albedo = true
			vmat.metallic = metallic
			vmat.roughness = roughness
			if iridescence > 0.0:
				vmat.iridescence_enabled = true
				vmat.iridescence = iridescence
			if transparency > 0.01:
				vmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				vmat.albedo_color = Color(1, 1, 1, 1.0 - transparency)
			if emission_energy > 0.0:
				vmat.emission_enabled = true
				vmat.emission = emission_color
				vmat.emission_energy_multiplier = emission_energy
			if double_sided:
				vmat.cull_mode = BaseMaterial3D.CULL_DISABLED
			_mesh_instance.material_override = vmat
		elif _material:
			_mesh_instance.material_override = _material

func _setup_material() -> void:
	if use_grid_material:
		_material = GridMaterialFactory.make(base_color, {"double_sided": double_sided})
	else:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = base_color
		if double_sided:
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.metallic = 0.2
		mat.roughness = 0.6
		_material = mat
