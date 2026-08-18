# reaction_diffusion_vr.gd
# VR-optimized reaction-diffusion using GPU shader
extends Node3D

# @identity
# essence: Gray-Scott reaction-diffusion on GPU via ping-pong SubViewport rendering — feed_rate and kill_rate parameters select pattern regimes (coral, mitosis, spots, maze, waves)
# desire: to watch Turing patterns bloom on a quad in front of you — spots splitting, stripes forming, mazes growing — all from two chemicals diffusing at different speeds
# critical_parameter: feed_rate / kill_rate pair — together they select the pattern regime; tiny changes (0.001) cross phase boundaries between spots and stripes
# triggers: preset cycling (KEY_LEFT/RIGHT) loads predefined feed/kill pairs; KEY_SPACE drops a new seed point; KEY_R resets the simulation to uniform state
# emerges: seed placement geometry determines the initial symmetry which the reaction-diffusion dynamics then break or amplify — same parameters, different seeds, different patterns
# needs: slider_horizontal [missing]; push_button [missing]; Label3D [has] (preset label)
# relationships: GPU shader complement to turing_pattern_generator's CPU simulation; absorbed into softbodies sequence from morphogenesis
# truth: Turing's last paper proved that two diffusing chemicals can create pattern from homogeneity — no blueprint needed, only differential diffusion

# Shader parameters
@export var feed_rate: float = 0.037
@export var kill_rate: float = 0.06
@export var resolution: int = 256  # Lower for VR performance

# Presets for different patterns
var presets = [
	{"name": "Coral", "feed": 0.055, "kill": 0.062},
	{"name": "Mitosis", "feed": 0.0367, "kill": 0.0649},
	{"name": "Fingers", "feed": 0.037, "kill": 0.06},
	{"name": "Spots", "feed": 0.025, "kill": 0.05},
	{"name": "Waves", "feed": 0.018, "kill": 0.051},
	{"name": "Maze", "feed": 0.029, "kill": 0.057},
	{"name": "Bubbles", "feed": 0.012, "kill": 0.047},
	{"name": "Worms", "feed": 0.078, "kill": 0.061}
]
var current_preset: int = 2  # Start with Fingers

# Node references
var viewport_a: SubViewport
var viewport_b: SubViewport
var display_mesh: MeshInstance3D
var sim_material: ShaderMaterial

# Ping-pong state
var current_viewport: SubViewport
var next_viewport: SubViewport

# UI
var preset_label: Label3D

func _ready() -> void:
	_setup_viewports()
	_setup_display()
	_setup_shader()
	_setup_ui()
	_add_initial_seeds()

func _setup_viewports() -> void:
	# Create SubViewport A
	viewport_a = SubViewport.new()
	viewport_a.name = "ViewportA"
	viewport_a.size = Vector2i(resolution, resolution)
	viewport_a.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport_a.transparent_bg = false
	add_child(viewport_a)

	# Add ColorRect to viewport A (initial state)
	var rect_a = ColorRect.new()
	rect_a.name = "ColorRect"
	rect_a.color = Color(1.0, 0.0, 0.0, 1.0)  # Full U, no V
	rect_a.anchors_preset = Control.PRESET_FULL_RECT
	rect_a.size = Vector2(resolution, resolution)
	viewport_a.add_child(rect_a)

	# Create SubViewport B
	viewport_b = SubViewport.new()
	viewport_b.name = "ViewportB"
	viewport_b.size = Vector2i(resolution, resolution)
	viewport_b.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport_b.transparent_bg = false
	add_child(viewport_b)

	# Add ColorRect to viewport B (shader processing)
	var rect_b = ColorRect.new()
	rect_b.name = "ColorRect"
	rect_b.anchors_preset = Control.PRESET_FULL_RECT
	rect_b.size = Vector2(resolution, resolution)
	viewport_b.add_child(rect_b)

	# Initialize ping-pong
	current_viewport = viewport_a
	next_viewport = viewport_b

func _setup_display() -> void:
	# Create a 3D quad to display the pattern
	display_mesh = MeshInstance3D.new()
	display_mesh.name = "Display"

	# Create a quad mesh
	var quad = QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)  # 2x2 meter display
	display_mesh.mesh = quad

	# Position slightly in front
	display_mesh.position = Vector3(0, 1.0, 0)

	add_child(display_mesh)

func _setup_shader() -> void:
	# Load the GPU shader
	var shader = load("res://algorithms/patterngeneration/reactiondiffusion/reactiondiffusion.gdshader")
	if not shader:
		push_error("Failed to load reaction-diffusion shader")
		return

	# Create material for the shader processing
	sim_material = ShaderMaterial.new()
	sim_material.shader = shader
	sim_material.set_shader_parameter("feed_rate", feed_rate)
	sim_material.set_shader_parameter("kill_rate", kill_rate)
	sim_material.set_shader_parameter("mouse_pos", Vector2(-1, -1))

	# Apply shader to viewport B's ColorRect
	var rect_b = viewport_b.get_node("ColorRect")
	if rect_b:
		rect_b.material = sim_material

	# Create display material with color mapping
	var display_material = ShaderMaterial.new()
	var display_shader = Shader.new()
	display_shader.code = """
shader_type spatial;
render_mode unshaded;

uniform sampler2D pattern_texture;

void fragment() {
	vec2 uv = UV;
	vec4 data = texture(pattern_texture, uv);

	float u = data.r;
	float v = data.g;

	// Beautiful color mapping
	vec3 color_u = vec3(0.1, 0.2, 0.4);   // Deep blue for U
	vec3 color_v = vec3(0.9, 0.7, 0.3);   // Golden for V
	vec3 color = mix(color_u, color_v, v * 2.0);

	// Add some contrast
	color = pow(color, vec3(0.8));

	ALBEDO = color;
	EMISSION = color * 0.3;
}
"""
	display_material.shader = display_shader
	display_mesh.material_override = display_material

func _setup_ui() -> void:
	# Create 3D label for current preset
	preset_label = Label3D.new()
	preset_label.name = "PresetLabel"
	preset_label.text = "Preset: " + presets[current_preset].name
	preset_label.position = Vector3(0, 2.3, 0)
	preset_label.font_size = 48
	preset_label.pixel_size = 0.005
	preset_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(preset_label)

func _add_initial_seeds() -> void:
	# Add seed pattern after setup
	await get_tree().process_frame
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame

	# Add multiple seed points
	var seed_positions = [
		Vector2(0.5, 0.5),
		Vector2(0.3, 0.3),
		Vector2(0.7, 0.3),
		Vector2(0.3, 0.7),
		Vector2(0.7, 0.7),
		Vector2(0.5, 0.25),
		Vector2(0.5, 0.75),
		Vector2(0.25, 0.5),
		Vector2(0.75, 0.5)
	]

	for pos in seed_positions:
		sim_material.set_shader_parameter("mouse_pos", pos)
		next_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().process_frame

	# Add some random seeds
	for i in range(15):
		var random_pos = Vector2(randf() * 0.6 + 0.2, randf() * 0.6 + 0.2)
		sim_material.set_shader_parameter("mouse_pos", random_pos)
		next_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().process_frame

	sim_material.set_shader_parameter("mouse_pos", Vector2(-1, -1))

func _process(_delta):
	if not sim_material:
		return

	# Pass current frame texture to shader
	var current_texture = current_viewport.get_texture()
	if current_texture:
		sim_material.set_shader_parameter("last_frame", current_texture)

	# Trigger render
	next_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

	# Update display with new texture
	var new_texture = next_viewport.get_texture()
	if new_texture and display_mesh.material_override:
		display_mesh.material_override.set_shader_parameter("pattern_texture", new_texture)

	# Swap buffers
	var temp = current_viewport
	current_viewport = next_viewport
	next_viewport = temp

func next_preset() -> void:
	current_preset = (current_preset + 1) % presets.size()
	_apply_preset()

func previous_preset() -> void:
	current_preset = (current_preset - 1 + presets.size()) % presets.size()
	_apply_preset()

func _apply_preset() -> void:
	var preset = presets[current_preset]
	feed_rate = preset.feed
	kill_rate = preset.kill

	if sim_material:
		sim_material.set_shader_parameter("feed_rate", feed_rate)
		sim_material.set_shader_parameter("kill_rate", kill_rate)

	if preset_label:
		preset_label.text = "Preset: " + preset.name

func reset_simulation() -> void:
	# Reset to initial state
	var rect_a = viewport_a.get_node("ColorRect")
	if rect_a:
		rect_a.color = Color(1.0, 0.0, 0.0, 1.0)

	current_viewport = viewport_a
	next_viewport = viewport_b

	# Re-add seeds
	_add_initial_seeds()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_RIGHT, KEY_D:
				next_preset()
			KEY_LEFT, KEY_A:
				previous_preset()
			KEY_R:
				reset_simulation()
			KEY_SPACE:
				# Add seed at random position
				if sim_material:
					var pos = Vector2(randf(), randf())
					sim_material.set_shader_parameter("mouse_pos", pos)
					next_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
					await get_tree().process_frame
					sim_material.set_shader_parameter("mouse_pos", Vector2(-1, -1))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
