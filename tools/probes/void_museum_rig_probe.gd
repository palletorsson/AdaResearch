extends "res://tools/probes/void_game_probe.gd"
## Real controller input, body physics and the existing Point One light switch.

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	await start(true)
	var origin: XROrigin3D = game.get_node("XROrigin3D")
	check("Void instantiates the shared museum player scene", origin.scene_file_path == "res://commons/player/museum_rig.tscn")
	check("one player body and four local movement providers", origin.find_children("*", "CharacterBody3D", true, false).size() == 1 and game.body._movement_providers.size() == 4)
	check("museum deadzone scripts resolve this player", origin.get_node("VelocityDeadzone")._player_body == game.body and origin.get_node("JoystickDeadzoneFix").fallback_y_deadzone == 0.5)
	var settings: Node = root.get_node("XRToolsUserSettings")
	check("museum stick deadzones are active", settings.y_axis_dead_zone == 0.5 and settings.x_axis_dead_zone == 0.3)
	var move: Node = origin.get_node("LeftHand/XRToolsCollisionHand/MovementDirect")
	var turn: Node = origin.get_node("RightHand/XRToolsCollisionHand/MovementTurn")
	check("museum walking speed and user turn preference retained", move.max_speed == 3.0 and turn.turn_mode == 0)
	game.place_player(Vector3(-5, 0.06, 4.5)); await frames(25)
	var before: Vector3 = game.body.global_position
	left.set_input("primary", Vector2(0.15, 0.42))
	right.set_input("primary", Vector2(0.08, 0.35))
	await frames(120)
	check("worn-stick idle offsets do not move the body", game.body.global_position.distance_to(before) < 0.02)
	left.set_input("primary", Vector2.ZERO); right.set_input("primary", Vector2.ZERO)
	left.set_input("primary", Vector2.RIGHT); await frames(30)
	check("intentional left-stick strafe still moves", game.body.global_position.x > before.x + 0.8)
	left.set_input("primary", Vector2.ZERO); await frames(35)
	before = game.body.global_position
	await frames(90)
	check("release stops without residual drift", game.body.global_position.distance_to(before) < 0.02 and Vector2(game.body.velocity.x, game.body.velocity.z).length() < 0.01)
	game.place_player(Vector3(-5, 0.06, 4.5)); await frames(20)
	before = game.body.global_position
	right.set_input("primary", Vector2(0,1)); await frames(25)
	check("right stick retains forward walking", game.body.global_position.z < before.z - 0.6)
	right.set_input("primary", Vector2.ZERO); await frames(20)
	var rotation_before: Basis = origin.global_basis
	right.set_input("primary", Vector2.RIGHT); await frames(15)
	check("right stick turns the shared rig", not origin.global_basis.is_equal_approx(rotation_before))
	right.set_input("primary", Vector2.ZERO)
	game.place_player(Vector3(-5, 0.06, 4.5)); await frames(20)
	right.set_input("ax_button", true); await frames(12)
	check("right A jumps with positive height", not game.body.is_on_floor() and game.body.global_position.y > 0.3)
	await frames(100)
	check("holding A does not jump again after landing", game.body.is_on_floor())
	right.set_input("ax_button", false)
	game.checkpoint = 1; game.place_player(game.spawn_for(1)); await frames(40)
	var switch_root: Node = game.building.content.props["1/point-light-switch"]
	var button: Area3D = switch_root.find_child("SunSwitchButton", true, false)
	var light_switch: Node = button.get_parent()
	# The actual authored switch, aimed at from 70 cm away, not a direct method call.
	var target: Vector3 = button.global_position
	game.place_player(Vector3(target.x, -5.94, target.z+1.2)); await frames(25)
	hand_at(left, target + Vector3(-0.8,0.2,1.0))
	hand_at(right, target + Vector3(0,0.013,0.7)); await frames(25)
	check("museum ray pointer targets the real Point One switch", game.pointers[1].last_target == button)
	var was_enabled: bool = light_switch.enabled
	right.set_input("trigger_click", true); await frames(5); right.set_input("trigger_click", false); await frames(5)
	check("trigger toggles the real floor lights", light_switch.enabled != was_enabled and game.body.is_on_floor())
	var lamps_match := true
	var lamp_count := 0
	for lamp in get_nodes_in_group("void_point_rod_light"):
		if light_switch._hall.is_ancestor_of(lamp):
			lamp_count += 1
			lamps_match = lamps_match and lamp.beam.visible == light_switch.enabled
	check("switch changes the actual rod lights", lamp_count > 0 and lamps_match)
	right.set_input("trigger_click", true); await frames(5); right.set_input("trigger_click", false); await frames(5)
	check("second trigger restores the lighting", light_switch.enabled == was_enabled)
	game.die("Retry"); await frames(4)
	check("death disables pointers and pickup", not game.pointers[0].enabled and not game.pointers[1].enabled and not game.pickups[0].enabled)
	await frames(90)
	check("respawn restores pointers and pickup", game.pointers[0].enabled and game.pointers[1].enabled and game.pickups[0].enabled and not game.recovering)
	game.queue_free(); await frames(4)
	for item in [head,left,right]: XRServer.remove_tracker(item)
	FileAccess.open(out.path_join("rig-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Godot physics and actual Point One switch; synthetic XR tracking, no physical headset."},"\t"))
	quit(0 if failed.is_empty() else 1)
