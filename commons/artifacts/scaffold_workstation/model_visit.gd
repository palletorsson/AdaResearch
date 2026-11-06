extends Node3D
## Bounded, reversible visit to the actual built model. No second save or world.
## Uses the existing noise-scale portal's XRTools contract (world_scale + gravity).
const Headset=preload("model_headset.gd")
const Kit=preload("res://commons/artifacts/primitive_encounters/geometry.gd")
const Furniture=preload("shop_furniture.gd")
const ButtonScene=preload("res://commons/interactables/push_button.tscn")
var work:Node3D
var headset:RigidBody3D
var game:Node3D
var actor:CharacterBody3D
var active:=false
var saved:Dictionary={}
var wait_frames:=0
var exit_panel:Node3D
var exit_button:Node3D
var factor:=.25
var transitions:=0
var return_frames:=0
var return_pose:=Transform3D.IDENTITY
var return_enabled:=true

func configure(station:Node3D)->void:
	work=station;factor=station.visitor_scale
	var dock:Node3D=Furniture.visor_table(work.controls)
	headset=Headset.new();headset.visit=self;headset.position=Vector3(0,.065,-.045);dock.add_child(headset)

func enter()->bool:
	game=get_tree().get_first_node_in_group("void_game") as Node3D
	if active or return_frames>0 or not work._interactive or game==null or game.recovering or game.returning:return false
	actor=game.body
	if actor.has_meta("ada_scale_owner") or work.built.is_empty() or is_instance_valid(work.held):
		work.feedback.text="BUILD a copy, release the part, then wear the visor.";headset.queued=false;return false
	if not work.visitor_start_clear():
		work.feedback.text="Clear the marked START pad before putting on the visor.";headset.queued=false;return false
	# Snapshot before releasing ownership; the desktop pointer also holds a reference.
	saved={"pose":actor.global_transform,"near":game.camera.near,"camera":game.camera.transform,
		"snap":actor.floor_snap_length,"margin":actor.safe_margin,"slope":actor.floor_max_angle,"enabled":actor.enabled,
		"game_physics":game.is_physics_processing(),"game_keys":game.is_processing_unhandled_key_input(),
		"stream":game.floor_stream.is_processing(),"suspended":game.health.suspended,"shapes":[],"hud":[]}
	_release_hands()
	active=true;transitions+=1
	actor.set_meta("ada_scale_owner",get_instance_id());actor.set_meta("ada_body_scale",factor)
	actor.floor_snap_length*=factor;actor.safe_margin*=factor
	# With a quarter-size visitor Jolt's rounded nose reports up to ~57 degrees
	# on the visible 26.6-degree ramp. Admit that contact locally; walls remain walls.
	actor.floor_max_angle=deg_to_rad(60)
	game.set_physics_process(false);game.set_process_unhandled_key_input(false)
	game.floor_stream.set_process(false);game.health.suspended=true
	# The scale visit is a building inspection. Park the unscaled catalyst halo
	# and optional costume while keeping the care body and actual XR hands.
	if is_instance_valid(game.catalyst):
		saved.catalyst_physics=game.catalyst.is_physics_processing();game.catalyst.set_physics_process(false);game.catalyst._hide_all()
	var wardrobe:Node=game.get_node_or_null("StudioWardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.costume):saved.hud.append([wardrobe.costume,wardrobe.costume.visible]);wardrobe.costume.hide()
	for item in [game.status,game.charge_display,game.desktop_help]:
		if is_instance_valid(item):saved.hud.append([item,item.visible]);item.hide()
	game.camera.near*=factor
	if actor is XRToolsPlayerBody:
		saved.world_scale=XRServer.world_scale
		saved.physics=actor.physics;actor.physics=actor.default_physics.duplicate();actor.physics.move_max_slope=60
		# Pickup Areas are children of the scaled collision hands in this rig.
		# XRTools scales that parent; scaling the pickup again would shrink it twice.
		saved.capsule=actor._collision_node.shape.duplicate();saved.capsule_position=actor._collision_node.position
		var adapter:Node3D=load("res://commons/movement/miniature_gravity_provider.gd").new()
		adapter.receiver=actor;adapter.factor=factor;actor.add_child(adapter)
		actor._movement_providers.append(adapter);actor._movement_providers.sort_custom(actor.sort_by_order);saved.adapter=adapter
		actor.enabled=false;XRServer.world_scale=saved.world_scale*factor;wait_frames=3
	else:
		for child in actor.get_children():
			if child is CollisionShape3D and child.shape is CapsuleShape3D:
				saved.shapes.append([child,child.shape,child.position])
				child.shape=child.shape.duplicate();child.shape.radius*=factor;child.shape.height*=factor;child.position*=factor
		game.camera.position*=factor;game.camera.rotation.x=0
		_place_inside()
	_make_exit()
	work.feedback.text="VISITING / the visor changes your relation to the same construction."
	return true

func _release_hands()->void:
	if game.vr:
		for pickup in game.pickups:pickup.drop_object()
	elif is_instance_valid(game.body.desktop_pointer):game.body.desktop_pointer._drop_held()
	if headset.is_picked_up():headset.drop()
	headset.dock()

func _place_inside()->void:
	var pose:Transform3D=work.visitor_start_pose()
	if actor is XRToolsPlayerBody:
		actor._update_body_under_camera(0.0)
		actor.teleport(pose)
	else:actor.global_transform=pose
	actor.velocity=Vector3.ZERO;game.rebase_player_motion()

func _make_exit()->void:
	exit_panel=Node3D.new();exit_panel.name="ModelExit";game.camera.add_child(exit_panel)
	# Kept in view and within hand reach; scales with the visitor, not the room.
	var ui_scale:float=XRServer.world_scale if game.vr else factor
	exit_panel.position=Vector3(.38,-.30,-.85)*ui_scale;exit_panel.scale=Vector3.ONE*ui_scale
	exit_panel.rotation.x=PI/2
	Kit.box(exit_panel,"Plate",Vector3.ZERO,Vector3(.50,.02,.17),Color("243b3e"),false)
	exit_button=Furniture.rectangular_button(ButtonScene);exit_button.rotation=Vector3.ZERO;exit_button.position=Vector3(-.17,.025,0)
	exit_button.pressed.connect(restore);exit_panel.add_child(exit_button)
	var caption:=Kit.label(exit_panel,"TAKE OFF\nVR GLASSES",Vector3(.065,.016,0),13)
	caption.rotation.x=-PI/2;caption.modulate=Color("e1eeeb")
	# Mouse-look must be able to aim at the button; a camera-locked off-centre
	# target could never reach the desktop crosshair. Leave it at the entry.
	if not game.vr:exit_panel.reparent(game,true)

func _physics_process(_delta:float)->void:
	if return_frames>0:
		return_frames-=1
		if return_frames==0 and is_instance_valid(actor):
			# Refresh the scaled eye-to-capsule offset before teleport preserves it.
			actor._update_body_under_camera(0.0)
			actor.teleport(return_pose);actor.enabled=return_enabled;actor.velocity=Vector3.ZERO
			if is_instance_valid(game):game.rebase_player_motion()
		return
	if not active:return
	if not is_instance_valid(actor) or not is_instance_valid(game):restore(false);return
	if wait_frames>0:
		wait_frames-=1
		if wait_frames==0:_place_inside();actor.enabled=saved.enabled
		return
	var at:Vector3=work.output.to_local(actor.global_position)
	if absf(at.x)>work.CLEAR*.5 or absf(at.z)>work.CLEAR*.5 or at.y<-.25 or game.recovering or game.returning:restore()

func _input(event:InputEvent)->void:
	if active and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		restore();get_viewport().set_input_as_handled()

func restore(relocate:bool=true)->void:
	if not active:return
	active=false;wait_frames=0;transitions+=1
	if saved.has("world_scale"):XRServer.world_scale=saved.world_scale
	if is_instance_valid(game) and is_instance_valid(actor):
		_release_hands()
		actor.floor_snap_length=saved.snap;actor.safe_margin=saved.margin;actor.floor_max_angle=saved.slope;actor.enabled=saved.enabled
		actor.remove_meta("ada_scale_owner");actor.remove_meta("ada_body_scale")
		if actor is XRToolsPlayerBody:
			actor.physics=saved.physics
			actor._collision_node.shape=saved.capsule;actor._collision_node.position=saved.capsule_position
			if is_instance_valid(saved.adapter):actor._movement_providers.erase(saved.adapter);saved.adapter.queue_free()
			if relocate:
				actor.teleport(saved.pose)
				# Re-centre after new tracked positions arrive, including room-scale X/Z.
				return_pose=saved.pose;return_enabled=saved.enabled;return_frames=3;actor.enabled=false
		else:
			for row in saved.shapes:
				if is_instance_valid(row[0]):row[0].shape=row[1];row[0].position=row[2]
			game.camera.transform=saved.camera
			if relocate:actor.global_transform=saved.pose
		game.camera.near=saved.near;actor.velocity=Vector3.ZERO
		game.set_physics_process(saved.game_physics);game.set_process_unhandled_key_input(saved.game_keys)
		game.floor_stream.set_process(saved.stream);game.health.suspended=saved.suspended
		if saved.has("catalyst_physics") and is_instance_valid(game.catalyst):game.catalyst.set_physics_process(saved.catalyst_physics)
		for row in saved.hud:
			if is_instance_valid(row[0]):row[0].visible=row[1]
		if is_instance_valid(game.camera) and game.camera.is_inside_tree() and actor.is_inside_tree():game.rebase_player_motion()
	if is_instance_valid(exit_panel):exit_panel.queue_free()
	if is_instance_valid(work):work.feedback.text="BACK AT THE BENCH / same construction, your usual size."
	saved.clear()

func _exit_tree()->void:
	restore(is_instance_valid(game) and not game.is_queued_for_deletion())
	if return_frames>0 and is_instance_valid(actor):
		actor.teleport(return_pose);actor.enabled=return_enabled
