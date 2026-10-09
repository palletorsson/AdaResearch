extends "./build.gd"
## A world built from repeated primitives, in response to Alex McLeod's image.
func build() -> void:
	var water := material(Color(0.055, 0.38, 0.42), 0.18, 0.5)
	box(Vector3(0, 0.025, 0), Vector3(11.5, 0.04, 9.5), water)
	var ground := material(Color(0.37, 0.49, 0.17), 0.87)
	for sign_value in [-1, 1]:
		ball(Vector3(sign_value * 3.3, -0.28, -0.3), Vector3(2.65, 0.64, 4.25), ground)
	var gold := material(Color(0.89, 0.61, 0.18), 0.19, 0.8)
	var green := material(Color(0.24, 0.50, 0.31), 0.29, 0.24)
	var pearl := material(Color(0.87, 0.80, 0.73), 0.22, 0.28)
	var tree_sites: Array[Vector3] = []
	var random := RandomNumberGenerator.new()
	random.seed = 810
	for i in 48:
		var sign_value := -1.0 if i < 24 else 1.0
		var at := Vector3(sign_value * random.randf_range(1.65, 4.75), 0.25, random.randf_range(-3.8, 3.3))
		tree_sites.append(at)
		var height := lerpf(0.28, 1.85, amount) * random.randf_range(0.65, 1.15)
		for tier in 3:
			var radius := 0.38 * (1.0 - tier * 0.24)
			cylinder(at + Vector3(0, height * (0.25 + tier * 0.25), 0), radius, height * 0.62, gold if i % 7 == 0 else green, 12, 0.0)
	# A pavilion of the same cones, turned into a roof, and repeated glazed boxes.
	var glass_colour := material(Color(0.06, 0.40, 0.45), 0.13, 0.65)
	for x in [-1, 0, 1]:
		box(Vector3(x * 0.73, 1.0, -2.6), Vector3(0.64, 1.7, 1.45), glass_colour)
		cylinder(Vector3(x * 0.73, 2.1, -2.6), 0.8, 1.1, gold, 4, 0.0).rotation_degrees.y = 45
	for i in 7:
		box(Vector3(0, 0.13, 2.5 - i * 0.65), Vector3(1.08, 0.2, 0.48), pearl)
	for i in 6:
		var path := PackedVector3Array()
		for j in 65:
			var angle := PI * float(j) / 64.0
			path.append(Vector3(cos(angle) * (3.35 + i * 0.15), 0.15 + sin(angle) * (3.35 + i * 0.15), -3.6))
		var hue: Color = [Color("f39ac2"), Color("eda177"), Color("edd58f"), Color("bce2b1"), Color("8bd1d8"), Color("a9a4e1")][i]
		tube(path, 0.10, material(hue, 0.5))
	for sign_value in [-1, 1]:
		for j in 4:
			ring(Vector3(sign_value * 3.9, 1.6 + j * 0.48, -2.6), 0.48, 0.13, gold)
	for cloud in [Vector3(-3, 3.1, 0.1), Vector3(3.2, 3.65, -1.4)]:
		for i in 3:
			ball(cloud + Vector3((i - 1) * 0.38, sin(i) * 0.15, 0), Vector3(0.47, 0.39, 0.38), pearl)
	evidence = {"tree_count": tree_sites.size(), "tree_positions": tree_sites, "cones_per_tree": 3, "height_factor": lerpf(0.28, 1.85, amount), "seed": 810}
