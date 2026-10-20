extends "res://addons/godot-xr-tools/staging/scene_base.gd"
## The sphere runs; the viewer stays centred. Four finite maps share this XR rig.
const Course := preload("course.gd")
const Campaign := preload("campaign.gd")
const Chunk := preload("chunk.gd")
const Blaster := preload("blaster.gd")
const InputProbe := preload("input_probe.gd")
const INPUT_REVISION := "2026-10-18-level-checkpoints-1"
const PointBody := preload("res://commons/museum_runner/forms/point_body.gd")
const LineSkin := preload("res://commons/museum_runner/forms/line_skin.gd")
const Route := preload("res://commons/hazards/biome_ladder/route.gd")
const RADIUS := 0.38
const VIEW_SPAWN := Vector3(0,2.0,7.5)
enum State { READY, RUNNING, PAUSED, OVER, WON, COMPLETE, SAVE_FAILED }
@export var save_path := "user://museum-runner/best.cfg"
var state := State.READY
var campaign := Campaign.new()
var level: Node3D
var level_index := 0
var banked_score := 0
var save_error := ""
var seed_value := 17
var distance := 0.0
var collected := 0
var best := 0
var lane := 0
var speed := 5.5
var chunks: Array[Node3D] = []
var next_chunk := 0
var runner: CharacterBody3D
var skin: MeshInstance3D
var shape: SphereShape3D
var camera: Camera3D
var environment: Environment
var hud: CanvasLayer
var status: Label
var instructions: Label
var action_button: Button
var vr_status: Label3D
var vr := false
var ready_for_play := false
var returning := false
var axis_armed := true
var axis_direction := 0
var axis_repeat := 0.0
var blaster: Node3D
var firing_hands: Array[XRController3D] = []
var mouse_firing := false
var trail: Array[MeshInstance3D] = []
var last_sample := Vector3.ZERO
var since_sample := 0.0
var collected_flash := 0.0
var last_hit := ""
var stuck: Node
var old_stuck := false
var mushroom_hand: Node
var old_mushroom_mode := Node.PROCESS_MODE_ALWAYS
var hidden_mushroom_layers: Array[CanvasLayer] = []
var mushroom_connections: Array[Dictionary] = []
var input_probe: RefCounted

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--runner-save="): save_path = arg.trim_prefix("--runner-save=")
	var interface := XRServer.primary_interface
	vr = interface != null and interface.is_initialized()
	stuck = get_node_or_null("/root/StuckDetector")
	if stuck != null:
		old_stuck = stuck.enabled
		stuck.enabled = false
	# This game owns trigger input. The global throwing hand is restored on exit.
	mushroom_hand = get_node_or_null("/root/MushroomHand")
	if mushroom_hand != null:
		old_mushroom_mode = mushroom_hand.process_mode
		mushroom_hand.process_mode = Node.PROCESS_MODE_DISABLED
		# Process mode does not suppress an already connected signal. Suspend
		# only this autoload's bindings; leave other hand listeners intact.
		for controller in get_tree().root.find_children("*","XRController3D",true,false):
			for connection in controller.get_signal_connection_list("button_pressed"):
				var callback: Callable = connection.callable
				if callback.get_object() == mushroom_hand:
					mushroom_connections.append({"controller":controller,"callback":callback,"flags":connection.flags})
					controller.button_pressed.disconnect(callback)
		for layer in mushroom_hand.find_children("*","CanvasLayer",true,false):
			if layer.visible:
				hidden_mushroom_layers.append(layer)
				layer.hide()
	campaign.restore(save_path)
	best = campaign.best
	_build_environment()
	_build_runner()
	_build_hud()
	blaster = Blaster.new()
	blaster.may_fire = func(): return state==State.RUNNING and not returning
	add_child(blaster)
	blaster.target_broken.connect(_update_hud)
	for hand in [get_node("XROrigin3D/LeftHand"),get_node("XROrigin3D/RightHand")]:
		hand.button_pressed.connect(_vr_button.bind(hand))
		hand.button_released.connect(_vr_release.bind(hand))
		blaster.register_hand(hand)
		var marker := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.025
		mesh.height = 0.05
		marker.mesh = mesh
		marker.material_override = Chunk.finish(Color("efb2cf"),0.4)
		hand.add_child(marker)
	reset_run(false)
	ready_for_play = true
	if FileAccess.file_exists("user://museum-runner/input-debug.on"):
		input_probe = InputProbe.new(self)
	print("[museum-runner] Ready. Joystick: lanes; trigger: shoot; A/X: start/jump. Desktop: arrows, Space, mouse to shoot.")
	print("[museum-runner] Input revision: ",INPUT_REVISION)

func _build_environment() -> void:
	environment = Environment.new()
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("121d35")
	sky_material.sky_horizon_color = Color("7e7f98")
	sky_material.ground_bottom_color = Color("151d2d")
	sky_material.ground_horizon_color = Color("7e7f98")
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("becde3")
	environment.ambient_light_energy = 0.36
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("565a78")
	environment.fog_density = 0.007
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-33,-26,0)
	sun.light_color = Color("ffe1c4")
	sun.light_energy = 0.75
	sun.shadow_enabled = true
	add_child(sun)
	var xr := get_node("XROrigin3D") as XROrigin3D
	xr.position = VIEW_SPAWN
	get_node("XROrigin3D/XRCamera3D").environment = environment
	if not vr:
		xr.process_mode = Node.PROCESS_MODE_DISABLED
		xr.hide()
		camera = Camera3D.new()
		camera.environment = environment
		camera.position = Vector3(0,3.4,7.2)
		camera.fov = 66
		add_child(camera)
		camera.look_at(Vector3(0,0.6,-11))
		camera.make_current()
	else: camera = get_node("XROrigin3D/XRCamera3D")
	# A continuous runway supports the ball; course tiles are visual copies.
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var boundary := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(6.5,0.4,220)
	boundary.shape = floor_shape
	boundary.position = Vector3(0,-0.2,-75)
	floor_body.add_child(boundary)
	add_child(floor_body)
	var under := Chunk.BoxBody.new(Vector3(24,0.25,220))
	under.position = Vector3(0,-1.4,-75)
	under.material_override = Chunk.finish(Color("172230"),0.95)
	add_child(under)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_runner() -> void:
	runner = CharacterBody3D.new()
	runner.name = "RunningPoint"
	runner.collision_layer = 8
	runner.collision_mask = 1
	skin = MeshInstance3D.new()
	# Inherit the tutorial's sphere mesh. Running is a new body behaviour;
	# XRTools pickup is deliberately not attached to the moving protagonist.
	var source := PointBody.new()
	skin.mesh = source.get_child(0).mesh
	source.free()
	skin.scale = Vector3.ONE * (RADIUS/PointBody.RADIUS)
	var material := Chunk.finish(Color("11141e"),0.14)
	material.metallic = 0.72
	skin.material_override = material
	runner.add_child(skin)
	shape = SphereShape3D.new()
	shape.radius = RADIUS
	var boundary := CollisionShape3D.new()
	boundary.shape = shape
	runner.add_child(boundary)
	add_child(runner)
	# A small rose light catches the black surface without hiding its form.
	var fill := OmniLight3D.new()
	fill.position = Vector3(-2,2.4,2)
	fill.light_color = Color("ffc1dd")
	fill.light_energy = 1.5
	fill.omni_range = 7
	add_child(fill)

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 20
	hud.visible = not vr
	add_child(hud)
	var panel := VBoxContainer.new()
	panel.position = Vector2(30,24)
	panel.add_theme_constant_override("separation",12)
	hud.add_child(panel)
	status = Label.new()
	status.add_theme_font_size_override("font_size",24)
	panel.add_child(status)
	instructions = Label.new()
	instructions.add_theme_font_size_override("font_size",17)
	panel.add_child(instructions)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation",12)
	panel.add_child(buttons)
	action_button = Button.new()
	action_button.focus_mode = Control.FOCUS_NONE
	action_button.custom_minimum_size = Vector2(180,42)
	action_button.pressed.connect(primary_action)
	buttons.add_child(action_button)
	for item in [["Saved checkpoint",func(): reset_run(false)],["Museum menu",return_to_menu]]:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.text = item[0]
		button.custom_minimum_size = Vector2(145,42)
		button.pressed.connect(item[1])
		buttons.add_child(button)
	vr_status = Label3D.new()
	vr_status.position = Vector3(0,3.6,1.5)
	vr_status.font_size = 40
	vr_status.pixel_size = 0.0035
	vr_status.outline_size = 6
	vr_status.visible = vr
	add_child(vr_status)

## Restore the last completed-map checkpoint; an unfinished attempt is discarded.
func reset_run(play := true) -> void:
	if state == State.RUNNING or state == State.PAUSED: _save_best()
	_load_level(mini(campaign.next_level, Campaign.MAPS.size()-1), play)
	if campaign.next_level == Campaign.MAPS.size():
		state = State.COMPLETE
		distance = level.length_m()
		for chunk in chunks: chunk.position.z = distance-chunk.index*Course.LENGTH
		_stream()
		_update_hud()

func _load_level(index: int, play := false) -> void:
	for chunk in chunks: chunk.free()
	chunks.clear()
	if is_instance_valid(level): level.free()
	for segment in trail: segment.free()
	trail.clear()
	level_index = index
	level = Campaign.MAPS[index].instantiate()
	add_child(level)
	banked_score = campaign.banked_score
	seed_value = level.course_seed
	next_chunk = 0
	distance = 0
	collected = 0
	lane = 0
	speed = level.start_speed
	last_hit = ""
	save_error = ""
	firing_hands.clear()
	mouse_firing = false
	axis_armed = true
	axis_direction = 0
	axis_repeat = 0.0
	blaster.reset()
	since_sample = 0
	collected_flash = 0
	runner.position = Vector3(0,RADIUS+0.015,0)
	runner.velocity = Vector3.ZERO
	last_sample = runner.position
	skin.rotation = Vector3.ZERO
	environment.fog_light_color = Chunk.FLOOR_COLOURS[level.chapter].lightened(0.25)
	_stream()
	state = State.RUNNING if play else State.READY
	_update_hud()

func primary_action() -> void:
	match state:
		State.READY, State.OVER, State.WON: reset_run(true)
		State.PAUSED: state = State.RUNNING
		State.RUNNING: jump()
		State.SAVE_FAILED: _complete_level()
		State.COMPLETE: return_to_menu()
	_update_hud()

## A win commits the next map before offering it. Repeated calls cannot award twice.
func _complete_level() -> void:
	if state != State.RUNNING and state != State.SAVE_FAILED: return
	firing_hands.clear()
	mouse_firing = false
	runner.velocity = Vector3.ZERO
	best = maxi(best,score())
	var error := campaign.store(save_path,level_index+1,score(),best)
	if error != OK:
		save_error = "Checkpoint could not be saved. Press A / X or Space to retry saving."
		state = State.SAVE_FAILED
	else:
		save_error = ""
		state = State.COMPLETE if campaign.next_level == Campaign.MAPS.size() else State.WON
	_update_hud()

func shift(direction: int) -> void:
	if state == State.RUNNING: lane = clampi(lane+signi(direction),-1,1)

func jump() -> bool:
	if state != State.RUNNING or not runner.is_on_floor() or runner.velocity.y > 0: return false
	runner.velocity.y = 6.8
	return true

func toggle_pause() -> void:
	firing_hands.clear()
	mouse_firing = false
	if state == State.RUNNING: state = State.PAUSED
	elif state == State.PAUSED: state = State.RUNNING
	_update_hud()

func _input(event: InputEvent) -> void:
	# A release over a HUD button must end a shot started in the world.
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		mouse_firing = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		mouse_firing = event.pressed and state==State.RUNNING
		return
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode:
		KEY_LEFT,KEY_A: shift(-1)
		KEY_RIGHT,KEY_D: shift(1)
		KEY_SPACE,KEY_UP: primary_action()
		KEY_P,KEY_ESCAPE: toggle_pause()
		KEY_R: reset_run(true)
		KEY_M: return_to_menu()

func _vr_button(button: String, hand: XRController3D = null) -> void:
	if input_probe != null: input_probe.button(button,hand)
	match button:
		"ax_button": primary_action()
		"trigger_click":
			if state==State.RUNNING and is_instance_valid(hand) and not firing_hands.has(hand): firing_hands.append(hand)
		"by_button": toggle_pause()
		"menu_button": return_to_menu()

func _vr_release(button: String, hand: XRController3D) -> void:
	if button=="trigger_click": firing_hands.erase(hand)

func steer_axis(x: float, delta: float) -> void:
	if state!=State.RUNNING: return
	if absf(x)<0.3:
		axis_armed = true
		axis_direction = 0
		axis_repeat = 0
		return
	if absf(x)<0.6: return
	var direction := 1 if x>0 else -1
	axis_repeat -= delta
	if axis_armed or direction!=axis_direction or axis_repeat<=0:
		shift(direction)
		axis_armed = false
		axis_direction = direction
		axis_repeat = 0.26

func _steering_input() -> float:
	# Read the actual XR actions independently of the render mode chosen in
	# _ready(). Either stick can steer; left wins a tie so two held sticks
	# cannot issue opposing lane changes in the same frame.
	var left: float = get_node("XROrigin3D/LeftHand").get_vector2("primary").x
	var right: float = get_node("XROrigin3D/RightHand").get_vector2("primary").x
	return left if absf(left)>=absf(right) else right

func _shoot() -> void:
	if state!=State.RUNNING: return
	for hand in firing_hands:
		if not is_instance_valid(hand): continue
		var channel := 1 if hand==get_node("XROrigin3D/LeftHand") else 2
		blaster.fire_from(hand.to_global(Vector3(0,0,-0.22)),-hand.global_basis.z,channel)
	if mouse_firing and not vr:
		var pixel := get_viewport().get_mouse_position()
		blaster.fire_from(camera.project_ray_origin(pixel),camera.project_ray_normal(pixel),0)

func _physics_process(delta: float) -> void:
	if not ready_for_play or returning: return
	# Input is resolved before moving/collision, so a shot can clear this frame's obstacle.
	_shoot()
	blaster.update_sights(vr and state==State.RUNNING)
	steer_axis(_steering_input(),delta)
	if input_probe != null: input_probe.tick(delta)
	if state == State.PAUSED: return
	if state in [State.OVER, State.WON, State.COMPLETE, State.SAVE_FAILED]:
		blaster.tick(delta,0)
		return
	var previous := runner.position
	if state == State.RUNNING:
		runner.velocity.x = clampf((lane*Course.LANE_WIDTH-runner.position.x)/delta,-10,10)
	else: runner.velocity.x = 0
	runner.velocity.y -= 18.0*delta
	runner.move_and_slide()
	if state != State.RUNNING:
		blaster.tick(delta,0)
		return
	speed = minf(10.0,level.start_speed+distance/200.0)
	var travel := minf(speed*delta,maxf(0,level.length_m()-distance))
	blaster.tick(delta,travel)
	# Query the actual sphere and obstacle shapes in their pre-scroll frame.
	# Relative motion includes the world moving towards the runner, preventing
	# thin beams from being skipped between physics ticks.
	var hit := _sweep(2,previous,runner.position,travel,false)
	var prize := _sweep(4,previous,runner.position,travel,true)
	if not prize.is_empty() and is_instance_valid(prize.get("collider")):
		var object: Area3D = prize.collider
		if object.get_meta("collectible",false):
			object.collision_layer = 0
			object.hide()
			collected += 1
			collected_flash = 0.3
	distance += travel
	for chunk in chunks: chunk.position.z += travel
	for segment in trail: segment.position.z += travel
	last_sample.z += travel
	since_sample += travel
	if since_sample >= 0.45:
		var segment := LineSkin.new()
		segment.show_segment(last_sample,runner.position-last_sample,last_sample.distance_to(runner.position))
		add_child(segment)
		trail.append(segment)
		if trail.size() > 32: trail.pop_front().free()
		last_sample = runner.position
		since_sample = 0
	skin.rotate_x(-travel/RADIUS)
	collected_flash = maxf(0,collected_flash-delta)
	_stream()
	if not hit.is_empty():
		firing_hands.clear()
		mouse_firing = false
		last_hit = "A form stopped the point. Try another line."
		state = State.OVER
		_save_best()
	elif distance >= level.length_m():
		_complete_level()
	_update_hud()

func _sweep(mask: int, from: Vector3, to: Vector3, travel: float, areas: bool) -> Dictionary:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY,from)
	query.collision_mask = mask
	query.collide_with_areas = areas
	query.collide_with_bodies = not areas
	query.motion = to-from-Vector3(0,0,travel)
	var space := get_world_3d().direct_space_state
	var overlap := space.intersect_shape(query,1)
	if not overlap.is_empty(): return overlap[0]
	var fraction := space.cast_motion(query)
	if fraction[0] >= 1.0: return {}
	query.transform.origin += query.motion * minf(1.0,fraction[1]+0.005)
	query.motion = Vector3.ZERO
	overlap = space.intersect_shape(query,1)
	return overlap[0] if not overlap.is_empty() else {"collider":null}

func _stream() -> void:
	while next_chunk < level.sections and next_chunk*Course.LENGTH <= distance+144:
		var chunk := Chunk.new()
		chunk.index = next_chunk
		chunk.seed_value = seed_value
		chunk.chapter_override = level.chapter
		chunk.last_section = next_chunk == level.sections-1
		chunk.position.z = distance-next_chunk*Course.LENGTH
		level.add_child(chunk)
		chunks.append(chunk)
		next_chunk += 1
	while not chunks.is_empty() and chunks[0].position.z > Course.LENGTH+12:
		chunks.pop_front().free()
	level.finish_gate.position.z = distance-level.length_m()

func score() -> int:
	return campaign.banked_score if state == State.COMPLETE else banked_score+int(distance)+collected*25

func _save_best() -> void:
	best = maxi(best,score())
	# An unfinished attempt may set a record, but cannot advance its checkpoint.
	var error := campaign.store(save_path,campaign.next_level,campaign.banked_score,best)
	if error != OK: push_warning("Museum Runner: record could not be saved: %s" % error)

func _update_hud() -> void:
	status.text = "MUSEUM RUNNER   /   MAP %d OF %d — %s\n%03d / %03d m     %02d cubes     %05d score     best %05d" % [level_index+1,Campaign.MAPS.size(),level.title,int(distance),int(level.length_m()),collected,score(),best]
	status.modulate = Color("fbdc81") if collected_flash > 0 or state in [State.WON,State.COMPLETE] else Color("f4eced")
	var prompt := "Reach the finish. A / D or ← / → : lanes · Space: jump · Mouse: shoot\nMint diamonds: breakable · Pink beams: jump or dodge · Gold cubes: collect"
	var action := "Jump"
	var vr_prompt := "RUNNING — reach the finish · A / X: jump"
	match state:
		State.READY:
			prompt = "Checkpoint: start of %s.\nReach the finish to save the next map." % level.title
			action = "Start map"
			vr_prompt = "READY · A / X: start map"
		State.OVER:
			prompt = last_hit + "\nSpace / R: return to the saved start of this map."
			action = "Retry checkpoint"
			vr_prompt = "TRY AGAIN · A / X: saved checkpoint"
		State.PAUSED:
			prompt = "PAUSED — this attempt is kept.\nSpace / P: resume · M: museum menu"
			action = "Resume"
			vr_prompt = "PAUSED · A / X or B / Y: resume"
		State.WON:
			prompt = "MAP COMPLETE — next map and score saved.\nSpace: continue to %s." % Course.TITLES[campaign.next_level]
			action = "Next map"
			vr_prompt = "MAP COMPLETE · SAVED · A / X: next map"
		State.COMPLETE:
			prompt = "ALL FOUR MAPS COMPLETE — progress saved.\nThe point has crossed the museum. Space / M: return to museum."
			action = "Return to museum"
			vr_prompt = "ALL MAPS COMPLETE · SAVED · A / X: museum"
		State.SAVE_FAILED:
			prompt = save_error
			action = "Retry save"
			vr_prompt = "FINISH REACHED · SAVE FAILED · A / X: retry save"
	instructions.text = prompt + "\nP: pause   ·   R: saved checkpoint   ·   M: menu"
	action_button.text = action
	var breaks: int = blaster.broken if blaster!=null else 0
	vr_status.text = "MAP %d / %d · %s\n%d / %d m · %d cubes · %d broken · score %d\n%s\nEither joystick: lanes · Trigger: shoot · B / Y: pause" % [level_index+1,Campaign.MAPS.size(),level.title,int(distance),int(level.length_m()),collected,breaks,score(),vr_prompt]
	if input_probe != null: vr_status.text += "\n" + input_probe.display

func is_map_ready() -> bool: return ready_for_play

func scene_loaded(_data = null) -> void:
	# XRTools must transfer the active origin away from the loading/menu scene.
	if vr: super.scene_loaded(Transform3D(Basis.IDENTITY,VIEW_SPAWN))
	camera.make_current()

func scene_visible(_data = null) -> void: camera.make_current()
func scene_exiting(_data = null) -> void: _save_best()

func return_to_menu() -> void:
	if returning: return
	returning = true
	_save_best()
	var parent := get_parent()
	while parent != null:
		if parent.has_method("return_to_main_menu"):
			parent.return_to_main_menu()
			return
		parent = parent.get_parent()
	Route.load_scene(self,"res://commons/scenes/vr_staging.tscn")

func _exit_tree() -> void:
	if is_instance_valid(stuck): stuck.enabled = old_stuck
	if is_instance_valid(mushroom_hand): mushroom_hand.process_mode = old_mushroom_mode
	for connection in mushroom_connections:
		if is_instance_valid(connection.controller) and connection.callback.is_valid():
			if not connection.controller.button_pressed.is_connected(connection.callback):
				connection.controller.button_pressed.connect(connection.callback,connection.flags)
	for layer in hidden_mushroom_layers:
		if is_instance_valid(layer): layer.show()
