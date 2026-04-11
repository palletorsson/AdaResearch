## ShaderBibliotek
## A freestanding wall of cubes — each cube showcases a different shader from
## across the project. Like a physical library card catalog of substrates.
## Default: 4 wide × 3 high over ground. Each cube has a label underneath.
##
## Config keys:
##   columns         – cubes across (default 4)
##   rows            – cubes high (default 3)
##   cube_size       – size of each cube (default 0.8)
##   gap             – spacing between cubes (default 0.15)
##   shader_set      – comma-separated shader names (overrides default)
##   emission        – emission strength (default 0.6)
##   spin            – rotate cubes slowly (default true)
##   label_visible   – show shader names (default true)

# @identity
# essence: for i in N: wall[i] = load_shader(catalog[i]) — a physical library of computational substrates
# desire: to stand before a wall where every cube is a different world — voronoi, rothko, velvet, slime — and understand that "material" is just a function from position to color
# critical_parameter: the catalog itself — which 12 shaders stand for all 218? curation IS the argument
# triggers: _ready builds the wall, loads one shader per cube, adds labels and slow spin
# emerges: the wall becomes a periodic table of visual computation — each cube a different element
# relationships: substrates are what maps are MADE OF; this artifact indexes them like a dictionary indexes words
# truth: a substrate is not decoration — it is the physics of a surface, the rules that light follows when it meets matter

extends Node3D
class_name ShaderBibliotek

@export var columns: int = 4
@export var rows: int = 3
@export var cube_size: float = 0.8
@export var gap: float = 0.15
@export var emission: float = 0.6
@export var spin: bool = true
@export var label_visible: bool = true

# Curated default set — self-contained shaders (no texture dependencies)
# Organized by substrate family: pattern, organic, material, art, math, effect
var _shader_catalog: Array[Dictionary] = [
	# Row 1: Pattern substrates
	{"path": "res://commons/resourses/shaders/voronoiShader.gdshader", "name": "Voronoi", "family": "cellular"},
	{"path": "res://commons/resourses/shaders/TruchetFloor.gdshader", "name": "Truchet", "family": "tiling"},
	{"path": "res://commons/resourses/shaders/tartanshader.gdshader", "name": "Tartan", "family": "weave"},
	{"path": "res://commons/resourses/shaders/DiscoGrid.gdshader", "name": "Disco Grid", "family": "grid"},
	# Row 2: Organic / material substrates
	{"path": "res://algorithms/shaders/queer_materials/fur_velvet.gdshader", "name": "Fur Velvet", "family": "material"},
	{"path": "res://commons/resourses/shaders/slime.gdshader", "name": "Slime", "family": "organic"},
	{"path": "res://commons/resourses/shaders/pearlescent.gdshader", "name": "Pearlescent", "family": "material"},
	{"path": "res://algorithms/shaders/queer_collection_2/oil_slick_latex.gdshader", "name": "Oil Slick", "family": "material"},
	# Row 3: Art / math substrates
	{"path": "res://commons/resourses/shaders/rothko.gdshader", "name": "Rothko", "family": "art"},
	{"path": "res://commons/resourses/shaders/coffeeswirl.gdshader", "name": "Coffee Swirl", "family": "fluid"},
	{"path": "res://commons/resourses/shaders/reaction_diffusion.gdshader", "name": "Reaction-Diffusion", "family": "emergence"},
	{"path": "res://commons/resourses/shaders/randomgridshader.gdshader", "name": "Random Grid", "family": "noise"},
]

var _cube_nodes: Array[MeshInstance3D] = []
var _spin_speed: float = 0.15

func _ready() -> void:
	_build_wall()
	_build_backplate()
	_build_title()

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("columns"):
		columns = clampi(int(config_data["columns"]), 1, 10)
	if config_data.has("rows"):
		rows = clampi(int(config_data["rows"]), 1, 6)
	if config_data.has("cube_size"):
		cube_size = clampf(float(config_data["cube_size"]), 0.3, 2.0)
	if config_data.has("gap"):
		gap = clampf(float(config_data["gap"]), 0.0, 1.0)
	if config_data.has("emission"):
		emission = clampf(float(config_data["emission"]), 0.0, 3.0)
	if config_data.has("spin"):
		spin = str(config_data["spin"]).to_lower() != "false"
	if config_data.has("label_visible"):
		label_visible = str(config_data["label_visible"]).to_lower() != "false"
	if config_data.has("shader_set"):
		_parse_shader_set(str(config_data["shader_set"]))

func _parse_shader_set(csv: String) -> void:
	_shader_catalog.clear()
	for s in csv.split(","):
		var trimmed := s.strip_edges()
		if trimmed != "":
			# Try commons/resourses/shaders first, then algorithms/shaders
			var path := "res://commons/resourses/shaders/%s.gdshader" % trimmed
			_shader_catalog.append({"path": path, "name": trimmed, "family": "custom"})

func _build_wall() -> void:
	var step := cube_size + gap
	var total_w := float(columns) * step - gap
	var x_offset := -total_w * 0.5 + cube_size * 0.5

	for idx in range(mini(_shader_catalog.size(), columns * rows)):
		var col := idx % columns
		var row := idx / columns
		var x := x_offset + float(col) * step
		var y := cube_size * 0.5 + float(row) * step + 0.05  # Slight lift off ground

		# Build cube
		var cube := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * cube_size
		cube.mesh = box
		cube.name = "Cube_%d" % idx
		cube.position = Vector3(x, y, 0.0)

		# Load and apply shader
		var entry: Dictionary = _shader_catalog[idx]
		var shader := load(entry["path"]) as Shader
		if shader:
			var mat := ShaderMaterial.new()
			mat.shader = shader
			_try_set(mat, "emission_strength", emission)
			_try_set(mat, "emission_energy", emission)
			_try_set(mat, "u_resolution", Vector2(256, 256))
			cube.material_override = mat
		else:
			# Fallback: colored cube with label
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.3, 0.0, 0.1)
			mat.emission_enabled = true
			mat.emission = Color(0.5, 0.0, 0.2)
			mat.emission_energy_multiplier = emission
			cube.material_override = mat
			print("[ShaderBibliotek] Failed to load: %s" % entry["path"])

		add_child(cube)
		_cube_nodes.append(cube)

		# Add collision for presence
		var body := StaticBody3D.new()
		var col_shape := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3.ONE * cube_size
		col_shape.shape = shape
		body.add_child(col_shape)
		cube.add_child(body)

		# Label below cube
		if label_visible:
			var label := Label3D.new()
			label.text = entry["name"]
			label.font_size = 48
			label.pixel_size = 0.002
			label.position = Vector3(0, -cube_size * 0.5 - 0.08, cube_size * 0.5 + 0.01)
			label.modulate = Color(0.8, 0.8, 0.9)
			label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
			label.outline_size = 8
			cube.add_child(label)

			# Family tag (smaller, above name)
			var tag := Label3D.new()
			tag.text = entry["family"]
			tag.font_size = 32
			tag.pixel_size = 0.0015
			tag.position = Vector3(0, -cube_size * 0.5 - 0.17, cube_size * 0.5 + 0.01)
			tag.modulate = Color(0.5, 0.5, 0.6, 0.7)
			tag.outline_modulate = Color(0.0, 0.0, 0.0, 0.5)
			tag.outline_size = 6
			cube.add_child(tag)

func _build_backplate() -> void:
	# Dark backplate behind the cubes
	var step := cube_size + gap
	var total_w := float(columns) * step + gap * 2
	var total_h := float(rows) * step + gap * 2
	var plate := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(total_w, total_h, 0.05)
	plate.mesh = box
	plate.position = Vector3(0, total_h * 0.5 - gap, -cube_size * 0.5 - 0.03)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.04, 0.04, 0.06)
	mat.roughness = 0.9
	plate.material_override = mat
	plate.name = "Backplate"
	add_child(plate)

func _build_title() -> void:
	var step := cube_size + gap
	var total_h := float(rows) * step
	var title := Label3D.new()
	title.text = "SUBSTRATE BIBLIOTEK"
	title.font_size = 72
	title.pixel_size = 0.003
	title.position = Vector3(0, total_h + 0.15, cube_size * 0.5 + 0.01)
	title.modulate = Color(0.9, 0.85, 1.0)
	title.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	title.outline_size = 10
	title.name = "Title"
	add_child(title)

func _process(delta: float) -> void:
	if not spin:
		return
	for cube in _cube_nodes:
		cube.rotate_y(_spin_speed * delta)

func _try_set(mat: ShaderMaterial, param_name: String, value: Variant) -> void:
	if mat.shader:
		for uniform in mat.shader.get_shader_uniform_list():
			if uniform["name"] == param_name:
				mat.set_shader_parameter(param_name, value)
				return
