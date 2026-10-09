extends "res://tools/probes/transformation_encounters.gd"
## Native views and a supplied key-input journey through the actual museum controller.
class KeyJourney extends Node:
	var world:Node3D
	var actor:CharacterBody3D
	var view:Camera3D
	var target:=Vector3.ZERO
	var moving:=false
	var arrived:=false
	var held:Dictionary={}
	func key(code:int,down:bool) -> void:
		if held.get(code,false)==down:return
		held[code]=down
		var event:=InputEventKey.new();event.keycode=code;event.pressed=down
		Input.parse_input_event(event)
	func release() -> void:
		for code in [KEY_W,KEY_SPACE,KEY_CTRL]:key(code,false)
	func _physics_process(delta:float) -> void:
		if moving:
			var difference:=target-actor.global_position
			var horizontal:=Vector3(difference.x,0,difference.z)
			if horizontal.length()>0.09:
				actor.look_at(actor.global_position+horizontal)
				view.global_basis=actor.global_basis
			key(KEY_W,horizontal.length()>0.09)
			key(KEY_SPACE,difference.y>0.10)
			key(KEY_CTRL,difference.y < -0.10)
			if horizontal.length()<0.11 and absf(difference.y)<0.12:
				moving=false;arrived=true;release()
		else:release()
		world._physics_process(delta)
	func _exit_tree() -> void:release()

var lab:Node3D
var actor:CharacterBody3D
var driver:KeyJourney
var complete:=false

func travel(point:Vector3,title:String) -> bool:
	driver.target=lab.to_global(point);driver.arrived=false;driver.moving=true
	var started:=Time.get_ticks_msec()
	while not driver.arrived and Time.get_ticks_msec()-started<9000:await process_frame
	driver.moving=false;driver.release()
	check(title,driver.arrived)
	observations[title]={"feet":xyz(lab.to_local(actor.global_position)),"target":xyz(point),"inside_flight":lab.enclosure.contains_point(actor.global_position)}
	return driver.arrived

func press_axis(axis:int) -> void:
	var buttons:=lab.find_children("InteractableAreaButton","Area3D",true,false)
	check("address buttons available",buttons.size()==3)
	if buttons.size()!=3:return
	var area:Node3D=buttons[axis]
	XRToolsPointerEvent.pressed(camera,area,area.global_position)
	XRToolsPointerEvent.released(camera,area,area.global_position)
	await tick()

func photo(title:String,eye:Vector3,aim:Vector3,fov:=55.0) -> void:
	await snapshot(title,lab.to_global(eye),lab.to_global(aim),fov)

func landing_checks() -> void:
	lab=find_scene("/array_flight_lab.gd")
	check("flight array exists in the production hall",lab!=null)
	if lab==null:return
	actor=museum.get("_player")
	actor.global_position=lab.to_global(Vector3(0,0.05,-7));actor.velocity=Vector3.ZERO
	museum.set("_dollhouse",false)
	await create_timer(0.4).timeout
	var originals:Dictionary={}
	for cell in lab.grid.get_children():
		if str(cell.name).begins_with("Cube_"):
			originals[str(cell.name)]=cell.position
			# Same bob/turn pose in the paired photographs; contact signal stays live.
			cell.set_process(false)
	check("sixty-four original occupants",originals.size()==64)
	check("start outside the flight volume",not lab.enclosure.contains_point(actor.global_position))
	await photo("enclosure",Vector3(8.1,6.2,-10.4),Vector3(0,5,0),66)
	await press_axis(0);await press_axis(1);await press_axis(1)
	check("real buttons select 1,2,0",lab.selected==Vector3i(1,2,0))
	check("selected address starts occupied",lab.values[2][0][1]==1 and "value 1" in lab.readout.text)
	await photo("console-before",Vector3(3.5,1.65,-8.4),Vector3(3.5,1.45,-6.9),52)
	driver=KeyJourney.new();driver.world=museum;driver.actor=actor;driver.view=museum.get("_cam");root.add_child(driver)
	if not await travel(Vector3(0,0.05,-5),"enter through the ground door"):return
	check("flight permission acquired by entering",lab.enclosure.contains_point(actor.global_position))
	if not await travel(Vector3(0,5.3,-5),"rise between the frame and first layer"):return
	var target:Node3D=lab.grid.get_node_or_null("Cube_1_2_0")
	check("target cube still present before approach",target!=null and lab.values[2][0][1]==1)
	await photo("address-before",Vector3(-0.1,6.15,-5.5),Vector3(-1.2,5.8,-3.6),53)
	if not await travel(Vector3(-1.2,5.3,-3.6),"fly to the selected address"):return
	await create_timer(0.7).timeout
	check("physical arrival collects the selected cube",not is_instance_valid(target) and lab.values[2][0][1]==0)
	var remaining:=0;var fixed:=true
	for cell in lab.grid.get_children():
		if str(cell.name).begins_with("Cube_"):
			remaining+=1;fixed=fixed and cell.position.is_equal_approx(originals[str(cell.name)])
	check("only the chosen occupant was collected",remaining==63)
	check("remaining occupants keep their positions",fixed)
	check("marker and address survive the collection",lab.selected==Vector3i(1,2,0) and "[1,2,0] | value 0" in lab.readout.text and lab.marker.position.is_equal_approx(lab.grid.position+Vector3(1,2,0)*2.4+Vector3(0,.35,0)))
	var before_hover:=actor.global_position
	await create_timer(0.5).timeout
	check("released inputs hover at the recorded absence",actor.global_position.distance_to(before_hover)<0.02 and lab.values[2][0][1]==0)
	await photo("address-after",Vector3(-0.1,6.15,-5.5),Vector3(-1.2,5.8,-3.6),53)
	await photo("console-after",Vector3(3.5,1.65,-8.4),Vector3(3.5,1.45,-6.9),52)
	if not await travel(Vector3(0,5.3,0),"fly between the interior layers"):return
	var eye:=actor.global_position+Vector3(0,1.65,0)
	await snapshot("inside-volume",eye,lab.to_global(Vector3(2.5,5.4,3.6)),66)
	if not await travel(Vector3(0,5.3,-5),"return to the entrance side"):return
	if not await travel(Vector3(0,0.05,-5),"descend to the ground doorway"):return
	if not await travel(Vector3(0,0.05,-7),"leave through the ground door"):return
	check("flight permission ends outside",not lab.enclosure.contains_point(actor.global_position))
	observations["selected_empty"]=[1,2,0]
	observations["sources"]={}
	for path in ["commons/artifacts/regularity/array_flight_lab.gd","commons/movement/museum_flight_box.gd","commons/movement/museum_flight_provider.gd","algorithms/arrays/grid_3d_4x4x4.gd"]:
		observations.sources[path]=FileAccess.get_sha256("res://"+path)
	complete=true

func finish() -> void:
	if driver!=null:driver.release();driver.set_physics_process(false)
	check("journey completed",complete)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Isolated production museum. Supplied Godot key events drive the unchanged museum physics controller and actual player capsule. Book camera poses are selected separately. Cube bob/turn processing frozen for matched figures; contact stays live. No headset or learner claim."},"  "))
	print("ENTERED ADDRESS ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
