extends Node
## Freeze an installation's visible geometry, then photograph it in a private
## world. No scripts, physics, RNG calls or viewer camera are copied or changed.
## The resulting PNG is used unchanged by both the wall and the book.
const FILTER = preload("res://commons/book/book_image_filter.gdshader")
var viewport: SubViewport
var receipt: Dictionary = {}
var dimensions := Vector2i(1600, 1200)

static func xyz(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

static func vector(value: Array) -> Vector3:
	return Vector3(value[0], value[1], value[2])

static func pose(value: Transform3D) -> Array:
	return [xyz(value.basis.x), xyz(value.basis.y), xyz(value.basis.z), xyz(value.origin)]

func freeze(source: Node3D, choice: Dictionary) -> void:
	viewport = SubViewport.new()
	viewport.name = "InstallationExposure"
	viewport.size = dimensions
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	var visual := Node3D.new()
	viewport.add_child(visual)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	var view: Dictionary = choice.camera
	camera.position = source.to_global(vector(view.eye))
	camera.look_at(source.to_global(vector(view.target)), source.global_basis.y.normalized())
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = float(view.height) * source.global_basis.get_scale().y
	camera.near = 0.01
	camera.far = 100.0
	camera.current = true
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("f3f0e7")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.7
	camera.environment = environment
	var sun := DirectionalLight3D.new()
	viewport.add_child(sun)
	sun.rotation_degrees = Vector3(-35,-40,0)
	sun.basis = source.global_basis.orthonormalized() * sun.basis
	sun.light_energy = 0.6
	var omitted: Array[String] = []
	_copy_visuals(source, source, visual, choice, omitted, true)
	var state: Dictionary = {}
	if source.has_method("capture_book_state"): state = source.capture_book_state()
	elif source.has_method("capture"): state = source.capture()
	receipt = {"id":choice.id, "artifact":choice.artifact, "choice":choice.duplicate(true),
		"source_transform":pose(source.global_transform), "camera_transform":pose(camera.global_transform),
		"camera_height":camera.size, "state":state, "visual_count":visual.get_child_count(),
		"omitted":omitted, "dimensions":[dimensions.x,dimensions.y],
		"method":"Actual arrival geometry; orthographic crop; labels/casing omitted only as declared; fixed print lighting; declared print filter; no invented marks."}

func _copy_visuals(node: Node, source: Node3D, into: Node3D, choice: Dictionary, omitted: Array[String], is_root := false) -> void:
	# Museum distance-culling may hide the artifact root. Preserve its own child
	# visibility instead; an offscreen installation must still be photographable.
	if not is_root and node is Node3D and not node.visible: return
	if (bool(choice.get("omit_casing", false)) and bool(node.get_meta("book_capture_omit", false))) or (bool(choice.get("omit_labels", false)) and node is Label3D):
		omitted.append(str(source.get_path_to(node)))
		return
	var copy: Node3D
	if node is MeshInstance3D or node is MultiMeshInstance3D or node is Label3D or node is Sprite3D:
		copy = node.duplicate(0)
		for child in copy.get_children(): child.free()
		copy.set_script(null)
		copy.visible = true
		copy.layers = 1
		copy.visibility_parent = NodePath()
		copy.transform = node.global_transform
		if copy is GeometryInstance3D:
			copy.visibility_range_begin = 0.0
			copy.visibility_range_end = 0.0
			if copy.material_override: copy.material_override = _freeze_material(copy.material_override)
			if copy.material_overlay: copy.material_overlay = _freeze_material(copy.material_overlay)
		if copy is MeshInstance3D and copy.mesh: copy.mesh = _freeze_mesh(copy.mesh)
		if copy is MultiMeshInstance3D and copy.multimesh:
			copy.multimesh = copy.multimesh.duplicate(false)
			copy.multimesh.mesh = _freeze_mesh(copy.multimesh.mesh)
		if copy is Label3D: copy.outline_size = 0
		into.add_child(copy)
	for child in node.get_children(): _copy_visuals(child,source,into,choice,omitted)

func _freeze_material(original: Material) -> Material:
	# Deep duplication loses a ViewportTexture's owning viewport. Keep ordinary
	# textures shared, but resolve live screen textures into immutable pixels.
	var copy: Material = original.duplicate(false)
	for property in original.get_property_list():
		var value: Variant = original.get(property.name)
		if value is ViewportTexture:
			var pixels: Image = value.get_image()
			if pixels != null and not pixels.is_empty(): copy.set(property.name,ImageTexture.create_from_image(pixels))
			else: copy.set(property.name,null)
	return copy

func _freeze_mesh(original: Mesh) -> Mesh:
	var copy: Mesh = original.duplicate(false)
	for surface in original.get_surface_count():
		var material := original.surface_get_material(surface)
		if material != null: copy.surface_set_material(surface,_freeze_material(material))
	return copy

func render(folder: String) -> Dictionary:
	if DisplayServer.get_name() == "headless":
		return {"ok":false, "error":"A rendering device is required for a wall photograph."}
	var started := Time.get_ticks_msec()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for frame in 3: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var raw := viewport.get_texture().get_image()
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var print_view := SubViewport.new()
	print_view.size = dimensions
	print_view.disable_3d = true
	print_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(print_view)
	var rect := TextureRect.new()
	rect.size = Vector2(dimensions)
	rect.texture = ImageTexture.create_from_image(raw)
	var material := ShaderMaterial.new()
	material.shader = FILTER
	var treatment: Dictionary = receipt.choice.filter
	material.set_shader_parameter("source_image",rect.texture)
	material.set_shader_parameter("source_size",Vector2(dimensions))
	for key in ["treatment", "line_width", "sensitivity"]: material.set_shader_parameter(key,treatment[key])
	material.set_shader_parameter("edge_softness",float(treatment.get("edge_softness",0.18)))
	material.set_shader_parameter("tone_white",float(treatment.get("tone_white",0.94)))
	material.set_shader_parameter("tone_black",float(treatment.get("tone_black",0.06)))
	rect.material = material
	print_view.add_child(rect)
	for frame in 3: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var result := print_view.get_texture().get_image()
	print_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var err := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	if err != OK: return {"ok":false,"error":"Cannot create capture folder."}
	var path := folder.path_join(str(receipt.id)+".png")
	if result.save_png(path) != OK: return {"ok":false,"error":"Cannot save wall photograph."}
	raw.save_png(folder.path_join(str(receipt.id)+"-source.png"))
	receipt["image"] = path.get_file()
	receipt["sha256"] = FileAccess.get_sha256(path)
	receipt["render_ms"] = Time.get_ticks_msec() - started
	# Release both rendering worlds; frames retain only the final still texture.
	viewport.queue_free()
	print_view.queue_free()
	return {"ok":true,"image":result,"receipt":receipt.duplicate(true)}
