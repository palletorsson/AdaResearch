extends "res://tools/probes/transformation_encounters.gd"
class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false
var completed := false
var gm:Node
var saved_nails:Color
var saved_skin:Color
var have_saved := false
var salon:Node3D
var controls:Dictionary={}
var receivers:Array[Node]=[]
var fixture_hands:Array[Node3D]=[]
var grabber:Node3D

func choose(target:int, colour:Color) -> void:
	var control:Node3D=controls[target]
	var mapper:Node3D=control.get_node("ValueMapper3D")
	var point:Node3D=mapper.point
	grabber.global_transform=point.global_transform
	point.pick_up(grabber)
	check("point picked up for surface "+str(target),point.is_picked_up())
	grabber.global_position=mapper.to_global(Vector3(colour.r,colour.g,colour.b)*mapper.space_size)
	for frame in 16:await physics_frame
	point.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	for frame in 3:await process_frame
	check("real RGB point reaches requested value "+str(target),control.get_nail_color().is_equal_approx(colour))
	check("preview shares selected value "+str(target),control.color_preview_cube.material_override.albedo_color.is_equal_approx(colour))
	var materials:Array=salon.nail_materials if target==0 else salon.skin_materials
	check("both salon hands receive value "+str(target),materials.size()==2 and materials.all(func(m):return m.albedo_color.is_equal_approx(colour)))
	for r in receivers:
		var mat:StandardMaterial3D=r.nail_material if target==0 else r.skin_material
		check(str(r.get_parent().name)+" receives selected surface "+str(target),mat!=null and mat.albedo_color.is_equal_approx(colour))

func landing_checks() -> void:
	root.size=Vector2i(1440,960)
	var grid:Node3D=hall.get_node_or_null("SimGrid_Color_Nails")
	check("authored grid present",grid!=null)
	if grid==null:return
	for frame in 3600:
		if grid.has_meta("stage_grid_ready"):break
		await process_frame
	check("grid completed",grid.has_meta("stage_grid_ready"))
	salon=find_scene("/nail_salon.gd")
	for n in hall.find_children("*","Node3D",true,false):
		if n.get_script()!=null and n.get_script().resource_path.ends_with("/nail_color_controller.gd"):controls[n.target_surface]=n
	check("salon and both separate surface controls placed",salon!=null and controls.size()==2)
	if salon==null or controls.size()!=2:return
	gm=root.get_node("GameManager");saved_nails=gm.get_nail_color();saved_skin=gm.get_hand_color();have_saved=true
	grabber=SuppliedGrabber.new();root.add_child(grabber)
	var giant_before:Transform3D=salon.giant.transform
	var petite_before:Transform3D=salon.petite.transform
	check("the two scales use the same source mesh",salon.giant.mesh==salon.petite.mesh)
	check("the display hands retain 4.3m and 0.32m heights",is_equal_approx((salon.giant.transform*salon.giant.get_aabb()).size.y,4.3) and is_equal_approx((salon.petite.transform*salon.petite.get_aabb()).size.y,0.32))
	# Actual production meshes/receivers; their XR pose driver is omitted here.
	# These are invisible material-wiring fixtures, not simulated tracked hands.
	for side in ["left","right"]:
		var hand:Node3D=load("res://commons/body/hands/"+side+"_hand.tscn").instantiate()
		hand.set_script(null)
		hand.name="Fixture_"+side
		hand.get_node("AnimationTree").active=false
		for ap in hand.find_children("*","AnimationPlayer",true,false):ap.stop()
		hand.visible=false
		root.add_child(hand);fixture_hands.append(hand)
		for frame in 4:await process_frame
		var receiver:Node=hand.get_node("PresistNailColor")
		receivers.append(receiver)
		check(side+" production receiver found named skin and nail surfaces",receiver.hand_mesh!=null and receiver.surface_skin_idx>=0 and receiver.surface_nails_idx>=0 and receiver.surface_skin_idx!=receiver.surface_nails_idx)
	for target in [0,1]:
		var control:Node3D=controls[target]
		var mapper:Node3D=control.get_node("ValueMapper3D")
		check("RGB volume remains at standing reach "+str(target),mapper.global_position.y>=0.85 and mapper.global_position.y+mapper.space_size.y<=1.5)
		check("open control mounting retained "+str(target),not control.get_node("MeshInstance3D").visible)
		observations["control_"+str(target)]={"local_position":xyz(salon.to_local(control.global_position)),"box_size":xyz(mapper.space_size)}
	await choose(1,Color(0.65,0.4,0.25))
	await choose(0,Color(0.8,0.08,0.12))
	await snapshot("salon-red",salon.to_global(Vector3(0.2,1.7,10.5)),salon.to_global(Vector3(0,2.8,0.9)),64)
	await snapshot("petite-red",salon.to_global(Vector3(0.65,1.55,4.1)),salon.to_global(Vector3(0,1.05,2.95)),43)
	await snapshot("giant-red",salon.to_global(Vector3(0.6,3.3,5.8)),salon.to_global(Vector3(0,3.1,-0.1)),51)
	var point_before:Vector3=controls[0].value_mapper.point.position
	await choose(0,Color(0.8,0.08,0.8))
	var change:Vector3=controls[0].value_mapper.point.position-point_before
	check("blue-only change leaves red and green coordinates fixed",absf(change.x)<0.0001 and absf(change.y)<0.0001 and change.z>0.3)
	check("nail edit leaves all skin receivers unchanged",salon.skin_materials.all(func(m):return m.albedo_color.is_equal_approx(Color(0.65,0.4,0.25))) and receivers.all(func(r):return r.skin_material.albedo_color.is_equal_approx(Color(0.65,0.4,0.25))))
	await snapshot("salon-violet",salon.to_global(Vector3(0.2,1.7,10.5)),salon.to_global(Vector3(0,2.8,0.9)),64)
	await snapshot("petite-violet",salon.to_global(Vector3(0.65,1.55,4.1)),salon.to_global(Vector3(0,1.05,2.95)),43)
	await snapshot("giant-violet",salon.to_global(Vector3(0.6,3.3,5.8)),salon.to_global(Vector3(0,3.1,-0.1)),51)
	var nails_before_skin:Color=gm.get_nail_color()
	await choose(1,Color(0.12,0.56,0.68))
	observations["nails_at_skin_edit"]={"before":[nails_before_skin.r,nails_before_skin.g,nails_before_skin.b],"after":[gm.get_nail_color().r,gm.get_nail_color().g,gm.get_nail_color().b]}
	check("skin edit leaves all nails unchanged",salon.nail_materials.all(func(m):return m.albedo_color.is_equal_approx(nails_before_skin)) and receivers.all(func(r):return r.nail_material.albedo_color.is_equal_approx(nails_before_skin)))
	await snapshot("salon-turquoise",salon.to_global(Vector3(0.2,1.7,10.5)),salon.to_global(Vector3(0,2.8,0.9)),64)
	await snapshot("petite-turquoise",salon.to_global(Vector3(0.65,1.55,4.1)),salon.to_global(Vector3(0,1.05,2.95)),43)
	await snapshot("giant-turquoise",salon.to_global(Vector3(0.6,3.3,5.8)),salon.to_global(Vector3(0,3.1,-0.1)),51)
	var mapper:Node3D=controls[0].value_mapper
	await snapshot("rgb-choice",mapper.to_global(Vector3(0.9,0.65,1.05)),mapper.to_global(Vector3(0.25,0.25,0.25)),52)
	await choose(0,Color(0.8,0.08,0.12))
	check("return to same address restores same nail value",gm.get_nail_color().is_equal_approx(Color(0.8,0.08,0.12)))
	check("colour edits preserve both body transforms and shared geometry",salon.giant.transform.is_equal_approx(giant_before) and salon.petite.transform.is_equal_approx(petite_before) and salon.giant.mesh==salon.petite.mesh)
	observations["selected_colours"]={"nails_a":[0.8,0.08,0.12],"nails_b":[0.8,0.08,0.8],"skin_a":[0.65,0.4,0.25],"skin_b":[0.12,0.56,0.68]}
	completed=true

func finish() -> void:
	if have_saved:
		for target in controls:
			controls[target].value_mapper.set_process(false)
		gm.set_nail_color(saved_nails);gm.set_hand_color(saved_skin)
		check("original loaded colour choices restored",gm.get_nail_color().is_equal_approx(saved_nails) and gm.get_hand_color().is_equal_approx(saved_skin))
	check("focused comparison completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Isolated production museum. Supplied XRTools grabber moves actual RGB points. Native display-hand captures. Original production left/right meshes and receiver children verify material propagation with their XR pose drivers omitted, invisible to the camera. No headset, tracked pose, physical reach, walking, learner or performance claim. Colours restored; no save requested."},"  "))
	print("NAILS CHOOSING HAND ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
