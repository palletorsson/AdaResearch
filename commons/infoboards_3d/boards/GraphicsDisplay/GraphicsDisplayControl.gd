extends Control

## Graphics Display Control - Cycles through visualization graphics
## No text, just animated visualizations

@export var visualization_topic: String = "vectors"
@export var frame_duration: float = 5.0
@export var auto_advance: bool = true

var _current_frame: int = 0
var _time_since_change: float = 0.0
var _vis_control: Control = null

# Visualization types per topic
var _visualizations: Dictionary = {
	"vectors": ["intro", "addition", "multiplication", "forces", "fields"],
	"forces": ["gravity", "friction", "attraction", "wind"],
	"arrays": ["intro", "array_1d", "array_2d", "array_3d", "advanced"],
	"waves": ["unit_circle", "sine_wave", "cosine_wave", "tangent_wave", "combined_waves"],
	"randomness": ["intro", "uniform", "gaussian", "random_walk", "perlin"],
	"procedural": ["intro", "noise_terrain", "lsystem", "dungeon", "advanced"],
	"unitcircle": ["intro"],
	"point": ["origin", "point_example", "point_sizes", "instantiation", "labels", "dynamic"],
	"line": ["basic_line", "drawing_lines", "direction_magnitude", "cylinder_lines", "multiple_lines"],
	"triangle": ["basic_triangle", "triangle_normal", "triangle_area", "triangle_mesh", "triangle_foundation"],
	"quad": ["basic_quad"],
	"cube": ["basic_cube"],
	"sphere": ["basic_sphere", "sphere_tessellation", "sphere_normals"],
	"cylinder": ["basic_cylinder"],
	"torus": ["basic_torus"],
	"polyhedra": ["tetrahedron"],
	"coordinatesystem": ["origin", "axes", "handedness", "positions"]
}

# Scene paths for visualizations
var _vis_scenes: Dictionary = {
	"vectors": "res://commons/infoboards_3d/boards/Vectors/VectorsVisualizationControl.tscn",
	# "forces": "res://commons/infoboards_3d/boards/Forces/ForcesVisualization.gd",  # Requires particle objects, not compatible
	"arrays": "res://commons/infoboards_3d/boards/Arrays/ArrayVisualizationControl.tscn",
	"waves": "res://commons/infoboards_3d/boards/Wave/WaveVisualizationControl.tscn",
	# "randomness": "res://commons/infoboards_3d/boards/Randomness/RandomnessVisualizationControl.tscn",  # Has particle.size issues
	"procedural": "res://commons/infoboards_3d/boards/ProceduralGeneration/ProceduralGenerationVisualizationControl.tscn",
	# "unitcircle": "res://commons/infoboards_3d/boards/UnitCircle/UnitCircleVisualization.gd",  # .gd script issues
	"point": "res://commons/infoboards_3d/boards/Point/PointVisualizationControl.tscn",
	"line": "res://commons/infoboards_3d/boards/Line/LineVisualizationControl.tscn",
	"triangle": "res://commons/infoboards_3d/boards/Triangle/TriangleVisualizationControl.tscn",
	"quad": "res://commons/infoboards_3d/boards/Quad/QuadVisualizationControl.tscn",
	"cube": "res://commons/infoboards_3d/boards/Cube/CubeVisualizationControl.tscn",
	"sphere": "res://commons/infoboards_3d/boards/Sphere/SphereVisualizationControl.tscn",
	"cylinder": "res://commons/infoboards_3d/boards/Cylinder/CylinderVisualizationControl.tscn",
	"torus": "res://commons/infoboards_3d/boards/Torus/TorusVisualizationControl.tscn",
	"polyhedra": "res://commons/infoboards_3d/boards/Polyhedra/PolyhedraVisualizationControl.tscn",
	"coordinatesystem": "res://commons/infoboards_3d/boards/CoordinateSystem/CoordinateSystemVisualizationControl.tscn"
}

func _ready() -> void:
	# Get viewport size for proper sizing
	var viewport = get_viewport()
	var viewport_size = Vector2(viewport.size) if viewport else Vector2(512, 512)

	# Reset anchors and set explicit size
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	anchor_left = 0
	anchor_top = 0
	anchor_right = 0
	anchor_bottom = 0
	position = Vector2.ZERO
	size = viewport_size
	custom_minimum_size = viewport_size

	print("GraphicsDisplayControl._ready: viewport_size=%s, my_size=%s" % [viewport_size, size])

	# Defer loading to ensure proper sizing
	call_deferred("_load_visualization")

func _process(delta: float) -> void:
	if not auto_advance:
		return

	_time_since_change += delta

	if _time_since_change >= frame_duration:
		_time_since_change = 0.0
		_advance_frame()

func _advance_frame() -> void:
	var vis_list = _visualizations.get(visualization_topic, ["intro"])
	_current_frame = (_current_frame + 1) % vis_list.size()
	_load_visualization()

func _load_visualization() -> void:
	# Remove existing visualization
	if _vis_control and is_instance_valid(_vis_control):
		_vis_control.queue_free()
		_vis_control = null

	var vis_list = _visualizations.get(visualization_topic, ["intro"])
	var vis_type = vis_list[_current_frame] if _current_frame < vis_list.size() else "intro"

	# Try to load the visualization scene
	var scene_path = _vis_scenes.get(visualization_topic, "")
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		_create_fallback_visualization(vis_type)
		return

	# Check if it's a .gd script or .tscn scene
	if scene_path.ends_with(".gd"):
		# Load script and create Control with it
		var script = load(scene_path)
		if script:
			_vis_control = Control.new()
			_vis_control.set_script(script)
			if "visualization_type" in _vis_control:
				_vis_control.visualization_type = vis_type
		else:
			_create_fallback_visualization(vis_type)
			return
	else:
		# Load scene normally
		var vis_scene = load(scene_path)
		if vis_scene:
			_vis_control = vis_scene.instantiate()
			if "visualization_type" in _vis_control:
				_vis_control.visualization_type = vis_type
		else:
			_create_fallback_visualization(vis_type)
			return

	# Get actual viewport size for proper sizing
	var viewport = get_viewport()
	var viewport_size = Vector2(viewport.size) if viewport else Vector2(512, 512)

	# Reset anchors to prevent layout issues - use explicit sizing
	_vis_control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_vis_control.anchor_left = 0
	_vis_control.anchor_top = 0
	_vis_control.anchor_right = 0
	_vis_control.anchor_bottom = 0

	# Set explicit size and position
	_vis_control.position = Vector2.ZERO
	_vis_control.size = viewport_size
	_vis_control.custom_minimum_size = viewport_size

	# Add to tree after configuring
	add_child(_vis_control)

	print("GraphicsDisplayControl: Loading %s/%s, viewport=%s, vis_size=%s" % [visualization_topic, vis_type, viewport_size, _vis_control.size])

	_initialize_visualization_data(_vis_control)

func _create_fallback_visualization(vis_type: String) -> void:
	var panel = ColorRect.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.color = Color(0.15, 0.15, 0.2, 1.0)

	var label = Label.new()
	label.text = "%s: %s" % [visualization_topic, vis_type]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 48)
	panel.add_child(label)

	_vis_control = panel
	add_child(_vis_control)

func _initialize_visualization_data(vis_ctrl: Control) -> void:
	if "particles" in vis_ctrl:
		vis_ctrl.particles = []
		var rng = RandomNumberGenerator.new()
		rng.randomize()

		for i in range(5):
			var particle_size = rng.randf_range(5, 15)
			vis_ctrl.particles.append({
				"position": Vector2(rng.randf_range(100, 400), rng.randf_range(100, 400)),
				"velocity": Vector2(rng.randf_range(-50, 50), rng.randf_range(-50, 50)),
				"acceleration": Vector2.ZERO,
				"mass": rng.randf_range(1, 3),
				"size": particle_size,
				"radius": particle_size,  # Same as size for compatibility
				"color": Color(rng.randf_range(0.4, 1.0), rng.randf_range(0.4, 1.0), rng.randf_range(0.4, 1.0))
			})

	if "forces" in vis_ctrl:
		vis_ctrl.forces = []
		vis_ctrl.forces.append({
			"position": Vector2(200, 200),
			"strength": 5000,
			"color": Color(0.2, 0.8, 0.3)
		})
		vis_ctrl.forces.append({
			"position": Vector2(300, 300),
			"strength": -3000,
			"color": Color(0.8, 0.3, 0.2)
		})

	if "velocity_trails" in vis_ctrl and "particles" in vis_ctrl:
		vis_ctrl.velocity_trails = []
		for i in range(vis_ctrl.particles.size()):
			vis_ctrl.velocity_trails.append([])

func set_topic(topic: String) -> void:
	visualization_topic = topic
	_current_frame = 0
	_time_since_change = 0.0
	_load_visualization()

func next_frame() -> void:
	_advance_frame()

func prev_frame() -> void:
	var vis_list = _visualizations.get(visualization_topic, ["intro"])
	_current_frame = (_current_frame - 1 + vis_list.size()) % vis_list.size()
	_load_visualization()
