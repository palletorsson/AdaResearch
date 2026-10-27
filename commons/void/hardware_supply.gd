extends RefCounted
## Rigid service trunking shared by architectural controls. The floor's
## electrical bus is a spatial connection, not a second power simulation.

static func connect_unit(unit: Node3D, local_port: Vector3) -> Node3D:
	var floor_root: Node = unit.get_parent()
	while floor_root != null and not floor_root.has_meta("void_content_floor"):
		floor_root = floor_root.get_parent()
	var route := Node3D.new()
	route.name = "HardwareSupply"
	unit.add_child(route)
	# A curator can rotate a unit freely. Trunking follows the building axes,
	# rather than becoming a broad diagonal box in the rotated artifact frame.
	route.global_basis = Basis.IDENTITY
	var end := unit.to_global(local_port)
	var ceiling := end + Vector3.UP*(4.8-local_port.y)
	var points: Array[Vector3] = [end,ceiling]
	if floor_root != null:
		var local: Vector3 = floor_root.to_local(end)
		ceiling.y = floor_root.global_position.y+4.8
		points[1] = ceiling
		var socket: Vector3 = floor_root.to_global(Vector3(-5 if local.x<0 else 5,4.8,-5.5 if local.z<0 else 5.5))
		points.append(Vector3(end.x,ceiling.y,socket.z))
		points.append(socket)
		route.set_meta("grid_socket",socket)
	var shell := StandardMaterial3D.new()
	shell.albedo_color = Color("51564f")
	shell.roughness = 0.65
	shell.metallic = 0.3
	var clamp := StandardMaterial3D.new()
	clamp.albedo_color = Color("d2d0bd")
	clamp.roughness = 0.8
	for i in range(points.size()-1):
		var a := route.to_local(points[i])
		var b := route.to_local(points[i+1])
		if a.distance_to(b)<0.01: continue
		var mesh := MeshInstance3D.new()
		mesh.name = "Trunk%d"%i
		var box := BoxMesh.new()
		box.size = (b-a).abs()+Vector3.ONE*0.075
		mesh.mesh = box
		mesh.position = (a+b)/2
		mesh.material_override = shell
		route.add_child(mesh)
		# Removable cover clips communicate installed, maintainable hardware.
		var count := maxi(1,ceili(a.distance_to(b)/0.9))
		for j in range(count+1):
			var joint := MeshInstance3D.new()
			var cap := BoxMesh.new()
			cap.size = Vector3.ONE*0.09
			joint.mesh = cap
			joint.position = a.lerp(b,float(j)/count)
			joint.material_override = clamp
			route.add_child(joint)
	return route
