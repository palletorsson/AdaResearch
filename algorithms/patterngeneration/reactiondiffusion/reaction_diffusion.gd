# simulation.gd
extends Node2D

# Reaction-Diffusion simulation using SubViewport ping-pong buffer + shader
# Converted from Control to Node3D for VR compatibility
# SubViewports remain for computation; result is displayed on a 3D QuadMesh


# --- SubViewports for computation (created procedurally) ---
var buffer_a: SubViewport
var buffer_b: SubViewport

# --- 3D display surface ---
var display_mesh: MeshInstance3D
var display_material: ShaderMaterial  # Used to show the result texture

# --- Shader material that will run the simulation ---
var sim_material: ShaderMaterial

# --- Variables to track which buffer is the source and which is the destination ---
var current_buffer: SubViewport
var next_buffer: SubViewport

# --- VR interaction buttons ---
var btn_noise: Node
var btn_reset: Node
var btn_seed: Node
var btn_blast: Node

var frame_count: int = 0

func _ready() -> void:
	print("Initializing Reaction-Diffusion System (Node3D)...")

	_create_subviewports()
	_create_display_surface()
	_create_vr_controls()
	_setup_simulation()

func _create_subviewports() -> void:
	# Create SubViewports as children for ping-pong computation
	# BufferA
	buffer_a = SubViewport.new()
	buffer_a.name = "BufferA"
	buffer_a.size = Vector2i(512, 512)
	buffer_a.render_target_update_mode = SubViewport.UPDATE_ONCE
	buffer_a.transparent_bg = false
	add_child(buffer_a)

	var rect_a := ColorRect.new()
	rect_a.name = "ColorRect"
	rect_a.color = Color.RED  # Initial state: full chemical U
	rect_a.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	buffer_a.add_child(rect_a)

	# BufferB
	buffer_b = SubViewport.new()
	buffer_b.name = "BufferB"
	buffer_b.size = Vector2i(512, 512)
	buffer_b.render_target_update_mode = SubViewport.UPDATE_ONCE
	buffer_b.transparent_bg = false
	add_child(buffer_b)

	var rect_b := ColorRect.new()
	rect_b.name = "ColorRect"
	rect_b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	buffer_b.add_child(rect_b)

func _create_display_surface() -> void:
	# Create a 0.5m x 0.5m QuadMesh to show the simulation output
	display_mesh = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.5, 0.5)
	display_mesh.mesh = quad
	display_mesh.position = Vector3(0, 0.25, 0)
	add_child(display_mesh)

	# Display material: simple unshaded texture display
	var display_shader := Shader.new()
	display_shader.code = """
shader_type spatial;
render_mode unshaded;

uniform sampler2D sim_texture : source_color;

void fragment() {
	ALBEDO = texture(sim_texture, UV).rgb;
}
"""
	display_material = ShaderMaterial.new()
	display_material.shader = display_shader
	display_mesh.material_override = display_material

	# Title label
	var title := Label3D.new()
	title.text = "Reaction-Diffusion Simulation"
	title.font_size = 32
	title.position = Vector3(0, 0.55, 0)
	title.modulate = Color.WHITE
	add_child(title)

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("RD SURFACE", [
		[{"type": "button", "label": "NOISE"}, {"type": "button", "label": "RESET"},
		 {"type": "button", "label": "SEEDS"}, {"type": "button", "label": "BLAST"}],
	])
	panel.position = Vector3(0, -0.05, 0)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	var callbacks := [_on_add_noise, _on_reset, _on_add_seeds, _on_big_blast]
	for i in callbacks.size():
		var btn: Node = panel.find_child("Btn_%d" % i, true, false)
		if btn:
			var area := btn.get_node_or_null("InteractableAreaButton")
			if area:
				area.button_pressed.connect(callbacks[i])

func _setup_simulation() -> void:
	# 1. Create ShaderMaterial and load the reaction-diffusion shader
	sim_material = ShaderMaterial.new()
	var shader = load("res://algorithms/patterngeneration/reactiondiffusion/reactiondiffusion.gdshader")
	if shader:
		sim_material.shader = shader
		sim_material.set_shader_parameter("feed_rate", 0.037)
		sim_material.set_shader_parameter("kill_rate", 0.06)
		print("Shader loaded successfully")
	else:
		print("Failed to load shader")
		return

	# 2. Apply shader to BufferB's ColorRect
	var rect_b := buffer_b.get_node_or_null("ColorRect")
	if rect_b:
		rect_b.material = sim_material
		print("Shader material applied to BufferB")

	# 3. Initialize ping-pong
	current_buffer = buffer_a
	next_buffer = buffer_b

	# 4. Add initial seeds
	call_deferred("add_initial_seed")

	print("Reaction-Diffusion system ready!")

func add_initial_seed() -> void:
	print("Adding initial seed points...")

	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame

	# Random seed points
	for i in range(30):
		var random_pos := Vector2(randf(), randf())
		sim_material.set_shader_parameter("mouse_pos", random_pos)
		next_buffer.render_target_update_mode = SubViewport.UPDATE_ONCE
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().process_frame

	# Central cluster
	var center_positions := [
		Vector2(0.5, 0.5),
		Vector2(0.45, 0.5),
		Vector2(0.55, 0.5),
		Vector2(0.5, 0.45),
		Vector2(0.5, 0.55)
	]

	for pos in center_positions:
		sim_material.set_shader_parameter("mouse_pos", pos)
		next_buffer.render_target_update_mode = SubViewport.UPDATE_ONCE
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().process_frame

	sim_material.set_shader_parameter("mouse_pos", Vector2(-1, -1))
	print("Initial seed points created!")

func _process(_delta: float) -> void:
	if not sim_material or not sim_material.shader:
		return

	frame_count += 1

	# 1. Pass previous frame's texture to the shader
	var current_texture := current_buffer.get_texture()
	if current_texture:
		call_deferred("_set_shader_texture", "last_frame", current_texture)

	# 2. No mouse interaction in VR -- seeds are added via buttons
	sim_material.set_shader_parameter("mouse_pos", Vector2(-1, -1))

	# 3. Force next_buffer to render
	next_buffer.render_target_update_mode = SubViewport.UPDATE_ONCE

	# 4. Update display surface with the new texture
	var new_texture := next_buffer.get_texture()
	if new_texture and display_material:
		display_material.set_shader_parameter("sim_texture", new_texture)

	# Debug output every few seconds
	if frame_count % 180 == 0:
		print("Frame ", frame_count, " - Simulation running (", current_buffer.name, " -> ", next_buffer.name, ")")

	# 5. Ping-pong swap
	var temp := current_buffer
	current_buffer = next_buffer
	next_buffer = temp

# ─── VR Button Callbacks ───

func _on_add_noise() -> void:
	print("Adding random noise...")
	add_random_noise()

func _on_reset() -> void:
	print("Resetting simulation...")
	reset_simulation()

func _on_add_seeds() -> void:
	print("Adding seed points...")
	add_seed_points()

func _on_big_blast() -> void:
	print("Big seed blast!")
	big_seed_blast()

# ─── Simulation Actions ───

func add_random_noise() -> void:
	for i in range(50):
		var random_pos := Vector2(randf(), randf())
		sim_material.set_shader_parameter("mouse_pos", random_pos)
		next_buffer.render_target_update_mode = SubViewport.UPDATE_ONCE
		await get_tree().process_frame
	sim_material.set_shader_parameter("mouse_pos", Vector2(-1, -1))

func add_seed_points() -> void:
	for x in range(5):
		for y in range(5):
			var pos := Vector2(x / 4.0, y / 4.0)
			sim_material.set_shader_parameter("mouse_pos", pos)
			next_buffer.render_target_update_mode = SubViewport.UPDATE_ONCE
			await get_tree().process_frame
	sim_material.set_shader_parameter("mouse_pos", Vector2(-1, -1))

func reset_simulation() -> void:
	var rect_a := buffer_a.get_node_or_null("ColorRect")
	if rect_a:
		rect_a.color = Color.RED
	current_buffer = buffer_a
	next_buffer = buffer_b

func big_seed_blast() -> void:
	if sim_material:
		for y_step in range(10):
			for x_step in range(10):
				var pos := Vector2(0.4 + x_step * 0.02, 0.4 + y_step * 0.02)
				sim_material.set_shader_parameter("mouse_pos", pos)
				next_buffer.render_target_update_mode = SubViewport.UPDATE_ONCE
				await get_tree().process_frame

		var corners := [Vector2(0.1, 0.1), Vector2(0.9, 0.1), Vector2(0.1, 0.9), Vector2(0.9, 0.9)]
		for corner in corners:
			sim_material.set_shader_parameter("mouse_pos", corner)
			next_buffer.render_target_update_mode = SubViewport.UPDATE_ONCE
			# out-of-tree guard: get_tree() is null once a map is torn down
			if not is_inside_tree():
				await tree_entered
			await get_tree().process_frame

		sim_material.set_shader_parameter("mouse_pos", Vector2(-1, -1))
		print("Big seed blast complete!")

func _set_shader_texture(param_name: String, texture: Texture2D) -> void:
	if sim_material and sim_material.shader:
		sim_material.set_shader_parameter(param_name, texture)

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
