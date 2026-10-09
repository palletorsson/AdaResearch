extends "res://doc/book/iterations/2026-09-29-point-and-coordinates/probe.gd"

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(2.5).timeout
	await coordinate_checks()
	var frame := find_scene("/CoordinateSystem3M.gd")
	if frame == null:
		check("coordinate frame exists", false)
		return
	check("drawing enlarged without changing coordinate scale", is_equal_approx(frame.axis_length,3.4) and frame.scale.is_equal_approx(Vector3.ONE*1.5))
	check("24 cm diameter axes", is_equal_approx(frame.axis_thickness*frame.scale.x*2.0,0.24))
	var colours: Array[Color] = [Color("d76c9f"),Color("96969d"),Color("202127")]
	for i in range(3):
		var axis: Node3D = frame.get_node("Axis"+["X","Y","Z"][i])
		var mat: StandardMaterial3D = axis.shaft.material_override
		check("axis %d is opaque and shaded" % i,mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and mat.shading_mode==BaseMaterial3D.SHADING_MODE_PER_PIXEL and is_equal_approx(mat.albedo_color.a,1.0))
		check("axis and marker %d share chosen colour" % i,mat.albedo_color.is_equal_approx(colours[i]) and frame._axis_markers[i].material_override.albedo_color.is_equal_approx(colours[i]))
	check("Z label names actual negative arm",frame.get_node("AxisLabelZ").text=="−Z" and frame.get_node("AxisLabelZ").position.z<0.0)
	check("X Y and Z keep their identifying letters",frame.get_node("AxisLabelX").text=="X" and frame.get_node("AxisLabelY").text=="Y")
	await snapshot("solid-frame",frame.global_position+Vector3(6,2.2,-6.3),frame.global_position+Vector3(1.2,1.9,-1.2),69)
	# This artifact is shared: verify its unconfigured appearance stays conventional.
	var default_frame: Node3D = load("res://algorithms/vectors/00_coordinates/CoordinateSystem3M.tscn").instantiate()
	default_frame.show_panel=false
	default_frame.origin_sign=false
	default_frame.adopt_external_point=false
	default_frame.position=Vector3(1000,0,1000)
	root.add_child(default_frame)
	check("unconfigured frame retains RGB and translucent material",default_frame.axis_palette=="rgb" and default_frame.get_node("AxisX").shaft.material_override.albedo_color.is_equal_approx(Color(1,0,0,0.5)))
	default_frame.queue_free()
