extends SceneTree

var checks: Array = []
var observations: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(label: String, passed: bool, details = null) -> void:
	checks.append({"label":label,"passed":passed,"details":details})

func vector(v: Vector3) -> Array:
	return [v.x,v.y,v.z]

func run() -> void:
	var source_path := OS.get_environment("UNIT_SOURCE")
	if source_path.is_empty():
		source_path = "res://algorithms/wavefunctions/unit_circle/UnitCircle.gd"
	var script = load(source_path)
	for placement in ["identity", "translated_rotated", "tilted_scaled"]:
		var holder := Node3D.new()
		root.add_child(holder)
		if placement != "identity":
			holder.position = Vector3(6,1.5,11)
			holder.rotation.y = PI/2
		if placement == "tilted_scaled":
			holder.rotation.x = 0.4
			holder.rotation.z = -0.2
			holder.scale = Vector3(0.8,1.2,1.4)
		var circle = script.new()
		circle.samples_per_cycle = 8
		circle.num_cycles = 1
		circle.enable_collision = false
		holder.add_child(circle)
		circle.set_process(false)
		for angle in [0.0,PI/2,PI,0.7]:
			circle.angle = angle
			circle._update_rotator_and_indicators()
			var x: float = cos(angle)
			var y: float = sin(angle)
			for item in [["radius_line",Vector3.ZERO,Vector3(x,y,0)], ["sine_line",Vector3(x,0,0),Vector3(x,y,0)], ["cosine_line",Vector3(0,y,0),Vector3(x,y,0)], ["_sine_cap",Vector3(x,0,0),Vector3(x,y,0)], ["_cos_cap",Vector3(0,y,0),Vector3(x,y,0)]]:
				var line: Node3D = circle.get(item[0])
				var expected: Vector3 = circle.to_global((item[1]+item[2])*0.5)
				var actual: Vector3 = line.global_position
				var expected_axis: Vector3 = (circle.global_basis * (item[2]-item[1])).normalized()
				var actual_axis: Vector3 = -line.global_basis.z.normalized()
				var record := {"placement":placement,"angle":angle,"line":item[0],"expected_center":vector(expected),"actual_center":vector(actual),"center_error_m":actual.distance_to(expected),"axis_dot":actual_axis.dot(expected_axis)}
				observations.append(record)
				check("rod centre follows its artifact: %s %s angle=%s" % [item[0],placement,angle], actual.distance_to(expected)<0.00001, record)
				if (item[2]-item[1]).length()>0.001:
					check("rod axis follows its artifact: %s %s angle=%s" % [item[0],placement,angle], actual_axis.dot(expected_axis)>0.99999, record)
		holder.queue_free()
		await process_frame
	var output: String = OS.get_environment("UNIT_PROBE_OUTPUT")
	var file := FileAccess.open(output,FileAccess.WRITE)
	file.store_string(JSON.stringify({"source":source_path,"checks":checks,"observations":observations},"  "))
	file.close()
	var failures := checks.filter(func(c):return not c.passed)
	print("UNIT_TRANSFORMS ",checks.size()," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
