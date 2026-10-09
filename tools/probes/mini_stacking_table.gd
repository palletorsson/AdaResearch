extends "res://tools/probes/forces_layout.gd"
## Real museum tabletop, supplied XRTools hand movements, actual Jolt release/contact.
var hand: XRController3D
var pickup: Node3D

func carry(piece: RigidBody3D,target: Vector3,turn:=0.0) -> void:
	hand.global_transform=piece.global_transform
	await tick();piece.pick_up(pickup);await tick()
	check("XR hand owns "+piece.name,piece.is_picked_up())
	var start=hand.global_transform
	for i in range(36):
		var t=float(i+1)/36
		hand.global_position=start.origin.lerp(target,t)+Vector3.UP*sin(t*PI)*0.25
		hand.global_basis=Basis(Vector3.UP,turn*t)*start.basis
		await physics_frame
	await tick()
	check("held shape follows hand "+piece.name,piece.global_position.distance_to(target)<0.03)
	piece.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	await create_timer(0.65).timeout
	check("release restores dynamic contact "+piece.name,not piece.freeze and not piece.is_picked_up() and piece.collision_layer==4)

func landing_checks() -> void:
	camera.set_cull_mask_value(19,false)
	await super.landing_checks()
	var table=find_scene("/stacking_table.gd")
	check("mini table is part of the real tower encounter",table!=null and table.get_parent().kind=="tower")
	if table==null:return
	check("nine independent shapes",table.pieces.size()==9 and table.bodies.size()==9)
	# Load after autoload initialization; a top-level XRTools class reference can
	# compile its user-settings dependency before SceneTree startup registers it.
	var pickable_script=load("res://addons/godot-xr-tools/objects/pickable.gd")
	check("each shape uses the normal pickable protocol",table.pieces.all(func(p):return is_instance_of(p,pickable_script) and p.release_mode==pickable_script.ReleaseMode.UNFROZEN))
	await create_timer(2).timeout
	check("small starting stack stands before the hand acts",table.pieces[2].position.y>1.36)
	await snapshot("mini-before",table.to_global(Vector3(1.5,1.9,-2.2)),table.to_global(Vector3(0,1.14,0)),55)
	await snapshot("mini-and-tower",table.to_global(Vector3(-3.3,2.4,-3.5)),table.to_global(Vector3(0,2.1,2.6)),63)
	var rig=XROrigin3D.new();var head=XRCamera3D.new();head.name="Camera";rig.add_child(head)
	hand=XRController3D.new();hand.name="LeftHand";rig.add_child(hand)
	pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);root.add_child(rig)
	# The existing cube and cylinder trade places; no slot, parenting or auto-stack.
	await carry(table.pieces[2],table.to_global(Vector3(0,table.TOP+0.047,-0.39)),PI/2)
	check("brick can turn in the hand",absf(table.pieces[2].global_basis.x.dot(table.global_basis.z))>0.9)
	await carry(table.pieces[0],table.to_global(Vector3(0,table.TOP+0.306,0)))
	await carry(table.pieces[2],table.to_global(Vector3(0,table.TOP+0.468,0)))
	check("student changed the actual stack order",table.pieces[1].position.y<table.pieces[0].position.y and table.pieces[0].position.y<table.pieces[2].position.y)
	await create_timer(1).timeout
	check("new order stands through physical contact",table.pieces[2].position.y>1.35 and table.pieces[2].position.y<1.46)
	await snapshot("mini-reordered",table.to_global(Vector3(1.5,1.9,-2.2)),table.to_global(Vector3(0,1.14,0)),55)
	hand.global_transform=table.pieces[2].global_transform;await tick();table.pieces[2].pick_up(pickup);await tick()
	check("reset refuses to take a piece from the hand",not table.reset())
	table.pieces[2].let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();rig.queue_free()
	var player=CharacterBody3D.new();root.add_child(player)
	var eye=Camera3D.new();player.add_child(eye);eye.global_position=table.to_global(Vector3(0,1.6,-1))
	var pointer=load("res://commons/scenes/em/em_desktop_pointer.gd").new();pointer.cam=eye;player.add_child(pointer)
	pointer.set_process(false);pointer.set_physics_process(false)
	pointer._grab_held(table.pieces[6])
	check("desktop can also hold the familiar point",table.pieces[6].has_meta("capability_desktop_held") and not table.reset())
	pointer._drop_held();await tick()
	check("desktop release restores a physical point",not table.pieces[6].freeze)
	player.queue_free()
	var big=table.get_parent();var big_home=big.members.key.transform
	check("table reset accepted after both hands release",table.reset())
	await create_timer(1).timeout
	check("reset restores the original small order",table.pieces[0].position.y<table.pieces[1].position.y and table.pieces[1].position.y<table.pieces[2].position.y)
	check("table reset leaves big tower alone",big.members.key.transform.origin.distance_to(big_home.origin)<0.01)
	observations.physics_engine=ProjectSettings.get_setting("physics/3d/physics_engine")
	observations.scope="Real museum, nine loose shapes; supplied XRTools hand moves and rotates shapes into a new order, physics supports it, desktop pickup and local reset. Headset reach still requires a physical visit."
