extends "res://addons/godot-xr-tools/staging/scene_base.gd"
## The existing head encounter inside the existing biome, with the shared XR rig.
const BIOME := preload("res://commons/artifacts/biome_object/biome_object.tscn")
var spawn := Vector3.ZERO
var arena: Node3D
var menu_button: Node3D
var habitats: Array[Node3D] = []
var walker: CharacterBody3D
var _vr := false
var _ready_for_play := false
var _returning := false
var _stuck: Node
var _stuck_was_enabled := false
var _mouse_mode: int
var environment: Environment

func _ready() -> void:
	# Head Arena is directly accessible for practice, including a fresh save.
	# Enable its hand form for this visit without silently earning the museum unlock.
	var capacity := get_node_or_null("/root/CatalystCapabilityManager")
	if capacity != null and is_instance_valid(capacity.first_catalyst):
		capacity.first_catalyst.set_unlocked(true)
	_mouse_mode = Input.mouse_mode
	var interface := XRServer.primary_interface
	_vr = interface != null and interface.is_initialized()
	_stuck = get_node_or_null("/root/StuckDetector")
	if _stuck != null:
		_stuck_was_enabled = _stuck.enabled
		_stuck.enabled = false
	_build.call_deferred()

func _build() -> void:
	_setup_light()
	# One complete reviewed generation-17 habitat IS the floor of the arena.
	# No surrounding patches, clearing slab, inlay or artificial perimeter.
	var habitat: Node3D = BIOME.instantiate()
	habitat.seed = 7
	habitat.size = 12
	habitat.stage = "full"; habitat.phase = 1.0
	habitat.record = "off"; habitat.residents = "on"
	habitat.community_seed = 0; habitat.foliage = "drawn"
	habitat.moisture = 0.50; habitat.relief = 0.50; habitat.wildness = 0.60
	add_child(habitat)
	habitats.append(habitat)
	await get_tree().physics_frame
	arena = load("res://commons/hazards/catalyst_counterpart/terrain_arena.gd").new()
	arena.terrain = habitat._patch.get_node("Ground")
	arena.menu_action = return_to_menu
	add_child(arena)
	menu_button = arena.menu_button
	spawn = arena.arrival
	await _prepare_player()

func _prepare_player() -> void:
	# Shared by the mature habitat and the early biome ladder.
	get_node("XROrigin3D").position = spawn
	var marker := Marker3D.new()
	marker.name = "SpawnPoint"; marker.position = spawn; marker.add_to_group("spawn_point")
	add_child(marker)
	if not _vr:
		get_node("XROrigin3D").process_mode = Node.PROCESS_MODE_DISABLED
		get_node("XROrigin3D").hide()
		# Disabling processing does not disable physics shapes. Park the spare
		# rig below the landscape so its capsule cannot occupy the walker spawn.
		get_node("XROrigin3D").position = Vector3(0, -100, 0)
		walker = load("res://commons/scenes/desktop_player.tscn").instantiate()
		# The shared desktop player supplies a cave lamp by default. This outdoor
		# scene owns its light; do not let that lamp alter staging's environment.
		walker.get_node("Head/PlayerHeldLight").free()
		walker.position = spawn
		walker.walk_speed = 2.5; walker.sprint_speed = 4.0
		add_child(walker)
		walker.camera.environment = environment
		var desktop: Node = load("res://commons/hazards/catalyst_counterpart/desktop_catalyst.gd").new()
		desktop.world = self
		add_child(desktop)
	await get_tree().physics_frame
	_ready_for_play = true
	print("[biome-arena] Encounter ready: ", scene_file_path)

func _setup_light() -> void:
	var env := Environment.new()
	environment = env
	var sky := Sky.new()
	var atmosphere := ProceduralSkyMaterial.new()
	atmosphere.sky_top_color = Color("152c37")
	atmosphere.sky_horizon_color = Color("9fae9b")
	atmosphere.ground_bottom_color = Color("333b32")
	atmosphere.ground_horizon_color = Color("9fae9b")
	sky.sky_material = atmosphere
	env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dfe4d1"); env.ambient_light_energy = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.85
	env.fog_enabled = true; env.fog_density = 0.004
	env.fog_light_color = Color("9fae9b")
	# Staging keeps the menu's WorldEnvironment alive while its menu is hidden.
	# Assign the scene environment to our camera so that menu black never wins.
	get_node("XROrigin3D/XRCamera3D").environment = env
	var sun: DirectionalLight3D = get_node("DirectionalLight3D")
	sun.rotation_degrees = Vector3(-42, -35, 0)
	sun.light_color = Color("fff6e7"); sun.light_energy = 0.8
	sun.shadow_enabled = true

func is_map_ready() -> bool: return _ready_for_play

func scene_loaded(user_data = null) -> void:
	while not _ready_for_play: await get_tree().process_frame
	if _vr:
		super.scene_loaded(user_data)
	else:
		walker.camera.make_current()

func scene_visible(_user_data = null) -> void:
	if not _vr and is_instance_valid(walker): walker.camera.make_current()

func _physics_process(_delta: float) -> void:
	if not _ready_for_play or _returning: return
	var body: Node3D = get_node("XROrigin3D/PlayerBody") if _vr else walker
	if body.global_position.y < -3 or absf(body.global_position.x) > 6.5 or absf(body.global_position.z) > 6.5:
		arena.rest()
		if _vr: center_player_on(Transform3D(Basis.IDENTITY, spawn))
		else:
			walker.position = spawn; walker.velocity = Vector3.ZERO

func return_to_menu() -> void:
	if _returning: return
	_returning = true
	arena.rest()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor.has_method("return_to_main_menu"):
			ancestor.return_to_main_menu()
			return
		ancestor = ancestor.get_parent()
	get_tree().change_scene_to_file.call_deferred("res://commons/scenes/vr_staging.tscn")

func _exit_tree() -> void:
	var capacity := get_node_or_null("/root/CatalystCapabilityManager")
	if capacity != null and is_instance_valid(capacity.first_catalyst): capacity.first_catalyst.clear_shots()
	if capacity != null and is_instance_valid(capacity.first_catalyst):
		capacity.first_catalyst.set_unlocked(capacity.has_first_catalyst())
	if is_instance_valid(_stuck): _stuck.enabled = _stuck_was_enabled
	Input.mouse_mode = _mouse_mode
