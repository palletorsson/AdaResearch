@tool
extends Node3D
class_name FacadeGrammarNode

## Node3D wrapper for FacadeGrammar.
## Renders architectural facades as 3D meshes.
## Supports grid system integration via apply_grid_config().

## === EXPORTS ===

@export_group("Facade")
## Number of vertical bay divisions
@export var bays: int = 5:
	set(v):
		bays = clampi(v, 1, 20)
		_needs_rebuild = true

## Facade symmetry mode
@export_enum("None", "Bilateral", "Axial Rhythm", "Hierarchical")
var symmetry: int = 1:
	set(v):
		symmetry = v
		_needs_rebuild = true

## Total facade width in meters
@export var total_width: float = 10.0:
	set(v):
		total_width = v
		_needs_rebuild = true

## Total facade height in meters
@export var total_height: float = 12.0:
	set(v):
		total_height = v
		_needs_rebuild = true

@export_group("Study Pack")
## Study pack name (e.g., "italy", "japan", "new_york")
@export var study_pack: String = "":
	set(v):
		study_pack = v
		if v != "" and is_inside_tree():
			_load_pack_and_rebuild()

## Preset name from the study pack
@export var preset: String = "":
	set(v):
		preset = v
		if v != "" and is_inside_tree():
			_load_preset_and_rebuild()

@export_group("Appearance")
## Base facade color
@export var base_color: Color = Color(0.85, 0.8, 0.72):
	set(v):
		base_color = v
		_update_material()

## Roughness
@export var roughness: float = 0.8:
	set(v):
		roughness = v
		_update_material()

## Double-sided rendering
@export var double_sided: bool = false

@export_group("Animation")
## Animate generation steps
@export var animate: bool = false

## Animation speed (generations per second)
@export var animation_speed: float = 0.5

## === SIGNALS ===
signal facade_generated()

## === INTERNAL ===
var _facade: FacadeGrammar = null
var _mesh_instance: MeshInstance3D = null
var _material: StandardMaterial3D = null
var _needs_rebuild: bool = false


func _ready() -> void:
	_facade = FacadeGrammar.new()
	_create_mesh_instance()

	if study_pack != "":
		_load_pack_and_rebuild()
	elif preset != "":
		_load_preset_and_rebuild()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if _needs_rebuild:
		_needs_rebuild = false
		_rebuild()


func _create_mesh_instance() -> void:
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "FacadeMesh"
	add_child(_mesh_instance)

	_material = StandardMaterial3D.new()
	_material.albedo_color = base_color
	_material.roughness = roughness
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED if double_sided else BaseMaterial3D.CULL_BACK
	_mesh_instance.material_override = _material


func _update_material() -> void:
	if _material:
		_material.albedo_color = base_color
		_material.roughness = roughness


func _load_pack_and_rebuild() -> void:
	if not _facade:
		return
	_facade.load_study_pack(study_pack)
	if preset != "":
		_facade.load_preset(preset)
	_rebuild()


func _load_preset_and_rebuild() -> void:
	if not _facade:
		return
	if study_pack != "":
		_facade.load_study_pack(study_pack)
	_facade.load_preset(preset)
	_rebuild()


func _rebuild() -> void:
	if not _facade or not _mesh_instance:
		return

	# Configure facade from exports
	_facade.total_width = total_width
	_facade.total_height = total_height
	_facade.bays = bays
	_facade.symmetry = symmetry as FacadeGrammar.FacadeSymmetry

	# Generate mesh
	var mesh_data := _facade.generate()
	if not mesh_data or mesh_data.face_count() == 0:
		return

	# Convert to ArrayMesh
	var array_mesh := mesh_data.to_array_mesh({
		"double_sided": double_sided,
		"generate_normals": true
	})

	_mesh_instance.mesh = array_mesh
	facade_generated.emit()


## === GRID CONFIG INTEGRATION ===

## Apply configuration from grid system / artifact registry.
func apply_grid_config(config_data: Dictionary) -> void:
	print("FacadeGrammarNode: Applying config: %s" % config_data)

	if config_data.has("study_pack"):
		study_pack = str(config_data["study_pack"])

	if config_data.has("preset"):
		preset = str(config_data["preset"])

	if config_data.has("bays"):
		bays = int(config_data["bays"])

	if config_data.has("total_width"):
		total_width = float(config_data["total_width"])

	if config_data.has("total_height"):
		total_height = float(config_data["total_height"])

	if config_data.has("symmetry"):
		var sym_str := str(config_data["symmetry"]).to_lower()
		match sym_str:
			"none": symmetry = 0
			"bilateral": symmetry = 1
			"axial_rhythm", "axial": symmetry = 2
			"hierarchical": symmetry = 3

	if config_data.has("base_color"):
		var color_str := str(config_data["base_color"])
		if color_str.begins_with("#"):
			base_color = Color.html(color_str)

	# Load study pack and preset
	if study_pack != "":
		_load_pack_and_rebuild()
	elif preset != "":
		_load_preset_and_rebuild()
	else:
		_needs_rebuild = true


## Get the internal FacadeGrammar for direct manipulation.
func get_facade_grammar() -> FacadeGrammar:
	return _facade


## Get available presets (requires study pack loaded).
func get_available_presets() -> Array[String]:
	if _facade:
		return _facade.get_available_presets()
	return []
