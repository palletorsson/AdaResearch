# PolyhedraVisualizationControl.gd
# 3D Visualization for Polyhedra concepts using SubViewport
extends Control

var visualization_type = "tetrahedron":
	set(value):
		visualization_type = value
		if is_node_ready():
			load_visualization()

var animation_time = 0.0
var animation_speed = 1.0
var animation_playing = true

# Scene references
var current_3d_scene: Node3D = null
var viewport_container: SubViewportContainer
var viewport: SubViewport
var camera: Camera3D

# Visualization scene paths mapping
const VISUALIZATION_SCENES = {
	"tetrahedron": "res://commons/primitives/tetrahedron/tetrahedron.tscn",
	"platonic_solids": "res://commons/infoboards_3d/visualizations/polyhedra_showcase.tscn",
	"tetrahedron_net": "res://commons/infoboards_3d/visualizations/polyhedron_nets.tscn",
	"cube_net": "res://commons/infoboards_3d/visualizations/polyhedron_nets_cube.tscn",
	"octahedron": "res://commons/primitives/octahedron/octahedron.tscn",
	"johnson_solids": "res://commons/infoboards_3d/visualizations/polyhedra_showcase_johnson.tscn",
	"cube": "res://commons/primitives/cube/cube.tscn"
}

func _ready():
	custom_minimum_size = Vector2(400, 400)

	# Create SubViewportContainer
	viewport_container = SubViewportContainer.new()
	viewport_container.stretch = true
	viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(viewport_container)

	# Create SubViewport
	viewport = SubViewport.new()
	viewport.size = Vector2i(800, 800)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(viewport)

	# Create Camera
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.5, 3)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	viewport.add_child(camera)

	# Create directional light
	var light = DirectionalLight3D.new()
	light.position = Vector3(2, 4, 3)
	light.rotation_degrees = Vector3(-45, 30, 0)
	light.light_energy = 1.2
	viewport.add_child(light)

	# Add ambient light
	var ambient = OmniLight3D.new()
	ambient.light_energy = 0.3
	ambient.omni_range = 10.0
	viewport.add_child(ambient)

	# Load initial visualization
	load_visualization()

func _process(delta):
	if animation_playing and current_3d_scene and is_instance_valid(current_3d_scene):
		animation_time += delta * animation_speed

		# Only rotate if it's a simple primitive (showcase scenes have their own rotation)
		if visualization_type in ["tetrahedron", "octahedron", "cube"]:
			current_3d_scene.rotate_y(delta * 0.5)
			current_3d_scene.rotate_x(delta * 0.3)

func load_visualization():
	# Clear previous scene
	if current_3d_scene and is_instance_valid(current_3d_scene):
		current_3d_scene.queue_free()
		current_3d_scene = null

	# Get scene path for this visualization type
	var scene_path = VISUALIZATION_SCENES.get(visualization_type, "")

	if scene_path.is_empty():
		push_warning("PolyhedraVisualizationControl: Unknown visualization type: %s" % visualization_type)
		return

	if not ResourceLoader.exists(scene_path):
		push_warning("PolyhedraVisualizationControl: Scene not found: %s" % scene_path)
		return

	# Load and instantiate the 3D scene
	var scene_resource = load(scene_path)
	if not scene_resource:
		push_warning("PolyhedraVisualizationControl: Failed to load scene: %s" % scene_path)
		return

	current_3d_scene = scene_resource.instantiate()
	viewport.add_child(current_3d_scene)

	# Adjust camera based on visualization type
	match visualization_type:
		"platonic_solids", "johnson_solids":
			# Pull back for multiple objects
			camera.position = Vector3(0, 2, 5)
		"tetrahedron_net", "cube_net":
			# Top-down view for nets
			camera.position = Vector3(0, 3, 1)
			camera.look_at(Vector3.ZERO, Vector3.UP)
		_:
			# Default close-up for single objects
			camera.position = Vector3(0, 1, 2.5)
			camera.look_at(Vector3.ZERO, Vector3.UP)

	print("PolyhedraVisualizationControl: Loaded visualization '%s' from %s" % [visualization_type, scene_path])
