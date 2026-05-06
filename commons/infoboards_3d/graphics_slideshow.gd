extends Node3D

## Graphics Slideshow - Cycles through visualization frames every 5 seconds
## No interaction, pure visual display

@export var frame_duration: float = 5.0  # Seconds per frame
@export var visualization_topic: String = "vectors"  # vectors, forces, arrays, waves, randomness, procedural
@export var auto_advance: bool = true

var _current_frame: int = 0
var _time_since_change: float = 0.0
var _vis_control: Control = null
var _viewport: SubViewport = null
var _sprite: Sprite3D = null

# Visualization types per topic
var _visualizations: Dictionary = {
	"vectors": ["intro", "addition", "multiplication", "forces", "fields"],
	"forces": ["gravity", "friction", "attraction", "wind"],
	"arrays": ["intro", "array_1d", "array_2d", "array_3d", "advanced"],
	"waves": ["unit_circle", "sine_wave", "cosine_wave", "tangent_wave", "combined_waves"],
	"randomness": ["intro", "uniform", "gaussian", "random_walk", "perlin"],
	"procedural": ["intro", "noise_terrain", "lsystem", "dungeon", "advanced"]
}

# Scene paths for visualizations
var _vis_scenes: Dictionary = {
	"vectors": "res://commons/infoboards_3d/boards/Vectors/VectorsVisualizationControl.tscn",
	"forces": "res://commons/infoboards_3d/boards/Forces/ForcesVisualization.gd",
	"arrays": "res://commons/infoboards_3d/boards/Arrays/ArrayVisualizationControl.tscn",
	"waves": "res://commons/infoboards_3d/boards/Wave/WaveVisualizationControl.tscn",
	"randomness": "res://commons/infoboards_3d/boards/Randomness/RandomnessVisualizationControl.tscn",
	"procedural": "res://commons/infoboards_3d/boards/ProceduralGeneration/ProceduralGenerationVisualizationControl.tscn"
}

func _ready() -> void:
	_setup_display()
	_load_visualization()

func _setup_display() -> void:
	# Create SubViewport for 2D rendering
	_viewport = SubViewport.new()
	_viewport.name = "VisualizationViewport"
	_viewport.size = Vector2i(512, 512)
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	# Create a root Control to anchor content properly
	var root_control = Control.new()
	root_control.name = "RootControl"
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.size = Vector2(512, 512)
	_viewport.add_child(root_control)

	# Create Sprite3D to display the viewport texture
	_sprite = Sprite3D.new()
	_sprite.name = "DisplaySprite"
	_sprite.pixel_size = 0.002  # Scale to fit ~1 unit square
	_sprite.centered = false  # Align to corner instead of center
	_sprite.offset = Vector2(-256, -256)  # Offset to center the display
	_sprite.texture = _viewport.get_texture()

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = _viewport.get_texture()
	_sprite.material_override = material

	add_child(_sprite)

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

func _get_root_control() -> Control:
	# Get the root control we created in _setup_display
	return _viewport.get_node_or_null("RootControl")

func _load_visualization() -> void:
	# Remove existing visualization
	if _vis_control and is_instance_valid(_vis_control):
		_vis_control.queue_free()
		_vis_control = null

	var vis_list = _visualizations.get(visualization_topic, ["intro"])
	var vis_type = vis_list[_current_frame] if _current_frame < vis_list.size() else "intro"

	var root = _get_root_control()
	if not root:
		push_error("GraphicsSlideshow: RootControl not found")
		return

	# Try to load the visualization scene
	var scene_path = _vis_scenes.get(visualization_topic, "")
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		print("GraphicsSlideshow: Visualization scene not found: %s" % scene_path)
		_create_fallback_visualization(vis_type)
		return

	var vis_scene = load(scene_path)
	if vis_scene:
		_vis_control = vis_scene.instantiate()
		if _vis_control.has_method("set") and "visualization_type" in _vis_control:
			_vis_control.visualization_type = vis_type
		_vis_control.set_anchors_preset(Control.PRESET_FULL_RECT)
		_vis_control.size = Vector2(512, 512)
		_vis_control.position = Vector2.ZERO
		root.add_child(_vis_control)
		_initialize_visualization_data(_vis_control)
		print("GraphicsSlideshow: Loaded visualization '%s' frame '%s'" % [visualization_topic, vis_type])
	else:
		_create_fallback_visualization(vis_type)

func _create_fallback_visualization(vis_type: String) -> void:
	var root = _get_root_control()
	if not root:
		return

	# Create a simple colored rectangle as fallback
	var panel = ColorRect.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.size = Vector2(512, 512)
	panel.position = Vector2.ZERO
	panel.color = Color(0.2, 0.3, 0.4, 1.0)

	var label = Label.new()
	label.text = "%s: %s" % [visualization_topic, vis_type]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 32)
	panel.add_child(label)

	_vis_control = panel
	root.add_child(_vis_control)

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

func get_current_frame() -> int:
	return _current_frame

func get_total_frames() -> int:
	return _visualizations.get(visualization_topic, ["intro"]).size()

# Grid system configuration
func apply_grid_config(config_data: Dictionary) -> void:
	print("GraphicsSlideshow: Applying grid config: %s" % config_data)

	# Check for topic configuration
	if config_data.has("topic"):
		var topic = str(config_data.topic).to_lower()
		if topic in _visualizations:
			set_topic(topic)
			print("  -> Set topic: %s" % topic)

	# Check for shorthand topic (e.g., graphics_slideshow#vectors)
	for key in config_data.keys():
		var key_str = str(key).to_lower()
		if key_str in _visualizations:
			set_topic(key_str)
			print("  -> Set topic from shorthand: %s" % key_str)
			break

	# Optional: frame duration config
	if config_data.has("duration"):
		frame_duration = float(config_data.duration)
		print("  -> Set frame duration: %s" % frame_duration)

	# Optional: auto-advance config
	if config_data.has("auto"):
		auto_advance = str(config_data.auto).to_lower() == "true"
		print("  -> Set auto advance: %s" % auto_advance)

func _initialize_visualization_data(vis_ctrl: Control) -> void:
	# Initialize particles and forces for visualizations that need them
	if "particles" in vis_ctrl:
		vis_ctrl.particles = []
		var rng = RandomNumberGenerator.new()
		rng.randomize()

		for i in range(5):
			vis_ctrl.particles.append({
				"position": Vector2(rng.randf_range(100, 400), rng.randf_range(100, 400)),
				"velocity": Vector2(rng.randf_range(-50, 50), rng.randf_range(-50, 50)),
				"acceleration": Vector2.ZERO,
				"mass": rng.randf_range(1, 3),
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
