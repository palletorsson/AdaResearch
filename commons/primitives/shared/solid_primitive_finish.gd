extends RefCounted
## Optional opaque pigment for a placed primitive: #solid_color:B7C7DB.
## A missing, empty or invalid colour preserves the supplied original material.
static func for_instance(node: Node, fallback: Material) -> Material:
	var pigment := str(node.get_meta("config_solid_color", "")).strip_edges()
	if pigment.is_empty() or not Color.html_is_valid(pigment):
		return fallback
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.html(pigment)
	material.roughness = 0.92
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
