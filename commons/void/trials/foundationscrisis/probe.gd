extends "res://tools/probes/void_transfer_probe.gd"
## Coordinator check of Claude's placement and the sole movement adapter.

func focused_checks(tag: String) -> void:
	if level==1:
		var plaque:Node3D=artifact("euclid_postulates_plaque")
		await approach(plaque,1.8)
		var before:int=plaque.current_postulate
		await press(plaque.get_node("LessonControls/NEXT"))
		check(tag+"NEXT uses spatial button",plaque.current_postulate==(before+1)%5)
		var gold:bool=plaque.highlight_fifth
		await press(plaque.get_node("LessonControls/GOLD"))
		check(tag+"GOLD uses spatial button",plaque.highlight_fifth!=gold)
	else:
		var bench:Node3D=artifact("triangle_curvature_workbench")
		check(tag+"original workbench starts on plane",bench._k_index==1)
		bench._slider.set_normalized_value(1.0);bench._on_slider_changed(1.0);await frames(30)
		check(tag+"HOST slider API changes to spherical host",bench._k_index==2)
		bench._slider.set_normalized_value(.5);bench._on_slider_changed(.5);await frames(30)
		var wing:Node3D=artifact("noneuclidean_wing")
		check(tag+"wing adapter and remote residency region",wing.get_script().resource_path.ends_with("noneuclidean_wing_void.gd") and wing.built and wing.is_in_group("void_floor_extension") and wing.contains_visitor(wing.to_global(Vector3(0,60,0))) and not wing.contains_visitor(wing.to_global(Vector3(0,1.6,2))))
		var deaths:int=game.deaths
		wing.visit(0);await frames(60)
		var eye:Vector3=wing.rooms[0].to_local(wing.eye_position())
		check(tag+"visit API carries visitor and keeps floor live",absf(eye.y-1.6)<.3 and absf(eye.x)<7 and absf(eye.z)<6 and game.floor_stream.focus==2 and game.deaths==deaths)
		wing.visit(1);await frames(120)
		check(tag+"remote chamber outside tower remains supported",game.deaths==deaths and not game.recovering)
		wing.leave();await frames(90)
		check(tag+"return API is not a fatal fall",game.deaths==deaths and game.checkpoint==2 and wing.to_local(wing.eye_position()).distance_to(Vector3(0,1.6,1.8))<.4)

func capture_floor() -> void:
	if level==1:
		await photo("01-euclid-collection",Vector3(6,-2,12),Vector3(0,-4.7,4))
		await photo("02-euclid-lesson",Vector3(1.7,-3.8,8.5),Vector3(0,-4.4,5))
	else:
		await photo("03-curvature-collection",Vector3(8,-8,14.5),Vector3(-1,-10.6,6))
		var wing:Node3D=artifact("noneuclidean_wing")
		wing.visit(0);await frames(45)
		# Keep the native visitor in this remote space during its photograph.
		await photograph("04-original-seven-spaces",wing.rooms[0].to_global(Vector3(3,3.2,5)),wing.rooms[0].to_global(Vector3(0,1,-2)))
		wing.leave();await frames(30)
