extends "./build.gd"
## Original flowers and a shared world-coordinate pattern, prompted by Hart.
func surface(a: Color, b: Color, style: int = 0) -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = preload("./pattern.gdshader")
	result.set_shader_parameter("colour_a", a)
	result.set_shader_parameter("colour_b", b)
	result.set_shader_parameter("pattern", style)
	result.set_shader_parameter("density", 2.0)
	result.set_shader_parameter("phase", amount * 0.5)
	animated_materials.append(result)
	return result

func build() -> void:
	var checker := surface(Color("ebe5ef"), Color("191021"))
	var hot := surface(Color("ed2268"), Color("281083"), 2)
	var cyan := surface(Color("39e6ce"), Color("901aee"), 1)
	var yellow := surface(Color("ffc333"), Color("62179a"), 1)
	box(Vector3(0, 0.01, 0), Vector3(11.7, 0.02, 9.7), hot)
	box(Vector3(0, 2.6, -4.86), Vector3(11.7, 5.2, 0.02), checker)
	box(Vector3(-5.85, 2.6, 0), Vector3(0.02, 5.2, 9.7), hot)
	for x in [-4.0, 0.0, 4.0]:
		box(Vector3(x, 1.15, -3.6), Vector3(1.9, 0.22, 1.9), cyan)
		box(Vector3(x, 0.52, -3.6), Vector3(0.9, 1.0, 0.9), checker)
	var flower_positions := [Vector3(-3,0,-2),Vector3(0,0,-2.8),Vector3(3.1,0,-2.1),Vector3(-2.5,0,1.2),Vector3(2.7,0,1.0)]
	for i in flower_positions.size():
		var site: Vector3 = flower_positions[i]
		var height := 2.1 + 0.35 * (i % 3)
		var stem := PackedVector3Array()
		for j in 25:
			var t := float(j) / 24
			stem.append(site + Vector3(sin(t * 2.6 + i) * t * 0.36, 0.14 + t * height, 0))
		tube(stem, 0.12, checker)
		var centre: Vector3 = stem[-1]
		ball(centre, Vector3(0.27,0.27,0.27), yellow)
		for j in 6:
			var angle := TAU * j / 6.0
			var petal := ball(centre + Vector3(cos(angle)*0.55, sin(angle)*0.55,0), Vector3(0.56,0.26,0.13), cyan if i % 2 == 0 else checker)
			petal.rotation.z = angle
		for sign_value in [-1, 1]:
			var leaf := ball(site + Vector3(sign_value*0.4, height*0.47,0), Vector3(0.6,0.2,0.10), yellow if i % 2 == 0 else cyan)
			leaf.rotation.z = sign_value * 0.55
	for i in 3:
		ring(Vector3(-3.5+i*3.5,3.5,-4.5),0.65,0.05,yellow,Vector3(90,0,0))
	evidence = {"flower_count": flower_positions.size(), "positions": flower_positions, "phase": amount * 0.5, "density": 2.0, "mapping": "world triplanar", "patterns": 3}
