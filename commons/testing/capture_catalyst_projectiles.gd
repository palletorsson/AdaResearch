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

	print("DONE: %d/%d projectiles captured -> %s" % [done, MODES.size(), OUT_DIR])
	quit(0 if done == MODES.size() else 1)


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
