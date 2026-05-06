# WalkgridShowcase.gd - Gallery of all walkable mathematical spaces
# Creates a grid of all 20 spaces for visual comparison and testing.
# Each space is smaller (10×10) with a label floating above it.
#
# Drop this into any scene to see all terrain types at a glance.

extends Node3D
class_name WalkgridShowcase

@export var columns: int = 5
@export var cell_size: float = 14.0       # Spacing between spaces
@export var space_size: Vector2 = Vector2(12, 12)  # Each space's footprint
@export var resolution: int = 50          # Lower res for gallery (20 spaces)
@export var height_scale: float = 1.5
@export var use_height_shader: bool = true  # Apply shared shader to all
@export var show_labels: bool = true

# All space configs: [registry_key, display_name, extra_config_func]
const GALLERY_ORDER = [
	# Core
	["sine", "Sine Wave"],
	["noise", "Fractal Noise"],
	["voronoi", "Voronoi Cells"],
	["random", "Pure Random"],
	["fractal", "Diamond-Square"],
	# Cellular
	["worley", "Worley Noise"],
	["cellular_automata", "Cellular Automata"],
	["reaction_diffusion", "Reaction Diffusion"],
	# Math Structures
	["mandelbrot", "Mandelbrot Set"],
	["lsystem", "L-System Tree"],
	["wave_interference", "Wave Interference"],
	["ridged_noise", "Ridged Mountains"],
	["spherical_harmonics", "Spherical Harmonics"],
	["flow_field", "Flow Field"],
	# Terrain
	["domain_warp", "Domain Warp"],
	["erosion", "Hydraulic Erosion"],
	# Topology
	["mobius", "Möbius Strip"],
	["torus", "Torus"],
	["hyperbolic", "Hyperbolic Space"],
	# Meta
	["knowledge", "Knowledge Terrain"],
]

var spaces: Array[Node3D] = []

func _ready():
	_create_gallery()

func _create_gallery():
	for i in range(GALLERY_ORDER.size()):
		var entry = GALLERY_ORDER[i]
		var key: String = entry[0]
		var label_text: String = entry[1]

		var col = i % columns
		var row = i / columns
		var pos = Vector3(col * cell_size, 0, row * cell_size)

		var space = _create_space(key)
		if space == null:
			continue

		space.position = pos
		# Override size and resolution for gallery
		if space.has_method("set") or true:
			space.set("space_size", space_size)
			space.set("resolution", resolution)
			space.set("height_scale", height_scale)

		# Disable animation for gallery (performance with 20 spaces)
		if space.has_method("set"):
			if "enable_animation" in space:
				space.set("enable_animation", false)

		add_child(space)
		spaces.append(space)

		# Apply shared shader
		if use_height_shader:
			# Wait for space to generate, then apply shader
			space.ready.connect(_apply_shader_to.bind(space))

		# Add label
		if show_labels:
			_add_label(pos, label_text, i)

	print("WalkgridShowcase: Created %d spaces in %dx%d grid" % [
		spaces.size(), columns, ceili(float(GALLERY_ORDER.size()) / columns)
	])

func _create_space(registry_key: String) -> Node3D:
	if not TopologyManager.SPACE_REGISTRY.has(registry_key):
		push_warning("WalkgridShowcase: Unknown key '%s'" % registry_key)
		return null

	var entry = TopologyManager.SPACE_REGISTRY[registry_key]
	var script_path: String = entry[0]
	var display_name: String = entry[1]

	var script = load(script_path)
	if script == null:
		push_warning("WalkgridShowcase: Could not load '%s'" % script_path)
		return null

	var space = script.new()
	space.name = display_name
	return space

func _apply_shader_to(space: Node3D):
	if space is TopologySpace:
		(space as TopologySpace).apply_height_shader(
			Color(0.12, 0.08, 0.18),   # Deep purple valleys
			Color(0.35, 0.4, 0.45),     # Steel mid
			Color(0.95, 0.88, 0.72),    # Warm peaks
			-height_scale,
			height_scale * 2.0,
			true,                        # Show contours
			0.4                          # Contour spacing
		)

func _add_label(pos: Vector3, text: String, index: int):
	var label = Label3D.new()
	label.text = text
	label.font_size = 32
	label.position = pos + Vector3(space_size.x / 2.0, height_scale * 2.5, -1.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color.WHITE
	label.outline_size = 6
	label.outline_modulate = Color(0, 0, 0, 0.8)
	add_child(label)

# ── Public API ───────────────────────────────────────────────

func get_space_by_key(key: String) -> Node3D:
	for i in range(GALLERY_ORDER.size()):
		if GALLERY_ORDER[i][0] == key:
			if i < spaces.size():
				return spaces[i]
	return null

func regenerate_all():
	for space in spaces:
		if space.has_method("generate_space"):
			space.generate_space()

func teleport_to(key: String) -> Vector3:
	for i in range(GALLERY_ORDER.size()):
		if GALLERY_ORDER[i][0] == key:
			var col = i % columns
			var row = i / columns
			return Vector3(col * cell_size + space_size.x / 2.0, height_scale + 2.0, row * cell_size + space_size.y / 2.0)
	return Vector3.ZERO
