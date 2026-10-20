extends "res://tools/probes/void_game_probe.gd"
const Ability := preload("res://commons/hazards/becoming_catalyst/first_catalyst_ability.gd")
var shots := 0
var actions := 0
var distances: Array[float] = []
var heights: Array[float] = []

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code; event.physical_keycode = code; event.pressed = pressed
	Input.parse_input_event(event)

func click(button: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button; event.pressed = pressed
	Input.parse_input_event(event)

func join_hands(joined: bool) -> void:
	if not xr:
		key(KEY_C, joined)
		return
	var center: Vector3 = game.camera.global_position + Vector3(0,-.16,-.48)
	var spread := .08 if joined else .4
	hand_at(left, center + Vector3(-spread,0,0))
	hand_at(right, center + Vector3(spread,0,0))

func trigger(pressed: bool) -> void:
	if xr: right.set_input("trigger_click", pressed)
	else: click(MOUSE_BUTTON_LEFT, pressed)

func grab(point: Node3D) -> void:
	if xr:
		hand_at(right, point.global_position); await frames(12)
		right.set_input("grip", 1.0)
	else:
		game.camera.look_at(point.global_position); await frames(12)
		click(MOUSE_BUTTON_RIGHT, true); click(MOUSE_BUTTON_RIGHT, false)
	await frames(15)

func release() -> void:
	if xr: right.set_input("grip", 0.0)
	else:
		click(MOUSE_BUTTON_RIGHT, true); click(MOUSE_BUTTON_RIGHT, false)
	await frames(12)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	for use_xr in [false, true]:
		shots = 0; actions = 0
		var ability := Ability.new(); root.add_child(ability)
		ability.form_sent.connect(func(_shot): shots += 1)
		await start(use_xr)
		var tag := "XR / " if xr else "Desktop / "
		var pointer: Node = game.pointers[1] if xr else game.body.desktop_pointer
		check(tag+"ten metre pointer includes handles, buttons and UI", pointer.distance==10.0 and (pointer.get("collision_mask") if xr else pointer.get("collision_mask_value"))==5505024)
		if not xr: check(tag+"mouse captured for real input delivery", Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
		game.place_player(Vector3(-5,.06,4.5)); await frames(25)
		var before: Vector3 = game.body.global_position
		axes(Vector2.RIGHT); await frames(60)
		distances.append(game.body.global_position.x-before.x)
		check(tag+"walk travels about three metres in one second", absf(distances.back()-3.0)<.15)
		axes(Vector2.ZERO); await frames(60)
		before = game.body.global_position; await frames(60)
		check(tag+"no drift after input release", game.body.global_position.distance_to(before)<.01)
		var peak := before.y
		press_jump()
		for i in 75:
			await frames(1)
			peak = maxf(peak, game.body.global_position.y)
		release_jump(); heights.append(peak-before.y)
		check(tag+"jump reaches one metre and lands", heights.back()>.9 and heights.back()<1.2 and game.body.is_on_floor())
		join_hands(true); await frames(45); trigger(true); await frames(2); trigger(false)
		check(tag+"locked catalyst cannot be bypassed", not ability.formed and shots==0)
		ability.set_unlocked(true); join_hands(false); await frames(2)
		join_hands(true); await frames(3)
		check(tag+"formation takes time", not ability.formed)
		await frames(20)
		check(tag+"near empty hands form the same ability", ability.formed and game.catalyst==ability)
		trigger(true); await frames(2); trigger(false)
		check(tag+"trigger sends the actual shared projectile", shots==1 and ability.projectiles[0].get_script().resource_path.ends_with("form_projectile.gd") and ability.projectiles[0].speed==6.0 and (ability.projectiles[0].collision_mask & 1)!=0)
		trigger(true); await frames(2); trigger(false)
		check(tag+"cooldown prevents rapid second shot", shots==1)
		await frames(25); trigger(true); await frames(2)
		check(tag+"shooting resumes after cooldown", shots==2)
		await frames(30)
		check(tag+"holding trigger does not auto fire", shots==2)
		trigger(false); join_hands(false); await frames(5); trigger(true); await frames(2); trigger(false)
		check(tag+"separated hands cannot shoot", shots==2 and not ability.formed)
		ability.clear_shots()
		game.checkpoint=1; game.place_player(game.spawn_for(1)); await frames(40)
		var button: Area3D = game.building.content.props["1/point-light-switch"].find_child("SunSwitchButton",true,false)
		var light_switch: Node = button.get_parent()
		var target: Vector3 = button.global_position
		game.place_player(Vector3(target.x,-5.94,target.z+1.2)); await frames(20)
		if xr:
			hand_at(left,target+Vector3(-.8,.2,1)); hand_at(right,target+Vector3(0,.013,.7))
		else: game.camera.look_at(target)
		await frames(25)
		var pointed: Node = game.pointers[1].last_target if xr else game.body.desktop_pointer._last_target
		check(tag+"pointer targets the authored light switch", pointed==button or pointed==light_switch)
		var was_enabled: bool = light_switch.enabled
		trigger(true); await frames(4); trigger(false); await frames(4)
		var lamps_match := true
		var lamps := 0
		for lamp in get_nodes_in_group("void_point_rod_light"):
			if light_switch._hall.is_ancestor_of(lamp):
				lamps += 1; lamps_match = lamps_match and lamp.beam.visible==light_switch.enabled
		check(tag+"trigger switches the actual rod lights", light_switch.enabled!=was_enabled and lamps>0 and lamps_match)
		game.checkpoint=2; game.place_player(game.spawn_for(2)); await frames(35)
		var point: RigidBody3D = game.coordinate_point
		game.place_player(Vector3(point.global_position.x,-11.94,point.global_position.z+1.8)); await frames(20)
		point.action_pressed.connect(func(_point): actions+=1)
		await grab(point)
		check(tag+"grabbing uses XRTools pickup state", point.is_picked_up() and point._is_held)
		check(tag+"grab turns on the point light", point.get_node("CarriedLight").visible)
		var old: Vector3=point.global_position
		if xr: hand_at(right, old+Vector3(0,.3,-.2))
		else: game.camera.rotation.x += .2
		await frames(20)
		check(tag+"held point moves with the hand", point.global_position.distance_to(old)>.15)
		join_hands(true); await frames(20); trigger(true); await frames(2); trigger(false)
		check(tag+"held point takes trigger and blocks catalyst", actions==1 and shots==2 and not ability.formed)
		await release()
		check(tag+"release restores point state and extinguishes light", not point.is_picked_up() and not point._is_held and not point.get_node("CarriedLight").visible)
		await grab(point)
		game.die("Retry"); await frames(5); trigger(true); await frames(2); trigger(false)
		check(tag+"recovery drops the point and suppresses shots", not point.is_picked_up() and not ability.is_physics_processing() and not ability.formed and shots==2)
		await frames(85)
		check(tag+"checkpoint restores the same point and interactions", not game.recovering and game.checkpoint==2 and ability.is_physics_processing() and point.global_transform.is_equal_approx(game.point_home))
		game.queue_free(); await frames(5)
		check(tag+"exit detaches input adapter and restores shared ability", ability.desktop_source==null and ability.is_physics_processing() and not ability.formed)
		ability.queue_free(); await frames(3)
		if xr:
			for item in [head,left,right]: XRServer.remove_tracker(item)
	check("Desktop and XR walking distance agree", absf(distances[0]-distances[1])<.08)
	check("Desktop and XR jump height agree", absf(heights[0]-heights[1])<.02)
	FileAccess.open(out.path_join("parity-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"distances":distances,"jump_heights":heights,"scope":"Actual Godot input events, artifacts, physics and XRTools with synthetic trackers. No physical headset test."},"\t"))
	quit(0 if failed.is_empty() else 1)
