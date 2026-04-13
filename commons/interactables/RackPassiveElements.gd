extends Node3D
class_name RackPassiveElements

## Procedural passive rack elements: speakers, meters, monitors.
## Dieter Rams / Braun aesthetic — cream panels, black patterns, copper accents.

const EL_S := 0.10  # Standard element size (meters)
const CREAM := Color(0.78, 0.75, 0.67)
const BLACK := Color(0.10, 0.10, 0.10)
const COPPER := Color(0.75, 0.38, 0.13)
const WARM_GRAY := Color(0.50, 0.47, 0.42)
const DARK := Color(0.14, 0.14, 0.14)


## Build a speaker with dot pattern (Braun circular)
static func build_speaker_dots(parent: Node3D) -> void:
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = CREAM
	bg_mat.metallic = 0.15
	bg_mat.roughness = 0.7

	var bg := MeshInstance3D.new()
	bg.name = "SpeakerDotsBg"
	var box := BoxMesh.new()
	box.size = Vector3(EL_S, EL_S, 0.004)
	bg.mesh = box
	bg.material_override = bg_mat
	parent.add_child(bg)

	var dot_mat := StandardMaterial3D.new()
	dot_mat.albedo_color = BLACK
	dot_mat.metallic = 0.4
	dot_mat.roughness = 0.5

	var dot_mesh := SphereMesh.new()
	dot_mesh.radius = 0.0014
	dot_mesh.height = 0.0028
	dot_mesh.radial_segments = 6
	dot_mesh.rings = 3

	var r := EL_S * 0.42
	for ring in range(1, 10):
		var rr: float = (float(ring) / 9.0) * r
		var count: int = max(6, ring * 5)
		for i in count:
			var a: float = (float(i) / float(count)) * TAU
			var dx: float = cos(a) * rr
			var dy: float = sin(a) * rr
			if dx * dx + dy * dy > r * r:
				continue
			var dot := MeshInstance3D.new()
			dot.mesh = dot_mesh
			dot.material_override = dot_mat
			dot.transform.origin = Vector3(dx, dy, 0.003)
			parent.add_child(dot)


## Build a speaker with horizontal line pattern
static func build_speaker_lines(parent: Node3D) -> void:
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = CREAM
	bg_mat.metallic = 0.15
	bg_mat.roughness = 0.7

	var bg := MeshInstance3D.new()
	bg.name = "SpeakerLinesBg"
	var box := BoxMesh.new()
	box.size = Vector3(EL_S, EL_S, 0.004)
	bg.mesh = box
	bg.material_override = bg_mat
	parent.add_child(bg)

	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = BLACK

	var r_val := EL_S * 0.44
	for i in 20:
		var y: float = -r_val + (float(i) / 19.0) * r_val * 2.0
		var dy: float = y / r_val
		var line_w: float = 0.0
		if dy * dy < 1.0:
			line_w = sqrt(1.0 - dy * dy) * r_val * 2.0
		if line_w < 0.003:
			continue
		var line := MeshInstance3D.new()
		var line_box := BoxMesh.new()
		line_box.size = Vector3(line_w, 0.002, 0.001)
		line.mesh = line_box
		line.material_override = line_mat
		line.transform.origin = Vector3(0, y, 0.003)
		parent.add_child(line)


## Build a speaker with uniform dot grid
static func build_speaker_grid(parent: Node3D) -> void:
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = CREAM
	bg_mat.metallic = 0.15
	bg_mat.roughness = 0.7

	var bg := MeshInstance3D.new()
	bg.name = "SpeakerGridBg"
	var box := BoxMesh.new()
	box.size = Vector3(EL_S, EL_S, 0.004)
	bg.mesh = box
	bg.material_override = bg_mat
	parent.add_child(bg)

	var dot_mat := StandardMaterial3D.new()
	dot_mat.albedo_color = BLACK

	var dot_mesh := SphereMesh.new()
	dot_mesh.radius = 0.0012
	dot_mesh.height = 0.0024
	dot_mesh.radial_segments = 4
	dot_mesh.rings = 2

	var grid_n := 13
	var area := EL_S * 0.85
	var step := area / float(grid_n)
	for row in grid_n:
		for col in grid_n:
			var dot := MeshInstance3D.new()
			dot.mesh = dot_mesh
			dot.material_override = dot_mat
			dot.transform.origin = Vector3(
				-area / 2.0 + step * 0.5 + float(col) * step,
				-area / 2.0 + step * 0.5 + float(row) * step,
				0.003
			)
			parent.add_child(dot)


## Build a vertical VU meter
static func build_vu_meter_v(parent: Node3D) -> void:
	var mw := 0.035
	var mh := EL_S

	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.04, 0.04, 0.04)
	bg_mat.metallic = 0.3
	bg_mat.roughness = 0.7

	var bg := MeshInstance3D.new()
	var bg_box := BoxMesh.new()
	bg_box.size = Vector3(mw + 0.008, mh + 0.008, 0.005)
	bg.mesh = bg_box
	bg.material_override = bg_mat
	parent.add_child(bg)

	var bars := 16
	var bar_h := (mh - 0.008) / float(bars)
	for i in bars:
		var frac := float(i) / float(bars)
		var lit := frac < 0.7
		var col: Color
		if frac > 0.85:
			col = COPPER
		elif frac > 0.6:
			col = WARM_GRAY
		else:
			col = Color(0.38, 0.38, 0.38)

		var bar_mat := StandardMaterial3D.new()
		bar_mat.albedo_color = col if lit else Color(0.10, 0.10, 0.10)
		if lit:
			bar_mat.emission_enabled = true
			bar_mat.emission = col
			bar_mat.emission_energy_multiplier = 0.5

		var bar := MeshInstance3D.new()
		var bar_box := BoxMesh.new()
		bar_box.size = Vector3(mw * 0.85, bar_h * 0.65, 0.002)
		bar.mesh = bar_box
		bar.material_override = bar_mat
		bar.transform.origin = Vector3(0, -mh / 2.0 + 0.004 + float(i) * bar_h + bar_h / 2.0, 0.005)
		parent.add_child(bar)


## Build a horizontal VU meter
static func build_vu_meter_h(parent: Node3D) -> void:
	var mw := EL_S
	var mh := 0.035

	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.04, 0.04, 0.04)
	bg_mat.metallic = 0.3
	bg_mat.roughness = 0.7

	var bg := MeshInstance3D.new()
	var bg_box := BoxMesh.new()
	bg_box.size = Vector3(mw + 0.008, mh + 0.008, 0.005)
	bg.mesh = bg_box
	bg.material_override = bg_mat
	parent.add_child(bg)

	var bars := 20
	var bar_w := (mw - 0.008) / float(bars)
	for i in bars:
		var frac := float(i) / float(bars)
		var lit := frac < 0.6
		var col: Color
		if frac > 0.85:
			col = COPPER
		elif frac > 0.6:
			col = WARM_GRAY
		else:
			col = Color(0.38, 0.38, 0.38)

		var bar_mat := StandardMaterial3D.new()
		bar_mat.albedo_color = col if lit else Color(0.10, 0.10, 0.10)
		if lit:
			bar_mat.emission_enabled = true
			bar_mat.emission = col
			bar_mat.emission_energy_multiplier = 0.5

		var bar := MeshInstance3D.new()
		var bar_box := BoxMesh.new()
		bar_box.size = Vector3(bar_w * 0.7, mh * 0.8, 0.002)
		bar.mesh = bar_box
		bar.material_override = bar_mat
		bar.transform.origin = Vector3(-mw / 2.0 + 0.004 + float(i) * bar_w + bar_w / 2.0, 0, 0.005)
		parent.add_child(bar)


## Build a monitor/scope display (static — no animation in this version)
static func build_monitor(parent: Node3D, w: float, h: float) -> void:
	# Bezel
	var bezel_mat := StandardMaterial3D.new()
	bezel_mat.albedo_color = Color(0.13, 0.13, 0.13)
	bezel_mat.metallic = 0.4
	bezel_mat.roughness = 0.5

	var bezel := MeshInstance3D.new()
	var bezel_box := BoxMesh.new()
	bezel_box.size = Vector3(w + 0.004, h + 0.004, 0.005)
	bezel.mesh = bezel_box
	bezel.material_override = bezel_mat
	parent.add_child(bezel)

	# Screen
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.08, 0.08, 0.08)
	screen_mat.metallic = 0.1
	screen_mat.roughness = 0.9

	var screen := MeshInstance3D.new()
	var screen_box := BoxMesh.new()
	screen_box.size = Vector3(w, h, 0.001)
	screen.mesh = screen_box
	screen.material_override = screen_mat
	screen.transform.origin = Vector3(0, 0, 0.004)
	parent.add_child(screen)

	# Grid lines (copper)
	var grid_mat := StandardMaterial3D.new()
	grid_mat.albedo_color = Color(0.20, 0.15, 0.10)
	for i in 5:
		var line := MeshInstance3D.new()
		var line_box := BoxMesh.new()
		line_box.size = Vector3(w * 0.9, 0.0004, 0.0005)
		line.mesh = line_box
		line.material_override = grid_mat
		line.transform.origin = Vector3(0, -h * 0.4 + float(i) * h * 0.2, 0.005)
		parent.add_child(line)
	for i in 7:
		var line := MeshInstance3D.new()
		var line_box := BoxMesh.new()
		line_box.size = Vector3(0.0004, h * 0.9, 0.0005)
		line.mesh = line_box
		line.material_override = grid_mat
		line.transform.origin = Vector3(-w * 0.4 + float(i) * w * 0.133, 0, 0.005)
		parent.add_child(line)
