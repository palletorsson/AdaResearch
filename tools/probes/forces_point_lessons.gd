extends "res://tools/probes/transformation_encounters.gd"
## Independent numeric expectations plus real desktop and XRTools pickup plumbing.
func landing_checks() -> void:
	var lesson=find_scene("/point_lesson.gd")
	check("lesson placed in the museum",lesson!=null)
	if lesson==null:return
	var point=lesson.points[0]
	check("point inherits the earlier pickable body",point.get_script().get_base_script().resource_path.ends_with("/ignorance_gallery/point_body.gd") and is_equal_approx(point.sphere.radius,0.14))
	check("visible point has a matching spherical boundary",point.get_child(1).shape is SphereShape3D and is_equal_approx(point.get_child(1).shape.radius,0.14))
	point.position=lesson.origin+Vector3(3,4,0)
	if lesson.principle=="addition":lesson.points[1].position=lesson.origin+Vector3(-2,1,3)
	await tick()
	match lesson.principle:
		"direction":
			check("3 4 0 has length 5",is_equal_approx(lesson.a.length(),5))
			check("unit result is 0.6 0.8 0",lesson.result.is_equal_approx(Vector3(0.6,0.8,0)))
			check("unit direction is always a separate reading",lesson.result_body.visible and point.position.is_equal_approx(lesson.origin+Vector3(3,4,0)))
			point.position=lesson.origin;await tick()
			check("zero displacement stays finite",lesson.result==Vector3.ZERO and lesson.result.is_finite())
		"addition":
			check("known independent sum",lesson.result.is_equal_approx(Vector3(1,5,3)))
			point.position=lesson.origin+Vector3(-2,1,3);lesson.points[1].position=lesson.origin+Vector3(3,4,0);await tick()
			check("swapping preserves result",lesson.result.is_equal_approx(Vector3(1,5,3)))
			lesson.points[1].position=lesson.origin+Vector3(2,-1,-3);await create_timer(0.1).timeout
			observations.cancel_a=xyz(lesson.a);observations.cancel_b=xyz(lesson.b);observations.cancel_result=xyz(lesson.result)
			check("opposite displacements cancel",lesson.result.is_equal_approx(Vector3.ZERO))
		"projection":
			check("x rail keeps 3 and leaves 4",lesson.result.is_equal_approx(Vector3(3,0,0)) and lesson.remainder.is_equal_approx(Vector3(0,4,0)))
			point.position=lesson.origin+Vector3(3,2,-2);await tick()
			check("perpendicular move preserves projection",lesson.result.is_equal_approx(Vector3(3,0,0)))
			check("parts reconstruct displacement",(lesson.result+lesson.remainder).is_equal_approx(Vector3(3,2,-2)))
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
	observations.principle=lesson.principle

func finish() -> void:
	var result={"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Actual museum lesson, numeric assertions, button events, desktop pointer and supplied XRTools rig. Physical headset tracking untested."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("FORCE POINT LESSON ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
