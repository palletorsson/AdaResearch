extends "res://doc/book/iterations/2026-09-29-line-black-box/probe.gd"
const Router = preload("res://commons/interactables/artifact_reactions/router.gd")
var events: Array = []

class LegacyTarget extends Node3D:
	var hits := 0
	func hit_by_projectile(_colour: Color) -> void: hits += 1

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(3.0).timeout
	await line_checks()
	await reaction_checks()

func reaction_checks() -> void:
	var room := find_scene("/line_black_box.gd")
	if room == null: return
	var receiver: Node = Router.receiver(room.line)
	check("black-box line has a shared component", receiver != null)
	if receiver == null: return
	receiver.reacted.connect(func(tool,at,mode): events.append([str(tool),at,str(mode)]))
	check("room shell is outside the reaction scope",Router.receiver(room.get_node("Floor"))==null and Router.receiver(room.reset_button)==null)
	var components := get_nodes_in_group("artifact_reactions")
	observations["reaction_components"] = components.size()
	observations["surface_count"] = 0
	observations["empty_components"] = []
	for comp in components:
		observations.surface_count += comp.surfaces.size()
		if comp.surfaces.is_empty(): observations.empty_components.append(str(comp.target.get_path()))
	check("all attached components have visible hit surfaces",observations.empty_components.is_empty())
	check("gallery rods react separately",components.size()>34)
	var a: Vector3 = room.to_global(Vector3(0,1.25,-0.7))
	var b: Vector3 = room.to_global(Vector3(0,1.25,0.8))
	var query := PhysicsRayQueryParameters3D.create(a,b,Router.HIT_LAYER)
	var hit := hall.get_world_3d().direct_space_state.intersect_ray(query)
	check("actual tool ray finds the line surface",not hit.is_empty() and Router.receiver(hit.collider)==receiver)
	if hit.is_empty(): return
	check("tool-only collider does not support or obstruct the player",hit.collider.collision_layer==Router.HIT_LAYER and hit.collider.collision_mask==0)
	# Launch the same projectile used by the catalyst/pink gun through physics.
	var shot: Node3D = load("res://commons/hazards/becoming_catalyst/catalyst_projectile.gd").new()
	shot.set("direction",(b-a).normalized());shot.set("speed",2.5)
	shot.set("color_primary",Color("ff4aaf"));shot.set("lifetime",3.0)
	root.add_child(shot);shot.global_position=a
	await create_timer(0.75).timeout
	check("physical catalyst projectile reaches the component",events.size()==1 and events[0][0]=="catalyst")
	check("catalyst colours without breaking",not receiver.is_destroyed and room.line.current_line.material_overlay!=null)
	await snapshot("catalyst-colour",room.to_global(Vector3(-0.42,1.65,-1.63)),room.to_global(Vector3(0,1.48,0.9)),77)
	if is_instance_valid(shot): shot.queue_free()
	# Exercise the real pink gun's fire function, not only the receiver API.
	var gun_body: Node3D = load("res://commons/artifacts/pink_gun/pink_gun.tscn").instantiate()
	root.add_child(gun_body)
	gun_body.set("freeze",true)
	var gun: Node3D = gun_body.get_node("PinkGun")
	gun_body.global_position=a-Vector3(0,0,0.4)
	gun_body.look_at(b)
	var muzzle: Node3D = gun.get("_muzzles")[0]
	gun_body.global_position += a-muzzle.global_position
	var count := events.size()
	observations["gun_aim"] = {"muzzle":xyz(muzzle.global_position),"direction":xyz(-gun.global_basis.z),"target":xyz(b)}
	var track_shot := func(node):
		if node is CatalystProjectile:
			node.projectile_hit.connect(func(body,at): observations["gun_impact"]={"body":str(body.get_path()),"at":xyz(at)})
	root.get_tree().node_added.connect(track_shot)
	gun.call("fire")
	await create_timer(0.55).timeout
	root.get_tree().node_added.disconnect(track_shot)
	check("pink gun fire colours the same study",events.size()>count and not receiver.is_destroyed)
	gun_body.queue_free()
	for mode in ["transformation", "primitives"]:
		var mode_shot: Node3D = load("res://commons/hazards/becoming_catalyst/modes/"+mode+"_projectile.gd").new()
		mode_shot.set("direction",(b-a).normalized());mode_shot.set("speed",14.0)
		count=events.size()
		root.add_child(mode_shot);mode_shot.global_position=a
		await create_timer(0.45).timeout
		check(mode+" catalyst mode reaches shared receiver",events.size()>count and events[count][2]==mode)
		check(mode+" mode leaves hit shape at authored size",hit.collider.scale.is_equal_approx(Vector3.ONE))
		if is_instance_valid(mode_shot): mode_shot.queue_free()
	var laser := find_scene("/laser_measure.gd")
	var hammer := find_scene("/line_sledgehammer.gd")
	check("existing laser and hammer remain",laser!=null and hammer!=null)
	if laser==null or hammer==null:return
	laser.set_process(false)
	laser.call("_burn",hit.collider,2.0)
	check("unattended laser cannot burn new studies",not receiver.is_destroyed)
	var holder: Node3D = laser
	while holder!=null and not holder.has_method("pick_up"): holder=holder.get_parent()
	check("laser has its original grab body",holder!=null)
	if holder==null:return
	var hand := SuppliedGrabber.new();root.add_child(hand)
	hand.global_transform=holder.global_transform
	holder.call("pick_up",hand)
	var dwell: float = laser.burn_seconds
	laser.call("_burn",hit.collider,dwell*0.45)
	check("laser requires dwell",not receiver.is_destroyed)
	laser.call("_burn",hit.collider,dwell*0.60)
	check("wielded laser breaks after dwell",receiver.is_destroyed and not room.line.visible)
	holder.call("let_go",hand,Vector3.ZERO,Vector3.ZERO)
	hand.queue_free()
	check("broken endpoints lose collision",room.point_a.collision_layer==0 and room.point_b.collision_layer==0)
	check("black room and reset survive",room.get_node("Floor").visible and room.reset_button.collision_layer!=0)
	await snapshot("line-broken",room.to_global(Vector3(-0.42,1.65,-1.63)),room.to_global(Vector3(0,1.48,0.9)),77)
	await create_timer(8.3).timeout
	check("line rebuilds automatically after eight seconds",not receiver.is_destroyed and room.line.visible and room.point_a.collision_layer!=0)
	check("line calculation resumes after rebuild",is_equal_approx(room.line.current_line.mesh.height,1.6))
	for i in range(3):
		hammer.call("_try_break",hit.collider,b)
		if i<2: check("melee strike "+str(i+1)+" chips without erasing",not receiver.is_destroyed)
		await create_timer(0.3).timeout
	check("three hammer hits break a rebuilt study",receiver.is_destroyed)
	check("rebuildable study not blacklisted by hammer",not hammer.get("_broken").has(room.line))
	receiver.restore()
	await create_timer(0.2).timeout
	check("restored original endpoints can still be grabbed",room.point_a.has_method("pick_up") and room.point_a.freeze)
	var second_hand := SuppliedGrabber.new();root.add_child(second_hand)
	second_hand.global_transform=room.point_a.global_transform
	room.point_a.pick_up(second_hand)
	second_hand.global_position+=Vector3.UP*0.2
	for i in range(12): await physics_frame
	check("actual pickup moves endpoint after rebuild",room.point_a.is_picked_up() and room.point_a.position.y>1.4)
	room.point_a.let_go(second_hand,Vector3.ZERO,Vector3.ZERO)
	second_hand.queue_free()
	room.reset_line()
	await snapshot("line-restored",room.to_global(Vector3(-0.42,1.65,-1.63)),room.to_global(Vector3(0,1.48,0.9)),77)
	# Opt-in installation must be idempotent and not leak across maps.
	var before := get_nodes_in_group("artifact_reactions").size()
	Router.attach(room,{"reactive":"break","reaction_target":"LineStudy"})
	check("installing twice creates no duplicate",get_nodes_in_group("artifact_reactions").size()==before)
	var plain := Node3D.new();root.add_child(plain)
	Router.attach(plain,{})
	check("unconfigured objects keep native behaviour",Router.receiver(plain)==null)
	plain.queue_free()
	await recovery_checks()
	observations["tool_paths_completed"] = true

func recovery_checks() -> void:
	var barrier := find_scene("/do_not_cross_barrier.gd")
	var reaction: Node = Router.receiver(barrier)
	check("existing barrier participates",reaction!=null)
	if reaction==null:return
	var barrier_events: Array=[]
	barrier.broken.connect(func(_by):barrier_events.append(true))
	var collider: CollisionShape3D = barrier.get("_body").get_child(0)
	var visitor := CharacterBody3D.new()
	visitor.collision_layer=1<<19;visitor.collision_mask=0
	var shape := CollisionShape3D.new();shape.shape=SphereShape3D.new();shape.shape.radius=0.3
	visitor.add_child(shape);root.add_child(visitor);visitor.global_position=collider.global_position
	for i in range(3):await physics_frame
	barrier.call("trigger_explosion")
	check("native barrier trigger keeps a rebuildable scene and emits its signal",barrier.is_broken() and not barrier.is_queued_for_deletion() and barrier_events.size()==1)
	reaction.set("_remaining",0.03)
	await create_timer(0.15).timeout
	check("rebuild waits while player occupies the returning collider",reaction.is_destroyed)
	visitor.global_position+=Vector3.UP*30
	await create_timer(0.65).timeout
	check("rebuild resumes when the player leaves",not barrier.is_broken() and barrier.hit_points_left()==3)
	visitor.queue_free()
	# Ordinary grid loading uses the same opt-in configuration path.
	var study := MeshInstance3D.new();study.mesh=BoxMesh.new();root.add_child(study)
	study.position=Vector3(100,20,100)
	var grid: Node = load("res://commons/grid/GridInteractablesComponent.gd").new()
	grid.call("_apply_artifact_config",study,{"reactive":"break","rebuild":"8"},"test_study")
	await create_timer(0.35).timeout
	var comp: Node = Router.receiver(study)
	check("ordinary grid config attaches the component",comp!=null)
	if comp!=null:
		comp.react(&"laser",study.global_position)
		comp.queue_free()
		await create_timer(0.15).timeout
		check("removing component restores surviving target and removes proxies",study.visible and study.material_overlay==null and study.get_child_count()==0 and Router.receiver(study)==null)
	study.queue_free();grid.free()
	var legacy := LegacyTarget.new();root.add_child(legacy)
	var shot: Node = load("res://commons/hazards/becoming_catalyst/catalyst_projectile.gd").new()
	shot.call("_dispatch_transformation",legacy)
	check("legacy projectile receiver still receives its native callback",legacy.hits==1)
	shot.free();legacy.queue_free()

func finish() -> void:
	check("all tool paths completed",bool(observations.get("tool_paths_completed",false)))
	var result := {"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Native museum render: actual base, pink-gun and two catalyst-mode projectile collisions; laser dwell and hammer dispatch; timed rebuild, occupancy delay, pickup after rebuild, component removal, ordinary grid config and legacy callback. Includes the earlier line/entrance checks. No headset or Quest performance trial."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("LINE REACTIONS ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
