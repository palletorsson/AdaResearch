# ===========================================================================
# Hazards Demo Scene
# Test scene for Plasma Critter, Stick Tool, Octapod Crawler, and Force Fields
#
# Place this scene in the Godot editor and run it to test:
# - Plasma Critter: walk into it (damage), touch with stick (fire torch)
# - Stick Tool: pick up and use to interact with plasma
# - Octapod Crawler: starts as egg-plant, hatches when you approach
# - Force Fields: walk into them (hazard), bring mushroom to transmute (benefit)
#   Q-FEP: same potential, different restraint, different manifestation
#
# Works in both VR and desktop (flat screen) modes.
# ===========================================================================

extends Node3D

# Preloads
var PlasmaCritterScene: PackedScene = null
var StickToolScene: PackedScene = null
var OctapodCrawlerScene: PackedScene = null

# Scene references
var _ground: StaticBody3D = null
var _camera: Camera3D = null
var _info_label: Label3D = null
var _health_label: Label3D = null

# Desktop camera control
var _camera_yaw: float = 0.0
var _camera_pitch: float = -0.2
var _camera_pos: Vector3 = Vector3(0, 1.6, 6.0)
var _mouse_captured: bool = false

func _ready() -> void:
	_load_scenes()
	_build_environment()
	_build_ground()
	_build_walls()
	_build_info_labels()
	_spawn_hazards()
	_setup_camera()

	print("[HazardsDemo] Scene ready — walk into plasma, grab stick, approach egg-plant")

# ═══════════════════════════════════════════════════════════════════════════
# SCENE SETUP
# ═══════════════════════════════════════════════════════════════════════════

func _load_scenes() -> void:
	PlasmaCritterScene = load("res://commons/hazards/plasma/plasma_critter.tscn")
	StickToolScene = load("res://commons/hazards/plasma/stick_tool.tscn")
	OctapodCrawlerScene = load("res://commons/hazards/octapod_crawler/octapod_crawler.tscn")

func _build_environment() -> void:
	# World environment — well-lit test arena
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.25, 0.28, 0.35)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_bloom = 0.15
	env.fog_enabled = false

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# Key light — bright directional from above-left
	var sun := DirectionalLight3D.new()
	sun.name = "KeyLight"
	sun.light_color = Color(0.95, 0.92, 0.85)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-45, -30, 0)
	add_child(sun)

	# Fill light — warm, from opposite side
	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.light_color = Color(0.6, 0.55, 0.5)
	fill.light_energy = 0.5
	fill.shadow_enabled = false
	fill.rotation_degrees = Vector3(-20, 150, 0)
	add_child(fill)

func _build_ground() -> void:
	_ground = StaticBody3D.new()
	_ground.name = "Ground"

	# Ground mesh — light stone floor
	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(16.0, 0.1, 16.0)
	mesh_inst.mesh = box_mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.35, 0.38)
	mat.roughness = 0.85
	mat.metallic = 0.05
	mesh_inst.material_override = mat

	_ground.add_child(mesh_inst)

	# Collision
	var coll := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(16.0, 0.1, 16.0)
	coll.shape = box_shape
	_ground.add_child(coll)

	_ground.position.y = -0.05
	add_child(_ground)

func _build_walls() -> void:
	# Simple low walls to give spatial reference
	var wall_positions: Array[Dictionary] = [
		{"pos": Vector3(0, 0.4, -7.5), "size": Vector3(16.0, 0.8, 0.3)},
		{"pos": Vector3(0, 0.4, 7.5), "size": Vector3(16.0, 0.8, 0.3)},
		{"pos": Vector3(-7.5, 0.4, 0), "size": Vector3(0.3, 0.8, 16.0)},
		{"pos": Vector3(7.5, 0.4, 0), "size": Vector3(0.3, 0.8, 16.0)},
	]

	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.25, 0.25, 0.28)
	wall_mat.roughness = 0.9

	for w in wall_positions:
		var wall := StaticBody3D.new()
		wall.position = w["pos"]

		var mesh := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = w["size"]
		mesh.mesh = bm
		mesh.material_override = wall_mat
		wall.add_child(mesh)

		var col := CollisionShape3D.new()
		var cs := BoxShape3D.new()
		cs.size = w["size"]
		col.shape = cs
		wall.add_child(col)

		add_child(wall)

func _build_info_labels() -> void:
	# Title label
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.font_size = 24
	_info_label.outline_size = 6
	_info_label.modulate = Color(0.9, 0.95, 1.0)
	_info_label.position = Vector3(0, 2.2, -3.0)
	_info_label.text = "HAZARDS DEMO\nPlasma + Octapod + Force Fields"
	add_child(_info_label)

	# Health display
	_health_label = Label3D.new()
	_health_label.name = "HealthLabel"
	_health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_health_label.font_size = 20
	_health_label.outline_size = 4
	_health_label.modulate = Color(1.0, 0.8, 0.7)
	_health_label.position = Vector3(0, 1.8, -3.0)
	_health_label.text = "Health: 100"
	add_child(_health_label)

	# Instruction labels near each hazard
	var plasma_label := Label3D.new()
	plasma_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	plasma_label.font_size = 16
	plasma_label.outline_size = 3
	plasma_label.modulate = Color(0.6, 0.8, 1.0)
	plasma_label.position = Vector3(-2.0, 1.0, -1.0)
	plasma_label.text = "PLASMA CRITTER\nWalk in = damage\nTouch with stick = fire torch"
	add_child(plasma_label)

	var stick_label := Label3D.new()
	stick_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	stick_label.font_size = 16
	stick_label.outline_size = 3
	stick_label.modulate = Color(0.8, 0.7, 0.5)
	stick_label.position = Vector3(0.0, 0.8, 0.5)
	stick_label.text = "STICK TOOL\nGrab and touch plasma"
	add_child(stick_label)

	var egg_label := Label3D.new()
	egg_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	egg_label.font_size = 16
	egg_label.outline_size = 3
	egg_label.modulate = Color(0.5, 0.8, 0.5)
	egg_label.position = Vector3(3.0, 1.0, -2.0)
	egg_label.text = "OCTAPOD CRAWLER\nLooks like a plant...\nApproach to hatch"
	add_child(egg_label)

# ═══════════════════════════════════════════════════════════════════════════
# SPAWN HAZARDS
# ═══════════════════════════════════════════════════════════════════════════

func _spawn_hazards() -> void:
	# --- Plasma Critters ---
	# Main plasma: center-left, RAW form
	if PlasmaCritterScene:
		var plasma1: Node = PlasmaCritterScene.instantiate()
		plasma1.position = Vector3(-2.0, 0.5, -1.0)
		add_child(plasma1)
		print("[HazardsDemo] Spawned plasma critter at (-2, 0.5, -1)")

		# Second plasma further away
		var plasma2: Node = PlasmaCritterScene.instantiate()
		plasma2.position = Vector3(-4.0, 0.5, 1.5)
		add_child(plasma2)
		print("[HazardsDemo] Spawned plasma critter at (-4, 0.5, 1.5)")

		# Third plasma — near the octapod for torch interaction
		var plasma3: Node = PlasmaCritterScene.instantiate()
		plasma3.position = Vector3(1.5, 0.5, -0.5)
		add_child(plasma3)
		print("[HazardsDemo] Spawned plasma critter at (1.5, 0.5, -0.5)")

	# --- Stick Tools (frozen in air for easy grabbing) ---
	if StickToolScene:
		# Stick near the first plasma
		var stick1: Node = StickToolScene.instantiate()
		stick1.position = Vector3(0.0, 1.0, 0.5)
		add_child(stick1)
		# Freeze so it hangs in the air
		if stick1 is RigidBody3D:
			(stick1 as RigidBody3D).freeze = true
		print("[HazardsDemo] Spawned stick tool at (0, 1.0, 0.5)")

		# Second stick further back
		var stick2: Node = StickToolScene.instantiate()
		stick2.position = Vector3(-1.0, 1.0, 2.0)
		add_child(stick2)
		if stick2 is RigidBody3D:
			(stick2 as RigidBody3D).freeze = true
		print("[HazardsDemo] Spawned stick tool at (-1, 1.0, 2)")

	# --- Octapod Crawlers (as egg-plants) ---
	if OctapodCrawlerScene:
		# Beast_demo technique: body at fixed Y = body_hover_height (0.35).
		# No gravity — body just sits at this height, SpringArm3Ds find ground.
		var spawn_y: float = 0.35  # Matches body_hover_height export default

		# Egg-plant 1: nearby, will hatch when player approaches
		var crawler1: Node = OctapodCrawlerScene.instantiate()
		crawler1.position = Vector3(3.0, spawn_y, -2.0)
		add_child(crawler1)
		print("[HazardsDemo] Spawned octapod egg-plant at (3, %.1f, -2)" % spawn_y)

		# Egg-plant 2: further away, larger hatch radius, more aggressive
		var crawler2: Node = OctapodCrawlerScene.instantiate()
		crawler2.position = Vector3(-3.5, spawn_y, -4.0)
		if "hatch_radius" in crawler2:
			crawler2.hatch_radius = 3.5
		add_child(crawler2)
		# Configure aggression after ready (applies multipliers)
		if crawler2.has_method("configure"):
			crawler2.configure({"aggression": "1.5"})
		print("[HazardsDemo] Spawned octapod egg-plant at (-3.5, %.1f, -4)" % spawn_y)

		# Active crawler (not dormant) for immediate testing
		var crawler3: Node = OctapodCrawlerScene.instantiate()
		crawler3.position = Vector3(5.0, spawn_y, 2.0)
		# Set start_dormant before adding to tree (so _ready sees it)
		if "start_dormant" in crawler3:
			crawler3.start_dormant = false
		add_child(crawler3)
		print("[HazardsDemo] Spawned active octapod at (5, %.1f, 2)" % spawn_y)

	# --- Beast Demo IK Reference (scaled down, autonomous patrol) ---
	var beast_scene = load("res://commons/hazards/octapod_crawler/beast_demo.tscn")
	if beast_scene:
		var beast_world = beast_scene.instantiate()
		var beast_node = beast_world.find_child("beast", false)
		if beast_node:
			beast_node.get_parent().remove_child(beast_node)
			# Scale the beast down to octapod-ish size (original is huge: Y=2.2, bones=1.0)
			beast_node.scale = Vector3(0.15, 0.15, 0.15)
			# At 0.15 scale: body height = 2.2*0.15 = 0.33 above ground
			beast_node.position = Vector3(0, 2.2 * 0.15, -3.0)
			add_child(beast_node)
			print("[HazardsDemo] Spawned scaled beast_demo at (0, %.2f, -3)" % beast_node.position.y)
		beast_world.queue_free()

	# --- IK Leg Critters (stepping gait demo) ---
	var three_leg_scene: PackedScene = load("res://commons/hazards/octapod_crawler/three_leg_critter.tscn")
	if three_leg_scene:
		var critter3: Node = three_leg_scene.instantiate()
		critter3.position = Vector3(-5.0, 0, 3.0)
		add_child(critter3)
		print("[HazardsDemo] Spawned 3-leg critter at (-5, 0, 3)")

	var four_leg_scene: PackedScene = load("res://commons/hazards/octapod_crawler/four_leg_critter.tscn")
	if four_leg_scene:
		var critter4: Node = four_leg_scene.instantiate()
		critter4.position = Vector3(5.0, 0, 3.0)
		add_child(critter4)
		print("[HazardsDemo] Spawned 4-leg critter at (5, 0, 3)")

	var six_leg_scene: PackedScene = load("res://commons/hazards/octapod_crawler/six_leg_critter.tscn")
	if six_leg_scene:
		var critter6: Node = six_leg_scene.instantiate()
		critter6.position = Vector3(0, 0, 5.0)
		add_child(critter6)
		print("[HazardsDemo] Spawned 6-leg critter at (0, 0, 5)")

	# Critter labels
	var critter_label := Label3D.new()
	critter_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	critter_label.font_size = 16
	critter_label.outline_size = 3
	critter_label.modulate = Color(0.7, 0.6, 0.9)
	critter_label.position = Vector3(0, 1.0, 5.0)
	critter_label.text = "IK LEG CRITTERS\nStepping gait"
	add_child(critter_label)

	# --- Edible Mushrooms — each color triggers a different post-processing effect (10 sec) ---
	var mushroom_scene: PackedScene = load("res://commons/hazards/mushroom/edible_mushroom.tscn")
	if mushroom_scene:
		# Red toadstool → Mushroom Trip (psychedelic)
		var m1: Node = mushroom_scene.instantiate()
		m1.position = Vector3(2.0, 0.8, 2.0)
		m1.effect_shader_path = "res://commons/resourses/shaders/mushroom_trip.gdshader"
		m1.effect_duration = 10.0
		if m1 is RigidBody3D:
			(m1 as RigidBody3D).freeze = true
		add_child(m1)

		# Blue mushroom → Ripple (watery distortion)
		var m2: Node = mushroom_scene.instantiate()
		m2.position = Vector3(2.5, 0.8, 2.3)
		m2.cap_color = Color(0.3, 0.4, 0.9)
		m2.glow_color = Color(0.2, 0.3, 1.0)
		m2.effect_shader_path = "res://commons/resourses/shaders/pp_ripple.gdshader"
		m2.effect_duration = 10.0
		if m2 is RigidBody3D:
			(m2 as RigidBody3D).freeze = true
		add_child(m2)

		# Green mushroom → Night Vision (green phosphor)
		var m3: Node = mushroom_scene.instantiate()
		m3.position = Vector3(1.5, 0.8, 2.5)
		m3.cap_color = Color(0.2, 0.7, 0.3)
		m3.glow_color = Color(0.1, 0.8, 0.2)
		m3.effect_shader_path = "res://commons/resourses/shaders/pp_night_vision.gdshader"
		m3.effect_duration = 10.0
		if m3 is RigidBody3D:
			(m3 as RigidBody3D).freeze = true
		add_child(m3)

		# Purple mushroom → Glitch (digital corruption)
		var m4: Node = mushroom_scene.instantiate()
		m4.position = Vector3(3.0, 0.8, 2.0)
		m4.cap_color = Color(0.6, 0.2, 0.7)
		m4.glow_color = Color(0.5, 0.1, 0.8)
		m4.effect_shader_path = "res://commons/resourses/shaders/pp_glitch.gdshader"
		m4.effect_duration = 10.0
		if m4 is RigidBody3D:
			(m4 as RigidBody3D).freeze = true
		add_child(m4)

		# Yellow mushroom → Pixelate (retro mosaic)
		var m5: Node = mushroom_scene.instantiate()
		m5.position = Vector3(1.0, 0.8, 1.8)
		m5.cap_color = Color(0.9, 0.8, 0.2)
		m5.glow_color = Color(0.9, 0.7, 0.1)
		m5.effect_shader_path = "res://commons/resourses/shaders/pp_pixelate.gdshader"
		m5.effect_duration = 10.0
		if m5 is RigidBody3D:
			(m5 as RigidBody3D).freeze = true
		add_child(m5)

		# White mushroom → Edge Detect (outline vision)
		var m6: Node = mushroom_scene.instantiate()
		m6.position = Vector3(3.5, 0.8, 2.5)
		m6.cap_color = Color(0.9, 0.9, 0.95)
		m6.stem_color = Color(0.85, 0.85, 0.9)
		m6.glow_color = Color(0.8, 0.8, 1.0)
		m6.effect_shader_path = "res://commons/resourses/shaders/pp_edge_detect.gdshader"
		m6.effect_duration = 10.0
		if m6 is RigidBody3D:
			(m6 as RigidBody3D).freeze = true
		add_child(m6)

		print("[HazardsDemo] Spawned 6 mushrooms — each triggers a different effect (10s)")

	# Mushroom label
	var mush_label := Label3D.new()
	mush_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mush_label.font_size = 16
	mush_label.outline_size = 3
	mush_label.modulate = Color(0.9, 0.6, 0.8)
	mush_label.position = Vector3(2.0, 1.5, 2.0)
	mush_label.text = "MUSHROOMS\nGrab + bring to face = eat\nEach color = different effect (10s)"
	add_child(mush_label)

	# --- Force Fields (dual-nature: hazard → transmuted) ---
	_spawn_force_fields()

	# --- Some environment props for atmosphere ---
	_add_glowing_pillar(Vector3(-5.0, 0, -5.0), Color(0.2, 0.1, 0.3))
	_add_glowing_pillar(Vector3(5.0, 0, -5.0), Color(0.1, 0.2, 0.15))
	_add_glowing_pillar(Vector3(-5.0, 0, 5.0), Color(0.15, 0.1, 0.2))
	_add_glowing_pillar(Vector3(5.0, 0, 5.0), Color(0.2, 0.15, 0.1))

func _spawn_force_fields() -> void:
	# Four force fields along the back-left area of the arena.
	# Each is a different type. Walk in = damage. Bring a mushroom = transmute.
	# The mushrooms in the demo are already in group "mushroom" (from EdibleMushroom).

	var force_configs: Array[Dictionary] = [
		{"type": ForceField.ForceType.FIRE, "pos": Vector3(-6.0, 0, -2.0)},
		{"type": ForceField.ForceType.ELECTRIC, "pos": Vector3(-6.0, 0, 0.5)},
		{"type": ForceField.ForceType.TOXIC, "pos": Vector3(-6.0, 0, 3.0)},
		{"type": ForceField.ForceType.FREEZING, "pos": Vector3(-6.0, 0, 5.5)},
	]

	for cfg in force_configs:
		var ff: ForceField = ForceField.new()
		ff.force_type = cfg["type"] as ForceField.ForceType
		ff.force_intensity = 0.5  # Gentler for demo
		ff.zone_radius = 1.2
		ff.zone_height = 2.2
		ff.position = cfg["pos"] as Vector3
		add_child(ff)

		var type_int: int = cfg["type"] as int
		var force_name: String = ForceTransmutationConfig.get_force_name(type_int)
		print("[HazardsDemo] Spawned ForceField: %s at %s" % [force_name, str(cfg["pos"])])

	# Force field section label
	var ff_label := Label3D.new()
	ff_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ff_label.font_size = 16
	ff_label.outline_size = 3
	ff_label.modulate = Color(1.0, 0.7, 0.4)
	ff_label.position = Vector3(-6.0, 2.5, 1.5)
	ff_label.text = "FORCE FIELDS\nWalk in = hazard damage\nBring mushroom in = TRANSMUTE\nSame potential, different restraint"
	add_child(ff_label)

	print("[HazardsDemo] Spawned 4 force fields — grab a mushroom and bring it in to transmute!")


func _add_glowing_pillar(pos: Vector3, color: Color) -> void:
	var pillar := StaticBody3D.new()
	pillar.position = pos

	# Pillar mesh
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.15
	cyl.bottom_radius = 0.2
	cyl.height = 2.5
	mesh.mesh = cyl
	mesh.position.y = 1.25

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color * 0.3
	mat.roughness = 0.6
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.8
	mesh.material_override = mat
	pillar.add_child(mesh)

	# Collision
	var col := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.2
	cs.height = 2.5
	col.shape = cs
	col.position.y = 1.25
	pillar.add_child(col)

	# Point light at top
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 0.8
	light.omni_range = 3.0
	light.omni_attenuation = 1.5
	light.position.y = 2.6
	pillar.add_child(light)

	add_child(pillar)

# ═══════════════════════════════════════════════════════════════════════════
# CAMERA (Desktop fallback when no VR)
# ═══════════════════════════════════════════════════════════════════════════

func _setup_camera() -> void:
	# Only add camera if no XROrigin3D is in the scene tree
	var xr_origin: Node = get_tree().get_first_node_in_group("player")
	if xr_origin != null:
		return  # VR is active, don't add desktop camera

	# Check if an XROrigin3D exists anywhere
	var scene_root: Node = get_tree().current_scene
	if scene_root and scene_root.find_child("XROrigin3D", true, false):
		return

	_camera = Camera3D.new()
	_camera.name = "DemoCamera"
	_camera.position = _camera_pos
	_camera.far = 100.0
	_camera.fov = 70.0
	_camera.current = true
	add_child(_camera)
	_update_camera_transform()
	print("[HazardsDemo] Desktop camera active — WASD to move, mouse to look, ESC to release")

func _input(event: InputEvent) -> void:
	if _camera == null:
		return

	# Mouse capture toggle
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			_mouse_captured = true
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_mouse_captured = false

	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.keycode == KEY_ESCAPE and key.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_mouse_captured = false

	# Mouse look
	if event is InputEventMouseMotion and _mouse_captured:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		_camera_yaw -= motion.relative.x * 0.003
		_camera_pitch -= motion.relative.y * 0.003
		_camera_pitch = clamp(_camera_pitch, -PI * 0.45, PI * 0.45)
		_update_camera_transform()

func _process(delta: float) -> void:
	_update_health_display()

	if _camera == null:
		return

	# WASD movement
	var move_dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		move_dir.z -= 1.0
	if Input.is_key_pressed(KEY_S):
		move_dir.z += 1.0
	if Input.is_key_pressed(KEY_A):
		move_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		move_dir.x += 1.0
	if Input.is_key_pressed(KEY_SPACE):
		move_dir.y += 1.0
	if Input.is_key_pressed(KEY_SHIFT):
		move_dir.y -= 1.0

	if move_dir.length_squared() > 0.0:
		# Transform movement by camera yaw
		var yaw_basis := Basis(Vector3.UP, _camera_yaw)
		var world_move: Vector3 = yaw_basis * move_dir.normalized()
		var speed: float = 4.0
		_camera_pos += world_move * speed * delta
		_camera.position = _camera_pos

func _update_camera_transform() -> void:
	if _camera:
		_camera.rotation = Vector3(_camera_pitch, _camera_yaw, 0)
		_camera.position = _camera_pos

func _update_health_display() -> void:
	if _health_label == null:
		return
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and "player_health" in gm:
		var hp: float = gm.player_health
		_health_label.text = "Health: %.0f" % hp
		# Color-code health
		var ratio: float = hp / 100.0
		_health_label.modulate = Color(
			1.0,
			ratio,
			ratio * 0.7,
			1.0
		)
	else:
		_health_label.text = "Health: (no GameManager)"
