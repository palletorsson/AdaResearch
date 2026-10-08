extends SceneTree
## probe_necklace_air.gd — WHAT IS ACTUALLY PAINTING THE FRAME.
##
## Palle: "no fog". The first repair set fog_enabled false, dropped the ambient
## flood from 0.7 to 0.10, unshaded the backdrop and darkened it to 0.055 — and
## the rendered frame came back BRIGHTER than before (mean luminance 92.7 -> 115.5)
## with the backdrop reading sRGB (124,129,123) where the arithmetic says (14,15,18).
## Green-dominant, when every colour set is blue-dominant.
##
## Three inferences were tried and all three were wrong (the tonemapper: reverting
## FILMIC to LINEAR moved it 6 points; an artifact body: the tiles-only frame is
## identical; a translucent HUD panel: the algebra does not close). So stop
## inferring and ask the engine.
##
## It reads back, off the live scene:
##   · every Environment in play — the camera's, the WorldEnvironment's, and the
##     viewport's own — property by property, as the engine holds them
##   · every child of the scene root: class, name, visibility, and for anything
##     visual its world AABB and its material's shading mode and albedo
##   · the CanvasLayer tree, because a full-screen Control is the one thing that
##     paints over 3D without appearing in any of the above
##   · the actual pixels, at points chosen to sit on known surfaces
##
##   "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . --xr-mode off \
##     --resolution 1600x900 --script res://commons/testing/probe_necklace_air.gd \
##     -- --out=<dir>

const SCENE := "res://commons/scenes/desktop_necklace.tscn"
const TRIAL_OPS := "user://_air_necklace_ops.json"


func _initialize() -> void:
	_run()


func _run() -> void:
	var outdir := ProjectSettings.globalize_path("user://")
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--out="):
			outdir = str(a).split("=", true, 1)[1]

	var ps := load(SCENE) as PackedScene
	var n: Node = ps.instantiate()
	n.set("ops_path", TRIAL_OPS)
	root.add_child(n)
	# bodies OFF, so nothing an artifact brought can be blamed
	n.call("set_live", false)
	for i in 60:
		await process_frame

	var R: Dictionary = {"probe": "necklace_air", "viewport": [
		root.get_visible_rect().size.x, root.get_visible_rect().size.y]}

	# ── the camera, and every Environment that could be in play
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	R["current_camera"] = "none" if cam == null else String(cam.get_path())
	R["camera_owner"] = "none" if cam == null else cam.get_parent().name
	if cam != null:
		R["camera_pos"] = [cam.global_position.x, cam.global_position.y, cam.global_position.z]
		R["camera_fov"] = cam.fov
		R["camera_env"] = _env_dump(cam.environment)
		R["camera_attributes"] = "null" if cam.attributes == null else str(cam.attributes)
	R["world_env"] = _env_dump(_find_world_env(n))
	R["world_env_node_present"] = _find_world_env_node(n) != null
	R["air_reasserts"] = int(n.call("air_reasserts"))
	## THE VIEWPORT'S OWN. root is a Window, and a Window IS a Viewport — if
	## anything set world_3d's fallback environment or the viewport's own, it wins
	## for nothing else in the scene and nobody would look here.
	var w3: World3D = root.get_world_3d()
	R["world3d_env"] = _env_dump(null if w3 == null else w3.environment)
	R["world3d_fallback_env"] = _env_dump(null if w3 == null else w3.fallback_environment)

	# ── every child of the scene root
	var kids: Array = []
	for c in n.get_children():
		var row: Dictionary = {"name": c.name, "class": c.get_class()}
		if c is Node3D:
			row["visible"] = (c as Node3D).visible
			row["pos"] = [(c as Node3D).position.x, (c as Node3D).position.y, (c as Node3D).position.z]
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			var a: AABB = mi.get_aabb()
			row["aabb"] = [a.position.x, a.position.y, a.position.z, a.size.x, a.size.y, a.size.z]
			row["layers"] = mi.layers
			var mat: Material = mi.material_override
			if mat == null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
				mat = mi.mesh.surface_get_material(0)
			row["mat"] = _mat_dump(mat)
		if c is DirectionalLight3D:
			var dl := c as DirectionalLight3D
			row["energy"] = dl.light_energy
			row["color"] = [dl.light_color.r, dl.light_color.g, dl.light_color.b]
			row["shadow"] = dl.shadow_enabled
		if c is CanvasLayer:
			row["canvas_visible"] = (c as CanvasLayer).visible
			row["children"] = _canvas_dump(c)
		kids.append(row)
	R["root_children"] = kids

	# ── the pixels, off the real frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	if img != null:
		img.save_png(outdir + "/air_frame.png")
		var pts: Dictionary = {
			"sky_top_left": Vector2i(40, 8),
			"sky_top_mid": Vector2i(800, 8),
			"under_hud": Vector2i(800, 175),
			"backdrop": Vector2i(790, 400),
			"backdrop_left": Vector2i(60, 300),
			"floor_near": Vector2i(790, 860),
			"floor_mid": Vector2i(790, 700),
		}
		var got: Dictionary = {}
		for k in pts.keys():
			var p: Vector2i = pts[k]
			var col: Color = img.get_pixelv(p)
			got[str(k)] = [roundi(col.r * 255.0), roundi(col.g * 255.0), roundi(col.b * 255.0)]
		R["pixels"] = got

	## THE CONTROL TEST, AND IT IS THE WHOLE POINT OF THE PROBE. Hide every
	## CanvasLayer under the scene and shoot again. If the wash survives it is 3D;
	## if it vanishes it is a Control nobody counted.
	for c2 in n.get_children():
		if c2 is CanvasLayer:
			(c2 as CanvasLayer).visible = false
	for i2 in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var img2: Image = root.get_texture().get_image()
	if img2 != null:
		img2.save_png(outdir + "/air_frame_nogui.png")
		var got2: Dictionary = {}
		for k2 in ["sky_top_mid", "backdrop", "floor_mid"]:
			var p2: Vector2i = {"sky_top_mid": Vector2i(800, 8),
				"backdrop": Vector2i(790, 400), "floor_mid": Vector2i(790, 700)}[k2]
			var c3: Color = img2.get_pixelv(p2)
			got2[k2] = [roundi(c3.r * 255.0), roundi(c3.g * 255.0), roundi(c3.b * 255.0)]
		R["pixels_no_gui"] = got2

	var f := FileAccess.open(outdir + "/necklace_air.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(R, "  ", false))
		f.close()
	quit(0)


func _find_world_env_node(n: Node) -> WorldEnvironment:
	for c in n.get_children():
		if c is WorldEnvironment:
			return c as WorldEnvironment
	return null


func _find_world_env(n: Node) -> Environment:
	for c in n.get_children():
		if c is WorldEnvironment:
			return (c as WorldEnvironment).environment
	return null


func _env_dump(e: Environment) -> Variant:
	if e == null:
		return "null"
	return {
		"background_mode": e.background_mode,
		"background_color": [e.background_color.r, e.background_color.g, e.background_color.b],
		"background_energy": e.background_energy_multiplier,
		"ambient_source": e.ambient_light_source,
		"ambient_color": [e.ambient_light_color.r, e.ambient_light_color.g, e.ambient_light_color.b],
		"ambient_energy": e.ambient_light_energy,
		"ambient_sky_contribution": e.ambient_light_sky_contribution,
		"fog_enabled": e.fog_enabled,
		"fog_mode": e.fog_mode,
		"fog_light_color": [e.fog_light_color.r, e.fog_light_color.g, e.fog_light_color.b],
		"fog_density": e.fog_density,
		"fog_sky_affect": e.fog_sky_affect,
		"volumetric_fog_enabled": e.volumetric_fog_enabled,
		"tonemap_mode": e.tonemap_mode,
		"tonemap_exposure": e.tonemap_exposure,
		"tonemap_white": e.tonemap_white,
		"glow_enabled": e.glow_enabled,
		"ssao_enabled": e.ssao_enabled,
		"ssil_enabled": e.ssil_enabled,
		"sdfgi_enabled": e.sdfgi_enabled,
		"adjustment_enabled": e.adjustment_enabled,
		"adjustment_brightness": e.adjustment_brightness,
		"adjustment_contrast": e.adjustment_contrast,
		"adjustment_saturation": e.adjustment_saturation,
	}


func _mat_dump(m: Material) -> Variant:
	if m == null:
		return "null"
	if not (m is BaseMaterial3D):
		return m.get_class()
	var b := m as BaseMaterial3D
	return {
		"class": b.get_class(),
		"shading_mode": b.shading_mode,
		"albedo": [b.albedo_color.r, b.albedo_color.g, b.albedo_color.b, b.albedo_color.a],
		"transparency": b.transparency,
		"blend_mode": b.blend_mode,
		"cull_mode": b.cull_mode,
		"roughness": b.roughness,
		"metallic": b.metallic,
		"emission_enabled": b.emission_enabled,
	}


## Every Control under a CanvasLayer, with the two facts that decide whether it
## is painting the whole frame: its RECT and its modulate alpha.
func _canvas_dump(layer: Node) -> Array:
	var out: Array = []
	var stack: Array = layer.get_children()
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		if c is Control:
			var ct := c as Control
			out.append({
				"name": ct.name, "class": ct.get_class(), "visible": ct.visible,
				"rect": [ct.global_position.x, ct.global_position.y, ct.size.x, ct.size.y],
				"modulate_a": ct.modulate.a, "self_modulate_a": ct.self_modulate.a,
			})
			# only the top two levels; the leaves are labels and buttons
			if ct.get_parent() == layer:
				for g in ct.get_children():
					stack.append(g)
	return out
