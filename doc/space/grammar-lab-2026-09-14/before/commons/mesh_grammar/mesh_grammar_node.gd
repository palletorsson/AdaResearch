## MeshGrammarNode — Node3D that displays a MeshGrammar result.
## Owns a MeshGrammar, renders the output as MeshInstance3D.
## Supports static generation and animated evolution.
## Modeled after KreslingSpire (owns geometry solver, rebuilds mesh, @export params).
extends Node3D
class_name MeshGrammarNode

const GridMaterialFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")

@export_group("Seed")
@export_enum("cube", "icosahedron", "sphere", "disk", "flower_disk", "custom") var seed_type: String = "icosahedron"
@export var seed_scale: float = 0.5

@export_group("Grammar")
@export var generations: int = 2
@export var max_faces: int = 10000
@export var auto_generate: bool = true

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

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_ensure_grammar()
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

## Configure from a dictionary (for map/grid system integration).
func configure(config: Dictionary) -> void:
	if config.has("seed"):
		seed_type = str(config["seed"])
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
	generate()

# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _ensure_grammar() -> void:
	if grammar == null:
		grammar = MeshGrammar.new()
		grammar.max_faces = max_faces

func _create_seed() -> void:
	var mesh_data: MeshData
	match seed_type:
		"cube":
			mesh_data = MeshData.create_cube(seed_scale)
		"sphere":
			mesh_data = MeshData.create_sphere(seed_scale, 12, 16)
		"icosahedron":
			mesh_data = MeshData.create_icosahedron(seed_scale)
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
