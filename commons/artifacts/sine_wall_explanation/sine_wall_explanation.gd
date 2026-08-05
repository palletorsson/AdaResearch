# sine_wall_explanation.gd
# Shows ONE wall with animated sine values displayed
# Demonstrates: x_offset = A·sin(f·z + t)
## Visualizes a sine-displaced wall to teach how sinusoidal functions create
## wave-shaped geometry. The wall surface is built segment-by-segment using
## SurfaceTool, with each vertex offset by A·sin(f·z + t). An interactive
## frequency slider lets the learner see how changing f reshapes the wave.
## Key parameters: amplitude controls displacement, frequency sets wave density,
## wave_speed drives animation when enabled.

extends Node3D

class_name SineWallExplanation

## Overall scale of the base plate (meters)

# @identity
# essence: surface(z, y, t) = base + A * sin(freq * z + speed * t) — animated sine wall cross-section
# desire: Examine a labeled sine wall model with adjustable parameters in VR
# critical_parameter: frequency — controls the wave density visible on the wall display
# triggers: VR sliders adjust amplitude, frequency, and wave speed; mesh regenerates per frame
# emerges: understanding what amplitude, frequency, and phase mean on a physical wall surface
# needs: VR sliders [has], mesh display [has]
# relationships: depends on SurfaceTool mesh animation; contrasts with sine_wall_corridor (explanation vs immersion); unlocks wave parameter literacy
# truth: A sine wall is a one-dimensional wave made two-dimensional — displacement as architecture.

@export_range(0.1, 5.0, 0.1) var display_size: float = 1.0
## Height of the sine wall (meters)
@export_range(0.1, 3.0, 0.05) var wall_height: float = 0.5
## Length of the wall along the z-axis (meters)
@export_range(0.1, 5.0, 0.1) var wall_length: float = 0.9
## Peak displacement of the sine wave (meters)
@export_range(0.01, 1.0, 0.01) var amplitude: float = 0.12
## Number of full sine cycles along the wall
@export_range(0.1, 10.0, 0.1) var frequency: float = 2.0
## Animation speed when animate is true (radians per second)
@export_range(0.0, 5.0, 0.1) var wave_speed: float = 0.4
## Whether the wave animates over time
@export var animate: bool = false
## Base color of the wall surface
@export var wall_color: Color = Color(0.8, 0.2, 0.3)
## Color for value markers and the sine curve overlay
@export var value_color: Color = Color(1.0, 1.0, 0.4)

## Minimum frequency the slider can reach
@export_range(0.1, 5.0, 0.1) var frequency_min: float = 0.5
## Maximum frequency the slider can reach
@export_range(1.0, 20.0, 0.5) var frequency_max: float = 6.0

## STAGE-2 DNA — AXIS: WHAT THE WALL IS MADE OF, which is the same as asking what a wave IS.
##
## THE WORD IS BORROWED ON PURPOSE, character for character, from the artifact this case
## exists to explain: `cut` = skin · ribs · strata · lattice, declared by sine_wall_corridor
## (algorithms/wavefunctions/sine_wall/SineWallCorridor.gd). The @identity below already
## names that pairing — "contrasts with sine_wall_corridor (explanation vs immersion)" — so
## the display case and the corridor are two scales of one object, and asking them the same
## question is the whole point. Both compute a sample grid and then decide which cells of it
## get a surface; neither touches the displacement function, the colour ramp or the sample
## positions. The corridor answers at 24 m with your body inside it. This answers at 90 cm
## with the formula written above it.
##
##   skin      every quad emitted, a closed ribbon. The wave as an OBJECT: continuous,
##             seamless, the arithmetic denied. The shipped lineage, byte for byte.
##   ribs      two columns kept of every four — twelve vertical fins with air between them.
##             The wave as a FAMILY OF PROFILES, which is how a wave is actually drawn, and
##             on a case whose job is to show the profile it is arguably the honest reading.
##   strata    the same cut taken horizontally: four bands with gaps, so the wall becomes a
##             stack of contours — the way a curved surface is really fabricated.
##   lattice   both cuts at once: six mullions and four rails standing on the sample lines.
##             The wave as its own measuring grid, with the surface withheld.
##
## THE DEFAULT IS SHORT-CIRCUITED, NOT RECOMPUTED. `skin` (and `ribs`) run at one row per
## column, so `_update_wall_mesh` emits y = 0.0 and y = wall_height exactly as the
## pre-promotion loop did — the same vertices in the same order with the same colours, not
## a subdivision that happens to agree. Only strata and lattice subdivide, because only they
## need somewhere to put a horizontal gap.
@export_enum("skin", "ribs", "strata", "lattice") var cut: String = "skin"
const FABRICS: PackedStringArray = ["skin", "ribs", "strata", "lattice"]

## Vertical subdivisions used ONLY by strata and lattice. At the shipped 0.5 m wall height
## that is 3.1 cm per row, so a two-row band is 6.2 cm and a one-row rail 3.1 cm — tens of
## pixels at the sweep's framing of a 1 m case, not hairlines. The column moduli are in
## SAMPLE units, so a fin stays a fin whatever wall_length is set to.
const WALL_ROWS: int = 16

var _wall_mesh: MeshInstance3D
var _base_plate: MeshInstance3D
var _formula_label: Label3D
var _title_label: Label3D
var _freq_label: Label3D
var _value_labels: Array[Label3D] = []
var _marker_mm: MultiMesh
var _marker_mmi: MultiMeshInstance3D
var _sine_curve: MeshInstance3D
var _freq_slider: Node
var _time: float = 0.0
var _created_nodes: Array[Node] = []

const SEGMENTS = 48
const VALUE_POINTS = 5  # Number of points showing values
var RackTpl = load("res://commons/audio/rack_templates/RackTemplates.gd")


func _ready():
	_read_grid_config_meta()
	_normalise_cut()
	_create_base_plate()
	_create_wall()
	_create_sine_curve()
	_create_value_markers()
	_create_labels()
	_create_reference_plane()
	_create_frequency_slider()
	set_process(animate)


func _create_base_plate():
	_base_plate = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(display_size * 0.6, 0.02, display_size)
	_base_plate.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.06, 0.06, 0.08)
	mat.metallic = 0.2
	mat.roughness = 0.9
	_base_plate.material_override = mat
	_base_plate.position.y = -0.01
	add_child(_base_plate)
	_created_nodes.append(_base_plate)


func _create_wall():
	_wall_mesh = MeshInstance3D.new()
	_wall_mesh.name = "SineWall"
	add_child(_wall_mesh)
	_created_nodes.append(_wall_mesh)
	_update_wall_mesh(0.0)


func _update_wall_mesh(phase: float):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_length = wall_length / 2.0
	var safe_amplitude = maxf(amplitude, 0.0001)
	var rows: int = _cut_rows()

	for i in range(SEGMENTS):
		var z0 = lerp(-half_length, half_length, float(i) / SEGMENTS)
		var z1 = lerp(-half_length, half_length, float(i + 1) / SEGMENTS)

		var t0 = float(i) / SEGMENTS
		var t1 = float(i + 1) / SEGMENTS

		# Sine displacement
		var disp0 = amplitude * sin(frequency * TAU * t0 + phase)
		var disp1 = amplitude * sin(frequency * TAU * t1 + phase)

		var x0 = disp0
		var x1 = disp1

		# Color: bright where displaced most
		var intensity0 = abs(disp0) / safe_amplitude
		var intensity1 = abs(disp1) / safe_amplitude
		var c0 = wall_color.lerp(Color.WHITE, intensity0 * 0.4)
		var c1 = wall_color.lerp(Color.WHITE, intensity1 * 0.4)

		# CUT gate. On "skin" rows is 1 and _cut_keeps is always true, so the two lines
		# below evaluate to 0.0 and wall_height and the vertex stream is emitted in full,
		# exactly as it was before the axis existed.
		for r in range(rows):
			if not _cut_keeps(i, r):
				continue
			var y0: float = wall_height * (float(r) / float(rows))
			var y1: float = wall_height * (float(r + 1) / float(rows))

			# Quad vertices - wall facing +X
			var v0 = Vector3(x0, y0, z0)
			var v1 = Vector3(x1, y0, z1)
			var v2 = Vector3(x1, y1, z1)
			var v3 = Vector3(x0, y1, z0)

			# Face toward viewer (+X direction)
			st.set_color(c0); st.add_vertex(v0)
			st.set_color(c1); st.add_vertex(v1)
			st.set_color(c1); st.add_vertex(v2)

			st.set_color(c0); st.add_vertex(v0)
			st.set_color(c1); st.add_vertex(v2)
			st.set_color(c0); st.add_vertex(v3)

	st.generate_normals()
	_wall_mesh.mesh = st.commit()

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.metallic = 0.15
	mat.roughness = 0.6
	mat.emission_enabled = true
	mat.emission = wall_color * 0.3
	mat.emission_energy_multiplier = 0.4
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_wall_mesh.material_override = mat


func _create_sine_curve():
	_sine_curve = MeshInstance3D.new()
	_sine_curve.name = "SineCurve"
	_sine_curve.position.y = wall_height + 0.02
	add_child(_sine_curve)
	_created_nodes.append(_sine_curve)


func _update_sine_curve(phase: float):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINE_STRIP)

	var half_length = wall_length / 2.0

	for i in range(SEGMENTS + 1):
		var t = float(i) / SEGMENTS
		var z = lerp(-half_length, half_length, t)
		var x = amplitude * sin(frequency * TAU * t + phase)

		st.set_color(value_color)
		st.add_vertex(Vector3(x, 0, z))

	_sine_curve.mesh = st.commit()

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_sine_curve.material_override = mat


func _create_value_markers():
	# MultiMesh for marker spheres (one draw call instead of VALUE_POINTS)
	var sphere := SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04

	_marker_mm = MultiMesh.new()
	_marker_mm.transform_format = MultiMesh.TRANSFORM_3D
	_marker_mm.use_colors = true
	_marker_mm.mesh = sphere
	_marker_mm.instance_count = VALUE_POINTS

	for i in VALUE_POINTS:
		_marker_mm.set_instance_transform(i, Transform3D())
		_marker_mm.set_instance_color(i, value_color)

	_marker_mmi = MultiMeshInstance3D.new()
	_marker_mmi.multimesh = _marker_mm

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = value_color
	mat.emission_energy_multiplier = 0.6
	_marker_mmi.material_override = mat

	add_child(_marker_mmi)
	_created_nodes.append(_marker_mmi)

	# Value labels (pre-sized)
	_value_labels.resize(VALUE_POINTS)
	for i in VALUE_POINTS:
		var label = Label3D.new()
		label.pixel_size = 0.001
		label.font_size = 36
		label.outline_size = 4
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.modulate = value_color
		add_child(label)
		_created_nodes.append(label)
		_value_labels[i] = label


func _update_value_markers(phase: float):
	var half_length = wall_length / 2.0

	for i in range(VALUE_POINTS):
		var t = float(i) / (VALUE_POINTS - 1)
		var z = lerp(-half_length, half_length, t)
		var sine_value = sin(frequency * TAU * t + phase)
		var x = amplitude * sine_value

		# Update marker position via MultiMesh
		var xf := Transform3D()
		xf.origin = Vector3(x, wall_height * 0.5, z)
		_marker_mm.set_instance_transform(i, xf)

		# Color based on sign
		var col = value_color if sine_value >= 0 else Color(0.4, 0.8, 1.0)
		_marker_mm.set_instance_color(i, col)

		# Update label with current sine value
		_value_labels[i].text = "%.2f" % sine_value
		_value_labels[i].position = Vector3(x + 0.08, wall_height * 0.5, z)
		_value_labels[i].modulate = col


func _create_reference_plane():
	var ref_plane = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(0.001, wall_length)
	ref_plane.mesh = plane_mesh
	ref_plane.rotation.x = PI/2
	ref_plane.position = Vector3(0, wall_height / 2, 0)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.4, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ref_plane.material_override = mat
	add_child(ref_plane)
	_created_nodes.append(ref_plane)

	var zero_label = Label3D.new()
	zero_label.pixel_size = 0.001
	zero_label.font_size = 28
	zero_label.text = "x=0"
	zero_label.position = Vector3(-0.05, wall_height + 0.02, -wall_length/2)
	zero_label.modulate = Color(0.5, 0.5, 0.6)
	add_child(zero_label)
	_created_nodes.append(zero_label)


func _create_labels():
	_title_label = Label3D.new()
	_title_label.pixel_size = 0.001
	_title_label.font_size = 52
	_title_label.outline_size = 6
	_title_label.text = "Sine Wall"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.position = Vector3(0, wall_height + 0.22, 0)
	_title_label.modulate = wall_color
	add_child(_title_label)
	_created_nodes.append(_title_label)

	_formula_label = Label3D.new()
	_formula_label.pixel_size = 0.001
	_formula_label.font_size = 48
	_formula_label.outline_size = 6
	_formula_label.text = "x = A·sin(f·z + t)"
	_formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formula_label.position = Vector3(0, wall_height + 0.12, 0)
	_formula_label.modulate = Color(0.9, 0.95, 1.0)
	add_child(_formula_label)
	_created_nodes.append(_formula_label)

	var z_label = Label3D.new()
	z_label.pixel_size = 0.001
	z_label.font_size = 36
	z_label.text = "z (along corridor) →"
	z_label.position = Vector3(0, -0.06, wall_length/2 + 0.08)
	z_label.rotation.x = -PI/4
	z_label.modulate = Color(0.5, 0.7, 0.9)
	add_child(z_label)
	_created_nodes.append(z_label)

	var x_label = Label3D.new()
	x_label.pixel_size = 0.001
	x_label.font_size = 32
	x_label.text = "← x offset →"
	x_label.position = Vector3(amplitude + 0.12, wall_height/2, 0)
	x_label.rotation.y = -PI/2
	x_label.modulate = Color(0.9, 0.6, 0.5)
	add_child(x_label)
	_created_nodes.append(x_label)

	var max_label = Label3D.new()
	max_label.pixel_size = 0.001
	max_label.font_size = 28
	max_label.text = "+A"
	max_label.position = Vector3(amplitude + 0.04, wall_height + 0.04, 0)
	max_label.modulate = value_color
	add_child(max_label)
	_created_nodes.append(max_label)

	var min_label = Label3D.new()
	min_label.pixel_size = 0.001
	min_label.font_size = 28
	min_label.text = "-A"
	min_label.position = Vector3(-amplitude - 0.06, wall_height + 0.04, 0)
	min_label.modulate = Color(0.4, 0.8, 1.0)
	add_child(min_label)
	_created_nodes.append(min_label)


func _create_frequency_slider():
	var norm = inverse_lerp(frequency_min, frequency_max, frequency)
	var panel = RackTpl.create_panel("FREQUENCY", [
		[{"type": "slider_h", "label": "f", "default": norm}],
	])
	panel.position = Vector3(display_size * 0.4, 0.05, wall_length / 2 + 0.1)
	panel.rotation.y = PI * 0.7
	add_child(panel)
	_created_nodes.append(panel)

	_freq_slider = panel.find_child("Param_0", true, false)
	if _freq_slider and _freq_slider.has_signal("slider_moved"):
		_freq_slider.slider_moved.connect(_on_freq_slider_moved)

	_freq_label = Label3D.new()
	_freq_label.pixel_size = 0.001
	_freq_label.font_size = 32
	_freq_label.text = "frequency: %.1f" % frequency
	_freq_label.position = Vector3(display_size * 0.4, 0.15, wall_length / 2 + 0.1)
	_freq_label.rotation.y = PI * 0.7
	_freq_label.modulate = Color(0.7, 0.85, 1.0)
	add_child(_freq_label)
	_created_nodes.append(_freq_label)


func _on_freq_slider_moved(_pos):
	if _freq_slider and _freq_slider.has_method("get_normalized_value"):
		var norm = _freq_slider.get_normalized_value()
		frequency = lerp(frequency_min, frequency_max, norm)
		_refresh_static()
		if _freq_label:
			_freq_label.text = "frequency: %.1f" % frequency


func _process(delta):
	if not animate:
		return
	_time += delta * wave_speed
	_update_wall_mesh(_time)
	_update_sine_curve(_time)
	_update_value_markers(_time)


func _exit_tree():
	if _freq_slider and _freq_slider.has_signal("slider_moved") and _freq_slider.slider_moved.is_connected(_on_freq_slider_moved):
		_freq_slider.slider_moved.disconnect(_on_freq_slider_moved)
	for node in _created_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_created_nodes.clear()


# Public API
func set_amplitude(a: float) -> void:
	amplitude = a
	_refresh_static()

func set_frequency(f: float) -> void:
	frequency = f
	_refresh_static()

func set_wave_speed(s: float) -> void:
	wave_speed = s


func _refresh_static() -> void:
	if _wall_mesh == null or _sine_curve == null or _marker_mm == null:
		return
	_time = 0.0
	_update_wall_mesh(_time)
	_update_sine_curve(_time)
	_update_value_markers(_time)


# ── CUT ──────────────────────────────────────────────────────────────────────────────────
# Appended LAST. Nothing here touches the displacement function, the colour ramp, the sine
# curve overlay, the value markers or the frequency slider — only which cells of the sample
# grid are given a surface.

## Snapped once, in _ready, so every downstream match sees a legal value and a typo in a
## map token renders the shipped wall rather than nothing.
func _normalise_cut() -> void:
	var c: String = str(cut).strip_edges().to_lower()
	cut = c if FABRICS.has(c) else "skin"


## The grid sets config_<key> metadata on the instantiated root BEFORE it calls
## apply_grid_config(), so reading it here means the wall is built once, correctly, instead
## of built as `skin` and then rebuilt. All six existing placements carry no such meta and
## fall straight through.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_cut"):
			cut = str(node.get_meta("config_cut"))
			return
		node = node.get_parent()


## One row per column unless the value needs a horizontal gap. This is the short-circuit
## that makes the default byte-identical rather than merely equivalent.
func _cut_rows() -> int:
	if cut == "strata" or cut == "lattice":
		return WALL_ROWS
	return 1


## Moduli in SAMPLE units. At the shipped 48 columns \ 0.9 m and 16 rows \ 0.5 m: twelve
## fins 3.8 cm wide, four bands 6.3 cm tall, and a cage of six 3.8 cm mullions crossing four
## 3.1 cm rails.
func _cut_keeps(col: int, row: int) -> bool:
	match cut:
		"ribs":
			return (col % 4) < 2
		"strata":
			return (row % 4) < 2
		"lattice":
			return ((col % 8) < 2) or ((row % 4) < 1)
		_:
			return true


## Config from map_data.json tokens:  sine_wall_explanation#cut:ribs
##
## GUARDED ON CHANGE. All six existing placements arrive here with no keys at all, and the
## grid reaches this twice for one placement; rebuilding unguarded would re-commit the mesh
## on both of those, for nothing. Before _ready has run there is no mesh to rebuild, so the
## value is only recorded and _ready builds with it — which is also the path the capture
## harness takes when it sets the export directly.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("cut"):
		return
	if _wall_mesh == null:
		cut = str(config_data["cut"])
		return
	var want: String = str(config_data["cut"]).strip_edges().to_lower()
	if not FABRICS.has(want) or want == cut:
		return
	cut = want
	_update_wall_mesh(_time)
