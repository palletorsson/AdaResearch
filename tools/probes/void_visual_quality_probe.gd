extends "res://tools/probes/void_evening_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	# Simulate arriving from a menu with different settings.
	root.msaa_3d = Viewport.MSAA_2X
	root.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	root.use_debanding = false
	root.anisotropic_filtering_level = Viewport.ANISOTROPY_4X
	await start(false)
	quality_contract("Desktop")
	material_contract()
	game.atmosphere.animate_sky = false
	game.atmosphere.set_sky_time(180)
	await visit(3)
	check("Streaming a new floor keeps the quality profile", root.msaa_3d == Viewport.MSAA_4X)
	await paired("line-collection", Vector3(17.9,-16.35,-1.4), Vector3(16.4,-16.1,-5.8), 80)
	await visit(4)
	check("Grid remains at the authored shaft position", game.building.content.exhibits["4/record"].get_node("Artifact/GridReplay/SavedTraceGrid").global_position.is_equal_approx(Vector3(-10,-25,0)))
	await paired("grid-shaft", Vector3(-5.5,-22.35,4.1), Vector3(-9.8,-24.2,0), 75)
	await visit(1)
	await paired("point-one", Vector3(0,-4.35,6.8), Vector3(0,-4.6,-1.7), 78)
	game.render_quality.profile = 1
	game.render_quality.apply()
	check("Lighter profile uses 2x MSAA without FXAA", root.msaa_3d == Viewport.MSAA_2X and root.screen_space_aa == Viewport.SCREEN_SPACE_AA_DISABLED)
	game.queue_free(); await frames(20)
	check("Leaving restores the menu's AA and filtering", root.msaa_3d == Viewport.MSAA_2X and root.screen_space_aa == Viewport.SCREEN_SPACE_AA_FXAA and not root.use_debanding and root.anisotropic_filtering_level == Viewport.ANISOTROPY_4X)
	await start(true)
	quality_contract("XR")
	check("Actual XR camera shares the configured viewport", game.camera is XRCamera3D and game.camera.get_viewport() == game.render_quality.viewport)
	game.queue_free(); await frames(20)
	for tracker in [head,left,right]: XRServer.remove_tracker(tracker)
	OS.delay_msec(200); await frames(10)
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"renderer":RenderingServer.get_current_rendering_method(),"scope":"Actual tower and synthetic XR rig; matched native renders. No headset frame-time measurement."},"\t"))
	quit(0 if failed.is_empty() else 1)

func quality_contract(label: String) -> void:
	check(label + ": balanced enables 4x geometry AA", root.msaa_3d == Viewport.MSAA_4X)
	check(label + ": no temporal accumulation or full-screen blur", not root.use_taa and root.screen_space_aa == Viewport.SCREEN_SPACE_AA_DISABLED)
	check(label + ": 8x anisotropic filtering", root.anisotropic_filtering_level == Viewport.ANISOTROPY_8X)
	check(label + ": debanding follows renderer support", root.use_debanding == (RenderingServer.get_current_rendering_method() != "gl_compatibility"))

func material_contract() -> void:
	var image := Image.create(8,8,false,Image.FORMAT_RGBA8)
	image.fill(Color.WHITE); image.generate_mipmaps()
	var source := StandardMaterial3D.new()
	source.albedo_texture = ImageTexture.create_from_image(image)
	var result: BaseMaterial3D = game.render_quality.filtered(source)
	check("Textured finish gets a local anisotropic copy", result != source and result.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC)
	check("Shared source finish remains unchanged", source.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS)
	check("Copies are reused across repeated props", game.render_quality.filtered(source) == result)
	var solid := StandardMaterial3D.new()
	check("Untextured materials are not duplicated", game.render_quality.filtered(solid) == solid)
	source.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	check("Intentional pixel-art filtering is preserved", game.render_quality.filtered(source) == source)
	source.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var host := MeshInstance3D.new()
	host.mesh = BoxMesh.new(); host.mesh.material = source
	game.add_child(host)
	game.render_quality.filter_branch(host)
	check("Filtering reaches mesh surfaces without changing their mesh", host.get_surface_override_material(0) == result and host.mesh.material == source)
	host.queue_free()

func paired(label: String, eye: Vector3, target: Vector3, fov: float) -> void:
	# The older capture helpers force MSAA; these captures deliberately do not.
	root.msaa_3d = Viewport.MSAA_DISABLED
	root.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	root.use_debanding = false
	RenderingServer.material_set_use_debanding(false)
	await photograph(label + "-off.png", eye, target, fov)
	game.render_quality.apply()
	await photograph(label + "-on.png", eye, target, fov)
	check(label + ": matching off/on renders saved", FileAccess.file_exists(out.path_join(label+"-on.png")) and FileAccess.file_exists(out.path_join(label+"-off.png")))

func photograph(filename: String, at: Vector3, target: Vector3, field_of_view := 75.0) -> void:
	game.status.hide(); game.notice_time = -1
	for layer in game.find_children("*","CanvasLayer",true,false): layer.hide()
	for avatar in game.find_children("Avatar","Node3D",true,false): avatar.hide()
	var cam := Camera3D.new()
	cam.fov = field_of_view
	root.add_child(cam)
	cam.environment = game.atmosphere.environment
	cam.position = at; cam.look_at(target); cam.make_current()
	await frames(25); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(filename))
	cam.queue_free(); await frames(2)
	game.camera.make_current()
