extends "res://addons/godot-xr-tools/staging/scene_base.gd"
## A continuing side game in the museum project, using its supplied player rigs.
const Encounter := preload("res://commons/shadow_game/encounter.gd")
const Route := preload("res://commons/hazards/biome_ladder/route.gd")
@export var save_path := "user://shadow-game/world-v1.json"
var encounter: Node3D
var habitat: Node3D
var walker: CharacterBody3D
var environment: Environment
var spawn := Vector3(0, 0.1, 5.4)
var ready_for_play := false
var returning := false
var vr := false
var old_mouse_mode: int
var stuck: Node
var old_stuck_enabled := false
var desktop_hud: CanvasLayer
var hud_label: Label

func _ready() -> void:
	old_mouse_mode = Input.mouse_mode
	var interface := XRServer.primary_interface
	vr = interface != null and interface.is_initialized()
	stuck = get_node_or_null("/root/StuckDetector")
	if stuck != null:
		old_stuck_enabled = stuck.enabled
		stuck.enabled = false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--shadow-save="): save_path = argument.trim_prefix("--shadow-save=")
	_build.call_deferred()

func _build() -> void:
	_light()
	habitat = load("res://commons/artifacts/biome_object/biome_object.tscn").instantiate()
	habitat.name = "SuppliedBiome"
	habitat.record = "off"
	habitat.seed = 7
	habitat.size = 16
	habitat.relief = 0.28
	habitat.moisture = 0.55
	habitat.residents = "off"
	habitat.position = Vector3(0, -1.6, -5)
	add_child(habitat)
	encounter = Encounter.new()
	encounter.name = "MakeACrossing"
	encounter.save_path = save_path
	encounter.menu_action = return_to_menu
	encounter.museum_action = return_to_museum
	add_child(encounter)
	get_node("XROrigin3D").position = spawn
	var marker := Marker3D.new()
	marker.name = "SpawnPoint"
	marker.add_to_group("spawn_point")
	marker.position = spawn
	add_child(marker)
	if not vr:
		var xr := get_node("XROrigin3D") as Node3D
		xr.process_mode = Node.PROCESS_MODE_DISABLED
		xr.hide()
		xr.position = Vector3(0, -100, 0)
		walker = load("res://commons/scenes/desktop_player.tscn").instantiate()
		walker.get_node("Head/PlayerHeldLight").free()
		walker.position = spawn
		walker.walk_speed = 2.5
		walker.sprint_speed = 3.6
		add_child(walker)
		walker.camera.environment = environment
		walker.camera.make_current()
		_hud()
	await get_tree().physics_frame
	ready_for_play = true
	print("[shadow-game] Ready: three objects, one crossing. Save: ", save_path)

func _light() -> void:
	environment = Environment.new()
	var sky := Sky.new()
	var material := ProceduralSkyMaterial.new()
	material.sky_top_color = Color("293c49")
	material.sky_horizon_color = Color("879d9d")
	material.ground_bottom_color = Color("394747")
	material.ground_horizon_color = Color("879d9d")
	sky.sky_material = material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("e5eadf")
	environment.ambient_light_energy = 0.25
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	environment.fog_enabled = true
	environment.fog_density = 0.009
	environment.fog_light_color = Color("bac7bf")
	get_node("XROrigin3D/XRCamera3D").environment = environment
	var sun := get_node("DirectionalLight3D") as DirectionalLight3D
	sun.rotation_degrees = Vector3(-42, -35, 0)
	sun.light_color = Color("fff1dc")
	sun.light_energy = 0.58
	sun.shadow_enabled = true

func _hud() -> void:
	desktop_hud = CanvasLayer.new()
	add_child(desktop_hud)
	walker.crosshair.reparent(desktop_hud)
	walker.crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var panel := PanelContainer.new()
	panel.position = Vector2(22, 22)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.06, 0.065, 0.88)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	desktop_hud.add_child(panel)
	hud_label = Label.new()
	hud_label.add_theme_font_size_override("font_size", 17)
	panel.add_child(hud_label)
	encounter.changed.connect(_update_hud)
	_update_hud()

func _update_hud() -> void:
	if hud_label == null: return
	var step: String = "Crossing kept. Keep arranging." if encounter.completed else ("3 / Carry the point to the far plinth." if encounter.bridge_open() else ("2 / Hold the stick. Left click turns the bridge." if encounter.powered else "1 / Release the cube inside the pink frame."))
	hud_label.text = "SHADOW GAME  ·  MAKE A CROSSING\n%s\nRight click: take / release · Wheel: reach · Arrows: walk\nEsc: cursor · Your arrangement saves on release." % step

func is_map_ready() -> bool: return ready_for_play

func scene_loaded(user_data = null) -> void:
	while not ready_for_play: await get_tree().process_frame
	if vr: super.scene_loaded(user_data)
	else: walker.camera.make_current()

func scene_visible(_user_data = null) -> void:
	if not vr and is_instance_valid(walker): walker.camera.make_current()

func scene_exiting(_user_data = null) -> void:
	if is_instance_valid(encounter): encounter.save_game()

func _physics_process(_delta: float) -> void:
	if not ready_for_play or returning: return
	var body: Node3D = get_node("XROrigin3D/PlayerBody") if vr else walker
	if body.global_position.y < -0.7 or absf(body.global_position.x) > 10 or body.global_position.z < -16 or body.global_position.z > 10:
		recover_player()

func recover_player() -> void:
	# A fall releases the hand; it never silently erases the player's trace.
	if vr:
		for body in encounter.objects.values():
			if body.is_picked_up(): body.drop()
		center_player_on(Transform3D(Basis.IDENTITY, spawn))
	else:
		walker.desktop_pointer._drop_held()
		walker.position = spawn
		walker.velocity = Vector3.ZERO
	# Released lost objects recover to their last placed pose in _released().
	# Other arrangements remain exactly where the player left them.

func return_to_menu() -> void:
	if returning: return
	returning = true
	encounter.save_game()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor.has_method("return_to_main_menu"):
			ancestor.return_to_main_menu()
			return
		ancestor = ancestor.get_parent()
	Route.load_scene(self, "res://commons/scenes/vr_staging.tscn")

func return_to_museum() -> void:
	if returning: return
	returning = true
	encounter.save_game()
	var museum: GDScript = load("res://commons/scenes/endless_museum.gd")
	museum.open_at("primitives", "Point_One")
	Route.load_scene(self, "res://commons/scenes/endless_museum_staged.tscn")

func _exit_tree() -> void:
	if is_instance_valid(stuck): stuck.enabled = old_stuck_enabled
	Input.mouse_mode = old_mouse_mode
