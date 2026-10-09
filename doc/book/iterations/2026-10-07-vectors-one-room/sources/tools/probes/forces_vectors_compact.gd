extends "res://tools/probes/transformation_encounters.gd"
## Numeric expectations and real input plumbing in the combined museum hall.
func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(0.3).timeout
	var lessons: Dictionary={}
	for node in get_nodes_in_group("force_point_lesson"):
		if hall.is_ancestor_of(node):lessons[node.principle]=node
	check("three distinct vector stations share this museum hall",lessons.size()==3)
	if lessons.size()!=3:return
	var count=0
	for mode in ["direction","addition","projection"]:
		var lesson=lessons[mode]
		count+=lesson.points.size()
		check(mode+": familiar point radius and collision",is_equal_approx(lesson.points[0].sphere.radius,0.14) and lesson.points[0].get_child(1).shape is SphereShape3D)
		check(mode+": one nearby control",lesson.buttons.size()==1 and lesson.buttons.has("RESET"))
		var point=lesson.points[0]
		point.position=lesson.origin+Vector3(3,4,0)
		if mode=="addition":lesson.points[1].position=lesson.origin+Vector3(-2,1,3)
		await create_timer(0.12).timeout
		check(mode+": annotation follows the moved point",lesson.point_labels[0].position.is_equal_approx(point.position+Vector3(0,0.38,0)))
		check(mode+": live values display the actual input",lesson.point_labels[0].text.contains("+3.00, +4.00, +0.00") and lesson.point_labels[0].text.contains("5.00"))
		var rod=lesson.arrows[0]
		check(mode+": direction is a thin solid cylinder",rod.shaft.mesh is CylinderMesh and rod.shaft.mesh.top_radius<0.025 and rod.head.mesh is CylinderMesh)
		check(mode+": rod reaches both endpoints",rod.from_point.is_equal_approx(lesson.origin) and rod.to_point.is_equal_approx(point.position))
		check(mode+": cylinder orientation follows displacement",(rod.basis.y).is_equal_approx(Vector3(0.6,0.8,0)))
		match mode:
			"direction":
				check("3-4 displacement has magnitude 5",is_equal_approx(lesson.a.length(),5))
				check("unit direction is independent of magnitude",lesson.result.is_equal_approx(Vector3(0.6,0.8,0)))
				check("separate unit display has length one",is_equal_approx(lesson.arrows[1].from_point.distance_to(lesson.arrows[1].to_point),1.0))
				point.position=lesson.origin;await create_timer(0.1).timeout
				check("zero hides both direction rods and marks undefined",not lesson.arrows[0].visible and not lesson.arrows[1].visible and not lesson.result_body.visible and lesson.result_label.text.contains("undefined"))
				point.position=lesson.origin+Vector3.DOWN;await create_timer(0.1).timeout
				check("opposite vertical direction remains finite",lesson.arrows[0].basis.is_finite() and lesson.arrows[0].basis.y.is_equal_approx(Vector3.DOWN))
			"addition":
				check("sum is 1 5 3",lesson.result.is_equal_approx(Vector3(1,5,3)))
				check("translated b begins at a and arrives at sum",lesson.arrows[2].from_point.is_equal_approx(lesson.origin+Vector3(3,4,0)) and lesson.arrows[2].to_point.is_equal_approx(lesson.origin+Vector3(1,5,3)))
				point.position=lesson.origin+Vector3(-2,1,3);lesson.points[1].position=lesson.origin+Vector3(3,4,0);await create_timer(0.1).timeout
				check("swapping keeps the same arrival",lesson.result.is_equal_approx(Vector3(1,5,3)))
				lesson.points[1].position=lesson.origin+Vector3(2,-1,-3);await create_timer(0.1).timeout
				check("opposites cancel without a degenerate visible cylinder",lesson.result.is_zero_approx() and not lesson.arrows[3].visible)
			"projection":
				check("rail keeps X and remainder keeps Y",lesson.result.is_equal_approx(Vector3(3,0,0)) and lesson.remainder.is_equal_approx(Vector3(0,4,0)))
				point.position=lesson.origin+Vector3(3,2,-2);await create_timer(0.1).timeout
				check("perpendicular movement preserves projection",lesson.result.is_equal_approx(Vector3(3,0,0)))
				point.position=lesson.origin+Vector3(-1,2,3);await create_timer(0.1).timeout
				check("projection retains its negative sign",lesson.result.is_equal_approx(Vector3(-1,0,0)) and lesson.result_label.text.contains("-1.00"))
				check("parts recover the original vector",(lesson.result+lesson.remainder).is_equal_approx(Vector3(-1,2,3)))
		await interaction(lesson)
	check("four directly grabbable black points",count==4)
	# Eye-height museum captures; no replacement gallery or synthetic illustration.
	var walker=museum.get("_player")
	if walker is Node3D:walker.visible=false
	var player_camera=museum.get("_cam")
	if player_camera is Node3D:player_camera.visible=false
	for mode in ["direction","addition","projection"]:
		var lesson=lessons[mode]
		lesson.act("RESET")
		await snapshot(mode,lesson.to_global(Vector3(0,1.8,-4.0)),lesson.to_global(Vector3(0,1.4,0.3)),61)
	lessons.direction.points[0].position=lessons.direction.origin+Vector3(-0.55,0.75,0.35)
	await create_timer(0.1).timeout
	await snapshot("direction-moved",lessons.direction.to_global(Vector3(0,1.8,-4)),lessons.direction.to_global(Vector3(0,1.4,0.3)),61)
	lessons.direction.act("RESET")
	observations.scope="Geometric vector operations, actual PointBody and XRTools pickup; no new force law."

func interaction(lesson: Node3D) -> void:
	var point=lesson.points[0]
	var player=CharacterBody3D.new();root.add_child(player)
	var eye=Camera3D.new();player.add_child(eye)
	var pointer=load("res://commons/scenes/em/em_desktop_pointer.gd").new();pointer.cam=eye;player.add_child(pointer)
	pointer.set_process(false);pointer.set_physics_process(false)
	pointer._grab_held(point)
	check("desktop grab marks held point",point.has_meta("lesson_held"))
	point.position=lesson.origin+Vector3(0.7,0.4,0.8);var held_at: Vector3=point.position
	lesson.buttons.RESET.pressed.emit()
	check("reset leaves desktop-held point alone",point.position.is_equal_approx(held_at))
	pointer._drop_held();await tick()
	check("desktop drop leaves a frozen readable point",point.freeze and not point.has_meta("lesson_held"))
	player.queue_free();await tick()
	var rig=XROrigin3D.new();var head=XRCamera3D.new();head.name="Camera";rig.add_child(head)
	var hand=XRController3D.new();hand.name="LeftHand";rig.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);root.add_child(rig)
	hand.global_position=point.global_position;await tick();point.pick_up(pickup)
	check("actual XRTools pickup owns the point",point.is_picked_up())
	held_at=point.position;lesson.buttons.RESET.pressed.emit()
	check("reset leaves XR-held point alone",point.position.is_equal_approx(held_at))
	point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
	check("XR drop preserves frozen reading",not point.is_picked_up() and point.freeze)
	lesson.buttons.RESET.pressed.emit();observations.reset_immediate=xyz(point.position);await tick()
	observations.reset_after_tick=xyz(point.position);observations.expected_reset=xyz(lesson.starts[0]);observations.point_parent=str(point.get_parent().get_path())
	await create_timer(0.2).timeout
	observations.reset_settled=xyz(point.position)
	check("reset restores initial point",point.position.is_equal_approx(lesson.starts[0]))
	rig.queue_free()

func finish() -> void:
	var result={"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Three stations in the real museum; live numeric labels, pooled solid cylinders, zero/signed/cancellation cases, desktop and XRTools grab/release/reset. Physical headset readability and reach untested."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("COMBINED VECTORS ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
