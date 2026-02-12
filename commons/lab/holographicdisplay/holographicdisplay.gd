# holographicdisplay.gd
# Holographic display with sine-based scan lines and flicker
# Demonstrates interference patterns and wave visualization
extends Node3D

class_name LabHolographicDisplay

@export_group("Hologram")
@export var scan_frequency: float = 2.0  # Hz
@export var flicker_frequency: float = 15.0  # Hz (subtle)
@export var flicker_intensity: float = 0.1
@export var hologram_color: Color = Color(0.2, 0.8, 1.0)
@export var hologram_height: float = 0.2

@export_group("Effects")
@export var rotation_speed: float = 0.3  # Rotations per second
@export var vertical_oscillation: float = 0.01
@export var scale_pulse: float = 0.05

## Internal
var time: float = 0.0
var hologram_content: Node3D
var scan_line: MeshInstance3D
var base_emitter: MeshInstance3D
var projector_lights: Array[SpotLight3D] = []

func _ready() -> void:
	_build_display()

func _process(delta: float) -> void:
	time += delta
	
	# Hologram rotation
	if hologram_content:
		hologram_content.rotation.y += rotation_speed * delta * TAU
		
		# Vertical bob
		var bob = vertical_oscillation * sin(time * 1.5 * TAU)
		hologram_content.position.y = 0.15 + bob
		
		# Scale pulse
		var pulse = 1.0 + scale_pulse * sin(time * 2.0 * TAU)
		hologram_content.scale = Vector3(pulse, pulse, pulse)
	
	# Scan line sweeps up and down
	if scan_line:
		var scan_pos = sin(time * scan_frequency * TAU) * hologram_height * 0.4
		scan_line.position.y = 0.15 + scan_pos
		
		# Scan line intensity
		if scan_line.material_override:
			var intensity = 0.5 + 0.5 * abs(cos(time * scan_frequency * TAU))
			scan_line.material_override.emission_energy_multiplier = intensity * 2.0
	
	# Flicker effect on hologram
	if hologram_content:
		var flicker = 1.0 - flicker_intensity * (0.5 + 0.5 * sin(time * flicker_frequency * TAU))
		_set_hologram_opacity(flicker)
	
	# Base emitter glow
	if base_emitter and base_emitter.material_override:
		var glow = 0.8 + 0.4 * sin(time * 3.0)
		base_emitter.material_override.emission_energy_multiplier = glow
	
	# Projector lights
	for i in range(projector_lights.size()):
		var light = projector_lights[i]
		var phase = float(i) * TAU / float(projector_lights.size())
		var intensity = 0.3 + 0.2 * sin(time * 4.0 + phase)
		light.light_energy = intensity

func _set_hologram_opacity(opacity: float) -> void:
	for child in hologram_content.get_children():
		if child is MeshInstance3D and child.material_override:
			child.material_override.albedo_color.a = opacity * 0.6

func _build_display() -> void:
	for child in get_children():
		child.queue_free()
	projector_lights.clear()
	
	# Base platform
	var base = MeshInstance3D.new()
	base.name = "Base"
	var base_mesh = CylinderMesh.new()
	base_mesh.top_radius = 0.12
	base_mesh.bottom_radius = 0.14
	base_mesh.height = 0.03
	base_mesh.radial_segments = 32
	base.mesh = base_mesh
	base.position = Vector3(0, 0.015, 0)
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.1, 0.12, 0.15)
	base_mat.metallic = 0.8
	base_mat.roughness = 0.2
	base.material_override = base_mat
	add_child(base)
	
	# Emitter ring
	base_emitter = MeshInstance3D.new()
	base_emitter.name = "EmitterRing"
	var emitter_mesh = TorusMesh.new()
	emitter_mesh.inner_radius = 0.08
	emitter_mesh.outer_radius = 0.1
	base_emitter.mesh = emitter_mesh
	base_emitter.position = Vector3(0, 0.035, 0)
	base_emitter.rotation.x = PI / 2
	var emitter_mat = StandardMaterial3D.new()
	emitter_mat.albedo_color = hologram_color
	emitter_mat.emission_enabled = true
	emitter_mat.emission = hologram_color
	emitter_mat.emission_energy_multiplier = 1.0
	base_emitter.material_override = emitter_mat
	add_child(base_emitter)
	
	# Projector points around the ring
	for i in range(4):
		var angle = float(i) * TAU / 4.0
		var x = cos(angle) * 0.09
		var z = sin(angle) * 0.09
		
		var proj_light = SpotLight3D.new()
		proj_light.name = "Projector_%d" % i
		proj_light.position = Vector3(x, 0.04, z)
		proj_light.rotation.x = -PI / 3
		proj_light.rotation.y = angle + PI
		proj_light.light_color = hologram_color
		proj_light.light_energy = 0.3
		proj_light.spot_range = 0.3
		proj_light.spot_angle = 30.0
		add_child(proj_light)
		projector_lights.append(proj_light)
	
	# Hologram content container
	hologram_content = Node3D.new()
	hologram_content.name = "HologramContent"
	hologram_content.position = Vector3(0, 0.15, 0)
	add_child(hologram_content)
	
	# Sample hologram - rotating wireframe cube
	_create_hologram_cube()
	
	# Scan line
	scan_line = MeshInstance3D.new()
	scan_line.name = "ScanLine"
	var scan_mesh = BoxMesh.new()
	scan_mesh.size = Vector3(0.2, 0.003, 0.2)
	scan_line.mesh = scan_mesh
	scan_line.position = Vector3(0, 0.15, 0)
	var scan_mat = StandardMaterial3D.new()
	scan_mat.albedo_color = Color(hologram_color.r, hologram_color.g, hologram_color.b, 0.3)
	scan_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	scan_mat.emission_enabled = true
	scan_mat.emission = hologram_color
	scan_mat.emission_energy_multiplier = 1.0
	scan_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	scan_line.material_override = scan_mat
	add_child(scan_line)

func _create_hologram_cube() -> void:
	var cube_size = 0.08
	var holo_mat = StandardMaterial3D.new()
	holo_mat.albedo_color = Color(hologram_color.r, hologram_color.g, hologram_color.b, 0.5)
	holo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	holo_mat.emission_enabled = true
	holo_mat.emission = hologram_color
	holo_mat.emission_energy_multiplier = 1.5
	holo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	holo_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# Wireframe edges (12 edges of a cube)
	var edge_thickness = 0.003
	var edges = [
		# Bottom face
		{"start": Vector3(-1, -1, -1), "end": Vector3(1, -1, -1)},
		{"start": Vector3(1, -1, -1), "end": Vector3(1, -1, 1)},
		{"start": Vector3(1, -1, 1), "end": Vector3(-1, -1, 1)},
		{"start": Vector3(-1, -1, 1), "end": Vector3(-1, -1, -1)},
		# Top face
		{"start": Vector3(-1, 1, -1), "end": Vector3(1, 1, -1)},
		{"start": Vector3(1, 1, -1), "end": Vector3(1, 1, 1)},
		{"start": Vector3(1, 1, 1), "end": Vector3(-1, 1, 1)},
		{"start": Vector3(-1, 1, 1), "end": Vector3(-1, 1, -1)},
		# Verticals
		{"start": Vector3(-1, -1, -1), "end": Vector3(-1, 1, -1)},
		{"start": Vector3(1, -1, -1), "end": Vector3(1, 1, -1)},
		{"start": Vector3(1, -1, 1), "end": Vector3(1, 1, 1)},
		{"start": Vector3(-1, -1, 1), "end": Vector3(-1, 1, 1)},
	]
	
	for edge in edges:
		var start = edge.start * cube_size / 2.0
		var end = edge.end * cube_size / 2.0
		var midpoint = (start + end) / 2.0
		var length = start.distance_to(end)
		var direction = (end - start).normalized()
		
		var edge_mesh = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = edge_thickness
		cyl.bottom_radius = edge_thickness
		cyl.height = length
		edge_mesh.mesh = cyl
		edge_mesh.position = midpoint
		edge_mesh.material_override = holo_mat
		
		# Rotate to align with edge direction
		if direction != Vector3.UP and direction != Vector3.DOWN:
			edge_mesh.look_at_from_position(midpoint, midpoint + direction, Vector3.UP)
			edge_mesh.rotate_object_local(Vector3.RIGHT, PI / 2)
		
		hologram_content.add_child(edge_mesh)
	
	# Corner spheres
	var corners = [
		Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, -1, 1), Vector3(-1, -1, 1),
		Vector3(-1, 1, -1), Vector3(1, 1, -1), Vector3(1, 1, 1), Vector3(-1, 1, 1),
	]
	
	for corner in corners:
		var sphere = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = edge_thickness * 1.5
		sphere_mesh.height = edge_thickness * 3.0
		sphere.mesh = sphere_mesh
		sphere.position = corner * cube_size / 2.0
		sphere.material_override = holo_mat
		hologram_content.add_child(sphere)

## Public API
func set_hologram_color(color: Color) -> void:
	hologram_color = color
	# Would need to rebuild or update materials

func set_content_rotation_speed(speed: float) -> void:
	rotation_speed = speed

func trigger_glitch() -> void:
	# Temporary high flicker
	var original_flicker = flicker_intensity
	flicker_intensity = 0.8
	await get_tree().create_timer(0.3).timeout
	flicker_intensity = original_flicker
