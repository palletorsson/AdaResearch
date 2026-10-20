extends "res://tools/probes/transformation_encounters.gd"
## Real physics overlap and XR pointer dispatch, without a headset or tracked hand.
var probe_hand: StaticBody3D
var pointer: Node3D

func landing_checks() -> void:
	root.size=Vector2i(1600,1000)
	museum.call("flush_stamps");await create_timer(0.5).timeout
	probe_hand=StaticBody3D.new();probe_hand.collision_layer=1<<17;probe_hand.collision_mask=0
	var shape:=SphereShape3D.new();shape.radius=0.012
	var collision:=CollisionShape3D.new();collision.shape=shape;probe_hand.add_child(collision)
	probe_hand.position=Vector3(0,-100,0);root.add_child(probe_hand)
	pointer=Node3D.new();root.add_child(pointer)
	if map_id=="Random_Entropies":await types_controls()
	else:await cabinet_controls()
	observations["scope"]="Physics overlap with a supplied 12 mm probe on the hand collision layer; real XR pointer-event dispatch after a physics ray hit. No tracked-controller input, headset comfort or discoverability result."

func settle_input() -> void:
	for i in 3:await tick()
	await create_timer(0.14).timeout

func ray_hit(button: Node3D, normal: Vector3) -> Dictionary:
	var query:=PhysicsRayQueryParameters3D.create(button.global_position+normal*0.40,button.global_position-normal*0.05,1|(1<<20))
	query.collide_with_areas=true
	return hall.get_world_3d().direct_space_state.intersect_ray(query)

func exercise(button: Node3D, owner: Node3D, label: String, outward:=Vector3.ZERO) -> void:
	var area: Area3D=button.get_node("InteractableAreaButton")
	var normal: Vector3=button.get_parent().global_basis.z.normalized() if outward==Vector3.ZERO else outward.normalized()
	var height:=button.global_position.y-owner.global_position.y
	check(label+" cap faces away from backing",button.global_basis.y.normalized().dot(normal)>0.99)
	check(label+" cap between 0.85 and 1.20 m",height>=0.85 and height<=1.20)
	var pulses: Array=[0]
	var callback: Callable=func():pulses[0]+=1
	button.pressed.connect(callback)
	# Forward of the cap, away from the solid backing. It must not require penetration.
	probe_hand.global_position=button.to_global(Vector3(0,0.045,0))
	await settle_input()
	check(label+" hand overlap activates once",area.pressed and pulses[0]==1)
	await settle_input()
	check(label+" holding contact does not repeat",pulses[0]==1)
	probe_hand.position=Vector3(0,-100,0);await settle_input()
	check(label+" leaving releases",not area.pressed)
	var hit:=ray_hit(button,normal)
	check(label+" front ray reaches area before solid",hit.get("collider")==area)
	if hit.get("collider")==area:
		XRToolsPointerEvent.pressed(pointer,hit.collider,hit.position)
		await settle_input()
		check(label+" pointer dispatch activates once",area.pressed and pulses[0]==2)
		XRToolsPointerEvent.pressed(pointer,hit.collider,hit.position)
		await settle_input()
		check(label+" repeated pointer-down does not repeat",pulses[0]==2)
		XRToolsPointerEvent.released(pointer,hit.collider,hit.position)
		await settle_input()
		check(label+" trigger release releases cap",not area.pressed)
	button.pressed.disconnect(callback)
	observations[label]={"height_m":height,"contact_normal":xyz(normal)}

func types_controls() -> void:
	var doors=find_scene("/ordinary_entropies/door_study.gd")
	var guesses=find_scene("/ordinary_entropies/one_guess.gd")
	check("door and four guessing tables installed",doors!=null and guesses!=null)
	if doors==null or guesses==null:return
	var step: Node3D=doors.buttons["STEP"]
	# Reproduce the source scene orientation as a negative control in memory.
	step.rotation.x=-PI/2;await settle_input()
	probe_hand.global_position=step.global_position+step.get_parent().global_basis.z.normalized()*0.10
	await settle_input()
	check("old reversed cap misses exterior contact",not step.get_node("InteractableAreaButton").pressed and doors.step_index==0)
	probe_hand.position=Vector3(0,-100,0);await settle_input();step.rotation.x=PI/2;await settle_input()
	await exercise(step,doors,"door STEP")
	check("hand and pointer advance one step each",doors.step_index==2)
	for name in ["RESET","GAP -","GAP +"]:await exercise(doors.buttons[name],doors,"door "+name)
	doors.reset_study()
	for i in guesses.versions.size():
		var table=guesses.versions[i]
		for key in table.buttons:await exercise(table.buttons[key],table,"table %d %s"%[i+1,key])
		table.reset_table()
		await exercise(table.buttons["PINK"],table,"table %d choose"%[i+1])
		await exercise(table.buttons["DRAW"],table,"table %d draw"%[i+1])
		check("table %d changes through real input route"%[i+1],table.model.guess==0 and table.model.draws==2)
		table.reset_table()
	await snapshot("doors-control",doors.to_global(Vector3(2.25,1.65,2.2)),doors.to_global(Vector3(2.25,1.05,0.22)),58)
	var table=guesses.versions[1]
	await snapshot("guess-standing",table.to_global(Vector3(0,1.65,2.35)),table.to_global(Vector3(0,0.95,0.5)),78)
	await snapshot("guess-lower-eye",table.to_global(Vector3(0,1.20,2.35)),table.to_global(Vector3(0,0.95,0.5)),78)
	var approach:=floor_at(table.to_global(Vector3(0,0,2.05)))
	check("guess rail approach has floor",not approach.is_empty())

func cabinet_controls() -> void:
	var cabinet=find_scene("/entropy_compartments/entropy_compartments.gd")
	check("cabinet installed",cabinet!=null)
	if cabinet==null:return
	var baseline: Dictionary=cabinet.capture()
	for key in cabinet.buttons:
		var button: Node3D=cabinet.buttons[key]
		var from:=cabinet.to_global(Vector3(button.position.x,1.35,1.45))
		var query:=PhysicsRayQueryParameters3D.create(from,button.to_global(Vector3(0,0.024,0)),1|(1<<20))
		query.collide_with_areas=true
		var hit:=hall.get_world_3d().direct_space_state.intersect_ray(query)
		check("cabinet angled ray reaches "+key,hit.get("collider")==button.get_node("InteractableAreaButton"))
	await exercise(cabinet.buttons["A LEFT -"],cabinet,"cabinet A LEFT -",cabinet.global_basis.y)
	var before: Array=cabinet.model.sites.duplicate()
	await exercise(cabinet.buttons["SAME k"],cabinet,"cabinet SAME k",cabinet.global_basis.y)
	check("cabinet retains changed arrangement",cabinet.model.sites!=before)
	cabinet.restore(baseline)
	await snapshot("cabinet-controls",cabinet.to_global(Vector3(0,1.65,2.2)),cabinet.to_global(Vector3(0,1.1,0.1)),65)

