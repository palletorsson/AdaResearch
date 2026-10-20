extends "res://tools/probes/void_game_probe.gd"
const Ability := preload("res://commons/hazards/becoming_catalyst/first_catalyst_ability.gd")
var shots := 0
var actions := 0

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated saves",ProjectSettings.get_setting("application/config/name") in ["Ada Void Trial Test","The Void / physics verification"])
	if not checks.back().passed: quit(1); return
	# Use the autoload's production ability. A second copy would bypass the
	# scene's pause/resume ownership and create misleading regression failures.
	var capabilities := root.get_node_or_null("CatalystCapabilityManager")
	var owns_ability := capabilities == null
	var ability: Node3D=Ability.new() if owns_ability else capabilities.first_catalyst
	if owns_ability: root.add_child(ability)
	ability.set_unlocked(false)
	ability.form_sent.connect(func(_shot): shots+=1)
	await start(true)
	var origin: XROrigin3D=game.get_node("XROrigin3D")
	var left_hand: Node3D=origin.get_node("LeftHand/XRToolsCollisionHand/LeftHand")
	var right_hand: Node3D=origin.get_node("RightHand/XRToolsCollisionHand/RightHand")
	check("base hand scenes and animation scripts are reused",left_hand.scene_file_path.ends_with("commons/body/hands/left_hand.tscn") and right_hand.scene_file_path.ends_with("commons/body/hands/right_hand.tscn") and left_hand.is_xr_class("XRToolsHand") and right_hand.is_xr_class("XRToolsHand"))
	check("both hands resolve the Void controllers",left_hand._controller==origin.get_node("LeftHand") and right_hand._controller==origin.get_node("RightHand"))
	check("care body keeps real IK arms without the growing costume",origin.has_node("PlayerBodyIK/LeftArmRig") and origin.has_node("PlayerBodyIK/RightArmRig") and not origin.has_node("CostumeWardrobe") and game.has_node("CareBody"))
	check("appearance adds no duplicate movement providers",game.body._movement_providers.size()==4 and origin.find_children("*","CharacterBody3D",true,false).size()==1)
	check("pickup discovers the corresponding visible hands",left_hand.find_instance(game.pickups[0])==left_hand and right_hand.find_instance(game.pickups[1])==right_hand)
	left.set_input("grip",0.75);right.set_input("trigger",0.65);await frames(6)
	check("grip and trigger animate the hand",is_equal_approx(left_hand.get_node("AnimationTree").get("parameters/Grip/blend_amount"),0.75) and is_equal_approx(right_hand.get_node("AnimationTree").get("parameters/Trigger/blend_amount"),0.65))
	left.set_input("grip",0.0);right.set_input("trigger",0.0)
	var center: Vector3=game.camera.global_position+Vector3(0,-0.3,-0.5)
	hand_at(left,center+Vector3(-0.08,0,0));hand_at(right,center+Vector3(0.08,0,0));await frames(40)
	right.set_input("trigger_click",true);await frames(3);right.set_input("trigger_click",false)
	check("locked ability stays locked in Void",not ability.unlocked and shots==0)
	ability.set_unlocked(true);await frames(60)
	check("near empty hands form the existing black catalyst",ability.formed and ability.sphere.visible and game.catalyst==ability)
	right.set_input("trigger_click",true);await frames(4)
	check("right trigger sends one real catalyst without jumping",shots==1 and game.body.is_on_floor() and ability.projectiles[0].get_script().resource_path.ends_with("form_projectile.gd"))
	await frames(25)
	check("held trigger does not auto-fire",shots==1)
	right.set_input("trigger_click",false)
	left.set_input("trigger_click",true);await frames(4);left.set_input("trigger_click",false)
	check("left trigger uses the same ability with no duplicate shortcut",shots==2 and get_nodes_in_group("void_shots").is_empty())
	hand_at(right,center+Vector3(0.5,0,0));await frames(25)
	right.set_input("trigger_click",true);await frames(3);right.set_input("trigger_click",false)
	check("separated hands cannot fire",not ability.formed and shots==2 and game.body.is_on_floor())
	right.set_input("ax_button",true);await frames(12)
	check("A jumps while trigger remains a separate action",not game.body.is_on_floor() and game.body.global_position.y>0.3)
	await frames(100)
	check("holding A does not jump again on landing",game.body.is_on_floor())
	right.set_input("ax_button",false)
	game.checkpoint=4;game.place_player(Vector3(-15,-23.94,4.2));await frames(25)
	var ball: RigidBody3D=game.building.content.exhibits["4/record"].get_node("Artifact/ShadowPoint").point
	ball.action_pressed.connect(func(_point): actions+=1)
	hand_at(right,ball.global_position);await frames(12);right.set_input("grip",1.0);await frames(20)
	check("visible right hand can grip the existing black point",game.pickups[1].picked_up_object==ball)
	var pos: Vector3=origin.get_node("RightHand").global_position
	hand_at(left,pos+Vector3(-0.15,0,0));await frames(25)
	right.set_input("trigger_click",true);await frames(3);right.set_input("trigger_click",false)
	check("held object receives trigger; nearby hands cannot also shoot",actions==1 and shots==2 and not ability.formed and game.body.is_on_floor())
	if "--capture" in OS.get_cmdline_user_args(): await pictures()
	right.set_input("grip",0.0);await frames(12)
	check("release lets go of the point",game.pickups[1].picked_up_object==null and not ball.is_held())
	hand_at(left,center+Vector3(-0.08,-24,0));hand_at(right,center+Vector3(0.08,-24,0));await frames(25)
	game.die("Avatar regression");await frames(5)
	right.set_input("trigger_click",true);await frames(4);right.set_input("trigger_click",false)
	check("recovery suppresses catalyst and clears the formed point",game.recovering and not ability.formed and not ability.is_physics_processing() and shots==2)
	await frames(80)
	check("checkpoint restores interactions and keeps the avatar",not game.recovering and game.checkpoint==4 and ability.is_physics_processing() and right_hand.is_inside_tree() and game.body.is_on_floor())
	game.queue_free();await frames(4)
	check("leaving Void restores shared ability processing",ability.is_physics_processing() and not ability.formed)
	ability.set_unlocked(false)
	if owns_ability: ability.queue_free()
	for item in [head,left,right]: XRServer.remove_tracker(item)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"scope":"Actual avatar, XRTools pickup/movement and catalyst with synthetic controllers; no headset comfort test."},"\t"))
	quit(0 if failed.is_empty() else 1)

func pictures() -> void:
	var origin: XROrigin3D=game.get_node("XROrigin3D")
	var sight: Vector3=game.camera.global_position
	hand_at(left,sight+Vector3(-0.2,-0.35,-0.5))
	hand_at(right,sight+Vector3(0.2,-0.35,-0.5))
	await frames(20)
	for side in ["LeftHand","RightHand"]:
		var hand: Node3D=origin.get_node(side+"/XRToolsCollisionHand/"+side)
		print("AVATAR_POSE ",side," head=",sight," body=",game.body.global_position," controller=",hand._controller.global_position," hand=",hand.global_position," mesh=",hand._hand_mesh.global_position," visible=",hand._hand_mesh.is_visible_in_tree())
	game.notice_time=-1;game.status.hide()
	game.atmosphere.set_process(false);game.atmosphere.set_sky_time(180)
	root.msaa_3d=Viewport.MSAA_4X
	var cam:=Camera3D.new();root.add_child(cam);cam.environment=game.atmosphere.environment;cam.make_current();cam.fov=68
	cam.global_position=game.camera.global_position+Vector3(0,0.08,0.13)
	cam.look_at(game.camera.global_position+Vector3(0,-0.5,-0.8))
	await frames(35);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("hands-point.png"))
	cam.global_position=game.body.global_position+Vector3(2.5,1.3,-2.7)
	cam.look_at(game.body.global_position+Vector3(0,0.9,-0.1))
	await frames(35);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("avatar.png"))
	cam.queue_free();await frames(2);game.camera.make_current()
