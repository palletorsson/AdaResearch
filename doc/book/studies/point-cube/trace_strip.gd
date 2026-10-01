extends MeshInstance3D
## Supplied display. One contract: draw(points).
## Give it the whole list each time; it clears and draws again. Each position is
## joined to the next by a straight segment. Fewer than two positions draw nothing.
## Positions are drawn in this node's own frame. It sits unmoved at its parent's
## origin, so that is the parent's frame too. We open this code in Point_Triangle_Context.

func _ready() -> void:
	mesh = ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.3, 0.6)
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func draw(points: Array[Vector3]) -> void:
	var strip := mesh as ImmediateMesh
	strip.clear_surfaces()
	if points.size() < 2:
		return
	strip.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for point in points:
		strip.surface_add_vertex(point)
	strip.surface_end()
