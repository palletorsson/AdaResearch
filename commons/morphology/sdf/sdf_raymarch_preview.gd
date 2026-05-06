# sdf_raymarch_preview.gd
# Drop-in replacement for sdf_voxel_preview.gd. Same API surface (sdf
# property, rebuild(), auto_rebuild_on_ready), but renders via a single
# box + fragment raymarching shader instead of thousands of voxel cubes.
#
# For static SDFs this is 100× cheaper per frame (one draw call, zero
# CPU voxel iteration). For animated SDFs (BlendedSDF with ping-pong t)
# you still rebuild the Texture3D — but that's an async-friendly bake,
# not a per-frame voxel loop.

extends Node3D

const SDFToTexture3D = preload("res://commons/morphology/sdf/sdf_to_texture3d.gd")

@export var sdf: Resource  # FormSDF
@export var resolution: Vector3i = Vector3i(64, 64, 64)
@export var base_color: Color = Color(0.9, 0.85, 0.75)
@export var edge_color: Color = Color(1.0, 0.95, 0.8)
@export var rim_strength: float = 0.7
@export var rim_power: float = 2.5
@export var roughness: float = 0.55
@export var auto_rebuild_on_ready: bool = true

var _mi: MeshInstance3D = null
var _material: ShaderMaterial = null


func _ready() -> void:
	if auto_rebuild_on_ready and sdf != null:
		rebuild()


func set_sdf(new_sdf: Resource) -> void:
	sdf = new_sdf
	rebuild()


func rebuild() -> void:
	if _mi:
		_mi.queue_free()
		_mi = null
	if sdf == null:
		return

	var aabb: AABB = sdf.get_aabb()
	var tex: ImageTexture3D = SDFToTexture3D.bake(sdf, resolution)
	if tex == null:
		push_warning("SDFRaymarchPreview: bake returned null")
		return

	# Box mesh matching the AABB — this is the volume the fragment shader
	# marches through.
	var mesh := BoxMesh.new()
	mesh.size = aabb.size

	var shader: Shader = load("res://commons/morphology/sdf/shaders/sdf_raymarch.gdshader")
	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("sdf_tex", tex)
	_material.set_shader_parameter("aabb_min", aabb.position)
	_material.set_shader_parameter("aabb_size", aabb.size)
	_material.set_shader_parameter("base_color", base_color)
	_material.set_shader_parameter("edge_color", edge_color)
	_material.set_shader_parameter("rim_strength", rim_strength)
	_material.set_shader_parameter("rim_power", rim_power)
	_material.set_shader_parameter("roughness_val", roughness)

	_mi = MeshInstance3D.new()
	_mi.name = "SDFRaymarch"
	_mi.mesh = mesh
	_mi.material_override = _material
	_mi.position = aabb.position + aabb.size * 0.5
	# Generous custom_aabb so Godot doesn't frustum-cull when the camera
	# is inside or grazing the box.
	_mi.custom_aabb = AABB(-aabb.size, aabb.size * 2.0)
	_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	add_child(_mi)


## Update shader parameters without a full rebuild. Useful for live
## morphing when the Texture3D contents change (re-bake) or when only
## color/rim parameters change (skip re-bake).
func set_color_params(base: Color, edge: Color, rim: float) -> void:
	base_color = base
	edge_color = edge
	rim_strength = rim
	if _material:
		_material.set_shader_parameter("base_color", base)
		_material.set_shader_parameter("edge_color", edge)
		_material.set_shader_parameter("rim_strength", rim)
