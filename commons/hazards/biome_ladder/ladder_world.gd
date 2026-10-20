extends "res://commons/hazards/catalyst_counterpart/biome_arena.gd"
const Route := preload("res://commons/hazards/biome_ladder/route.gd")
const Encounter := preload("res://commons/hazards/biome_ladder/ladder_encounter.gd")

func _build() -> void:
	_setup_light()
	_make_encounter()
	await _prepare_player()
	_set_walking_floor()

func _make_encounter() -> void:
	arena = Encounter.new(); arena.stage = Route.selected_stage
	arena.stage_action = change_stage; arena.menu_action = return_to_menu
	arena.museum_action = continue_museum; arena.mature_action = mature_biome
	add_child(arena); spawn = arena.arrival
	if _ready_for_play: _set_walking_floor()

func _set_walking_floor() -> void:
	# Both locomotion bodies use the same ground contract. No projectile mask changes.
	if is_instance_valid(walker): arena.set_walking_body(walker)
	var xr_body := get_node_or_null("XROrigin3D/PlayerBody") as PhysicsBody3D
	if xr_body != null: arena.set_walking_body(xr_body)

func _setup_light() -> void:
	super()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.22, 0.22, 0.22)
	environment.ambient_light_color = Color.WHITE; environment.ambient_light_energy = 0.6
	environment.fog_light_color = Color(0.36, 0.36, 0.36); environment.fog_density = 0.006
	get_node("DirectionalLight3D").light_color = Color.WHITE

func change_stage(index: int) -> void:
	if _returning or arena.player_dead: return
	Route.selected_stage = clampi(index, 0, Route.STAGES.size() - 1)
	arena.rest(); remove_child(arena); arena.queue_free()
	_make_encounter()
	if _vr: center_player_on(Transform3D(Basis.IDENTITY, spawn))
	elif is_instance_valid(walker): walker.position = spawn; walker.velocity = Vector3.ZERO

func _physics_process(_delta: float) -> void:
	if not _ready_for_play or _returning: return
	var body: Node3D = get_node("XROrigin3D/PlayerBody") if _vr else walker
	if body.global_position.y < -3 or absf(body.global_position.x) > 6.5 or absf(body.global_position.z) > 12.5:
		arena.rest()
		if _vr: center_player_on(Transform3D(Basis.IDENTITY, spawn))
		else: walker.position = spawn; walker.velocity = Vector3.ZERO

func continue_museum() -> void:
	if _returning: return
	_returning = true; arena.rest()
	Route.continue_museum(self)

func mature_biome() -> void:
	if _returning: return
	_returning = true; arena.rest()
	Route.load_scene(self, "res://commons/hazards/catalyst_counterpart/biome_arena.tscn")
