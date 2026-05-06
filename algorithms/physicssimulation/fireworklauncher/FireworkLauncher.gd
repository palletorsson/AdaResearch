# ===========================================================================
# FireworkLauncher.gd - Particle System Firework Display
# Launch rockets that explode into particle sprays with gravity + drag + fading
# Shows particle emission, lifetime, forces on many bodies, emergent patterns
#
# QFEP: Many from one — a single event creates a statistical population.
# ===========================================================================
#
# @identity
# essence: launch → ascend → explode(N particles) → each: v += g, v *= drag, life -= dt, fade. One event becomes sixty trajectories.
# desire: To launch a rocket and watch it bloom — sixty glowing particles inheriting random velocities from a single explosion point, then falling under gravity and drag.
# critical_parameter: burst_force (1.0-8.0) — the initial speed of exploded particles. It sets the bloom radius. Higher = wider, more dramatic, longer airtime before gravity wins.
# triggers: Auto-launch every 2.5s, FIRE button → manual launch, preset buttons → color palettes (classic/ocean/garden) and patterns (sphere/ring), burst slider → controls explosion force
# emerges: Ring patterns from constrained emission (horizontal only). Sphere patterns from uniform random direction. Particle trails tracing parabolas. The moment of bloom as maximum expansion.
# needs: VR preset buttons [has], fire button [has], burst force slider [has], auto-launch toggle [has]. Missing: height slider, multi-launch choreography.
# relationships: CPU particle system (contrasts with particle_systems using GPUParticles3D). Lives in ForcesSystems. Each particle is a mini bouncing_ball with drag and lifetime.
# truth: A firework is a population explosion. One event becomes many independent trajectories, each obeying the same law, each taking a different path.
extends Node3D

class_name FireworkLauncher

## Firework parameters
@export var particle_count_per_burst: int = 60
@export var burst_force: float = 3.0:
	set(value):
		burst_force = clampf(value, 1.0, 8.0)
@export var gravity_strength: float = 2.0
@export var drag: float = 0.98
@export var particle_lifetime: float = 3.0

## Launch parameters
@export var launch_speed: float = 4.0
@export var launch_height: float = 1.5

## Visuals
@export var trail_enabled: bool = true

# Internal
var _rockets: Array = []  # Active rockets flying upward
var _particles: Array = []  # Exploded particles falling
var _info_label: Label3D
var _control_panel: Node3D
var _time_since_auto: float = 0.0
var _auto_launch: bool = true

# Presets: [name, colors, spread_pattern]
var _presets := [
	["CLASSIC", [Color(1.0, 0.3, 0.2), Color(1.0, 0.7, 0.1), Color(1.0, 1.0, 0.3)], "sphere"],
	["OCEAN", [Color(0.2, 0.5, 1.0), Color(0.3, 0.8, 0.9), Color(0.5, 1.0, 1.0)], "sphere"],
	["GARDEN", [Color(0.4, 1.0, 0.3), Color(1.0, 0.4, 0.7), Color(0.9, 0.3, 1.0)], "sphere"],
	["RING", [Color(1.0, 0.8, 0.2), Color(1.0, 0.4, 0.1), Color(0.8, 0.2, 0.1)], "ring"],
]
var _current_preset: int = 0


func _ready() -> void:
	_create_launch_tube()
	_create_labels()
	_create_vr_controls()

func _create_launch_tube() -> void:
	# Launch tube visual
	var tube := MeshInstance3D.new()
	tube.name = "LaunchTube"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.04
	cyl.bottom_radius = 0.06
	cyl.height = 0.2
	tube.mesh = cyl

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.35)
	mat.metallic = 0.6
	tube.material_override = mat
	tube.position = Vector3(0, 0.1, 0)
	add_child(tube)

	# Base plate
	var base := MeshInstance3D.new()
	base.name = "Base"
	var box := BoxMesh.new()
	box.size = Vector3(0.25, 0.02, 0.25)
	base.mesh = box
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.15, 0.15, 0.18)
	base_mat.metallic = 0.4
	base.material_override = base_mat
	add_child(base)

func _launch_firework() -> void:
	var preset: Array = _presets[_current_preset]
	var colors: Array = preset[1]

	# Create rocket
	var rocket := {
		"pos": Vector3(randf_range(-0.05, 0.05), 0.2, randf_range(-0.05, 0.05)),
		"vel": Vector3(randf_range(-0.3, 0.3), launch_speed, randf_range(-0.3, 0.3)),
		"target_height": launch_height + randf_range(-0.3, 0.3),
		"colors": colors,
		"pattern": preset[2] as String,
		"mesh": null,
		"trail_points": PackedVector3Array(),
		"trail_mesh": null,
	}

	# Rocket visual
	var mesh := MeshInstance3D.new()
	mesh.name = "Rocket"
	var sphere := SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.9, 0.5)
	mat.emission_energy_multiplier = 3.0
	mesh.material_override = mat
	mesh.position = rocket["pos"]
	add_child(mesh)
	rocket["mesh"] = mesh

	# Trail mesh
	if trail_enabled:
		var trail := MeshInstance3D.new()
		trail.name = "RocketTrail"
		add_child(trail)
		rocket["trail_mesh"] = trail

	_rockets.append(rocket)

func _explode(rocket: Dictionary) -> void:
	var pos: Vector3 = rocket["pos"]
	var colors: Array = rocket["colors"]
	var pattern: String = rocket["pattern"]

	for i in range(particle_count_per_burst):
		var dir: Vector3
		if pattern == "ring":
			# Ring pattern: particles spread in a horizontal ring
			var angle := float(i) / float(particle_count_per_burst) * TAU
			dir = Vector3(cos(angle), randf_range(-0.2, 0.4), sin(angle))
		else:
			# Sphere pattern: random directions
			dir = Vector3(
				randf_range(-1, 1),
				randf_range(-1, 1),
				randf_range(-1, 1)
			).normalized()

		var speed := burst_force * randf_range(0.5, 1.0)
		var color: Color = colors[i % colors.size()]
		# Slight color variation
		color = color.lightened(randf_range(-0.1, 0.1))

		var particle := {
			"pos": pos,
			"vel": dir * speed,
			"color": color,
			"life": particle_lifetime,
			"max_life": particle_lifetime,
			"mesh": null,
		}

		# Particle visual
		var mesh := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.012
		sphere.height = 0.024
		mesh.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.5
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material_override = mat
		mesh.position = pos
		add_child(mesh)
		particle["mesh"] = mesh

		_particles.append(particle)

	# Remove rocket visual
	if rocket["mesh"]:
		(rocket["mesh"] as MeshInstance3D).queue_free()
	if rocket["trail_mesh"]:
		(rocket["trail_mesh"] as MeshInstance3D).queue_free()

func _physics_process(delta: float) -> void:
	# Update rockets
	var exploded_indices: Array[int] = []
	for i in range(_rockets.size()):
		var r: Dictionary = _rockets[i]
		r["vel"].y -= gravity_strength * 0.3 * delta  # Light gravity on rockets
		r["pos"] += r["vel"] * delta

		if r["mesh"]:
			(r["mesh"] as MeshInstance3D).position = r["pos"]

		# Track trail
		if trail_enabled and r["trail_mesh"]:
			(r["trail_points"] as PackedVector3Array).append(r["pos"])
			_update_trail_mesh(r["trail_mesh"] as MeshInstance3D, r["trail_points"] as PackedVector3Array, Color(1.0, 0.7, 0.3, 0.5))

		if r["pos"].y >= r["target_height"]:
			exploded_indices.append(i)

	# Explode rockets that reached target
	for i in range(exploded_indices.size() - 1, -1, -1):
		_explode(_rockets[exploded_indices[i]])
		_rockets.remove_at(exploded_indices[i])

	# Update particles
	var dead_indices: Array[int] = []
	for i in range(_particles.size()):
		var p: Dictionary = _particles[i]
		p["vel"].y -= gravity_strength * delta
		p["vel"] *= drag
		p["pos"] += p["vel"] * delta
		p["life"] -= delta

		if p["mesh"]:
			var mesh: MeshInstance3D = p["mesh"]
			mesh.position = p["pos"]

			# Fade out
			var life_ratio: float = float(p["life"]) / float(p["max_life"])
			var mat := mesh.material_override as StandardMaterial3D
			if mat:
				mat.albedo_color.a = life_ratio
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.emission_energy_multiplier = 2.5 * life_ratio

			# Shrink
			var s: float = life_ratio * 0.8 + 0.2
			mesh.scale = Vector3(s, s, s)

		if p["life"] <= 0:
			dead_indices.append(i)

	# Clean up dead particles
	for i in range(dead_indices.size() - 1, -1, -1):
		var p: Dictionary = _particles[dead_indices[i]]
		if p["mesh"]:
			(p["mesh"] as MeshInstance3D).queue_free()
		_particles.remove_at(dead_indices[i])

	# Auto-launch
	if _auto_launch:
		_time_since_auto += delta
		if _time_since_auto >= 2.5:
			_time_since_auto = 0.0
			_launch_firework()

	_update_info()

func _update_trail_mesh(mesh: MeshInstance3D, points: PackedVector3Array, color: Color) -> void:
	if points.size() < 2:
		return
	# Keep last 30 points
	while points.size() > 30:
		points.remove_at(0)

	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(points.size()):
		var alpha := float(i) / float(points.size()) * 0.6
		im.surface_set_color(Color(color.r, color.g, color.b, alpha))
		im.surface_add_vertex(points[i])
	im.surface_end()
	mesh.mesh = im

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat

func _update_info() -> void:
	_info_label.text = "FIREWORKS — %s\nParticles: %d  Rockets: %d" % [
		(_presets[_current_preset][0] as String),
		_particles.size(),
		_rockets.size()
	]

func _create_labels() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 14
	_info_label.position = Vector3(0, launch_height + 0.8, 0)
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.outline_size = 3
	_info_label.outline_modulate = Color.BLACK
	_info_label.text = "FIREWORK LAUNCHER"
	add_child(_info_label)

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("FIREWORKS", [
		[
			{"type": "button", "label": "CLASSIC"},
			{"type": "button", "label": "OCEAN"},
			{"type": "button", "label": "GARDEN"},
			{"type": "button", "label": "RING"},
		],
		[
			{"type": "button", "label": "FIRE!"},
			{"type": "slider_h", "label": "BURST", "default": 0.5},
		],
	])
	_control_panel.position = Vector3(0, 0.02, 0.3)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)

	# Preset buttons
	for i in 4:
		var btn: Node = _control_panel.find_child("Btn_%d" % i, true, false)
		if btn:
			var idx: int = i
			var area = btn.get_node_or_null("InteractableAreaButton")
			if area:
				area.button_pressed.connect(func(_b): _current_preset = idx)

	# Fire button (Btn_4)
	var fire_btn: Node = _control_panel.find_child("Btn_4", true, false)
	if fire_btn:
		var fire_area = fire_btn.get_node_or_null("InteractableAreaButton")
		if fire_area:
			fire_area.button_pressed.connect(func(_b): _launch_firework())

	# Burst slider
	var force_slider: Node = _control_panel.find_child("Param_0", true, false)
	if force_slider and force_slider.has_signal("slider_moved"):
		force_slider.slider_moved.connect(func(_pos):
			if force_slider.has_method("get_normalized_value"):
				burst_force = 1.0 + force_slider.get_normalized_value() * 7.0
		)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE: _launch_firework()
			KEY_1: _current_preset = 0
			KEY_2: _current_preset = 1
			KEY_3: _current_preset = 2
			KEY_4: _current_preset = 3
			KEY_A: _auto_launch = not _auto_launch

func reset() -> void:
	# Clean up all particles and rockets
	for p in _particles:
		if p["mesh"]:
			(p["mesh"] as MeshInstance3D).queue_free()
	_particles.clear()
	for r in _rockets:
		if r["mesh"]:
			(r["mesh"] as MeshInstance3D).queue_free()
		if r["trail_mesh"]:
			(r["trail_mesh"] as MeshInstance3D).queue_free()
	_rockets.clear()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
