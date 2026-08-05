# sine_space_explanation.gd
# Explains the TOPOLOGY of sine space - the wave surface mesh
# Shows: y = A·sin(f·x)·cos(f·z) creating the wave terrain

extends Node3D

class_name SineSpaceExplanation


# @identity
# essence: z(x,y,t) = A * sin(freq * x + speed * t) * sin(freq * y + speed * t)
# desire: Examine a miniature animated sine surface with labeled parameters you can adjust
# critical_parameter: frequency — controls the wave density visible on the explanation display
# triggers: VR sliders adjust amplitude, frequency, and wave speed in real-time
# emerges: understanding through control — seeing how each parameter deforms the surface
# needs: VR sliders [has], display surface [has]
# relationships: depends on SurfaceTool mesh regeneration; contrasts with sine_space (explanation vs immersion); unlocks sine surface parameter literacy
# truth: Understanding a wave means knowing what each parameter does to the shape.

# --- DNA (stage 2, promoted 2026-08-05) ---------------------------------------
# crossing — how the two perpendicular sine directions MEET on this display.
#
# The surface is the entire content of the case, and until now its equation was the
# one thing no map could reach: _get_height() inlined a single product and the plate
# beneath it read "y = sin(x)·cos(z)" as though that were the only way two waves can
# cross. It is one answer of four, and the four look nothing alike in a still — a
# field of bumps, a run of diagonal ridges, concentric rings, or a plain corrugation
# that never crosses anything at all.
#
#   product  the shipped egg-crate, sin(x)·cos(z). Interference as MULTIPLICATION: a
#            crest survives only where both factors crest, so either factor's zero
#            line cuts the whole surface flat and the relief comes out as bumps in a
#            grid. The default, byte for byte.
#   sum      superposition instead, ½(sin(x) + cos(z)). This is what two waves
#            meeting actually does in a medium, and it gives DIAGONAL RIDGES — the
#            grid of bumps dissolves, because a crest and a trough now cancel to
#            zero rather than to a saddle.
#   radial   one wave in the DISTANCE from the origin. x and z stop being
#            independent terms and the display stops being a product of two 1-D
#            waves at all: a ripple tank, concentric, with no axes in it.
#   single   sin(x) alone, the z term withheld. A corrugation — and the measure of
#            how much of the shipped relief the second factor was doing.
#
# The word and its four values are sine_space's, character for character
# (algorithms/wavefunctions/sine_space/SineSpace.gd:20). That artifact is the
# IMMERSION twin of this EXPLANATION twin — the @identity line above already names
# the pair — so the same question is now asked of the surface you stand on and of
# the surface you look at, and the two can be compared instead of merely related.
#
# THE CAPTION MOVES WITH THE SURFACE. This object's whole job is to explain, so a
# formula plate still reading sin(x)·cos(z) over a ripple tank would be the axis
# making the artifact lie. _formula_text() and _topology_text() branch as well, and
# both return the shipped strings byte for byte at "product".
@export_enum("product", "sum", "radial", "single") var crossing: String = "product"
const CROSSINGS: PackedStringArray = ["product", "sum", "radial", "single"]

@export var display_size: float = 1.0
@export var grid_resolution: int = 24
@export var amplitude: float = 0.12
@export var frequency: float = 1.5
@export var wave_speed: float = 0.3
@export var animate: bool = false
@export var surface_color: Color = Color(0.2, 0.5, 0.8)
@export var wireframe_color: Color = Color(0.4, 0.8, 1.0)

var _surface_mesh: MeshInstance3D
var _wireframe_mesh: MeshInstance3D
var _base_plate: MeshInstance3D
var _formula_label: Label3D
var _title_label: Label3D
var _topo_label: Label3D
var _time: float = 0.0


func _ready():
	_read_dna_meta()
	_create_base_plate()
	_create_surface()
	_create_wireframe()
	_create_labels()
	_create_axis_markers()
	set_process(animate)


## The grid sets `config_*` metadata BEFORE add_child, so this runs ahead of the
## build and the very first mesh is already the one the map asked for. An unknown
## word keeps the default; no metadata at all means no change, which is the case
## for every one of the four existing placements. The DNA sweep takes the other
## route and sets the @export itself, also before add_child — both land here.
func _read_dna_meta() -> void:
	if has_meta("config_crossing"):
		var c: String = str(get_meta("config_crossing")).strip_edges().to_lower()
		crossing = c if CROSSINGS.has(c) else crossing


func _create_base_plate():
	_base_plate = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(display_size * 1.1, 0.02, display_size * 1.1)
	_base_plate.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.05, 0.07)
	mat.metallic = 0.2
	mat.roughness = 0.9
	_base_plate.material_override = mat
	_base_plate.position.y = -amplitude - 0.02
	add_child(_base_plate)


func _create_surface():
	_surface_mesh = MeshInstance3D.new()
	_surface_mesh.name = "SineSurface"
	add_child(_surface_mesh)
	
	_update_surface_mesh(0.0)


func _create_wireframe():
	_wireframe_mesh = MeshInstance3D.new()
	_wireframe_mesh.name = "Wireframe"
	add_child(_wireframe_mesh)
	
	_update_wireframe_mesh(0.0)


func _update_surface_mesh(phase: float):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var half = display_size * 0.45
	var step = (half * 2) / grid_resolution
	
	for zi in range(grid_resolution):
		for xi in range(grid_resolution):
			var x0 = -half + xi * step
			var z0 = -half + zi * step
			var x1 = x0 + step
			var z1 = z0 + step
			
			# Calculate heights at corners using sin(x)*cos(z)
			var y00 = _get_height(x0, z0, phase)
			var y10 = _get_height(x1, z0, phase)
			var y01 = _get_height(x0, z1, phase)
			var y11 = _get_height(x1, z1, phase)
			
			var v00 = Vector3(x0, y00, z0)
			var v10 = Vector3(x1, y10, z0)
			var v01 = Vector3(x0, y01, z1)
			var v11 = Vector3(x1, y11, z1)
			
			# Color based on height
			var c00 = _height_to_color(y00)
			var c10 = _height_to_color(y10)
			var c01 = _height_to_color(y01)
			var c11 = _height_to_color(y11)
			
			# Quad as two triangles
			st.set_color(c00); st.add_vertex(v00)
			st.set_color(c10); st.add_vertex(v10)
			st.set_color(c11); st.add_vertex(v11)
			
			st.set_color(c00); st.add_vertex(v00)
			st.set_color(c11); st.add_vertex(v11)
			st.set_color(c01); st.add_vertex(v01)
	
	st.generate_normals()
	_surface_mesh.mesh = st.commit()
	
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.metallic = 0.3
	mat.roughness = 0.5
	mat.emission_enabled = true
	mat.emission = surface_color * 0.2
	mat.emission_energy_multiplier = 0.3
	_surface_mesh.material_override = mat


func _update_wireframe_mesh(phase: float):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	
	var half = display_size * 0.45
	var step = (half * 2) / grid_resolution
	
	# Draw grid lines in X direction
	for zi in range(grid_resolution + 1):
		var z = -half + zi * step
		for xi in range(grid_resolution):
			var x0 = -half + xi * step
			var x1 = x0 + step
			var y0 = _get_height(x0, z, phase)
			var y1 = _get_height(x1, z, phase)
			
			st.set_color(wireframe_color)
			st.add_vertex(Vector3(x0, y0 + 0.002, z))
			st.add_vertex(Vector3(x1, y1 + 0.002, z))
	
	# Draw grid lines in Z direction
	for xi in range(grid_resolution + 1):
		var x = -half + xi * step
		for zi in range(grid_resolution):
			var z0 = -half + zi * step
			var z1 = z0 + step
			var y0 = _get_height(x, z0, phase)
			var y1 = _get_height(x, z1, phase)
			
			st.set_color(wireframe_color)
			st.add_vertex(Vector3(x, y0 + 0.002, z0))
			st.add_vertex(Vector3(x, y1 + 0.002, z1))
	
	_wireframe_mesh.mesh = st.commit()
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_wireframe_mesh.material_override = mat


func _get_height(x: float, z: float, phase: float) -> float:
	# The sine space formula: y = A * sin(f*x + φ) * cos(f*z + φ)
	#
	# `a` and `b` are the two arguments the shipped one-liner already computed, in
	# the order it computed them, so the "product" branch below is that line and not
	# a re-derivation of it: same terms, same operations, same result to the bit.
	var a: float = frequency * x * TAU / display_size + phase
	var b: float = frequency * z * TAU / display_size + phase * 0.7
	match crossing:
		"sum":
			return amplitude * (sin(a) + cos(b)) * 0.5
		"radial":
			return amplitude * sin(frequency * sqrt(x * x + z * z) * TAU / display_size + phase)
		"single":
			return amplitude * sin(a)
		_:
			return amplitude * sin(a) * cos(b)


## The plate under the surface. Every branch stays inside [-A, A], so _height_to_color()
## keeps its full range and the colour ramp reads the same way for all four.
func _formula_text() -> String:
	match crossing:
		"sum":
			return "y = ½(sin(x) + cos(z))"
		"radial":
			return "y = sin(√(x²+z²))"
		"single":
			return "y = sin(x)"
		_:
			return "y = sin(x)·cos(z)"


## The sentence that says what kind of thing the relief IS. The default returns the
## shipped two lines unchanged.
func _topology_text() -> String:
	match crossing:
		"sum":
			return "Superposition: diagonal ridges\nwhere two waves add, not multiply"
		"radial":
			return "One wave in the radius:\nconcentric rings, no axes left"
		"single":
			return "One wave only: a corrugation\nwith nothing to cross it"
		_:
			return "Wave surface: peaks & valleys\nfrom perpendicular sine waves"


## Both captions, re-read from the axis. Called only when `crossing` changed.
func _refresh_captions() -> void:
	if _formula_label != null and is_instance_valid(_formula_label):
		_formula_label.text = _formula_text()
	if _topo_label != null and is_instance_valid(_topo_label):
		_topo_label.text = _topology_text()


func _height_to_color(y: float) -> Color:
	var t = (y / amplitude + 1.0) * 0.5  # 0 to 1
	var low_color = Color(0.1, 0.2, 0.4)
	var mid_color = surface_color
	var high_color = Color(0.8, 0.9, 1.0)
	
	if t < 0.5:
		return low_color.lerp(mid_color, t * 2)
	else:
		return mid_color.lerp(high_color, (t - 0.5) * 2)


func _create_labels():
	# Title
	_title_label = Label3D.new()
	_title_label.pixel_size = 0.001
	_title_label.font_size = 52
	_title_label.outline_size = 6
	_title_label.text = "Sine Space Topology"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.position = Vector3(0, amplitude + 0.28, 0)
	_title_label.modulate = wireframe_color
	add_child(_title_label)
	
	# Formula
	_formula_label = Label3D.new()
	_formula_label.pixel_size = 0.001
	_formula_label.font_size = 48
	_formula_label.outline_size = 6
	_formula_label.text = _formula_text()
	_formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formula_label.position = Vector3(0, amplitude + 0.18, 0)
	_formula_label.modulate = Color(0.9, 0.95, 1.0)
	add_child(_formula_label)
	
	# Explanation - topology description
	var topo_label = Label3D.new()
	topo_label.pixel_size = 0.001
	topo_label.font_size = 32
	topo_label.outline_size = 4
	topo_label.text = _topology_text()
	topo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	topo_label.position = Vector3(0, -amplitude - 0.12, display_size/2 + 0.08)
	topo_label.rotation.x = -PI/4
	topo_label.modulate = Color(0.7, 0.8, 0.9)
	add_child(topo_label)
	_topo_label = topo_label


func _create_axis_markers():
	# X-axis
	var x_label = Label3D.new()
	x_label.pixel_size = 0.001
	x_label.font_size = 40
	x_label.text = "x →"
	x_label.position = Vector3(display_size * 0.5, -amplitude, 0)
	x_label.modulate = Color(1.0, 0.5, 0.3)
	add_child(x_label)
	
	# Z-axis
	var z_label = Label3D.new()
	z_label.pixel_size = 0.001
	z_label.font_size = 40
	z_label.text = "z →"
	z_label.position = Vector3(0, -amplitude, display_size * 0.5)
	z_label.modulate = Color(0.3, 0.5, 1.0)
	add_child(z_label)
	
	# Y-axis (height)
	var y_label = Label3D.new()
	y_label.pixel_size = 0.001
	y_label.font_size = 36
	y_label.text = "↑ height"
	y_label.position = Vector3(-display_size * 0.52, amplitude * 0.5, 0)
	y_label.rotation.y = PI/2
	y_label.modulate = Color(0.3, 0.9, 0.4)
	add_child(y_label)


func _process(delta):
	if not animate:
		return
	_time += delta * wave_speed
	_update_surface_mesh(_time)
	_update_wireframe_mesh(_time)


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
	if _surface_mesh == null or _wireframe_mesh == null:
		return
	_time = 0.0
	_update_surface_mesh(_time)
	_update_wireframe_mesh(_time)

func apply_grid_config(config_data: Dictionary):
	# The generic setter is the SHIPPED behaviour and is left exactly as it was —
	# it assigns and redraws nothing, which is what the four existing placements
	# have always got. Only the DNA axis gets a redraw, and only under two guards:
	# `crossing` must actually have CHANGED, and the meshes must already exist
	# (_refresh_static returns early before _ready has built them). A bare map token
	# sends no config at all — GridInteractablesComponent skips this call on an empty
	# dictionary — so none of the four placements reaches even the comparison.
	var before: String = crossing
	for key in config_data:
		if key in self:
			set(key, config_data[key])
	if crossing != before:
		var c: String = str(crossing).strip_edges().to_lower()
		crossing = c if CROSSINGS.has(c) else before
		if crossing != before:
			_refresh_static()
			_refresh_captions()
