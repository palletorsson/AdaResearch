extends "res://commons/artifacts/force_play/play_space.gd"
## A rigid padded bag on a real pin joint. Tracked mitts and held tools collide;
## the body stays dynamic and attached rather than becoming a grabbed transform.
var bag: RigidBody3D
var tether: Node3D
var club_rack: Node3D
var mitts: Dictionary={}
var hand_scan:=0.0
var anchor_point:=Vector3(0,3.25,0)
var bag_anchor:=Vector3.ZERO

func build() -> void:
	kind="punching_bag";extent=Vector2(6,7)
	floor_patch(extent,ink)
	title("A PUSH COMES BACK","Punch with your hands. Strike with the club. Pull the rose grip.",3.85)
	var support=fixed(Vector3(0,3.42,0.3),Vector3(3.5,0.22,1.1),pale)
	for x in [-1.6,1.6]:
		fixed(Vector3(x,1.71,0.7),Vector3(0.18,3.42,0.18),pale)
		fixed(Vector3(x,0.12,0.5),Vector3(0.55,0.24,1.2),blue)
	bag=BODY.new();bag.position=Vector3(0,1.55,0);bag.mass=7.0
	var capsule=CapsuleMesh.new();capsule.radius=0.34;capsule.height=1.35;capsule.radial_segments=24;capsule.rings=8
	var skin=material("eb8ab7");skin.roughness=0.78
	var mesh=MeshInstance3D.new();mesh.mesh=capsule;mesh.material_override=skin;bag.add_child(mesh)
	var collision=CollisionShape3D.new();var bound=CapsuleShape3D.new();bound.radius=0.34;bound.height=1.35;collision.shape=bound;bag.add_child(collision)
	for y in [-0.39,0.39]:
		var band=MeshInstance3D.new();var ring=CylinderMesh.new();ring.top_radius=0.343;ring.bottom_radius=0.343;ring.height=0.075;ring.radial_segments=24
		band.mesh=ring;band.material_override=ink;band.position.y=y;bag.add_child(band)
	box(Vector3(0,0,-0.339),Vector3(0.17,0.24,0.018),pale,false,bag)
	add_child(bag);remember(bag);bag.linear_damp=0.12;bag.angular_damp=0.22
	bag.physics_material_override=physics_material(0.5,0.12)
	pin_at(support,bag,anchor_point);bag_anchor=bag.to_local(to_global(anchor_point))
	tether=rod(anchor_point,to_local(bag.to_global(Vector3(0,0.65,0))),pale,0.02)
	grip(bag,Vector3(0,0,-0.36))
	club_rack=load("res://commons/artifacts/force_play/impact_club_rack.tscn").instantiate()
	club_rack.position=Vector3(2.25,0,-1.5);add_child(club_rack)
	_scan_hands.call_deferred()

func step(dt: float) -> void:
	tether.set_ends(anchor_point,to_local(bag.to_global(Vector3(0,0.65,0))))
	hand_scan+=dt
	if hand_scan>=1:hand_scan=0;_scan_hands()
	for id in mitts.keys():
		var item: Dictionary=mitts[id]
		if not is_instance_valid(item.hand):item.body.queue_free();mitts.erase(id);continue
		var at: Vector3=item.hand.global_position
		var xr=XRServer.primary_interface
		var tracked=xr==null or not xr.is_initialized() or item.hand.get_is_active()
		var near=tracked and at.distance_to(to_global(Vector3(0,1.55,0)))<2.4
		var jump=at.distance_to(item.body.global_position)>0.5
		item.body.collision_mask=4 if near and item.active and not jump else 0
		item.body.collision_layer=item.body.collision_mask
		item.body.visible=near
		item.body.global_transform=item.hand.global_transform
		item.active=near
	status.text="7 kg / %.2f m/s\nHit, release, watch the return."%bag.linear_velocity.length()

func _scan_hands() -> void:
	for controller in get_tree().root.find_children("*","XRController3D",true,false):
		var origin: Node=controller.get_parent()
		while origin!=null and not origin is XROrigin3D:origin=origin.get_parent()
		if origin==null or not origin.current:continue
		var id=controller.get_instance_id()
		if mitts.has(id):continue
		var body=RigidBody3D.new();body.freeze=true;body.freeze_mode=RigidBody3D.FREEZE_MODE_KINEMATIC
		body.collision_layer=0;body.collision_mask=0;body.gravity_scale=0;body.mass=1
		var col=CollisionShape3D.new();var sphere=SphereShape3D.new();sphere.radius=0.11;col.shape=sphere;body.add_child(col)
		var visual=MeshInstance3D.new();var mesh=SphereMesh.new();mesh.radius=0.11;mesh.height=0.22;mesh.radial_segments=16;mesh.rings=8
		visual.mesh=mesh;visual.material_override=blue;body.add_child(visual);add_child(body)
		body.global_transform=controller.global_transform
		# Mitts touch nearby loose bodies too, but disappear and stop colliding
		# when the visitor leaves the bag's bay.
		for other in [club_rack.stick]+grips:body.add_collision_exception_with(other)
		mitts[id]={"hand":controller,"body":body,"active":false}

func after_reset() -> void:
	for item in mitts.values():item.body.collision_mask=0;item.body.collision_layer=0;item.active=false
