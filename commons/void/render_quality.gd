extends Node
## Scene-scoped rendering. Geometry AA preserves small text and fine moving lines.
enum Profile { BALANCED, PERFORMANCE }
var viewport: Viewport
var previous: Dictionary = {}
var filtered_materials: Dictionary = {}
var profile := Profile.BALANCED

func configure(target: Viewport, selected: int) -> void:
	viewport = target
	for property in ["msaa_3d", "screen_space_aa", "use_taa", "use_debanding", "anisotropic_filtering_level"]:
		previous[property] = viewport.get(property)
	profile = selected
	apply()

func apply() -> void:
	viewport.msaa_3d = Viewport.MSAA_2X if profile == Profile.PERFORMANCE else Viewport.MSAA_4X
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	viewport.use_taa = false
	viewport.anisotropic_filtering_level = Viewport.ANISOTROPY_8X
	viewport.use_debanding = RenderingServer.get_current_rendering_method() != "gl_compatibility"
	# Mobile uses a material shader flag as well as the viewport flag.
	RenderingServer.material_set_use_debanding(viewport.use_debanding)

func filter_branch(branch: Node) -> void:
	# Duplicate only eligible textured materials: never edit the museum's shared resources.
	if branch is MeshInstance3D:
		if branch.material_override != null:
			branch.material_override = filtered(branch.material_override)
		elif branch.mesh != null:
			for surface in range(branch.mesh.get_surface_count()):
				var source: Material = branch.get_active_material(surface)
				var result := filtered(source)
				if result != source: branch.set_surface_override_material(surface, result)
	elif branch is MultiMeshInstance3D and branch.multimesh != null:
		if branch.material_override != null:
			branch.material_override = filtered(branch.material_override)
		elif branch.multimesh.mesh != null and branch.multimesh.mesh.get_surface_count() == 1:
			var source: Material = branch.multimesh.mesh.surface_get_material(0)
			var result := filtered(source)
			if result != source: branch.material_override = result
	for child in branch.get_children(): filter_branch(child)

func filtered(source: Material) -> Material:
	if not source is BaseMaterial3D: return source
	if source.texture_filter != BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS: return source
	if filtered_materials.has(source): return filtered_materials[source]
	var eligible := false
	for slot in [BaseMaterial3D.TEXTURE_ALBEDO, BaseMaterial3D.TEXTURE_NORMAL, BaseMaterial3D.TEXTURE_ROUGHNESS, BaseMaterial3D.TEXTURE_METALLIC, BaseMaterial3D.TEXTURE_EMISSION]:
		var texture: Texture2D = source.get_texture(slot)
		if texture != null and not texture is ViewportTexture:
			eligible = true
			break
	if not eligible: return source
	var result: BaseMaterial3D = source.duplicate()
	result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	filtered_materials[source] = result
	return result

func _exit_tree() -> void:
	if is_instance_valid(viewport):
		for property in previous: viewport.set(property, previous[property])
	# Mobile's material flag must agree with the restored main viewport.
	RenderingServer.material_set_use_debanding(bool(previous.get("use_debanding", ProjectSettings.get_setting("rendering/anti_aliasing/quality/use_debanding", false))))
	filtered_materials.clear()
