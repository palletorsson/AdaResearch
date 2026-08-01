extends SceneTree

## Photographs each catalyst projectile mode in flight.
##
## For every projectile mode (the 10 bound ones), calls the mode script's
## create_projectile(), lets the body fly ~0.55 s so trails, oscillation and
## spin develop, then parks a camera beside its CURRENT position and grabs a
## frame. One boot, ten tiles -> user://catalyst_projectiles/<mode>.png.
## Assemble the labelled sheet with tools/build_projectile_gallery.py.
##
## Run:
##   godot --path . --xr-mode off --no-window --script res://commons/testing/capture_catalyst_projectiles.gd

const MODES := [
	"primitives", "transformation", "chromatic", "forces", "waveform",
	"chaos", "cellular", "fractal", "branching", "swarm",
]
const MODE_DIR := "res://commons/hazards/becoming_catalyst/modes/"
const OUT_DIR := "user://catalyst_projectiles"
const FLIGHT_FRAMES := 80   # ~1.33 s at 60 fps — past fractal's 1.0 s split
const FOE_SCENE := preload("res://commons/hazards/catalyst_foe/catalyst_foe.tscn")
const HIT_TIMEOUT_FRAMES := 130   # give slow/wandering projectiles time to arrive
const AFTER_HIT_FRAMES := 10      # ~0.17 s — mid-shockwave: ring expanding, flash fading, light lit

func _initialize() -> void:
	get_root().size = Vector2i(720, 720)
	DirAccess.make_dir_recursive_absolute(OUT_DIR)

	var stage := Node3D.new()
	stage.name = "Stage"
	get_root().add_child(stage)

	# The gallery's dark stage — matches the proposal page's panel ground.
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.047, 0.067, 0.106)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.56, 0.66)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.6
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -30, 0)
	sun.light_energy = 0.8
	stage.add_child(sun)

	var cam := Camera3D.new()
	cam.name = "Cam"
	cam.fov = 50.0
	# Camera-level environment beats any autoload's WorldEnvironment —
	# without this the project's default green sky wins the frame.
	cam.environment = env
	stage.add_child(cam)
	cam.make_current()

	await process_frame
	await process_frame

	var done: int = 0
	for mode_id in MODES:
		var mode_script = load(MODE_DIR + "mode_%s.gd" % mode_id)
		if mode_script == null:
			print("SKIP %s: mode script missing" % mode_id)
			continue
		# Fresh container per mode, registered as current_scene — projectiles
		# parent their splits, trails and grown structures to
		# get_tree().current_scene, which is NULL in a SceneTree script:
		# without this every mode's most characteristic visuals silently
		# never spawn.
		var arena := Node3D.new()
		arena.name = "Arena_%s" % mode_id
		get_root().add_child(arena)
		current_scene = arena
		var proj = mode_script.call("create_projectile", Vector3.ZERO, Vector3(1, 0, 0))
		if proj == null:
			print("SKIP %s: create_projectile returned null" % mode_id)
			arena.queue_free()
			continue
		arena.add_child(proj)
		proj.global_position = Vector3.ZERO

		for i in FLIGHT_FRAMES:
			await process_frame

		# Freeze the world so the frame doesn't drift while we place the
		# camera, then shoot the ARENA's whole visual AABB — splits, trails
		# and grown structures included.
		paused = true
		var bounds: AABB = _visual_aabb(arena)
		var center: Vector3 = bounds.get_center()
		var radius: float = maxf(bounds.size.length() * 0.5, 0.25)
		var dist: float = clampf(radius * 2.0, 0.9, 14.0)
		cam.global_position = center + Vector3(-0.45, 0.4, 1.0).normalized() * dist
		cam.look_at(center, Vector3.UP)
		await process_frame
		await RenderingServer.frame_post_draw

		var img: Image = get_root().get_texture().get_image()
		img.save_png("%s/%s.png" % [OUT_DIR, mode_id])
		print("captured %s at %s (r=%.2f)" % [mode_id, center, radius])
		done += 1
		paused = false
		current_scene = null
		arena.queue_free()
		await process_frame

	# ── Stage two: impact — each mode fired at a live CatalystFoe ──────────
	# Floor lives in the STAGE (not the arena) so it never bloats the
	# framing AABB. Projectile mask is layer 2 only, so it flies over.
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(14, 0.2, 8)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	var floor_mesh := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(14, 0.2, 8)
	floor_mesh.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.075, 0.095, 0.13)
	fmat.roughness = 0.85
	floor_mesh.material_override = fmat
	floor_body.add_child(floor_mesh)
	floor_body.position = Vector3(2.5, -0.1, 0)
	stage.add_child(floor_body)

	var impact_done: int = 0
	for mode_id in MODES:
		var mode_script = load(MODE_DIR + "mode_%s.gd" % mode_id)
		if mode_script == null:
			continue
		var arena := Node3D.new()
		arena.name = "Impact_%s" % mode_id
		get_root().add_child(arena)
		current_scene = arena

		var foe: Node3D = FOE_SCENE.instantiate()
		arena.add_child(foe)
		foe.global_position = Vector3(3.2, 0.6, 0)
		# long settle: the foe's spawn dissolve-in particles must clear the
		# air before the shot, or they dominate the framing AABB
		for i in 70:
			await process_frame
		if not is_instance_valid(foe):
			print("SKIP impact %s: foe died settling" % mode_id)
			current_scene = null
			arena.queue_free()
			continue

		var start := Vector3(0, 0.55, 0)
		var focus: Vector3 = foe.global_position + Vector3(0, 0.2, 0)
		var aim: Vector3 = (foe.global_position + Vector3(0, 0.15, 0) - start).normalized()
		var proj = mode_script.call("create_projectile", start, aim)
		arena.add_child(proj)
		proj.global_position = start

		var waited: int = 0
		while waited < HIT_TIMEOUT_FRAMES:
			await process_frame
			waited += 1
			if not is_instance_valid(proj) or bool(proj.get("has_hit")):
				break
		for i in AFTER_HIT_FRAMES:
			await process_frame

		paused = true
		var bounds: AABB = _visual_aabb(arena)
		var center: Vector3 = bounds.get_center()
		# particles inflate the AABB and a fully-dissolved foe deflates it —
		# clamp the shot to a portrait distance and fall back to where the
		# foe stood
		var radius: float = clampf(bounds.size.length() * 0.5, 0.3, 2.2)
		if bounds.size.length() < 0.35 or center.distance_to(focus) > 4.0:
			center = focus
			radius = 1.0
		var dist: float = clampf(radius * 2.2, 1.2, 5.5)
		cam.global_position = center + Vector3(-0.45, 0.4, 1.0).normalized() * dist
		cam.look_at(center, Vector3.UP)
		await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("%s/impact_%s.png" % [OUT_DIR, mode_id])
		print("impact %s captured (waited %d frames, r=%.2f)" % [mode_id, waited, radius])
		impact_done += 1
		paused = false
		current_scene = null
		arena.queue_free()
		await process_frame

	print("DONE: %d/%d flight, %d/%d impact -> %s" % [done, MODES.size(), impact_done, MODES.size(), OUT_DIR])
	quit(0 if done == MODES.size() and impact_done == MODES.size() else 1)


func _visual_aabb(root: Node) -> AABB:
	var merged := AABB()
	var first := true
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is VisualInstance3D:
			var vi := n as VisualInstance3D
			var ab: AABB = vi.global_transform * vi.get_aabb()
			if first:
				merged = ab
				first = false
			else:
				merged = merged.merge(ab)
		for ch in n.get_children():
			stack.append(ch)
	if first and root is Node3D:
		merged = AABB((root as Node3D).global_position - Vector3.ONE * 0.2, Vector3.ONE * 0.4)
	return merged
