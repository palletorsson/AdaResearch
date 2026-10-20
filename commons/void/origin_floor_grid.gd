extends MeshInstance3D
## Fixed world reference: X/Z in metres, on the Y=0 roof.
## The ink is lifted 8 mm to keep it distinct from the slab's depth.
func _ready() -> void:
	name = "OriginFloorGrid"
	var plane := QuadMesh.new()
	plane.size = Vector2(5.2,5.2)
	mesh = plane
	rotation.x = -PI/2
	position = Vector3(0,0.008,0)
	var ink := StandardMaterial3D.new()
	ink.albedo_texture = load("res://commons/void/textures/origin-floor-grid.png")
	ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	ink.alpha_scissor_threshold = 0.3
	ink.roughness = 1.0
	ink.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material_override = ink
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
