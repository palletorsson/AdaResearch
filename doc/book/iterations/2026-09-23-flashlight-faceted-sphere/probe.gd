extends "res://tools/probes/transformation_encounters.gd"
class SuppliedGrabber extends Node3D:
	var picked_up_ranged: bool = false
var completed := false
var demo: Node3D
var lamps: Array[Node3D] = []
var homes: Array[Transform3D] = []

func landing_checks() -> void:
	root.size = Vector2i(1440, 960)
	var grid: Node3D = hall.get_node_or_null("SimGrid_Color_Flashlight")
	check("authored grid present", grid != null)
	if grid == null: return
	for frame in 3600:
		if grid.has_meta("stage_grid_ready"): break
		await process_frame
	check("grid completed", grid.has_meta("stage_grid_ready"))
	demo = find_scene("/flashlight_demo.gd")
	check("registered flashlight scene placed", demo != null)
	if demo == null: return
	for frame in 15: await physics_frame
	var receiver: Node3D = demo.get_node_or_null("FacetedReceiver")
	check("map keeps its authored 180-degree orientation", is_equal_approx(fposmod(demo.rotation_degrees.y,360),180))
	check("authored seven-division receiver built", receiver != null and demo.receiver_sides == 7)
	if receiver == null: return
	var sphere: MeshInstance3D = receiver.get_node("Sphere")
	var canvas: CSGBox3D = demo.get_node("Canvas")
	var material: StandardMaterial3D = sphere.material_override
	check("sphere shares the board material", material == canvas.material)
	check("shared receiver material is pale and nonemissive", material.albedo_color.is_equal_approx(Color(0.95, 0.95, 0.95, 1)) and not material.emission_enabled)
	check("board and side cube preserved", canvas.size.is_equal_approx(Vector3(6,4,0.1)) and demo.has_node("ReceiverCube"))
	var a: Array = sphere.mesh.surface_get_arrays(0)
	var normals: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var vertices: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var flat := true
	var outward := true
	for i in range(0, vertices.size(), 3):
		flat = flat and normals[i].is_equal_approx(normals[i+1]) and normals[i].is_equal_approx(normals[i+2])
		outward = outward and normals[i].dot((vertices[i]+vertices[i+1]+vertices[i+2])/3.0) > 0.01
	check("each triangle has one flat outward normal", flat and outward)
	check("sphere collision follows visible mesh", sphere.get_child_count() == 1 and sphere.get_child(0) is StaticBody3D and sphere.get_child(0).get_child(0).shape is ConcavePolygonShape3D)
	check("sphere base meets pedestal", is_equal_approx(sphere.position.y+sphere.mesh.get_aabb().position.y,0.65))
	observations["sphere"] = {"radial_divisions":7,"triangles":vertices.size()/3,"diameter_m":1.7,"centre_above_floor_m":1.5,"material":material.albedo_color.to_html(),"global_position":xyz(sphere.global_position)}
	for pos in [Vector3(-5.6,0,1),Vector3(-6.95,0,-1),Vector3(-4.25,0,-1)]:
		var hit := floor_at(demo.to_global(pos))
		check("floor supports sphere approach "+str(pos), not hit.is_empty() and absf(hit.position.y-demo.global_position.y)<0.02)
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32; capsule.height = 1.5
	for pos in [Vector3(-5.6,0.8,1),Vector3(-6.95,0.8,-1),Vector3(-4.25,0.8,-1)]:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = Transform3D(Basis.IDENTITY,demo.to_global(pos))
		query.collision_mask = 1
		var player:CharacterBody3D= museum.get("_player")
		query.exclude = [player.get_rid()]
		var hits := hall.get_world_3d().direct_space_state.intersect_shape(query)
		check("body clearance at receiver approach "+str(pos),hits.is_empty())
	var grabber := SuppliedGrabber.new()
	root.add_child(grabber)
	for name in ["RedFlashlight","GreenFlashlight","BlueFlashlight","WhiteFlashlight"]:
		var lamp: Node3D = demo.get_node(name)
		lamps.append(lamp); homes.append(lamp.global_transform)
		check("reachable pickable lamp "+name, lamp.can_pick_up(grabber) and is_equal_approx(lamp.position.y,1.1))
		grabber.global_transform = lamp.global_transform
		lamp.pick_up(grabber)
		grabber.position.x += 0.2
		for frame in 6: await physics_frame
		check("supplied grabber moves "+name, lamp.is_picked_up() and lamp.global_position.distance_to(homes[-1].origin)>0.1)
		lamp.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
		check("released lamp stays available "+name, not lamp.is_picked_up() and lamp.freeze)
		lamp.global_transform = homes[-1]
	await snapshot("arrival", demo.to_global(Vector3(-0.5,1.7,6.8)),demo.to_global(Vector3(-0.7,1.7,-1.5)),76)
	var eye := demo.to_global(Vector3(-5.6,1.65,2.6))
	var target := sphere.global_position
	await snapshot("sphere-at-arrival",eye,target,48)
	var initial: Transform3D = sphere.global_transform
	# All four lamps remain on: compare actual pickup and aim, not visibility toggles.
	grabber.global_transform = lamps[0].global_transform
	lamps[0].pick_up(grabber)
	grabber.global_position = demo.to_global(Vector3(-7.15,2.0,0.8))
	grabber.look_at(target)
	for frame in 12: await physics_frame
	await snapshot("red-from-left",eye,target,48)
	var first := root.get_texture().get_image()
	grabber.global_position = demo.to_global(Vector3(-4.05,2.0,0.8))
	grabber.look_at(target)
	for frame in 12: await physics_frame
	await snapshot("red-from-right",eye,target,48)
	var second := root.get_texture().get_image()
	var changed := 0
	var count := 0
	var total := 0.0
	# Sample only camera rays that hit the actual receiver collision, avoiding the board.
	for x in range(360,1080,12):
		for y in range(160,800,12):
			var pixel := Vector2(x,y)
			var ray := PhysicsRayQueryParameters3D.create(camera.project_ray_origin(pixel),camera.project_ray_origin(pixel)+camera.project_ray_normal(pixel)*8,1)
			var hit := hall.get_world_3d().direct_space_state.intersect_ray(ray)
			if not hit.is_empty() and hit.collider == sphere.get_child(0):
				count += 1
				var diff := absf(first.get_pixel(x,y).r-second.get_pixel(x,y).r)
				total += diff
				if diff>0.025:changed += 1
	check("moving held red lamp visibly changes sphere faces", count>100 and changed>count*0.2 and total/maxi(1,count)>0.03)
	observations["rendered_comparison"]={"sphere_ray_samples":count,"changed_red_samples":changed,"mean_red_difference":total/maxi(count,1)}
	lamps[0].let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	check("receiver remains still and its material unchanged", sphere.global_transform.is_equal_approx(initial) and sphere.material_override == material and material.albedo_color.is_equal_approx(Color(0.95,0.95,0.95,1)))
	# A second colour gives the user a useful next encounter, not a new control.
	grabber.global_transform = lamps[2].global_transform
	lamps[2].pick_up(grabber)
	grabber.global_position = demo.to_global(Vector3(-7.15,1.7,0.8))
	grabber.look_at(target)
	for frame in 12: await physics_frame
	lamps[2].let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	await snapshot("two-colours",eye,target,48)
	await snapshot("board-and-sphere",demo.to_global(Vector3(-2.8,1.8,4.8)),demo.to_global(Vector3(-1.8,1.65,-1.7)),76)
	for i in lamps.size():lamps[i].global_transform=homes[i]
	check("all four lamps retain colour and on state",lamps.all(func(lamp):return lamp.get_node("SpotLight3D").visible))
	# Verify the opt-in geometry can be authored with either requested division count.
	demo.apply_grid_config({"receiver_sides":5})
	check("five-division authoring option works",demo.receiver_sides==5 and demo.has_node("FacetedReceiver"))
	demo.apply_grid_config({"receiver_sides":7})
	check("seven-division setting restored without duplicate receivers",demo.receiver_sides==7 and demo.find_children("FacetedReceiver*","Node3D",false,false).size()==1)
	var legacy:Node3D=load("res://algorithms/postprocessing/flashlight_demo/flashlight_demo.tscn").instantiate()
	for path in ["WorldEnvironment","Camera3D"]:legacy.get_node(path).free()
	legacy.visible=false;root.add_child(legacy)
	check("legacy installations do not acquire new receivers",not legacy.has_node("FacetedReceiver") and not legacy.has_node("ReceiverCube") and is_equal_approx(legacy.get_node("RedFlashlight").position.y,0.6))
	legacy.queue_free()
	completed = true

func finish() -> void:
	check("focused encounter completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Actual isolated museum; native Compatibility renders; supplied XRTools grabber movement, floor rays, flat normals and receiver collision. No tracked hands, headset, learner or performance claim."},"  "))
	print("FACETED FLASHLIGHT ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
