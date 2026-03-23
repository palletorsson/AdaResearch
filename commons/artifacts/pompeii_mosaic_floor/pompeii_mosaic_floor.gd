# pompeii_mosaic_floor.gd
# Multi-zone Roman mosaic floor from Pompeii.
# Composes field, border, corner, and threshold patterns using wallpaper
# group symmetries with opus tessellatum aging effects.
#
# @identity
#   essence: a floor that carries the geometry of Roman domestic space
#   desire: players look down and see 2000-year-old pattern logic still tiling
#   critical_parameter: pattern_name — which composite mosaic to render
#   triggers: loading a composite JSON from the mosaic editor pipeline
#   emerges: the understanding that symmetry groups predate their mathematics
#   needs: [implemented] multi-zone composition, GPU aging shader
#   relationships: pattern_maker_station (creates domains), array_carpet (display)
#   truth: constraint applied to two colors on a grid produced all of Pompeii's floors

extends Node3D
class_name PompeiiMosaicFloor

## Path to composite mosaic JSON (set via apply_grid_config or export)
@export var pattern_path: String = ""

## Global wear level 0-1 (overrides per-zone weathering)
@export_range(0.0, 1.0) var wear_level: float = 0.3

## Floor dimensions in meters
@export var floor_size: Vector2 = Vector2(1.0, 1.0)

## Resolution of the composed texture (higher = sharper)
@export var texture_resolution: int = 128

## Tile shape: 0=square, 1=diagonal TL-BR, 4=diagonal TR-BL, 5=tumbling blocks
@export var tile_shape: int = 0

var _mesh_instance: MeshInstance3D


func _ready() -> void:
	if not pattern_path.is_empty():
		_build_from_composite(pattern_path)
	else:
		_build_default()


func apply_grid_config(config: Dictionary) -> void:
	pattern_path = str(config.get("pattern_name", config.get("pattern_path", "")))
	wear_level = float(config.get("wear_level", 0.3))

	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	elif fs is Vector2:
		floor_size = fs

	texture_resolution = int(config.get("texture_resolution", 128))
	tile_shape = int(config.get("tile_shape", 0))

	if not pattern_path.is_empty():
		_build_from_composite(pattern_path)
	else:
		_build_default()


func _build_from_composite(path: String) -> void:
	# Resolve relative paths
	var full_path := path
	if not path.begins_with("res://"):
		full_path = "res://commons/patterns/mosaics/%s" % path
		if not full_path.ends_with(".json"):
			full_path += ".json"

	var composite = PatternLoader.load_composite(full_path, texture_resolution)
	if not composite:
		push_warning("[PompeiiMosaicFloor] Failed to load composite: %s" % full_path)
		_build_default()
		return

	_create_floor_mesh(composite.composed_texture)
	print("[PompeiiMosaicFloor] Loaded '%s' (%d zones)" % [composite.name, composite.zones.size()])


func _build_default() -> void:
	# Load the truchet pinwheel via the standard PatternLoader pipeline
	var pkg := PatternLoader.load_package("res://commons/patterns/pinwheel_truchet.json")
	if pkg and pkg.domain_texture:
		tile_shape = pkg.tile_shape
		var shader := load("res://commons/resourses/shaders/wallpaper_tile.gdshader") as Shader
		if shader:
			var mat := ShaderMaterial.new()
			mat.shader = shader
			PatternLoader.apply_to_material(mat, pkg)
			# Apply global wear override
			mat.set_shader_parameter("wear_amount", wear_level * 0.5)
			mat.set_shader_parameter("dust_amount", wear_level * 0.3)
			mat.set_shader_parameter("crack_density", wear_level * 0.15)
			_create_floor_mesh_with_material(pkg.domain_texture, mat)
			return

	# Fallback: simple checkerboard
	var default_palette := PackedColorArray([
		Color.html("#141418"),
		Color.html("#EBE6D9"),
	])
	tile_shape = 1
	var tex := PatternLoader._build_domain_texture([[0, 1], [1, 0]], default_palette, 2)
	_create_floor_mesh(tex, 10.0)


func _create_floor_mesh_with_material(_texture: ImageTexture, mat: ShaderMaterial) -> void:
	if _mesh_instance:
		_mesh_instance.queue_free()
	_mesh_instance = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = floor_size
	_mesh_instance.mesh = quad
	_mesh_instance.rotation_degrees.x = -90
	_mesh_instance.position.y = 0.005
	_mesh_instance.material_override = mat
	add_child(_mesh_instance)


func _create_floor_mesh(texture: ImageTexture, override_tile_scale: float = 0.0) -> void:
	# Remove previous mesh if any
	if _mesh_instance:
		_mesh_instance.queue_free()

	_mesh_instance = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = floor_size
	_mesh_instance.mesh = quad

	# Floor orientation: face up
	_mesh_instance.rotation_degrees.x = -90
	_mesh_instance.position.y = 0.005  # Avoid z-fighting

	# Try GPU shader, fall back to simple material
	var shader := load("res://commons/resourses/shaders/wallpaper_tile.gdshader") as Shader
	if shader and texture:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("domain_texture", texture)
		mat.set_shader_parameter("wallpaper_group", 0)  # P1 — symmetry pre-baked
		mat.set_shader_parameter("tile_scale", override_tile_scale if override_tile_scale > 0.0 else 1.0)
		mat.set_shader_parameter("tile_shape", tile_shape)
		mat.set_shader_parameter("grout_width", 0.015)
		mat.set_shader_parameter("noise_distort", 0.005)
		mat.set_shader_parameter("wear_amount", wear_level * 0.5)
		mat.set_shader_parameter("dust_amount", wear_level * 0.3)
		mat.set_shader_parameter("fade_amount", wear_level * 0.2)
		mat.set_shader_parameter("crack_density", wear_level * 0.15)
		mat.set_shader_parameter("stain_amount", wear_level * 0.1)
		mat.set_shader_parameter("chip_amount", wear_level * 0.05)
		_mesh_instance.material_override = mat
	elif texture:
		# Simple fallback with StandardMaterial3D
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = texture
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_mesh_instance.material_override = mat

	add_child(_mesh_instance)
