# dark_sphere.gd
# Atmospheric dark sphere — ambient decorative artifact for L-system maps.
# A semi-transparent dark orb with pulsing emission, slow rotation,
# and a faint shadow halo underneath.

# @identity
# essence: a dark semi-transparent sphere pulses with purple emission and wobbles slowly — it marks the inhabited space without asserting itself, a witness to the algorithms around it
# desire: to be always present but never dominant — the learner barely notices it, but its absence would make the space feel empty
# critical_parameter: pulse_speed (1.2) and emission range (0.05–0.35) — too fast and it competes with the artifact; too slow and it reads as static
# triggers: _ready builds sphere + flat halo disc; _process drives rotation wobble and sinusoidal emission pulse every frame; apply_grid_config rebuilds both shapes
# emerges: the halo ring beneath the sphere creates a soft shadow that anchors it to the ground without a hard collision plane
# needs: VR grab [missing — pure ambient, not interactive]; color config from map [has via apply_grid_config]; apply_grid_config [has]
# relationships: placed alongside primary artifacts in nearly every primitives map; pairs with CoordinateSystem3M as spatial markers; contrasts with laser_exploding_sphere (reactive vs contemplative)
# truth: some things in a space exist not to be used but to be sensed — dark_sphere is a mood, not a lesson

extends Node3D

class_name DarkSphere


# Spine-corridor contract — see doc/SPINE_HINTS_CONTRACT.md
func spine_hints() -> Dictionary:
	return {
		"role":         "ambient",
		"footprint":    Vector2i(1, 1),
		"approach":     "any",
		"reading_dist": 0.0,
		"height":       -0.5,
		"budget_ms":    0.2,
		"tags":         ["visual"],
	}


## Display settings
@export var display_size: float = 0.5
@export var sphere_radius: float = 0.35
@export var float_height: float = 0.25
@export var rotation_speed: float = 0.15
@export var pulse_speed: float = 1.2
@export var pulse_min: float = 0.05
@export var pulse_max: float = 0.35

## Colors
@export var albedo_color: Color = Color(0.08, 0.04, 0.12)
@export var emission_color: Color = Color(0.18, 0.08, 0.28)

var _sphere_mesh: MeshInstance3D
var _halo_ring: MeshInstance3D
var _sphere_material: StandardMaterial3D
var _time_elapsed: float = 0.0


func _ready() -> void:
	_create_sphere()
	_create_halo_ring()


func _process(delta: float) -> void:
	_time_elapsed += delta

	# Slow rotation around Y axis with slight wobble on X
	if _sphere_mesh:
		_sphere_mesh.rotation.y += rotation_speed * delta
		_sphere_mesh.rotation.x = sin(_time_elapsed * 0.4) * 0.05

	# Pulsing emission energy
	if _sphere_material:
		var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
		_sphere_material.emission_energy_multiplier = lerpf(pulse_min, pulse_max, pulse_t)

		# Subtle albedo brightness oscillation
		var brightness := lerpf(0.6, 1.0, pulse_t)
		_sphere_material.albedo_color = Color(
			albedo_color.r * brightness,
			albedo_color.g * brightness,
			albedo_color.b * brightness,
			albedo_color.a
		)

	# Halo ring subtle pulse (opacity)
	if _halo_ring:
		var halo_mat := _halo_ring.material_override as StandardMaterial3D
		if halo_mat:
			var halo_t := (sin(_time_elapsed * pulse_speed * 0.7) + 1.0) * 0.5
			halo_mat.albedo_color.a = lerpf(0.08, 0.2, halo_t)


func _create_sphere() -> void:
	_sphere_mesh = MeshInstance3D.new()
	_sphere_mesh.name = "SphereDisplay"

	var mesh := SphereMesh.new()
	mesh.radius = sphere_radius
	mesh.height = sphere_radius * 2.0
	mesh.radial_segments = 32
	mesh.rings = 16
	_sphere_mesh.mesh = mesh

	# Dark semi-transparent material with metallic sheen and emission
	_sphere_material = StandardMaterial3D.new()
	_sphere_material.albedo_color = Color(albedo_color.r, albedo_color.g, albedo_color.b, 0.85)
	_sphere_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_sphere_material.metallic = 0.6
	_sphere_material.metallic_specular = 0.7
	_sphere_material.roughness = 0.25
	_sphere_material.emission_enabled = true
	_sphere_material.emission = emission_color
	_sphere_material.emission_energy_multiplier = pulse_min
	_sphere_material.cull_mode = BaseMaterial3D.CULL_BACK
	_sphere_mesh.material_override = _sphere_material

	# Float above the ground
	_sphere_mesh.position = Vector3(0, float_height + sphere_radius, 0)

	add_child(_sphere_mesh)


func _create_halo_ring() -> void:
	_halo_ring = MeshInstance3D.new()
	_halo_ring.name = "HaloRing"

	# Flat cylinder acting as a shadow/halo disc beneath the sphere
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = sphere_radius * 1.2
	ring_mesh.bottom_radius = sphere_radius * 1.2
	ring_mesh.height = 0.005
	ring_mesh.radial_segments = 24
	_halo_ring.mesh = ring_mesh

	var halo_mat := StandardMaterial3D.new()
	halo_mat.albedo_color = Color(0.1, 0.04, 0.16, 0.15)
	halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_halo_ring.material_override = halo_mat

	# Sit just above the ground plane
	_halo_ring.position = Vector3(0, 0.01, 0)

	add_child(_halo_ring)


## Grid system integration
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("display_size"):
		display_size = float(config_data["display_size"])
	if config_data.has("sphere_radius"):
		sphere_radius = clampf(float(config_data["sphere_radius"]), 0.1, 1.0)
	if config_data.has("float_height"):
		float_height = clampf(float(config_data["float_height"]), 0.0, 1.0)
	if config_data.has("rotation_speed"):
		rotation_speed = clampf(float(config_data["rotation_speed"]), 0.0, 2.0)
	if config_data.has("pulse_speed"):
		pulse_speed = clampf(float(config_data["pulse_speed"]), 0.1, 5.0)
	if config_data.has("emission_color"):
		var c = config_data["emission_color"]
		if c is Color:
			emission_color = c
	if config_data.has("albedo_color"):
		var c = config_data["albedo_color"]
		if c is Color:
			albedo_color = c

	# Rebuild with new parameters
	for child in get_children():
		child.queue_free()
	_create_sphere()
	_create_halo_ring()
