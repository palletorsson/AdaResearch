extends "res://commons/hazards/catalyst_counterpart/test_arena.gd"
## The ground, cover and encounter are one world; no stage inside another biome.
const Head := preload("res://commons/hazards/biome_ladder/ladder_skull.gd")
const Route := preload("res://commons/hazards/biome_ladder/route.gd")
enum Motion { TRANSLATE, ROTATE, SCALE }
var stage := 0
var heads: Array[CharacterBody3D] = []
var motions: Array[Dictionary] = []
var floor_materials: Array[StandardMaterial3D] = []
var floor_tiles: Array[MeshInstance3D] = []
var floor_marks: Dictionary = {}
var floor_tile_hits: Dictionary = {}
var floor_tile_bodies: Array[StaticBody3D] = []
var floor_body: StaticBody3D
var direction_field: Node3D
var floor_flashes: Dictionary = {}
var flash_views: Array[MeshInstance3D] = []
var walking_bodies: Array[PhysicsBody3D] = []
const FLASH_SECONDS := 1.15
var pickups: Array[Area3D] = []
var collected := 0
var player_hits := 0
var player_dead := false
var hit_cooldown := 0.0
var clock := 0.0
var arrival := Vector3(0, 0.12, 10.5)
var stage_action: Callable
var menu_action: Callable
var museum_action: Callable
var mature_action: Callable
var ability: Node3D
var saved_glow_colours: Array = []
var address_labels: Array[Label3D] = []
var volley_label: Label3D
var volley_step := 0
var volley_timer := 0.0
var last_volley: Array[int] = []
var has_started := false
const VOLLEY_INTERVAL := 4.8

func _ready() -> void:
	name = "LadderEncounter"
	_ground()
	if stage >= 5:
		direction_field = preload("res://commons/hazards/biome_ladder/direction_field.gd").new()
		direction_field.tiles = floor_tiles
		add_child(direction_field)
	_landscape()
	for i in range(9 if stage >= 2 else 3):
		var head := Head.new()
		head.stage = stage; head.slot = i
		head.array_controlled = stage >= 2
		@warning_ignore("integer_division")
		var row := i / 3
		head.home_position = Vector3((i % 3 - 1) * 2.4, 3.9 - row * 1.3, 3.5) if stage >= 2 else Vector3([-3.0, 3.0, 0.0][i], 1.8, 3.0 - i * 4.5)
		head.position = head.home_position
		head.travel_bounds = AABB(Vector3(-5, 0.3, -11), Vector3(10, 3.0, 22))
		add_child(head); heads.append(head)
		head.ball_hit_player.connect(_on_ball_hit_player)
		if stage >= 3: head.ball_sent.connect(_on_head_ball_sent)
		head.defeated.connect(_head_down)
		if stage == 0:
			# Thin enough for the falling body to drop beside it, not catch on it.
			var pole := CylinderMesh.new(); pole.top_radius = 0.035; pole.bottom_radius = 0.055; pole.height = 1.52
			_view(pole, Vector3(head.position.x, 0.76, head.position.z), Color(0.15, 0.15, 0.15))
		if stage >= 2:
			address_labels.append(_label("[%d, %d]" % [row, i % 3], head.home_position + Vector3(0, -0.43, 0.08), 40, 0.003))
	if stage >= 2: _array_frame()
	catalyst = load("res://commons/artifacts/ignorance_gallery/resolution_catalyst.gd").new()
	catalyst.position = Vector3(-1.5, 1.15, 9.4); add_child(catalyst)
	if stage >= 1: catalyst.form_sent.connect(_on_form_sent)
	_plinth(Vector3(-1.5, 0.48, 9.4), Vector3(0.38, 0.96, 0.38))
	_label("SOURCE A FORM", Vector3(-1.5, 1.65, 9.4), 28, 0.0018)
	_label("Hands together. Aim. Trigger.\nOr take the point.", Vector3(-1.5, 1.43, 9.4), 22, 0.0016)
	_controls()
	var game := get_node_or_null("/root/GameManager")
	if game != null: game.player_died.connect(_on_player_died)
	var capacity := get_node_or_null("/root/CatalystCapabilityManager")
	if capacity != null:
		ability = capacity.first_catalyst
		if stage >= 1: ability.form_sent.connect(_on_form_sent)
		for glow in [ability.left_glow, ability.right_glow, ability.sphere.get_child(0)]:
			saved_glow_colours.append(glow.material_override.get_shader_parameter("glow_colour"))
			glow.material_override.set_shader_parameter("glow_colour", Color(0.86, 0.86, 0.86))
	_update_readout()

func _view(mesh: Mesh, at: Vector3, colour: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new(); node.mesh = mesh; node.position = at
	var mat := StandardMaterial3D.new(); mat.albedo_color = colour; mat.roughness = 0.5
	node.material_override = mat; add_child(node)
	return node

func _array_frame() -> void:
	# Open cells, not a solid wall: the slot outlasts its occupant without blocking a shot.
	for x in [-3.6, -1.2, 1.2, 3.6]:
		_surface(Vector3(x, 2.6, 3.27), Vector3(0.018, 3.9, 0.018), Color(0.12, 0.12, 0.12))
	for y in [0.65, 1.95, 3.25, 4.55]:
		_surface(Vector3(0, y, 3.27), Vector3(7.2, 0.018, 0.018), Color(0.12, 0.12, 0.12))
	volley_label = _label("3 ROWS / 3 COLUMNS", Vector3(0, 4.95, 3.5), 40, 0.004)
	_label("A FALL LEAVES AN EMPTY PLACE", Vector3(0, 4.69, 3.5), 30, 0.004)
	if stage >= 5:
		_label("CENTRE COLUMN\nARROWS > SIGNAL > ONE TURN", Vector3(0, 5.55, 3.5), 34, 0.0035)

func _begin_array_volley() -> void:
	var by_row := volley_step < 3
	var address := volley_step % 3
	last_volley.clear()
	for head in heads:
		@warning_ignore("integer_division")
		var row: int = head.slot / 3
		var column: int = head.slot % 3
		if (row if by_row else column) != address or head.destroyed: continue
		head.begin_telegraph(to_local(head.target_position()))
		last_volley.append(head.slot)
	volley_label.text = "%s [%d] / %d OF 3" % ["ROW" if by_row else "COLUMN", address, last_volley.size()]
	volley_step = (volley_step + 1) % 6

func _ground() -> void:
	# One continuous collider, tiled appearance. No seams in walking or ball impacts.
	_plinth(Vector3(0, -0.12, 0), Vector3(12, 0.24, 24))
	var ground: MeshInstance3D = get_child(get_child_count() - 1)
	ground.name = "LadderGround12x24"
	floor_body = ground.get_child(0)
	for i in range(12):
		var mat := StandardMaterial3D.new(); mat.roughness = 0.62
		floor_materials.append(mat)
	if stage < 2:
		var ink := ShaderMaterial.new()
		ink.shader = preload("res://commons/hazards/biome_ladder/outlined_floor.gdshader")
		ground.material_override = ink
		if stage == 0:
			_update_floor()
			return
		# The backing remains solid when separate white tiles shrink and turn.
		ink.set_shader_parameter("show_grid", false)
		ink.set_shader_parameter("base_colour", Color(0.18, 0.18, 0.18))
	else:
		ground.material_override.albedo_color = Color(0.06, 0.06, 0.06)
	var tile_ink := ShaderMaterial.new()
	tile_ink.shader = preload("res://commons/hazards/biome_ladder/outlined_tile.gdshader")
	for z in range(12):
		for x in range(6):
			var height := 0.04
			var tile := BoxMesh.new(); tile.size = Vector3(1.98, height, 1.98)
			var v := _view(tile, Vector3(-5 + x * 2, height * 0.5, -11 + z * 2), Color.WHITE)
			v.material_override = floor_materials[(x + z) % 12 if stage >= 3 else (x + z) % 2]
			floor_tiles.append(v)
			if stage == 1:
				v.material_override = tile_ink
			var body := StaticBody3D.new(); body.collision_layer = 1; body.collision_mask = 0
			var shape := CollisionShape3D.new(); var box := BoxShape3D.new()
			box.size = tile.size; shape.shape = box
			body.add_child(shape); v.add_child(body)
			floor_tile_bodies.append(body)
			if stage >= 4:
				var flash := MeshInstance3D.new(); var plane := PlaneMesh.new()
				plane.size = Vector2(1.96, 1.96); flash.mesh = plane
				flash.position.y = height * 0.5 + 0.003
				var material := ShaderMaterial.new()
				material.shader = preload("res://commons/hazards/biome_ladder/pattern_flash.gdshader")
				flash.material_override = material; flash.hide()
				flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				v.add_child(flash); flash_views.append(flash)
	_update_floor()

func set_walking_body(body: PhysicsBody3D) -> void:
	# Paint receivers retain their exact transformed collision for projectiles.
	# Feet use the continuous backing, so a 4 cm motif edge cannot become a barrier.
	for tile in floor_tile_bodies: body.add_collision_exception_with(tile)
	if body not in walking_bodies: walking_bodies.append(body)

func _landscape() -> void:
	for row in range(6):
		for side in [-1, 1]:
			var at := Vector3(side * 4.6, 0.65, 6.5 - row * 3.0)
			var kind := row % 4
			var shelter := kind == 0 or kind == 2
			var height := 2.0 if shelter else 1.3
			# The upper row can fire down over a low shelter; retain a tall arrival refuge.
			if stage >= 2 and row == 0: height = 3.0
			if shelter:
				# Boxes protect a standing visitor near the entrance and far end.
				# Cylinders sit further inward: step around their curved edge to fire.
				# Later stages keep these shelters. The growing cylinders leave
				# at least 1.88 m between them (2.1 m at their original size).
				at.x = side * (2.2 if kind == 0 else 1.6)
				# Open the arrival view onto all nine cells; the same refuge boxes remain.
				if stage >= 2 and row == 0: at.x = side * 4.35
				at.y = height * 0.5
			var mesh: PrimitiveMesh
			match kind:
				0:
					var box := BoxMesh.new()
					var width := 1.35 if shelter else 1.1
					if stage >= 2 and row == 0: width = 2.0
					box.size = Vector3(width, height, width); mesh = box
				1:
					var sphere_mesh := SphereMesh.new(); sphere_mesh.radius = 0.65; sphere_mesh.height = 1.3; sphere_mesh.radial_segments = 12; sphere_mesh.rings = 6; mesh = sphere_mesh
				_:
					var column := CylinderMesh.new(); column.top_radius = 0 if kind == 3 else 0.55; column.bottom_radius = 0.55; column.height = height; column.radial_segments = 12; mesh = column
			var colour := Color.from_hsv(row / 6.0, 0.58, 0.85) if stage >= 3 else Color(0.12, 0.12, 0.12) if row % 2 == 0 else Color(0.83, 0.83, 0.83)
			var view := _view(mesh, at, colour)
			var body := AnimatableBody3D.new(); body.position = at; body.collision_layer = 1; body.collision_mask = 0
			if shelter: body.name = "PrimitiveCover_%d_%s" % [row, "Left" if side < 0 else "Right"]
			add_child(body)
			var shape := CollisionShape3D.new(); shape.shape = mesh.create_convex_shape(); body.add_child(shape)
			# Each operation moves the visible form and its collision together.
			view.reparent(body); view.transform = Transform3D.IDENTITY
			# The entrance boxes remain a dependable refuge; cones stay still.
			if stage >= 1 and row != 0 and kind != 3:
				var operation := Motion.TRANSLATE if kind == 1 else Motion.ROTATE if kind == 0 else Motion.SCALE
				motions.append({"body": body, "view": view, "shape": shape, "home": at, "kind": operation, "phase": row * 0.6})
	if stage >= 1:
		# Keep collection positions inside the walk, clear of growing cover.
		for i in range(3): _pickup(Vector3([-0.65, 0.65, 0.0][i], 0.40, [6.0, 1.5, -4.0][i]))

func _pickup(at: Vector3) -> void:
	var area := Area3D.new(); area.position = at; area.collision_layer = 0; area.collision_mask = 1 | 524288
	var shape := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = Vector3(0.6, 0.8, 0.6); shape.shape = box
	area.add_child(shape); add_child(area)
	var mesh := BoxMesh.new(); mesh.size = Vector3.ONE * 0.24
	var view := _view(mesh, at, Color(0.94, 0.94, 0.94)); view.reparent(area); view.position = Vector3.ZERO
	area.body_entered.connect(func(body):
		if not running or not area.visible or not (body.is_in_group("player_body") or body.is_in_group("player")): return
		area.hide(); collected += 1
		player_hits = maxi(0, player_hits - 1)
		var game := get_node_or_null("/root/GameManager")
		if game != null: game.set_health(game.max_player_health * float(3 - player_hits) / 3.0)
		_update_readout())
	pickups.append(area)

func _controls() -> void:
	_surface(Vector3(2.6, 1.15, 9.5), Vector3(5.1, 1.1, 0.08), Color(0.09, 0.09, 0.09))
	_label("BIOME / " + Route.STAGES[stage].title, Vector3(2.2, 1.95, 9.5), 40, 0.002)
	readout = _label("", Vector3(2.2, 1.76, 9.56), 25, 0.0016)
	start_button = _small_button("START", Vector3(1.2, 1.48, 9.6), start_round)
	rest_button = _small_button("REST", Vector3(2.2, 1.48, 9.6), rest)
	reset_button = _small_button("RESET", Vector3(3.2, 1.48, 9.6), reset_round)
	for i in range(Route.STAGES.size()):
		var idx := i
		# Let the pressed button finish its event before replacing its room.
		_small_button(["1 FORM", "2 MOVE", "3 ARRAY", "4 COLOUR", "5 TILE", "6 CHANGE"][i], Vector3(0.6 + i * 0.8, 1.17, 9.6), func(): stage_action.call_deferred(idx))
	_small_button("MUSEUM >", Vector3(1.15, 0.85, 9.6), museum_action)
	_small_button("FULL BIOME", Vector3(2.2, 0.85, 9.6), mature_action)
	_small_button("MENU", Vector3(3.25, 0.85, 9.6), menu_action)
	_label("A hit drops a head. Three hits end your life.\nSmall cubes restore one hit.", Vector3(2.2, 0.54, 9.56), 23, 0.0015)
	_label("START / RESUME keeps your work. RESET restores it.", Vector3(2.2, 0.37, 9.56), 23, 0.0015)
	if stage >= 2:
		_label("READ THE BRIGHT PATH.\nSTEP ASIDE. USE THE COVER.", Vector3(4.35, 2.60, 7.52), 30, 0.0035)
	if stage >= 4:
		var hint := "Shoot one tile. Watch all its copies flash."
		if stage >= 5: hint = "Shoot a tile to turn its arrows.\nThe centre balls follow, signal, then turn once."
		_label(hint, Vector3(-4.35, 2.65, 7.52), 29, 0.003)
	# Far-end onward controls let the walk continue instead of requiring a return.
	_small_button("NEXT STAGE", Vector3(-0.65, 1.1, -10.5), func(): stage_action.call_deferred(mini(Route.STAGES.size() - 1, stage + 1)))
	_small_button("MUSEUM >", Vector3(0.65, 1.1, -10.5), museum_action)

func _small_button(caption: String, at: Vector3, action: Callable) -> Node3D:
	var button := _control(caption, at, action); button.scale = Vector3.ONE * 1.05
	button.accent = Color(0.85, 0.85, 0.85)
	return button

func _process(delta: float) -> void:
	hit_cooldown = maxf(0, hit_cooldown - delta)
	clock += delta
	if stage >= 3: _update_floor()
	_update_flashes(delta)

func _update_flashes(delta: float) -> void:
	for index: int in floor_flashes.keys():
		var left := maxf(0.0, float(floor_flashes[index]) - delta)
		floor_flashes[index] = left
		flash_views[index].material_override.set_shader_parameter("pulse", left / FLASH_SECONDS)
		if left <= 0:
			flash_views[index].hide(); floor_flashes.erase(index)

func _physics_process(_delta: float) -> void:
	if stage >= 2 and running:
		volley_timer -= _delta
		if volley_timer <= 0:
			_begin_array_volley()
			volley_timer = VOLLEY_INTERVAL
	for motion in motions:
		var body: AnimatableBody3D = motion.body
		var t: float = clock * 0.6 + float(motion.phase)
		match int(motion.kind):
			Motion.TRANSLATE: body.position = motion.home + Vector3(0, 0, sin(t))
			Motion.ROTATE: body.rotation.y = t
			Motion.SCALE:
				# Uniform growth from 1 to 1.2 keeps standing cover at least 2 m
				# tall. Raise the centre with the radius so the base stays on the floor.
				var factor := 1.0 + 0.2 * (0.5 + 0.5 * sin(t))
				motion.view.scale = Vector3.ONE * factor
				motion.shape.scale = Vector3.ONE * factor
				body.position.y = float(motion.home.y) * factor
	for pickup in pickups:
		if pickup.visible: pickup.get_child(1).rotation.y = clock * 0.6

func _update_floor() -> void:
	for i in range(floor_materials.size()):
		if stage < 2:
			floor_materials[i].albedo_color = Color.WHITE
		else:
			floor_materials[i].albedo_color = Color.from_hsv(fposmod(i / 12.0 + floor(clock / 4.0) / 12.0, 1.0), 0.35, 0.42) if stage >= 3 else Color(0.18, 0.18, 0.18) if i % 2 == 0 else Color(0.70, 0.70, 0.70)

func _on_form_sent(shot: RigidBody3D) -> void:
	# The same impact gains colour, then repetition, as the route develops.
	shot.projectile_hit.connect(_transform_floor_tile)
	if stage < 3: return
	# Both the hand ability and held catalyst retain their real projectile.
	# Colour is local to this encounter and fixed at the moment of release.
	var tint := Color.from_hsv(fposmod(floor(clock / 4.0) / 12.0, 1.0), 0.80, 0.95)
	shot.color_primary = tint
	shot.color_secondary = tint.darkened(0.25)
	shot._mesh_instance.material_override.albedo_color = tint
	shot.projectile_hit.connect(_mark_pattern_floor.bind(tint))

func _pattern_indices(index: int) -> Array[int]:
	if stage < 4: return [index]
	# Address within a 2 x 2 motif. Repeat that address over the 6 x 12 floor.
	var indices: Array[int] = []
	var column := index % 6
	@warning_ignore("integer_division")
	var row := index / 6
	for z in range(row % 2, 12, 2):
		for x in range(column % 2, 6, 2):
			indices.append(z * 6 + x)
	return indices

func _transform_floor_tile(body: Node3D, _at: Vector3) -> void:
	# A real tile is the source. A gap reaches the backing and creates no pattern.
	if not body is StaticBody3D: return
	var index := floor_tile_bodies.find(body)
	if stage < 1 or index < 0: return
	for target in _pattern_indices(index):
		var hits := int(floor_tile_hits.get(target, 0)) + 1
		floor_tile_hits[target] = hits
		var tile := floor_tiles[target]
		tile.scale = Vector3.ONE * pow(0.8, hits)
		tile.rotation.y = deg_to_rad(22.5 * hits)
		tile.position.y = tile.mesh.size.y * tile.scale.y * 0.5
		# The child collider inherits the mesh transform, including distant copies.
		if stage >= 4:
			floor_flashes[target] = FLASH_SECONDS
			flash_views[target].material_override.set_shader_parameter("pulse", 1.0)
			flash_views[target].show()

func _mark_pattern_floor(body: Node3D, at: Vector3, tint: Color) -> void:
	if not body is StaticBody3D: return
	var index := floor_tile_bodies.find(body)
	if index < 0: return
	for target in _pattern_indices(index):
		_mark_floor(floor_tile_bodies[target], at, tint)

func _reset_floor_tiles() -> void:
	for flash in flash_views: flash.hide()
	floor_flashes.clear()
	for index: int in floor_tile_hits:
		var tile := floor_tiles[index]
		tile.scale = Vector3.ONE
		tile.rotation = Vector3.ZERO
		tile.position.y = tile.mesh.size.y * 0.5
	floor_tile_hits.clear()

func _on_head_ball_sent(shot: Node3D) -> void:
	shot.surface_hit.connect(_mark_floor.bind(shot.tint))

func _mark_floor(body: Node3D, _at: Vector3, tint: Color) -> void:
	# A hit on cover, a head or a player must not paint the ground beneath it.
	# Keep the mark attached to the actual tile, even after its outline moves.
	if not body is StaticBody3D: return
	var index := floor_tile_bodies.find(body)
	if stage < 3 or index < 0: return
	floor_marks[index] = tint
	var material := StandardMaterial3D.new()
	material.albedo_color = tint; material.roughness = 0.62
	material.emission_enabled = true; material.emission = tint
	material.emission_energy_multiplier = 0.18
	floor_tiles[index].material_override = material

func _clear_floor_marks() -> void:
	for index: int in floor_marks:
		var x := index % 6
		var z := index / 6
		floor_tiles[index].material_override = floor_materials[(x + z) % 12]
	floor_marks.clear()

func start_round() -> void:
	# Resume this encounter: no erasing paint, restoring heads, healing or replenishing pickups.
	if running or player_dead or completed: return
	running = true; has_started = true
	# A cancelled windup gets a fresh warning for the next group on resume.
	volley_timer = 0.0
	for head in heads: head.set_active(true)
	_update_readout()

func rest() -> void:
	running = false
	for head in heads: head.set_active(false)
	_clear_shots(); _update_readout()
	if is_instance_valid(volley_label): volley_label.text = "3 ROWS / 3 COLUMNS"

func reset_round() -> void:
	if player_dead: return
	rest(); completed = false; player_hits = 0; collected = 0; hit_cooldown = 0
	has_started = false
	_clear_floor_marks()
	_reset_floor_tiles()
	volley_step = 0; volley_timer = 0; last_volley.clear()
	for head in heads: head.restore()
	for pickup in pickups: pickup.show()
	var game := get_node_or_null("/root/GameManager")
	if game != null: game.set_health(game.max_player_health)
	_update_readout()

func _clear_shots() -> void:
	if is_instance_valid(catalyst): super._clear_shots()
	for head in heads: head.clear_shots()
	if is_instance_valid(ability): ability.clear_shots()

func _head_down() -> void:
	completed = heads.all(func(head): return head.destroyed)
	if completed: rest()
	_update_readout()

func _update_readout() -> void:
	if not is_instance_valid(readout): return
	var down := heads.filter(func(head): return head.destroyed).size()
	var caption := "RESUME" if has_started and not running else "START"
	start_button.label = caption
	for child in start_button.get_children():
		if child is Label3D: child.text = caption
	readout.text = "%s / %d OF %d DOWN / YOU %d OF 3" % ["CLEAR - RESET TO REPLAY" if completed else "PLAY" if running else "REST" if has_started else "READY", down, heads.size(), player_hits]
	for i in range(address_labels.size()):
		@warning_ignore("integer_division")
		var row := i / 3
		address_labels[i].text = "[%d, %d]%s" % [row, i % 3, "\nEMPTY" if heads[i].destroyed else ""]

func _on_ball_hit_player(_body: Node3D) -> void:
	if not running or player_dead or hit_cooldown > 0: return
	var game := get_node_or_null("/root/GameManager")
	if game == null or game._death_sequence_running: return
	player_hits += 1; hit_cooldown = 0.75
	game.set_health(game.max_player_health * float(3 - player_hits) / 3.0)
	if player_hits < 3:
		var fx := get_node_or_null("/root/DeathEffect")
		if fx != null: fx.damage_flash()
	_update_readout()

func _on_player_died(_at: Vector3) -> void:
	player_dead = true
	get_node("/root/GameManager").set_meta("encounter_return_scene", Route.SCENE)
	rest()

func _exit_tree() -> void:
	# Remove exceptions while tile RIDs still exist; Jolt must not retain freed bodies.
	for body in walking_bodies:
		if is_instance_valid(body):
			for tile in floor_tile_bodies:
				if is_instance_valid(tile): body.remove_collision_exception_with(tile)
	walking_bodies.clear()
	if is_instance_valid(ability) and ability.form_sent.is_connected(_on_form_sent):
		ability.form_sent.disconnect(_on_form_sent)
	_clear_shots()
	if is_instance_valid(ability) and saved_glow_colours.size() == 3:
		var glows := [ability.left_glow, ability.right_glow, ability.sphere.get_child(0)]
		for i in range(3): glows[i].material_override.set_shader_parameter("glow_colour", saved_glow_colours[i])
