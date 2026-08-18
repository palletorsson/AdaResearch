# edge_of_chaos_orb.gd
# A sphere that visualizes the current QFEP state
# Color and behavior shift based on global λ and φ values
# Green and dancing when at the edge of chaos (λ≈0.4, φ>0)

extends Node3D

class_name EdgeOfChaosOrb

signal state_changed(regime: String)

## Orb parameters
@export var orb_radius: float = 0.4
@export var ring_count: int = 3

## Lambda / phi values (driven externally or by keyboard)
@export var lambda: float = 0.4:
	set(v):
		lambda = clampf(v, 0.0, 1.0)
		_update_state()

@export var phi: float = 0.5:
	set(v):
		phi = clampf(v, 0.0, 1.0)
		_update_state()

# Colors
const COLOR_ORDER := Color(0.15, 0.25, 0.8)     # Deep blue — frozen
const COLOR_EDGE := Color(0.2, 1.0, 0.45)        # Bright green — alive
const COLOR_CHAOS := Color(0.95, 0.15, 0.1)      # Hot red — dissolved
const COLOR_WINDOW := Color(1.0, 0.85, 0.2)      # Gold — window of order

# Internal
var _orb_mesh: MeshInstance3D
var _orb_material: StandardMaterial3D
var _rings: Array[MeshInstance3D] = []
var _ring_materials: Array[StandardMaterial3D] = []
var _particles: GPUParticles3D
var _light: OmniLight3D
var _label: Label3D
var _state_label: Label3D
var _time: float = 0.0
var _current_regime: String = ""
var _pulse_speed: float = 1.0
var _wobble_amount: float = 0.0

func _ready() -> void:
	_build_orb()
	_build_rings()
	_build_particles()
	_build_light()
	_build_labels()
	_update_state()

	add_to_group("qfep_reactive")
	add_to_group("interactable")

	# Try connecting to existing lambda/phi controllers
	call_deferred("_connect_to_controllers")
	print("EdgeOfChaosOrb: Observing the edge of chaos")

# ---------------------------------------------------------------------------
# Orb — central glowing sphere
# ---------------------------------------------------------------------------

func _build_orb() -> void:
	_orb_mesh = MeshInstance3D.new()
	_orb_mesh.name = "OrbSphere"
	var sphere := SphereMesh.new()
	sphere.radius = orb_radius
	sphere.height = orb_radius * 2.0
	sphere.radial_segments = 32
	sphere.rings = 16
	_orb_mesh.mesh = sphere
	_orb_mesh.position = Vector3(0, orb_radius + 0.3, 0)

	_orb_material = StandardMaterial3D.new()
	_orb_material.albedo_color = COLOR_EDGE
	_orb_material.emission_enabled = true
	_orb_material.emission = COLOR_EDGE
	_orb_material.emission_energy_multiplier = 1.5
	_orb_material.metallic = 0.3
	_orb_material.roughness = 0.4
	_orb_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_orb_material.albedo_color.a = 0.85
	_orb_mesh.material_override = _orb_material

	add_child(_orb_mesh)

# ---------------------------------------------------------------------------
# Rings — orbit around the orb, speed reflects lambda
# ---------------------------------------------------------------------------

func _build_rings() -> void:
	for i in range(ring_count):
		var ring := MeshInstance3D.new()
		ring.name = "Ring%d" % i
		var torus := TorusMesh.new()
		torus.inner_radius = orb_radius + 0.05 + float(i) * 0.08
		torus.outer_radius = torus.inner_radius + 0.015
		torus.rings = 32
		torus.ring_segments = 12
		ring.mesh = torus
		ring.position = _orb_mesh.position

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 1.0, 1.0, 0.4)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = COLOR_EDGE
		mat.emission_energy_multiplier = 0.8
		ring.material_override = mat

		add_child(ring)
		_rings.append(ring)
		_ring_materials.append(mat)

# ---------------------------------------------------------------------------
# Particles — more active at edge, frozen at order, wild at chaos
# ---------------------------------------------------------------------------

func _build_particles() -> void:
	_particles = GPUParticles3D.new()
	_particles.name = "OrbParticles"
	_particles.amount = 60
	_particles.lifetime = 2.0
	_particles.position = _orb_mesh.position

	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pmat.emission_sphere_radius = orb_radius * 1.2
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = 0.1
	pmat.initial_velocity_max = 0.3
	pmat.gravity = Vector3.ZERO
	pmat.damping_min = 1.0
	pmat.damping_max = 2.0
	pmat.scale_min = 0.3
	pmat.scale_max = 1.0
	_particles.process_material = pmat

	var pmesh := SphereMesh.new()
	pmesh.radius = 0.012
	pmesh.height = 0.024
	_particles.draw_pass_1 = pmesh

	add_child(_particles)

# ---------------------------------------------------------------------------
# Light — radiates from orb
# ---------------------------------------------------------------------------

func _build_light() -> void:
	_light = OmniLight3D.new()
	_light.name = "OrbLight"
	_light.position = _orb_mesh.position
	_light.light_color = COLOR_EDGE
	_light.light_energy = 2.0
	_light.omni_range = 3.0
	_light.omni_attenuation = 1.5
	add_child(_light)

# ---------------------------------------------------------------------------
# Labels
# ---------------------------------------------------------------------------

func _build_labels() -> void:
	_label = Label3D.new()
	_label.text = "λ=0.40  φ=0.50"
	_label.font_size = 22
	_label.position = _orb_mesh.position + Vector3(0, orb_radius + 0.3, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.outline_size = 4
	_label.outline_modulate = Color.BLACK
	add_child(_label)

	_state_label = Label3D.new()
	_state_label.text = "EDGE OF CHAOS"
	_state_label.font_size = 18
	_state_label.position = _orb_mesh.position + Vector3(0, orb_radius + 0.5, 0)
	_state_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_state_label.outline_size = 3
	_state_label.outline_modulate = Color.BLACK
	add_child(_state_label)

# ---------------------------------------------------------------------------
# Connect to global QFEP controllers
# ---------------------------------------------------------------------------

func _connect_to_controllers() -> void:
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame

	for slider in get_tree().get_nodes_in_group("qfep_lambda_controllers"):
		if slider.has_signal("lambda_changed"):
			slider.lambda_changed.connect(func(v: float): lambda = v)
			print("EdgeOfChaosOrb: Connected to lambda controller")

	for slider in get_tree().get_nodes_in_group("qfep_phi_controllers"):
		if slider.has_signal("phi_changed"):
			slider.phi_changed.connect(func(v: float): phi = v)
			print("EdgeOfChaosOrb: Connected to phi controller")

# ---------------------------------------------------------------------------
# State computation
# ---------------------------------------------------------------------------

func _update_state() -> void:
	var color: Color
	var regime: String

	# Determine regime from lambda
	if lambda < 0.2:
		regime = "FROZEN (pure order)"
		color = COLOR_ORDER
		_pulse_speed = 0.3
		_wobble_amount = 0.0
	elif lambda < 0.35:
		regime = "CRYSTALLIZING"
		color = COLOR_ORDER.lerp(COLOR_EDGE, (lambda - 0.2) / 0.15)
		_pulse_speed = 0.8
		_wobble_amount = 0.01
	elif lambda >= 0.35 and lambda <= 0.5:
		regime = "EDGE OF CHAOS"
		var edge_t: float = (lambda - 0.35) / 0.15
		color = COLOR_EDGE
		# At the sweet spot, phi amplifies the glow
		if phi > 0.3:
			color = color.lerp(Color(0.4, 1.0, 0.6), phi * 0.5)
		_pulse_speed = 3.0 + phi * 4.0
		_wobble_amount = 0.05 + phi * 0.1
	elif lambda < 0.7:
		regime = "TURBULENT"
		color = COLOR_EDGE.lerp(COLOR_CHAOS, (lambda - 0.5) / 0.2)
		_pulse_speed = 5.0
		_wobble_amount = 0.15
	else:
		regime = "DISSOLVED (chaos)"
		color = COLOR_CHAOS
		_pulse_speed = 8.0
		_wobble_amount = 0.3

	# Apply to visuals
	if _orb_material:
		_orb_material.albedo_color = Color(color.r, color.g, color.b, 0.85)
		_orb_material.emission = color

	for mat in _ring_materials:
		mat.emission = color

	if _light:
		_light.light_color = color

	if _label:
		_label.text = "λ=%.2f  φ=%.2f" % [lambda, phi]
		_label.modulate = color

	if _state_label:
		_state_label.text = regime
		_state_label.modulate = color

	if regime != _current_regime:
		_current_regime = regime
		state_changed.emit(regime)

# ---------------------------------------------------------------------------
# Animation
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta

	# Keyboard fallback
	if Input.is_key_pressed(KEY_RIGHT):
		lambda = clampf(lambda + 0.3 * delta, 0.0, 1.0)
	if Input.is_key_pressed(KEY_LEFT):
		lambda = clampf(lambda - 0.3 * delta, 0.0, 1.0)
	if Input.is_key_pressed(KEY_UP):
		phi = clampf(phi + 0.3 * delta, 0.0, 1.0)
	if Input.is_key_pressed(KEY_DOWN):
		phi = clampf(phi - 0.3 * delta, 0.0, 1.0)

	# Pulsing emission
	if _orb_material:
		var pulse: float = 1.0 + sin(_time * _pulse_speed) * 0.5
		_orb_material.emission_energy_multiplier = pulse * (1.0 + phi)

	# Wobble the orb
	if _orb_mesh and _wobble_amount > 0:
		var wx: float = sin(_time * 2.3) * _wobble_amount
		var wz: float = cos(_time * 1.7) * _wobble_amount
		_orb_mesh.position.x = wx
		_orb_mesh.position.z = wz

	# Spin rings at varying speeds
	for i in range(_rings.size()):
		var ring := _rings[i]
		var speed: float = (1.0 + float(i) * 0.5) * _pulse_speed * 0.2
		var axis := Vector3(
			sin(float(i) * 1.2),
			1.0,
			cos(float(i) * 0.8)
		).normalized()
		ring.rotate(axis, speed * delta)

	# Particle energy
	if _particles and _particles.process_material:
		var pmat := _particles.process_material as ParticleProcessMaterial
		_particles.amount = int(lerpf(10.0, 120.0, lambda))
		pmat.initial_velocity_max = lerpf(0.05, 0.5, lambda)
		pmat.spread = lerpf(30.0, 180.0, lambda)

	# Light pulsing
	if _light:
		_light.light_energy = 1.5 + sin(_time * _pulse_speed) * 0.8

# Public API
func set_lambda(value: float) -> void:
	lambda = value

func set_phi(value: float) -> void:
	phi = value

func get_regime() -> String:
	return _current_regime
