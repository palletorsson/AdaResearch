extends "res://addons/godot-xr-tools/staging/scene_base.gd"
## Roof and authored floors. Checkpoints require a safe slab or balcony landing.
const Health := preload("health.gd")
const SightEffect := preload("sight_effect.gd")
var charge: Node
var health: Node # Existing artifacts address this alias of the same charge resource.
var charge_display: Label3D
var _last_charge_position := Vector3.ZERO
var _charge_position_valid := false
var _airborne_peak := 0.0
var _movement_settle := 0.0
var _landing_cost_armed := false
var sight: Node
var hurt_time := 0.0
const Architecture := preload("architecture.gd")
const Atmosphere := preload("atmosphere.gd")
const RenderQuality := preload("render_quality.gd")
@export_enum("Balanced (4x MSAA)", "Performance (2x MSAA)") var visual_quality: int = 0
var render_quality: Node
const MuseumRig := preload("res://commons/player/museum_rig.tscn")
const FloorStream := preload("floor_stream.gd")
const Soundscape := preload("soundscape.gd")
const MotionMeter := preload("motion_meter.gd")
static var motion_test_requested := false
## Menu selection is consumed by the next main-tower instance, never persisted
## into a separate trial or into the player's museum progress.
static var requested_floor := -1
var soundscape: Node3D
var floor_stream: Node
## Full architecture/editor captures can opt out; gameplay streams by default.
@export var stream_floors := true
@export var trial_id := ""
var trial_session: Node
const Walker := preload("walker.gd")
const PlayerRules := preload("player_rules.gd")
const Jump := preload("jump.gd")
const Ground := preload("res://addons/godot-xr-tools/overrides/ground_physics_settings.gd")
const Route := preload("res://commons/hazards/biome_ladder/route.gd")
const HARD_LANDING_SPEED := 9.8
const FALL_DAMAGE := 0.0 # Falls and jumps are free; legacy callers read this value.
const FLOOR_TOLERANCE := 0.35
const DEATH_RED := Color(0.12, 0.003, 0.009)
const FADE_IN_SECONDS := 0.3
const RELOCATE_SECONDS := 0.65
const FADE_OUT_START := 0.85
const RESPAWN_SECONDS := 1.2

signal checkpoint_saved(floor_index: int)
signal died(reason: String)
signal respawned(floor_index: int)

var force_xr := false # Physics tests provide synthetic trackers; no headset required.
var vr := false
var building: Node3D
var atmosphere: Node3D
var body: CharacterBody3D
var camera: Camera3D
var jump: Node3D
var checkpoint := 0
var deaths := 0
var cushioned_landings := 0
var last_impact := 0.0
var last_death := ""
var airborne_speed := 0.0
var fall_start_y := 0.0 # Last support height, not the apex of a jump.
var stable_floor := -1
var stable_time := 0.0
var recovering := false
var recovery_time := 0.0
var recovery_placed := false
var ready_for_play := false
var returning := false
var status: Label3D
var fade: MeshInstance3D
var fade_material: StandardMaterial3D
var desktop_help: CanvasLayer
var notice_time := 5.0
var stuck: Node
var old_stuck := false
var mushroom: Node
var old_mushroom_mode := Node.PROCESS_MODE_INHERIT
var mushroom_connections: Array[Dictionary] = []
var mushroom_layers: Array[CanvasLayer] = []
var pickups: Array[Node3D] = []
var pointers: Array[Node3D] = []
var coordinate_point: RigidBody3D
var point_home: Transform3D
var catalyst: Node3D
var catalyst_was_processing := true
var catalyst_was_unlocked := false
var laser_unlocked := true # Catalyst and supplied canisters coexist in this trial.
var throwable_tools := false # Physical tools no longer replace the catalyst.
signal laser_acquired()
var previous_desktop_source: WeakRef
var prefab_inventory: Node
var inventory_board: Node3D

func _ready() -> void:
	add_to_group("void_game")
	prefab_inventory = preload("prefab_inventory.gd").new()
	prefab_inventory.name = "PrefabInventory"
	add_child(prefab_inventory)
	prefab_inventory.earned.connect(func(id):
		_notice("PREFAB UNLOCKED / " + str(prefab_inventory.definitions[id].title) + "\nI / left stick click: inventory. Available in the live editor."))
	charge = Health.new()
	health = charge
	health.name = "BodyCharge"
	add_child(health)
	health.depleted.connect(func(): die("Charge depleted"))
	health.changed.connect(_on_health_changed)
	process_physics_priority = 100 # Observe after XRTools' move_and_slide (-100).
	var interface := XRServer.primary_interface
	vr = force_xr or (interface != null and interface.is_initialized())
	for arg in OS.get_cmdline_user_args():
		if arg == "--void-quality=performance": visual_quality = RenderQuality.Profile.PERFORMANCE
	render_quality = RenderQuality.new()
	render_quality.name = "RenderQuality"
	add_child(render_quality)
	render_quality.configure(get_viewport(), visual_quality)
	_suspend_global_tools()
	# The normal base rig's earned ability owns the two-hand catalyst gesture.
	catalyst = get_tree().get_first_node_in_group("first_catalyst_ability") as Node3D
	if catalyst != null:
		catalyst_was_processing = catalyst.is_physics_processing()
		catalyst_was_unlocked = catalyst.unlocked
		if is_instance_valid(catalyst.desktop_source): previous_desktop_source = weakref(catalyst.desktop_source)
		catalyst.desktop_source = null
		catalyst._hide_all()
		catalyst.set_physics_process(false)
		catalyst.set_unlocked(true)
	building = Architecture.new()
	trial_id = Architecture.Content.Source.selected(trial_id)
	if not trial_id.is_empty():
		trial_session = preload("trials/session.gd").new()
		add_child(trial_session)
	building.trial_id = trial_id
	building.name = "Building"
	building.stream_content = stream_floors
	add_child(building)
	building.content.floor_changed.connect(_content_changed)
	building.content.floor_changed.connect(_filter_floor_materials)
	_filter_structural_materials.call_deferred()
	_content_changed(0)
	_build_environment()
	_build_player()
	soundscape = Soundscape.new()
	soundscape.name = "VoidSoundscape"
	add_child(soundscape)
	soundscape.configure(self)
	body.add_to_group("player_body")
	_build_signs()
	_build_feedback()
	inventory_board = preload("inventory_board.gd").new()
	inventory_board.name = "PlayerInventory"
	inventory_board.game = self; inventory_board.inventory = prefab_inventory
	add_child(inventory_board)
	if stream_floors:
		floor_stream=FloorStream.new()
		floor_stream.name="FloorStream"
		add_child(floor_stream)
		floor_stream.configure(self)
		atmosphere.environment.fog_enabled=true
		atmosphere.environment.fog_depth_end=30.0
		atmosphere.environment.fog_depth_curve=1.5
		atmosphere.environment.fog_density=1.0
		atmosphere.get_node("WarmSun").directional_shadow_max_distance=28.0
	var start_floor := int(Architecture.Content.Source.definition(trial_id).get("start_floor", 0))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--void-start-floor="): start_floor=clampi(int(arg.trim_prefix("--void-start-floor=")),0,building.spec.levels.size()-1)
	if trial_id.is_empty() and requested_floor >= 0:
		start_floor = clampi(requested_floor, 0, building.spec.levels.size()-1)
		requested_floor = -1
	checkpoint=start_floor
	place_player(spawn_for(start_floor))
	ready_for_play = true
	_set_enabled(true)
	# Visual study is explicit and scene-scoped; normal launches retain their look.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--void-look="):
			var look := preload("res://commons/void/visual_profile.gd").new()
			look.name = "VisualProfileStudy"
			add_child(look)
			look.configure(self,arg.trim_prefix("--void-look="))
	if motion_test_requested or "--void-motion-test" in OS.get_cmdline_user_args():
		motion_test_requested = false
		var meter := MotionMeter.new()
		meter.name = "MotionMeter"
		add_child(meter)
		meter.configure(self, "tower")
	_notice("THE VOID\nFind a landing below.\n" + ("A / B: jump   Grip: grab" if vr else "Space: jump   R: retry"))
	if trial_session != null:
		# A trial names its own notice in playable.json; the first trial keeps its text.
		var trial := Architecture.Content.Source.definition(trial_id)
		if trial.has("notice"): _notice(str(trial.get("label", trial_id)).to_upper() + "\n" + str(trial.notice))
		else: _notice("TRANSFORMATION TRIAL\nStill / rise / turn / scale. Then collect.\nA / B: jump. R (desktop): reset the encounter. M (desktop): menu. Left X: inventory.")
	print("[void] Museum rig. Left stick: move/strafe; right stick: forward/back and turn; right A / B: jump; grip: grab; trigger: point at switches / held tool; smoke: opposite-hand pin, release to throw; empty hands together + trigger: catalyst; left Y: prefab board; left X: inventory prism.")

func _build_player() -> void:
	var origin := get_node("XROrigin3D") as XROrigin3D
	if vr:
		# Both base.tscn and the tower instantiate this one player scene.
		# The scene-base placeholder has no body, hands or interaction providers.
		remove_child(origin)
		origin.free()
		origin = MuseumRig.instantiate()
		origin.name = "XROrigin3D"
		origin.get_node("PlayerCustomization").care_body_mode = true
		var left := origin.get_node("LeftHand") as XRController3D
		var right := origin.get_node("RightHand") as XRController3D
		var left_hand := left.get_node("XRToolsCollisionHand")
		var right_hand := right.get_node("XRToolsCollisionHand")
		for hand in [left_hand,right_hand]:
			hand.get_node("FunctionPickup").set_script(preload("force_pickup.gd"))
		jump = right_hand.get_node("MovementJump")
		jump.set_script(Jump) # One A/B press per jump; no repeat on landing.
		body = origin.get_node("PlayerBody")
		# Keep the capsule aligned with the head. Hand-direction blending in
		# this XRTools version has a zero-axis rotation when hands line up.
		body.body_forward_mix = 0.0
		var physics := Ground.new()
		physics.jump_velocity = PlayerRules.JUMP
		physics.move_traction = PlayerRules.TRACTION
		physics.move_drag = PlayerRules.DRAG
		body.physics = physics
		body.ground_control = 2 # Air steering is necessary to choose a landing.
		# Apply the museum's existing deadzones before the first movement frame.
		origin.get_node("JoystickDeadzoneFix")._apply_fallback("Void uses museum rig")
		var manager := get_node_or_null("/root/GameManager")
		if manager != null and manager.has_method("get_hand_color"):
			origin.get_node("PlayerCustomization").skin_color = manager.get_hand_color()
		add_child(origin)
		origin.owner = self
		body.owner = self # XRTools scene centering searches owned player bodies.
		# XRTools gathers providers globally; keep this scene's own providers.
		body._movement_providers = [right_hand.get_node("MovementTurn"),
			left_hand.get_node("MovementDirect"), right_hand.get_node("MovementDirect"), jump]
		left.button_pressed.connect(_left_button)
		right.button_pressed.connect(_right_button)
		for hand in [left_hand, right_hand]:
			hand.get_node("MovementDirect").max_speed = PlayerRules.SPEED
			hand.get_node("FunctionPickup").ranged_distance = PlayerRules.GRAB_DISTANCE
			hand.get_node("FunctionPointer").distance = PlayerRules.POINTER_DISTANCE
			hand.get_node("FunctionPointer").collision_mask = PlayerRules.POINTER_MASK
			pickups.append(hand.get_node("FunctionPickup"))
			pointers.append(hand.get_node("FunctionPointer"))
		camera = origin.get_node("XRCamera3D")
	else:
		origin.process_mode = Node.PROCESS_MODE_DISABLED
		origin.hide()
		body = Walker.new()
		body.name = "DesktopWalker"
		add_child(body)
		camera = body.camera
		body.desktop_pointer.ability = catalyst
		if is_instance_valid(catalyst): catalyst.desktop_source = body.desktop_pointer
	camera.near = 0.05
	camera.far = 350.0
	# Keep the same environment on the active desktop or XR camera even
	# when the staging scene has its own WorldEnvironment.
	camera.environment = atmosphere.environment
	camera.make_current()
	var care_body := preload("res://commons/void/care_body.gd").new()
	care_body.name = "CareBody"
	add_child(care_body)
	care_body.configure(camera,body)
	if building.content.data.floors.any(func(f):return f.map=="Ribbon_Patterns_03"):
		# Reuse the museum wardrobe for the original WEAR and mirror controls.
		var wardrobe := preload("res://commons/player/costume_wardrobe.gd").new()
		wardrobe.name = "StudioWardrobe"
		wardrobe.mount_path = NodePath("..")
		wardrobe.head_path = camera.get_path()
		wardrobe.appearance_save_path = "user://void_studio_appearance.cfg"
		add_child(wardrobe)
	_content_changed(-1)

func _content_changed(_index: int) -> void:
	if is_instance_valid(prefab_inventory): prefab_inventory.bind_lesson(building.content,trial_id)
	for mount in building.content.exhibits.values():
		if not is_instance_valid(mount): continue
		var source: Node = mount.get_node_or_null("Artifact")
		if is_instance_valid(source) and source.get_meta("void_source","")=="res://commons/artifacts/drag_catwalk/drag_catwalk.tscn" and is_instance_valid(camera):
			source.viewer = camera
	if is_instance_valid(coordinate_point): return
	for mount in building.content.exhibits.values():
		if not is_instance_valid(mount): continue
		var artifact: Node = mount.get_node_or_null("Artifact")
		if artifact == null: continue # Collected museum pickups free their own node.
		var held := artifact.get_node_or_null("HeldPoint") as RigidBody3D
		if held!=null:
			coordinate_point=held;point_home=held.global_transform;return

func _build_environment() -> void:
	atmosphere = Atmosphere.new()
	add_child(atmosphere)

func _build_signs() -> void:
	for index in range(building.spec.levels.size()):
		var y: float = building.spec.levels[index]
		# Leave the north balcony approach clear on the middle floor.
		var sign_x := 3.5 if index > 0 else 0.0
		var sign_at := Vector3(sign_x, y + 1.35, -7.8)
		var sign_turn := 0.0
		if building.content.data.floors[index].map == "Point_Triangle_Context":
			# The north bay is now the proof cubicle. Face the approach from the
			# clear south strip, rather than cutting the board through its wall.
			sign_at = Vector3(9.0, y + 1.35, 8.3)
			sign_turn = PI
		elif building.content.data.floors[index].map == "Primitives_Polythedra":
			# Keep the boundary plate and its unfolding monitor unobstructed.
			sign_at = Vector3(9.0, y + 1.35, 8.3)
			sign_turn = PI
		# Transfer trials can clear an original installation without moving its
		# geometry. Unconfigured floors retain their existing sign positions.
		var sign_position: Array = building.spec.get("floor_sign_positions", {}).get(str(index), [])
		if sign_position.size() == 2:
			sign_at.x = float(sign_position[0])
			sign_at.z = float(sign_position[1])
		var sign_board: Node3D = building.box(building.detail_root(index), "FloorSign", sign_at, Vector3(3.7, 1.65, 0.12), building.steel)
		sign_board.rotation.y = sign_turn
		var label := Label3D.new()
		label.position = sign_at + Vector3(0,0,.08).rotated(Vector3.UP,sign_turn)
		label.rotation.y = sign_turn
		label.font_size = 40
		label.pixel_size = 0.003
		label.outline_size = 0
		label.modulate = Color("f0e9dd")
		var directions := "Last structural floor.\nA / B: jump / Left X: inventory"
		if index+1 < building.spec.levels.size():
			if building.spec.descent.get("mode") == "corner_pads":
				var corner := "south" if (index+1)%2==1 else "north"
				corner += "-west" if float(building.spec.descent.get("pad_x_sides",{}).get(str(index+1),1))<0 else "-east"
				var shaft: String = building.spec.descent.get("pad_shafts",{}).get(str(index+1),building.spec.descent.get("pad_shaft","B"))
				directions="Shaft %s / %s corner below\nMarked planks: soft landing.\nFalls are safe. A / B: jump" % [shaft,corner]
			elif float(index+1) in building.spec.descent.get("shaft_corner_floors",[]):
				var next_title := str(building.content.data.floors[index+1].title).get_slice(" / ",1)
				directions="Next: %s / shaft B, east edge\nTwo timber landings, three metres apart.\nLand on the first, then jump south to the second." % next_title
			elif index < building.spec.descent.get("balcony_sides",[]).size():
				directions="Next balcony: %s edge\nLand on the pink cushion.\nA / B: jump" % building.spec.descent.balcony_sides[index]
			else:
				directions="Open structure below / route not built yet.\nFalls are safe.\nA / B: jump / Left X: inventory"
		label.text = str(building.content.data.floors[index].title) + "\n" + directions
		building.detail_root(index).add_child(label)
		# A pale pink arrival strip sits on real concrete, outside both holes.
		building.box(building.detail_root(index), "CheckpointStrip", Vector3(-6, y + 0.015, 4.5), Vector3(1.8, 0.03, 0.12), building.pink, false)

func _build_feedback() -> void:
	charge_display = Label3D.new()
	charge_display.name = "BodyChargeReadout"
	charge_display.position = Vector3(0.21,-0.28,-0.8)
	charge_display.font_size = 30
	charge_display.pixel_size = 0.0005
	charge_display.no_depth_test = true
	charge_display.outline_size = 4
	camera.add_child(charge_display)
	_update_charge_display()
	sight=SightEffect.new()
	sight.name="BiteSight"
	add_child(sight)
	sight.configure(camera,health)
	status = Label3D.new()
	status.position = Vector3(0, -0.19, -0.8)
	status.font_size = 40
	status.pixel_size = 0.00055
	status.outline_size = 8
	status.no_depth_test = true
	camera.add_child(status)
	fade = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	fade.mesh = quad
	fade.position.z = -0.065
	fade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fade_material = StandardMaterial3D.new()
	fade_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fade_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fade_material.no_depth_test = true
	fade_material.render_priority = 127
	fade_material.albedo_color = Color(0, 0, 0, 0)
	fade.material_override = fade_material
	fade.extra_cull_margin = 100
	camera.add_child(fade)
	fade.hide()
	if not vr:
		desktop_help = CanvasLayer.new()
		add_child(desktop_help)
		var help := Label.new()
		help.position = Vector2(20, 18)
		help.text = "THE VOID\nWASD: move   Mouse: look   Space: jump   Right click: grab / release\nLeft click: use / drag   Smoke: left click pull pin, then throw   C + click: catalyst\nI: prefab inventory   R: last floor   T: roof   M: menu   Esc: release mouse\nCHARGE: movement drains the battery. Falls and landings are safe. Outside the tower: return to the last floor."
		if trial_session != null:
			var label := str(Architecture.Content.Source.definition(trial_id).get("label", trial_id)).to_upper()
			help.text = help.text.replace("THE VOID", "VOID TRIAL / " + label).replace("R: last floor   T: roof", "R / T: reset the encounter")
		var reticle := Label.new()
		reticle.text = "+"
		reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		desktop_help.add_child(reticle)
		reticle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		help.add_theme_font_size_override("font_size", 18)
		help.add_theme_color_override("font_shadow_color", Color.BLACK)
		help.add_theme_constant_override("shadow_offset_y", 2)
		desktop_help.add_child(help)

func _physics_process(delta: float) -> void:
	if not ready_for_play or returning: return
	# Retiring a standalone artifact camera can make Godot auto-select the
	# dormant XR camera in desktop mode. Keep the active visitor rig in charge.
	if not vr and get_viewport().get_camera_3d()==get_node("XROrigin3D/XRCamera3D"):
		camera.make_current()
	if recovering:
		recovery_time += delta
		_set_fade(minf(recovery_time / FADE_IN_SECONDS, 1.0))
		if recovery_time >= RELOCATE_SECONDS and not recovery_placed:
			_restore_point()
			if trial_session != null:
				trial_session.reset()
				var content: Node3D = building.content
				if floor_stream != null: floor_stream.records.clear()
				content.pending.clear()
				for floor_root in content.roots.values(): floor_root.free()
				content.roots.clear(); content.exhibits.clear(); content.cells.clear(); content.props.clear()
				var trial := Architecture.Content.Source.definition(trial_id)
				checkpoint = int(trial.get("retry_floors", {}).get(str(checkpoint), trial.get("start_floor", 1)))
			elif str(building.content.data.floors[checkpoint].map).begins_with("Trans_"):
				if floor_stream != null: floor_stream.records.erase(checkpoint)
				building.content.reset_floor(checkpoint)
			for area in get_tree().get_nodes_in_group("void_lines_area"):
				area.reset_after_fall()
			health.reset()
			place_player(spawn_for(checkpoint))
			recovery_placed = true
		if recovery_time > FADE_OUT_START:
			_set_fade(clampf((RESPAWN_SECONDS - recovery_time) / (RESPAWN_SECONDS - FADE_OUT_START), 0.0, 1.0))
		if recovery_time >= RESPAWN_SECONDS:
			recovering = false
			health.suspended = false
			_set_enabled(true)
			_set_fade(0.0)
			_notice("Back on %s" % floor_name(checkpoint))
			respawned.emit(checkpoint)
		return
	hurt_time = maxf(0.0,hurt_time-delta)
	if hurt_time > 0:
		fade_material.albedo_color = Color(0.65,0.06,0.1,hurt_time*0.8)
		fade.visible = true
	else:
		fade.visible = false
	notice_time -= delta
	status.visible = notice_time > 0.0
	var feet := body.global_position
	_drain_movement(feet,delta)
	if recovering: return
	# Bounded flight borrows the noise exhibit's locomotion. It is controlled
	# travel, so restart fall accounting here rather than measuring from entry.
	var controlled_carry := false
	for field in get_tree().get_nodes_in_group("void_controlled_carry"):
		if field.can_process() and field._point_inside(feet): controlled_carry = true; break
	if controlled_carry or preload("res://commons/movement/museum_flight_box.gd").at_point(get_tree(),feet) != null:
		airborne_speed = 0.0
		fall_start_y = feet.y
		_airborne_peak = 0.0
		_landing_cost_armed = false
		stable_floor = -1
		stable_time = 0.0
		return
	var balcony_depth := float(building.spec.get("descent", {}).get("balcony_depth", 0.0))
	balcony_depth = maxf(balcony_depth, Architecture.CliffLandings.extent(building.spec))
	var outside := absf(feet.x) > float(building.spec.width) / 2.0 + 3.0 or absf(feet.z) > float(building.spec.depth) / 2.0 + balcony_depth + 3.0
	if feet.y < float(building.spec.levels.back()) - 5.0 or (outside and not _exterior_walk_support(feet)):
		# A missed route returns the visitor without injury, death or pain audio.
		place_player(spawn_for(checkpoint))
		_notice("Back on %s" % floor_name(checkpoint))
		return
	if not body.is_on_floor():
		airborne_speed = maxf(airborne_speed, -body.velocity.y)
		if _landing_cost_armed: _airborne_peak = maxf(_airborne_peak,feet.y-fall_start_y)
		stable_floor = -1
		stable_time = 0.0
		return
	last_impact = airborne_speed if airborne_speed > 0 else last_impact
	# Preserve real gravity/contact and the pad's visual response. Neither drop
	# height nor impact speed injures the electrical unit or spends its charge.
	if airborne_speed >= HARD_LANDING_SPEED:
		var pad := _landing_pad_contact()
		if pad != null:
			cushioned_landings += 1
			building.absorb_landing(pad)
	_airborne_peak = 0.0
	_landing_cost_armed = true
	airborne_speed = 0.0
	fall_start_y = feet.y
	var landed := _main_floor_contact()
	if landed != stable_floor:
		stable_floor = landed
		stable_time = 0.0
	stable_time += delta
	if landed >= 0 and landed != checkpoint and stable_time >= 0.18:
		checkpoint = landed
		checkpoint_saved.emit(checkpoint)
		_notice("%s / checkpoint saved%s" % [floor_name(checkpoint), "\nDescent complete" if checkpoint == building.spec.levels.size()-1 else ""])

func _exterior_walk_support(feet: Vector3) -> bool:
	# An edited/copy-rotated walkway can extend into the sky. Only real support
	# underneath it extends the playable boundary; a missed route returns quietly.
	# Sample the foot area too: F33 bridge cells have visible 2 cm joints that
	# the player's capsule spans, while a single centre ray can pass through.
	for offset in [Vector3.ZERO,Vector3(.15,0,.15),Vector3(-.15,0,.15),Vector3(.15,0,-.15),Vector3(-.15,0,-.15)]:
		var query := PhysicsRayQueryParameters3D.create(feet+offset+Vector3.UP*.2,feet+offset-Vector3.UP*4.0,1)
		query.exclude=[body.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty(): continue
		var node: Node=hit.collider
		while node!=null:
			if node.is_in_group("void_exterior_walk"): return true
			node=node.get_parent()
	return false

func _main_floor_contact() -> int:
	for i in range(body.get_slide_collision_count()):
		var hit := body.get_slide_collision(i)
		var collider := hit.get_collider() as Node3D
		if collider == null or hit.get_normal().y < 0.8: continue
		var index := _floor_for(collider)
		if index >= 0: return index
	# Jolt may retain is_on_floor without producing a new slide collision
	# for a stationary body. Confirm the slab directly under grounded feet.
	var query := PhysicsRayQueryParameters3D.create(body.global_position + Vector3.UP * 0.06, body.global_position - Vector3.UP * 0.16, 1)
	query.exclude = [body.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.normal.y > 0.8:
		return _floor_for(hit.collider as Node3D)
	return -1

func _floor_for(collider: Node3D) -> int:
	if collider == null: return -1
	var authored := int(collider.get_meta("void_floor_index",-1))
	if authored>=0 and authored<building.spec.levels.size() and absf(body.global_position.y-float(building.spec.levels[authored]))<0.16:
		return authored
	for index in range(building.floors.size()):
		if collider.get_parent() == building.floors[index] and (str(collider.name).begins_with("Slab") or collider in building.landing_pads) and absf(body.global_position.y - float(building.spec.levels[index])) < 0.16:
			return index
	# A grounded arrival on an authored cube, wedge or deck also saves this
	# lesson. The caller has already checked the top contact and fall distance.
	var ancestor: Node = collider
	while ancestor != null:
		if ancestor.has_meta("void_content_floor"):
			var index := int(ancestor.get_meta("void_content_floor"))
			var height := body.global_position.y - float(building.spec.levels[index])
			# Museum instruments often include a 5 cm floor plate. It is the
			# same arrival floor, not an airborne visitor with no checkpoint.
			var flush_floor := height >= -.16 and height < .16
			var raised_transform := str(building.content.data.floors[index].map).begins_with("Trans_") and height >= -.16 and height < float(building.spec.storey_height)-.4
			if flush_floor or raised_transform:
				return index
			break
		ancestor = ancestor.get_parent()
	return -1

func _landing_pad_contact() -> StaticBody3D:
	# A horizontal top contact is required: brushing a pad's side cannot
	# claim a cushioned contact on concrete, or save an airborne checkpoint.
	for i in range(body.get_slide_collision_count()):
		var hit := body.get_slide_collision(i)
		var pad := hit.get_collider() as StaticBody3D
		if hit.get_normal().y > 0.8 and pad in building.landing_pads and _floor_for(pad) >= 0:
			return pad
	return null

func spawn_for(index: int) -> Vector3:
	var trial_spawn: Array = Architecture.Content.Source.definition(trial_id).get("spawn_points",{}).get(str(index),building.spec.get("spawn_points",{}).get(str(index),[]))
	if trial_spawn.size()==3:
		return Vector3(trial_spawn[0],float(building.spec.levels[index])+trial_spawn[1],trial_spawn[2])
	if index == 0 and building.content != null:
		for item in building.content.data.floors[0].get("props",[]):
			if item.kind == "arrival_crate":
				return Vector3(item.position[0],float(building.spec.levels[0])+0.06,item.position[1])
	if index == 3 and building.content != null:
		var mount: Node3D = building.content.exhibits.get("3/setting_out")
		if mount != null:
			var entry := mount.get_node_or_null("Artifact/MeasurementRoom") as Node3D
			if entry != null: return entry.to_global(Vector3(0,0.06,2.5))
		# Direct-start loading has not instantiated the room yet. Read the same
		# editor placements rather than spawning outside the puzzle enclosure.
		for item in building.content.data.floors[index].artifacts:
			if item.id != "setting_out": continue
			var part: Dictionary=item.get("config",{}).get("parts",{}).get("MeasurementRoom",{})
			var p: Array=part.get("position",[0,0,-3.2])
			var r: Array=part.get("rotation",[0,0,0])
			var pose := Transform3D(Basis.from_euler(Vector3(deg_to_rad(r[0]),deg_to_rad(r[1]),deg_to_rad(r[2]))),Vector3(p[0],p[1],p[2]))
			var offset: Vector3=(pose*Vector3(0,0.06,2.5)).rotated(Vector3.UP,deg_to_rad(float(item.facing)))
			return Vector3(item.position[0],float(building.spec.levels[index])+float(item.get("height",0)),item.position[1])+offset
	return Vector3(-6.0, float(building.spec.levels[index]) + 0.06, 4.5)

func floor_name(index: int) -> String:
	return "Roof" if index == 0 else "Floor %02d" % index

func place_player(at: Vector3) -> void:
	if floor_stream!=null: floor_stream.set_focus(floor_stream.floor_at_position(at))
	if vr:
		center_player_on(Transform3D(Basis.IDENTITY, at))
		body.on_ground = false
		body.ground_control_velocity = Vector2.ZERO
		jump.queued = false
	else:
		body.global_position = at
		body.rotation = Vector3.ZERO
		body.camera.rotation = Vector3.ZERO
		body.jump_queued = false
	body.velocity = Vector3.ZERO
	# Follow the editor's arrival-crate facing, including XR scene centering.
	if absf(at.y-float(building.spec.levels[0])) < 1.0 and building.content != null:
		for item in building.content.data.floors[0].get("props",[]):
			if item.kind != "arrival_crate": continue
			var yaw := deg_to_rad(float(item.facing))
			if vr: center_player_on(Transform3D(Basis(Vector3.UP,yaw),at))
			else: body.rotation.y = yaw
			break
	rebase_player_motion()

## A scripted relocation does not spend walking charge or inherit fall velocity.
func rebase_player_motion() -> void:
	airborne_speed = 0.0
	fall_start_y = body.global_position.y
	stable_floor = -1
	stable_time = 0.0
	_airborne_peak = 0.0
	_last_charge_position = body.global_position
	_charge_position_valid = true
	_movement_settle = 0.5
	_landing_cost_armed = false

func die(reason: String) -> void:
	if recovering or returning: return
	deaths += 1
	last_death = reason
	recovering = true
	# The camera-cover must stay filled if death starts in the mesh-reveal zone.
	# Relocating out of that zone releases its occupancy normally.
	get_viewport().debug_draw = Viewport.DEBUG_DRAW_DISABLED
	if reason not in ["Retry", "Restart from roof"]:
		health.set_health(0.0)
		if soundscape != null: soundscape.play_hurt()
	health.suspended = true
	hurt_time = 0.0
	recovery_time = 0.0
	recovery_placed = false
	_set_enabled(false)
	_notice("%s\nReturning to %s" % [reason, floor_name(checkpoint)])
	died.emit(reason)

func _set_enabled(value: bool) -> void:
	body.enabled = value
	if desktop_help != null: desktop_help.visible = value
	if is_instance_valid(catalyst):
		catalyst.set_physics_process(value and not throwable_tools)
		if not value:
			catalyst._hide_all()
			catalyst.clear_shots()
	if not vr: body.desktop_pointer.set_enabled(value)
	if vr:
		for provider in body._movement_providers: provider.enabled = value
		for pickup in pickups:
			if not value: pickup.drop_object()
			pickup.enabled = value
		for pointer in pointers: pointer.enabled = value

func _restore_point() -> void:
	# A point released beyond the slab must remain reachable after retrying.
	if not is_instance_valid(coordinate_point): return
	coordinate_point.global_transform = point_home
	coordinate_point.linear_velocity = Vector3.ZERO
	coordinate_point.angular_velocity = Vector3.ZERO

func _set_fade(alpha: float) -> void:
	fade_material.albedo_color = Color(DEATH_RED,alpha)
	fade.visible = alpha > 0.0

func _notice(message: String) -> void:
	status.text = message
	status.show()
	notice_time = 4.0

func _right_button(button: String) -> void:
	if recovering or returning: return
	if button in ["ax_button", "by_button"]: jump.queued = true

func acquire_laser() -> void:
	if laser_unlocked: return
	laser_unlocked = true
	if is_instance_valid(catalyst): catalyst.set_unlocked(true)
	laser_acquired.emit()
	_notice("LASER BURST INSTALLED\nVR: empty hands together + trigger\nDesktop: hold C + left click")

func fire_catalyst() -> void:
	# Compatibility for callers: no alternate projectile or unlock bypass.
	if not vr: body.desktop_pointer.try_fire()

func _left_button(button: String) -> void:
	if returning: return
	if button == "primary_click": inventory_board.toggle()
	elif button == "ax_button":
		# Palle 2026-10-29: X opens the inventory prism (museum_rig.tscn/InventoryPrism), not the reset to the menu.
		var prism := get_tree().get_root().find_child("InventoryPrism", true, false)
		if prism != null and prism.has_method("toggle"): prism.toggle()

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo: return
	if event.keycode == KEY_M: return_to_menu()
	elif event.keycode == KEY_I: inventory_board.toggle()
	elif event.keycode == KEY_R: die("Retry")
	elif event.keycode == KEY_T and not recovering:
		checkpoint = 0
		die("Restart from roof")

func place_inventory_prefab(id: String) -> void:
	if not prefab_inventory.unlocked(id): return
	inventory_board.hide()
	var definition: Dictionary = prefab_inventory.definitions[id]
	var from: Vector3 = inventory_board.placement_from
	var direction: Vector3 = inventory_board.placement_direction
	# Place on a slab in view; never add a hidden support over a shaft.
	var query := PhysicsRayQueryParameters3D.create(from,from+direction*18,1)
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.normal.y < .95:
		_notice("Aim down at a clear floor slab, then open inventory to place."); return
	var index := -1
	for i in building.spec.levels.size():
		if absf(float(building.spec.levels[i])-hit.position.y)<.06: index=i; break
	if index<0: _notice("Place on a floor slab."); return
	var at: Vector3 = hit.position
	var centre: Array = definition.placement.get("bounds_center",[0,2.8,0])
	at -= Vector3(float(centre[0]),0,float(centre[2]))
	var dimensions: Array = definition.dimensions
	var half_x: float = float(dimensions[0])/2
	var half_z: float = float(dimensions[2])/2
	if absf(hit.position.x)+half_x>building.spec.width/2 or absf(hit.position.z)+half_z>building.spec.depth/2:
		_notice("AND needs a clear 14 × 7.2 metre bay. Place it in the lab editor."); return
	for shaft in building.spec.shafts:
		if absf(hit.position.x-float(shaft.x))<half_x+building.spec.shaft_width/2 and absf(hit.position.z)<half_z+building.spec.shaft_depth/2:
			_notice("Keep the shafts open. Choose a clear slab bay."); return
	var bounds := BoxShape3D.new(); bounds.size=Vector3(dimensions[0],dimensions[1]-.15,dimensions[2])
	var overlap := PhysicsShapeQueryParameters3D.new(); overlap.shape=bounds; overlap.collision_mask=1
	overlap.transform=Transform3D(Basis.IDENTITY,hit.position+Vector3(0,float(dimensions[1])/2+.05,0))
	if not camera.get_world_3d().direct_space_state.intersect_shape(overlap,1).is_empty():
		_notice("That bay is occupied. Use a clear floor or arrange the parts in the lab editor."); return
	var config: Dictionary = definition.placement.get("config",{}).duplicate(true)
	config.editor_source={"floor":definition.placement.source_floor,"id":definition.placement.source_id}
	var record := {"id":"inventory-"+id+"-"+str(Time.get_ticks_usec()),"artifact":definition.placement.artifact,"station":"NW","position":[at.x,at.z],"height":0,"facing":0,"scale":1,"config":config}
	building.content.load_floor(index)
	building.content.data.floors[index].get_or_add("copies",[]).append(record)
	building.content._build_artifact(building.content.roots[index],index,record)
	building.content.floor_changed.emit(index)
	_notice("AND placed / session copy. Use the lab editor to save a permanent arrangement.")

func scene_loaded(_user_data = null) -> void:
	if ready_for_play:
		place_player(spawn_for(checkpoint))
		camera.make_current()
		if vr: get_node("XROrigin3D").current = true

func scene_visible(_user_data = null) -> void:
	if ready_for_play: camera.make_current()

func is_map_ready() -> bool:
	return ready_for_play

func return_to_menu() -> void:
	if returning: return
	returning = true
	_set_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor.has_method("return_to_main_menu"):
			ancestor.return_to_main_menu()
			return
		ancestor = ancestor.get_parent()
	Route.load_scene(self, "res://commons/scenes/vr_staging.tscn")

func _suspend_global_tools() -> void:
	stuck = get_node_or_null("/root/StuckDetector")
	if stuck != null:
		old_stuck = stuck.enabled
		stuck.enabled = false
	mushroom = get_node_or_null("/root/MushroomHand")
	if mushroom == null: return
	old_mushroom_mode = mushroom.process_mode
	mushroom.process_mode = Node.PROCESS_MODE_DISABLED
	for controller in get_tree().root.find_children("*", "XRController3D", true, false):
		for connection in controller.get_signal_connection_list("button_pressed"):
			var callback: Callable = connection.callable
			if callback.get_object() == mushroom:
				mushroom_connections.append({"controller": controller, "callback": callback, "flags": connection.flags})
				controller.button_pressed.disconnect(callback)
	for layer in mushroom.find_children("*", "CanvasLayer", true, false):
		if layer.visible:
			mushroom_layers.append(layer)
			layer.hide()

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(catalyst):
		catalyst._hide_all()
		catalyst.clear_shots()
		catalyst.desktop_source = previous_desktop_source.get_ref() if previous_desktop_source != null else null
		catalyst.set_physics_process(catalyst_was_processing)
		catalyst.set_unlocked(catalyst_was_unlocked)
	if is_instance_valid(stuck): stuck.enabled = old_stuck
	if is_instance_valid(mushroom):
		mushroom.process_mode = old_mushroom_mode
		for item in mushroom_connections:
			if is_instance_valid(item.controller) and not item.controller.button_pressed.is_connected(item.callback):
				item.controller.button_pressed.connect(item.callback, item.flags)
		for layer in mushroom_layers:
			if is_instance_valid(layer): layer.show()

func _drain_movement(feet: Vector3, delta: float) -> void:
	_movement_settle = maxf(0,_movement_settle-delta)
	if _charge_position_valid and _movement_settle<=0:
		var step := feet-_last_charge_position
		step.y = 0.0 # Gravity's travel never drains the charge.
		if body.is_on_floor():
			var platform := body.get_platform_velocity()*delta
			step -= Vector3(platform.x,0,platform.z)
		var distance := step.length()
		# Ignore tracking noise and relocation. Ordinary walking is ~5cm/tick.
		if distance > maxf(0.001,delta*0.02) and distance < 2.0:
			charge.travel(distance)
	_last_charge_position = feet
	_charge_position_valid = true

func _update_charge_display() -> void:
	if not is_instance_valid(charge_display): return
	charge_display.text = "CHARGE %d%%" % ceili(charge.get_charge())
	charge_display.modulate = Color("ffbe73") if charge.get_charge()<=20 else Color("d7e4ca")

func _on_health_changed(value: float, difference: float) -> void:
	_update_charge_display()
	if charge.last_cause == "movement": return
	if difference < 0 and not recovering:
		hurt_time = 0.65 if charge.last_cause=="ceiling laser" else 0.25
		if soundscape != null: soundscape.play_hurt()
		_notice("%s / charge %d%%" % [str(charge.last_cause).to_upper(),ceili(value)])
	elif difference > 0:
		_notice("CHARGING / %d%%" % ceili(value))

func _filter_floor_materials(index: int) -> void:
	# Artifact finishes may change during interaction: leave their materials alone.
	for key in building.content.props:
		if str(key).begins_with(str(index) + "/"):
			render_quality.filter_branch.call_deferred(building.content.props[key])

func _filter_structural_materials() -> void:
	for child in building.get_children():
		if child != building.content: render_quality.filter_branch(child)
	for index in building.content.roots: _filter_floor_materials(index)
