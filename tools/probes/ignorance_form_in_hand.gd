extends "res://tools/probes/transformation_encounters.gd"

class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false

class Receiver extends StaticBody3D:
	var hit_mode := ""
	func hit_by_catalyst_mode(_colour: Color, mode: String) -> void: hit_mode=mode

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(1.0).timeout
	var court := find_scene("/geometry_courtyard.gd")
	var capsule := find_scene("/capsule_reliquary.gd")
	check("geometry court and capsule present",court != null and capsule != null)
	if court == null or capsule == null: return
	await snapshot("court",court.to_global(Vector3(-4.3,1.7,-4.7)),court.to_global(Vector3(0,1.35,0)),73)
	await snapshot("capsule",capsule.to_global(Vector3(-3,1.7,-3.9)),capsule.to_global(Vector3(0,1.6,0)),65)
	var station := find_scene("/form_in_hand.gd")
	check("suspended point installed in the real hall",station != null)
	if station != null: await station_checks(station)

func station_checks(station: Node3D) -> void:
	var point: Node3D=station.point
	observations["station_position"]=xyz(station.global_position)
	check("point starts within seated and standing reach",is_equal_approx(point.position.y,1.45))
	check("paired direction studies have the same actual mesh",station.specimens.size()==2 and station.specimens[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==station.specimens[1].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	await snapshot("hanging-point",station.to_global(Vector3(-2.3,1.65,-5.6)),station.to_global(Vector3(0,1.6,0)),66)
	await snapshot("rings-and-segments",station.to_global(Vector3(0,1.65,-6.8)),station.to_global(Vector3(0,1.4,-1.0)),66)
	point.set_process(false)
	point.advance(2.0)
	check("unheld sphere does not simplify",point.sphere.rings==16 and point.sphere.radial_segments==32)
	point.action()
	check("unheld trigger cannot fire",point.projectiles.is_empty())
	var home: Transform3D=point.global_transform
	var hand:=SuppliedGrabber.new();root.add_child(hand);hand.global_transform=home
	point.pick_up(hand)
	hand.position+=Vector3(0.3,0.1,-0.3)
	await create_timer(0.2).timeout
	check("XRTools grab moves the actual point",point.global_position.distance_to(home.origin)>0.2)
	check("suspension releases when held",not point.suspension.visible)
	point.advance(0.30)
	check("two held steps reduce each count by two",point.sphere.rings==14 and point.sphere.radial_segments==30)
	check("radius and physical boundary do not shrink",is_equal_approx(point.sphere.radius,0.14) and is_equal_approx(point.get_child(1).shape.radius,0.14))
	point.action()
	check("held trigger creates one form",point.projectiles.size()==1)
	var shot: RigidBody3D=point.projectiles[0]
	shot.set_physics_process(false)
	check("shot has an independent mesh with the selected counts",shot.form!=point.sphere and shot.form.rings==14 and shot.form.radial_segments==30)
	check("shot starts clear of the held point",shot.global_position.distance_to(point.global_position)>0.28)
	check("shot travels along its aim",shot.linear_velocity.is_equal_approx(shot.direction*6.0))
	point.advance(20.0)
	check("minimum remains valid: one ring, four segments",point.sphere.rings==1 and point.sphere.radial_segments==4)
	point._process(0.0)
	check("readout names the current mesh",point.readout.text=="1 RINGS   /   4 SEGMENTS")
	check("later simplification does not rewrite a launched form",shot.form.rings==14 and shot.form.radial_segments==30)
	point.action()
	check("rapid duplicate trigger respects cooldown",point.projectiles.size()==1)
	shot.queue_free();await process_frame
	await snapshot("held-low-resolution",point.global_position+Vector3(-0.48,0.20,-0.65),point.global_position,43)
	# Actual collision and shared catalyst dispatch, not a direct receiver invocation.
	var target:=Receiver.new();target.collision_layer=2;target.collision_mask=0
	var shape:=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=Vector3(0.7,0.7,0.15)
	target.add_child(shape);root.add_child(target)
	target.global_position=point.global_position-point.global_basis.z*1.35
	point._cooldown=0.0;point.action()
	await create_timer(0.45).timeout
	check("fired form reaches an actual collider and delivers primitives mode",target.hit_mode=="primitives")
	target.queue_free()
	# Bounded live forms, even under repeated trigger presses.
	for i in 12:
		point._cooldown=0.0;point.action()
	check("at most eight active forms",point.projectiles.size()<=8)
	point.let_go(hand,Vector3.ZERO,Vector3.ZERO)
	var counts:=Vector2i(point.sphere.rings,point.sphere.radial_segments)
	point.advance(1.0)
	check("release pauses resolution",Vector2i(point.sphere.rings,point.sphere.radial_segments)==counts)
	point._process(2.1)
	check("released point returns to suspension",point.global_transform.is_equal_approx(home) and point.suspension.visible)
	check("return restores the smooth starting counts",point.sphere.rings==16 and point.sphere.radial_segments==32)
	hand.queue_free()
	# Desktop uses the same pickup hook and action signal.
	point.on_desktop_grab(null);point.advance(0.15)
	check("desktop holding uses the same resolution rule",point.sphere.rings==15 and point.sphere.radial_segments==31)
	point.on_desktop_drop(null);point._process(2.1)
	check("desktop drop also returns and resets",point.sphere.rings==16 and not point.desktop_held)
	point.set_process(true)
	await create_timer(5.5).timeout
	check("all emitted forms expire",point.projectiles.all(func(p): return not is_instance_valid(p)))
	# Preserve the passage along the centre and access to the alcove.
	var walker:=CharacterBody3D.new();walker.collision_layer=0;walker.collision_mask=1
	var boundary:=CollisionShape3D.new();boundary.shape=CapsuleShape3D.new();boundary.shape.radius=0.28;boundary.shape.height=1.6;boundary.position.y=0.8
	walker.add_child(boundary);root.add_child(walker)
	for x in [-1.5,1.5]:
		walker.global_position=station.to_global(Vector3(x,0.03,-4.8));await physics_frame
		check("body-width route remains beside the point "+str(x),walker.move_and_collide(station.global_basis*Vector3(0,0,9.4))==null)
	walker.queue_free()

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Real Endless Museum scene. Controlled input and native rendering; headset acceptance remains open."},"  "))
	quit(0 if failures.is_empty() else 1)
