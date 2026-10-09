extends "./build.gd"
## An original passage study prompted by the user's Bałka photograph.
## The title, dimensions and material of the photographed work are not established.
func build() -> void:
	var width := lerpf(0.48, 1.68, amount)
	var plaster := material(Color(0.69, 0.65, 0.54), 0.93)
	var cut := material(Color(0.15, 0.13, 0.105), 0.83)
	var wall_width := 5.2
	var side_width := (wall_width - width) * 0.5
	for sign_value in [-1, 1]:
		box(Vector3(sign_value * (width + side_width) * 0.5, 1.75, 0), Vector3(side_width, 3.5, 0.36), plaster, true)
		box(Vector3(sign_value * (width * 0.5 + 0.012), 1.02, 0), Vector3(0.018, 2.04, 0.38), cut)
	box(Vector3(0, 2.775, 0), Vector3(width, 1.45, 0.36), plaster, true)
	box(Vector3(0, 2.045, 0), Vector3(width, 0.022, 0.38), cut)
	# One displaced architectural element and an empty approach.
	cylinder(Vector3(-2.2, 0.10, 2.4), 0.57, 0.20, material(Color(0.05, 0.046, 0.042)), 64)
	box(Vector3(0, 0.006, 0), Vector3(0.56, 0.008, 7.0), material(Color(0.42, 0.40, 0.36)))
	box(Vector3(0, 0.01, -2.0), Vector3(0.56, 0.012, 0.05), material(Color(0.91, 0.38, 0.54)))
	plaque("WHO FITS THROUGH?", Vector3(0, 4.25, -4.84))
	evidence = {"opening_width": width, "opening_height": 2.05, "probe_diameter": 0.56, "wall_collision": true}
