# SequelHookCinematic.gd
# The final moment: the player reaches the far horizon, the world falls away,
# the QFEP formula hangs in empty space, and Ada Research — Chapter One ends.
# Attach to the horizon marker Node3D in the landscape scene.

extends Node3D
class_name SequelHookCinematic

signal cinematic_finished

const ASCENT_DURATION := 8.0
const TEXT_FADE_DURATION := 1.5
const TEXT_HOLD_DURATION := 3.0
const BLACKOUT_DURATION := 2.0
const ASCENT_HEIGHT := 40.0

var _triggered := false
var _xr_origin: XROrigin3D = null
var _world_env: WorldEnvironment = null
var _formula_instance: Node3D = null
var _title_labels: Array[Label3D] = []
var _blackout_mesh: MeshInstance3D = null


func setup(trigger_area: Area3D) -> void:
	trigger_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _triggered:
		return
	if not (body is CharacterBody3D or body.name == "PlayerBody"):
		return
	_triggered = true
	print("SequelHookCinematic: Triggered — beginning final sequence")
	_run_cinematic()


func _run_cinematic() -> void:
	_find_references()
	_disable_player_movement()

	# Phase 1: Fog swallows the terrain (3s)
	await _fade_fog_in(3.0)

	# Phase 2: Ascend through fog into void (8s)
	await _ascend(ASCENT_DURATION)

	# Phase 3: Clear fog, reveal stars + formula
	await _reveal_cosmos()

	# Phase 4: Title cards
	await _show_title_sequence()

	# Phase 5: Fade to black and return
	await _fade_to_black()

	cinematic_finished.emit()
	_return_to_lab()


# ── Phase 1: Fog ────────────────────────────────────────────────────

func _fade_fog_in(duration: float) -> void:
	if not _world_env or not _world_env.environment:
		await get_tree().create_timer(duration).timeout
		return

	var env := _world_env.environment
	var start_density: float = env.fog_density
	var tween := create_tween()
	tween.tween_method(func(v: float):
		env.fog_density = v
	, start_density, 0.15, duration)
	tween.set_ease(Tween.EASE_IN)
	await tween.finished


# ── Phase 2: Ascend ──────────────────────────────────────────────────

func _ascend(duration: float) -> void:
	if not _xr_origin:
		await get_tree().create_timer(duration).timeout
		return

	var start_pos := _xr_origin.global_position
	var end_pos := start_pos + Vector3(0, ASCENT_HEIGHT, 0)

	var tween := create_tween()
	tween.tween_property(_xr_origin, "global_position", end_pos, duration)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	await tween.finished


# ── Phase 3: Cosmos ──────────────────────────────────────────────────

func _reveal_cosmos() -> void:
	if _world_env and _world_env.environment:
		var env := _world_env.environment

		# Clear fog to zero
		var tween := create_tween()
		tween.tween_method(func(v: float):
			env.fog_density = v
		, env.fog_density, 0.0, 2.0)

		# Darken sky to near-black (space)
		tween.parallel().tween_method(func(v: float):
			if env.sky and env.sky.sky_material is ProceduralSkyMaterial:
				var sky_mat: ProceduralSkyMaterial = env.sky.sky_material
				sky_mat.sky_top_color = Color(0.02, 0.02, 0.06).lerp(sky_mat.sky_top_color, v)
				sky_mat.sky_horizon_color = Color(0.03, 0.03, 0.08).lerp(sky_mat.sky_horizon_color, v)
				sky_mat.ground_bottom_color = Color(0.01, 0.01, 0.03)
				sky_mat.ground_horizon_color = Color(0.02, 0.02, 0.05)
		, 1.0, 0.0, 2.0)

		# Dim all lights
		tween.parallel().tween_method(func(v: float):
			for child in get_tree().current_scene.find_children("*", "DirectionalLight3D", true, false):
				child.light_energy = v
		, 1.3, 0.15, 2.0)

		await tween.finished

	# Spawn formula in front of player
	_spawn_cosmic_formula()

	# Add star particles
	_spawn_stars()

	await get_tree().create_timer(1.5).timeout


func _spawn_cosmic_formula() -> void:
	if not _xr_origin:
		return

	var formula_scene = load("res://commons/interfaces/qfep/formula_display/qfep_formula_3d.tscn")
	if not formula_scene:
		return

	_formula_instance = formula_scene.instantiate()
	_formula_instance.name = "CosmicFormula"

	# Position in front of player, slightly above eye level
	var cam := _xr_origin.find_child("XRCamera3D", true, false)
	var forward: Vector3 = -cam.global_transform.basis.z if cam else Vector3(0, 0, -1)
	var cam_pos: Vector3 = cam.global_position if cam else _xr_origin.global_position + Vector3(0, 1.8, 0)

	_formula_instance.global_position = cam_pos + forward * 6.0 + Vector3(0, 0.5, 0)
	_formula_instance.scale = Vector3(5, 5, 5)

	# Face the player
	get_tree().current_scene.add_child(_formula_instance)
	_formula_instance.look_at(cam_pos, Vector3.UP)

	# Fade in with emission boost
	var tween := create_tween()
	tween.tween_property(_formula_instance, "scale", Vector3(5, 5, 5), 2.0).from(Vector3(0.1, 0.1, 0.1))
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)


func _spawn_stars() -> void:
	# Simple star field using small sphere meshes scattered around
	var star_mat := StandardMaterial3D.new()
	star_mat.albedo_color = Color.WHITE
	star_mat.emission_enabled = true
	star_mat.emission = Color(0.9, 0.92, 1.0)
	star_mat.emission_energy_multiplier = 3.0
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var star_root := Node3D.new()
	star_root.name = "StarField"
	add_child(star_root)

	var rng := RandomNumberGenerator.new()
	rng.seed = 777

	var center := _xr_origin.global_position if _xr_origin else Vector3.ZERO

	for i in range(80):
		var star := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = rng.randf_range(0.02, 0.08)
		sphere.height = sphere.radius * 2.0
		sphere.radial_segments = 4
		sphere.rings = 2
		star.mesh = sphere
		star.material_override = star_mat

		# Distribute in a sphere around player
		var dir := Vector3(
			rng.randf_range(-1, 1),
			rng.randf_range(-1, 1),
			rng.randf_range(-1, 1)
		).normalized()
		star.global_position = center + dir * rng.randf_range(15, 50)
		star_root.add_child(star)


# ── Phase 4: Title Cards ────────────────────────────────────────────

func _show_title_sequence() -> void:
	var cam := _xr_origin.find_child("XRCamera3D", true, false) if _xr_origin else null
	var cam_pos: Vector3 = cam.global_position if cam else Vector3.ZERO
	var forward: Vector3 = -cam.global_transform.basis.z if cam else Vector3(0, 0, -1)
	var right: Vector3 = cam.global_transform.basis.x if cam else Vector3(1, 0, 0)

	# Position below the formula
	var text_base: Vector3 = cam_pos + forward * 5.0 + Vector3(0, -1.5, 0)

	var lines := [
		"The Lab was inside something larger.",
		"",
		"Ada Research",
		"Chapter One",
	]

	for i in range(lines.size()):
		if lines[i].is_empty():
			await get_tree().create_timer(0.5).timeout
			continue

		var label := Label3D.new()
		label.text = lines[i]
		label.font_size = 64 if i >= 2 else 42
		label.pixel_size = 0.003
		label.modulate = Color(0.85, 0.88, 1.0, 0.0)  # Start invisible
		label.outline_size = 6
		label.position = text_base + Vector3(0, -i * 0.6, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED

		get_tree().current_scene.add_child(label)
		_title_labels.append(label)

		# Fade in
		var tween := create_tween()
		tween.tween_property(label, "modulate:a", 0.95, TEXT_FADE_DURATION)
		await tween.finished

		# Hold
		await get_tree().create_timer(TEXT_HOLD_DURATION).timeout

	# Final pause with everything visible
	await get_tree().create_timer(2.0).timeout


# ── Phase 5: Blackout ───────────────────────────────────────────────

func _fade_to_black() -> void:
	# Fade all labels out
	var tween := create_tween()
	for label in _title_labels:
		if is_instance_valid(label):
			tween.parallel().tween_property(label, "modulate:a", 0.0, BLACKOUT_DURATION)

	# Fade formula out
	if is_instance_valid(_formula_instance):
		tween.parallel().tween_property(_formula_instance, "scale", Vector3(0.01, 0.01, 0.01), BLACKOUT_DURATION)

	# Dim stars
	var star_field := find_child("StarField", true, false)
	if star_field:
		for star in star_field.get_children():
			if star is MeshInstance3D and star.material_override:
				tween.parallel().tween_property(star.material_override, "emission_energy_multiplier", 0.0, BLACKOUT_DURATION)

	await tween.finished
	await get_tree().create_timer(1.0).timeout


# ── Utilities ────────────────────────────────────────────────────────

func _find_references() -> void:
	# Find XR origin
	var scene := get_tree().current_scene
	if scene:
		var origins = scene.find_children("*", "XROrigin3D", true, false)
		if origins.size() > 0:
			_xr_origin = origins[0]

	# Find WorldEnvironment
	if scene:
		var envs = scene.find_children("*", "WorldEnvironment", true, false)
		if envs.size() > 0:
			_world_env = envs[0]


func _disable_player_movement() -> void:
	if not _xr_origin:
		return

	# Disable all movement providers
	var movement_nodes := [
		"MovementDirect", "MovementFlight", "MovementTurn",
		"MovementJump", "MovementWallWalk"
	]

	for node_name in movement_nodes:
		var node := _xr_origin.find_child(node_name, true, false)
		if node:
			if "enabled" in node:
				node.set("enabled", false)
			elif node.has_method("set_enabled"):
				node.set_enabled(false)

	print("SequelHookCinematic: Player movement disabled for cinematic")


func _return_to_lab() -> void:
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager and scene_manager.has_method("_return_to_hub"):
		print("SequelHookCinematic: Returning to lab after cinematic")
		scene_manager._return_to_hub({"return_from": "landscape_cinematic"})
	else:
		push_warning("SequelHookCinematic: SceneManager not found")
