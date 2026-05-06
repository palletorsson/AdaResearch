class_name WavefunctionResources
extends RefCounted

## Shared resources for wavefunction visualizations
## Uses static pattern - no autoload needed, lazy initialization
##
## Usage:
##   var mesh = WavefunctionResources.get_trail_sphere()
##   var mat = WavefunctionResources.get_emissive_material(Color.ORANGE, 0.5)

# =============================================================================
# SHARED MESHES
# =============================================================================

static var _trail_sphere: SphereMesh
static var _unit_sphere: SphereMesh
static var _point_sphere: SphereMesh

## Small sphere for trail visualization (radius 0.02)
static func get_trail_sphere() -> SphereMesh:
	if not _trail_sphere:
		_trail_sphere = SphereMesh.new()
		_trail_sphere.radius = 0.02
		_trail_sphere.height = 0.04
		_trail_sphere.radial_segments = 8
		_trail_sphere.rings = 4
	return _trail_sphere

## Unit sphere (radius 1.0) for general use
static func get_unit_sphere() -> SphereMesh:
	if not _unit_sphere:
		_unit_sphere = SphereMesh.new()
		_unit_sphere.radius = 1.0
		_unit_sphere.height = 2.0
		_unit_sphere.radial_segments = 32
		_unit_sphere.rings = 16
	return _unit_sphere

## Tiny point sphere for particles (radius 0.01)
static func get_point_sphere() -> SphereMesh:
	if not _point_sphere:
		_point_sphere = SphereMesh.new()
		_point_sphere.radius = 0.01
		_point_sphere.height = 0.02
		_point_sphere.radial_segments = 6
		_point_sphere.rings = 3
	return _point_sphere

# =============================================================================
# MATERIAL CACHE
# =============================================================================

static var _material_cache: Dictionary = {}

## Get or create an emissive material with the given color and alpha
## Materials are cached by color+alpha key for reuse
static func get_emissive_material(color: Color, alpha: float = 1.0, emission_strength: float = 0.5) -> StandardMaterial3D:
	var key = "%s_%.2f_%.2f" % [color.to_html(false), alpha, emission_strength]
	
	if not _material_cache.has(key):
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(color.r, color.g, color.b, alpha)
		mat.emission_enabled = true
		mat.emission = color * emission_strength
		mat.emission_energy_multiplier = 1.0
		if alpha < 1.0:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material_cache[key] = mat
	
	return _material_cache[key]

## Get a simple unlit material (no emission)
static func get_simple_material(color: Color, alpha: float = 1.0) -> StandardMaterial3D:
	var key = "simple_%s_%.2f" % [color.to_html(false), alpha]
	
	if not _material_cache.has(key):
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(color.r, color.g, color.b, alpha)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		if alpha < 1.0:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material_cache[key] = mat
	
	return _material_cache[key]

## Get transparent glass-like material
static func get_glass_material(color: Color, opacity: float = 0.3) -> StandardMaterial3D:
	var key = "glass_%s_%.2f" % [color.to_html(false), opacity]
	
	if not _material_cache.has(key):
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(color.r, color.g, color.b, opacity)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.emission_enabled = true
		mat.emission = color * 0.2
		_material_cache[key] = mat
	
	return _material_cache[key]

# =============================================================================
# MULTIMESH HELPERS
# =============================================================================

## Create a MultiMesh configured for trail/particle visualization
static func create_trail_multimesh(instance_count: int, use_colors: bool = true) -> MultiMesh:
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = use_colors
	mm.instance_count = instance_count
	mm.mesh = get_trail_sphere()
	return mm

## Create a MultiMeshInstance3D ready to use for trails
static func create_trail_multimesh_instance(instance_count: int, base_color: Color = Color.WHITE) -> MultiMeshInstance3D:
	var mmi = MultiMeshInstance3D.new()
	mmi.multimesh = create_trail_multimesh(instance_count, true)
	mmi.material_override = get_emissive_material(base_color, 1.0, 0.8)
	
	# Initialize all instances as invisible (scale 0)
	for i in range(instance_count):
		mmi.multimesh.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
	
	return mmi

# =============================================================================
# AUDIO HELPERS
# =============================================================================

static var _sine_table: PackedFloat32Array
static var _square_table: PackedFloat32Array
const WAVE_TABLE_SIZE = 4096

## Get precomputed sine wave lookup table
static func get_sine_table() -> PackedFloat32Array:
	if _sine_table.is_empty():
		_sine_table.resize(WAVE_TABLE_SIZE)
		for i in range(WAVE_TABLE_SIZE):
			var phase = (float(i) / float(WAVE_TABLE_SIZE)) * TAU
			_sine_table[i] = sin(phase)
	return _sine_table

## Get precomputed square wave lookup table
static func get_square_table() -> PackedFloat32Array:
	if _square_table.is_empty():
		_square_table.resize(WAVE_TABLE_SIZE)
		for i in range(WAVE_TABLE_SIZE):
			_square_table[i] = 1.0 if i < WAVE_TABLE_SIZE / 2 else -1.0
	return _square_table

## Fast sine lookup (phase 0.0 to 1.0)
static func fast_sine(phase: float) -> float:
	var table = get_sine_table()
	var index = int(fposmod(phase, 1.0) * WAVE_TABLE_SIZE) % WAVE_TABLE_SIZE
	return table[index]

## Fast square wave lookup (phase 0.0 to 1.0)
static func fast_square(phase: float) -> float:
	var table = get_square_table()
	var index = int(fposmod(phase, 1.0) * WAVE_TABLE_SIZE) % WAVE_TABLE_SIZE
	return table[index]

# =============================================================================
# UTILITY
# =============================================================================

## Clear all cached materials (call if memory is a concern)
static func clear_cache() -> void:
	_material_cache.clear()

## Get cache statistics
static func get_cache_stats() -> Dictionary:
	return {
		"materials_cached": _material_cache.size(),
		"trail_sphere_created": _trail_sphere != null,
		"unit_sphere_created": _unit_sphere != null,
		"sine_table_created": not _sine_table.is_empty()
	}
