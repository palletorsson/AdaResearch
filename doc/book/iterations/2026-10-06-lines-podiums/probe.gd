extends "res://tools/probes/transformation_encounters.gd"
const Router = preload("res://commons/interactables/artifact_reactions/router.gd")

class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false

func landing_checks() -> void:
	root.size=Vector2i(1600,1000)
	museum.flush_stamps()
	await create_timer(1.0).timeout
	var gallery := find_scene("/line_relations_gallery.gd")
	check("line gallery present in actual museum hall",gallery!=null)
	if gallery==null:return
	observations["gallery_world"]=xyz(gallery.global_position)
	await arrangement_checks(gallery)
	await snapshot("hall",gallery.to_global(Vector3(-0.5,1.65,-6.5)),gallery.to_global(Vector3(0,1.3,1)),85)
	await snapshot("follow",gallery.to_global(Vector3(5.5,1.65,17.4)),gallery.to_global(Vector3(12.4,1.2,13.7)),67)
	await snapshot("relations",gallery.to_global(Vector3(6.3,1.65,-5)),gallery.to_global(Vector3(4,1.22,0)),65)
	await snapshot("horizontal-vertical",gallery.to_global(Vector3(-6,1.65,-4.5)),gallery.to_global(Vector3(-6,1.2,0)),69)
	await snapshot("materials",gallery.to_global(Vector3(-5.7,1.65,2.7)),gallery.to_global(Vector3(-7,1.55,6)),68)
	await snapshot("cross-depth",gallery.to_global(Vector3(9.6,1.65,-1.65)),gallery.to_global(Vector3(8,1.4,0)),57)

func arrangement_checks(gallery: Node3D) -> void:
	check("28 line bodies retain existing pickup behaviour",gallery.lines.size()==28)
	var names := ["horizontal","vertical","parallel_a","parallel_b","plus_horizontal","plus_vertical","cross_a","cross_b"]
	for id in names:
		var line: Node3D=gallery.get_node(id)
		var ends: Array[Vector3]=line.endpoints()
		check(id+" has equal 1.2m span",is_equal_approx(ends[0].distance_to(ends[1]),1.2))
		var aligned := true
		for suffix in ["A","B"]:
			var mesh: MeshInstance3D=line.get_node("Endpoint"+suffix)
			var boundary: CollisionShape3D=line.get_node("EndpointBoundary"+suffix)
			aligned=aligned and mesh.position.is_equal_approx(boundary.position) and is_equal_approx(mesh.mesh.radius,boundary.shape.radius)
		check(id+" visible endpoints match grab collision",aligned)
	var horizontal: Node3D=gallery.get_node("horizontal")
	var vertical: Node3D=gallery.get_node("vertical")
	check("horizontal and vertical change direction without changing length",absf(horizontal.basis.x.dot(vertical.basis.x))<0.0001)
	check("parallel bars share direction",gallery.get_node("parallel_a").basis.x.is_equal_approx(gallery.get_node("parallel_b").basis.x))
	for pair in [["plus_horizontal","plus_vertical"],["cross_a","cross_b"]]:
		var a: Node3D=gallery.get_node(pair[0]);var b: Node3D=gallery.get_node(pair[1])
		check(pair[0]+" crosses only in view: 18cm depth gap",is_equal_approx(absf(a.position.z-b.position.z),0.18) and absf(a.basis.x.dot(b.basis.x))<0.0001)
	var bottoms_match := true
	for id in ["horizontal","vertical","cross_a","cross_b"]:
		var line: Node3D=gallery.get_node(id)
		var e: Array[Vector3]=line.endpoints()
		var low: float=minf(gallery.to_local(e[0]).y,gallery.to_local(e[1]).y)-line.ENDPOINT_RADIUS
		bottoms_match=bottoms_match and is_equal_approx(low,gallery.PODIUM_TOP)
	check("bottom endpoint spheres rest on podium tops",bottoms_match)
	for i in range(5):
		var plinth: StaticBody3D=gallery.get_node("RelationPodium%d"%i)
		var p:=plinth.global_position
		var hit := hall.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3(0,0.5,-1.4),p+Vector3(0,0.5,0),1))
		check("podium %d is solid and outside tool reactions"%i,not hit.is_empty() and hit.collider==plinth and Router.receiver(plinth)==null)
	for finish in ["plank","stick","light","measure"]:
		check("material study "+finish+" remains grabbable",gallery.get_node("material_"+finish).has_method("pick_up"))
	var walker:=CharacterBody3D.new();walker.collision_layer=0;walker.collision_mask=1
	var shape:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new()
	capsule.radius=0.3;capsule.height=1.6;shape.shape=capsule;shape.position.y=0.8
	walker.add_child(shape);root.add_child(walker)
	for x in [-6.0,-2.0,2.0,6.0]:
		walker.global_position=gallery.to_global(Vector3(x,0.025,-1.8))
		await physics_frame
		check("visitor can walk between podiums at x="+str(x),walker.move_and_collide(gallery.global_basis*Vector3(0,0,3.6))==null)
	walker.queue_free()
	var wall_hit := hall.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(gallery.to_global(Vector3(12,2,13.7)),gallery.to_global(Vector3(13,2,13.7)),1))
	check("rising line sits against the actual hall wall",not wall_hit.is_empty() and absf(gallery.to_local(wall_hit.position).x-12.5)<0.08)
	# Move the real XRTools body, release it, then exercise its shared reaction.
	var hand := SuppliedGrabber.new();root.add_child(hand)
	hand.global_transform=horizontal.global_transform
	var first := horizontal.global_transform
	horizontal.pick_up(hand)
	hand.global_position+=gallery.global_basis*Vector3(0,0.3,-0.4)
	for i in range(12):await physics_frame
	check("production XR pickup carries pink segment and white endpoints together",horizontal.is_picked_up() and horizontal.global_position.distance_to(first.origin)>0.45)
	var held := horizontal.global_transform
	gallery.restore_arrangements()
	check("reset leaves a held line in the hand",horizontal.global_transform.is_equal_approx(held))
	horizontal.let_go(hand,Vector3.ZERO,Vector3.ZERO)
	for i in range(8):await physics_frame
	check("release retains visitor's arrangement",horizontal.freeze and horizontal.global_transform.is_equal_approx(held))
	gallery.restore_arrangements();hand.queue_free()
	await physics_frame
	check("reset restores a released line to its podium",horizontal.global_transform.is_equal_approx(first))
	var reaction: Node=Router.receiver(horizontal)
	check("new pink segment retains its tool-reaction component",reaction!=null)
	if reaction!=null:
		var a:=horizontal.to_global(Vector3(0,0,-0.3));var b:=horizontal.to_global(Vector3(0,0,0.3))
		var hit:=hall.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,Router.HIT_LAYER))
		check("tool ray hits new cylindrical surface",not hit.is_empty() and Router.receiver(hit.collider)==reaction)
		reaction.react(&"laser",horizontal.global_position)
		check("breaking a line leaves the furniture and other studies",reaction.is_destroyed and not horizontal.visible and vertical.visible and gallery.get_node("RelationPodium0").visible)
		await create_timer(8.3).timeout
		check("line rebuilds automatically after eight seconds",not reaction.is_destroyed and horizontal.visible and horizontal.collision_layer!=0)

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Real museum runtime and desktop captures; headset acceptance remains open."},"  "))
	quit(0 if failures.is_empty() else 1)
