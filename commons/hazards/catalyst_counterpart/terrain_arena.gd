extends "res://commons/hazards/catalyst_counterpart/test_arena.gd"
## The existing encounter on the actual biome substrate. No stage or floor overlay.
var terrain: Node3D
var vertices: PackedVector3Array
var arrival: Vector3
var menu_button: Node3D
var menu_action: Callable
var console_ground := 0.0
var player_hits := 0
var player_dead := false
var hit_cooldown := 0.0

func _ready() -> void:
	name = "BiomeEncounter"
	open_landscape = true
	vertices = terrain.mesh_instance.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	arrival = on_ground(Vector3(0, 0, 4.8), 0.10)
	head_home = on_ground(Vector3(0, 0, -1.2), 1.65)
	skull = Skull.new()
	skull.combat_enabled = true
	skull.home_position = head_home
	skull.position = head_home
	skull.travel_bounds = AABB(Vector3(-4.5, 0.4, -4.5), Vector3(9, 3.6, 8.5))
	skull.target_y_limits = Vector2(0.5, 3.8)
	skull.ground_height = height_at
	add_child(skull)
	skull.interrupted.connect(_on_interruption)
	skull.ball_hit_player.connect(_on_ball_hit_player)
	catalyst = load("res://commons/artifacts/ignorance_gallery/resolution_catalyst.gd").new()
	catalyst.position = on_ground(Vector3(-1.3, 0, 3.1), 1.18)
	add_child(catalyst)
	# A narrow stand sinks slightly into the slope; the visitor stands on soil.
	_plinth(on_ground(Vector3(-1.3, 0, 3.1), 0.44), Vector3(0.38, 1.04, 0.38))
	get_child(get_child_count() - 1).name = "PointStand"
	_label("TAKE THE POINT", on_ground(Vector3(-1.3, 0, 3.0), 1.66), 27, 0.0018)
	_label("Trigger sends a form", on_ground(Vector3(-1.3, 0, 3.0), 1.49), 23, 0.0015)
	# One small console at the bank. The biome remains visible beyond it.
	console_ground = maxf(height_at(Vector3(0.8, 0, 3.4)), height_at(Vector3(2.4, 0, 3.4)))
	_surface(Vector3(1.6, console_ground + 1.16, 3.4), Vector3(1.85, 0.86, 0.08), Color("242b26"))
	for x in [0.8, 2.4]:
		var low := height_at(Vector3(x, 0, 3.4)) - 0.05
		var top := console_ground + 0.85
		_plinth(Vector3(x, (low + top) * 0.5, 3.4), Vector3(0.055, top - low, 0.055))
	for i in range(3):
		var power := i + 1
		var button := _small_control(["MOVE", "TURN", "SCALE"][i], Vector3(1.02 + i * 0.58, console_ground + 1.04, 3.50), func(): set_operation(power))
		buttons.append(button)
	start_button = _small_control("START", Vector3(1.02, console_ground + 1.37, 3.50), start_round)
	rest_button = _small_control("REST", Vector3(1.60, console_ground + 1.37, 3.50), rest)
	reset_button = _small_control("RESET", Vector3(2.18, console_ground + 1.37, 3.50), reset_round)
	menu_button = _small_control("MAIN MENU", Vector3(1.60, console_ground + 0.80, 3.50), menu_action)
	_label("THE BIOME", Vector3(1.6, console_ground + 1.88, 3.4), 35, 0.0017)
	_label("Dodge its balls. Send a form.\nThree hits break the head. Three hits end your life.", Vector3(1.6, console_ground + 1.72, 3.4), 21, 0.0015)
	readout = _label("", Vector3(1.6, console_ground + 0.51, 3.48), 21, 0.0011)
	for i in range(GOAL):
		var light := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.026; mesh.height = 0.052; mesh.radial_segments = 8; mesh.rings = 4
		light.mesh = mesh
		light.position = Vector3(1.45 + i * 0.15, console_ground + 0.66, 3.48)
		add_child(light); score_lights.append(light)
	_update_score()
	var game := get_node_or_null("/root/GameManager")
	if game != null: game.player_died.connect(_on_player_died)

func _process(delta: float) -> void:
	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	var status := "YOU DIED" if player_dead else ("HEAD DESTROYED" if completed else ("DODGE / RETURN FIRE" if running else "READY / PRESS START"))
	readout.text = "%s\nHEAD %d / 3  ·  YOU %d / 3" % [status, round_hits, player_hits]

func start_round() -> void:
	if running or player_dead: return
	skull.restore()
	player_hits = 0; hit_cooldown = 0.0
	var game := get_node_or_null("/root/GameManager")
	if game != null: game.set_health(game.max_player_health)
	super.start_round()

func reset_round() -> void:
	if player_dead: return # The death screen owns continuation after a lethal hit.
	skull.restore()
	player_hits = 0; hit_cooldown = 0.0
	var game := get_node_or_null("/root/GameManager")
	if game != null: game.set_health(game.max_player_health)
	super.reset_round()

func _clear_shots() -> void:
	super._clear_shots()
	skull.clear_shots()
	var capacity := get_node_or_null("/root/CatalystCapabilityManager")
	if capacity != null and is_instance_valid(capacity.first_catalyst): capacity.first_catalyst.clear_shots()

func _on_ball_hit_player(_body: Node3D) -> void:
	if not running or player_dead or hit_cooldown > 0.0: return
	var game := get_node_or_null("/root/GameManager")
	if game == null or game._death_sequence_running: return
	player_hits += 1; hit_cooldown = 0.75
	# Three discrete hits, not repeated overlap damage or rounded float subtraction.
	# set_health routes the third hit through the existing player death sequence.
	game.set_health(game.max_player_health * float(3 - player_hits) / 3.0)
	if player_hits < 3:
		var fx := get_node_or_null("/root/DeathEffect")
		if fx != null: fx.damage_flash()

func _on_player_died(_at: Vector3) -> void:
	player_dead = true
	# The death screen returns through XR staging, keeping the saved hand ability.
	get_node("/root/GameManager").set_meta("encounter_return_scene", "res://commons/hazards/catalyst_counterpart/biome_arena.tscn")
	rest()

func _small_control(caption: String, at: Vector3, action: Callable) -> Node3D:
	var button := _control(caption, at, action)
	button.scale = Vector3.ONE * 1.15
	for label in button.find_children("*", "Label3D", true, false):
		label.modulate = Color("eeeade")
	return button

func on_ground(at: Vector3, lift: float = 0.0) -> Vector3:
	return Vector3(at.x, height_at(at) + lift, at.z)

func height_at(at: Vector3) -> float:
	# Interpolate the SAME two triangles used by TopologySpace's terrain mesh
	# and collider, not a bilinear approximation of the underlying noise field.
	var local: Vector3 = terrain.to_local(to_global(at)) - terrain.position_offset
	var r: int = terrain.resolution
	var cell: Vector2 = (Vector2(local.x, local.z) / terrain.space_size + Vector2(0.5, 0.5)) * r
	cell = cell.clamp(Vector2.ZERO, Vector2(r, r))
	var x := mini(int(cell.x), r - 1)
	var z := mini(int(cell.y), r - 1)
	var u := cell.x - x; var v := cell.y - z
	var i := z * (r + 1) + x
	var a := vertices[i].y; var b := vertices[i + 1].y
	var c := vertices[i + r + 1].y; var d := vertices[i + r + 2].y
	var h := a + (b - a) * u + (c - a) * v if u + v <= 1.0 else d + (c - d) * (1.0 - u) + (b - d) * (1.0 - v)
	return to_local(terrain.to_global(Vector3(local.x, h, local.z))).y
