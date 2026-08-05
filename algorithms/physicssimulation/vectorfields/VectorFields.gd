## Vector Fields — Visualizes force fields with MultiMesh arrows and Area3D sources
## Arrows rendered in ONE draw call via MultiMesh, particles advected through the field
##
## @identity
## essence: F(p) = sum(sources). Each point samples the superposed field of all Area3D gravity sources. Arrows point where particles would go.
## desire: To place an attractor and a repulsor and watch the field tear itself between them — arrows bending, particles caught in the tug of war.
## critical_parameter: The ratio of attractor gravity (+8) to repulsor gravity (-6). It determines whether particles orbit, escape, or get trapped.
## triggers: Automatic — 125 arrows orient by sampling field, 30 particles advected by Area3D gravity overrides, escaped particles respawn randomly
## emerges: Saddle points between attractor and repulsor where the field cancels. Particle streams forming visible flow lanes. Color gradient mapping field magnitude.
## needs: MultiMesh arrow grid [has], RigidBody3D test particles [has], Area3D sources [has]. Missing: VR grabbable sources, field strength sliders.
## relationships: More physical than VectorFieldFlow (uses Godot's Area3D physics). Complements force_field_visualizer (which computes fields analytically). Lives in ForcesSystems.
## truth: A field is not a picture of arrows. It is a promise: if you put a particle here, this is what will happen.
extends Node3D

@export var grid_resolution: int = 5  # arrows per axis (5³ = 125 arrows)
@export var grid_spacing: float = 0.7
@export var arrow_scale: float = 0.18
@export var particle_count: int = 30

## --- DNA (stage 2, promoted 2026-08-04) --------------------------------------------
## poles — WHAT MAKES THE FIELD. The law never changes: every arrow is the superposition
##   of point sources falling off as 1/d², the same three lines of _update_arrows at every
##   value. What changes is how many sources there are and which way they pull, and that
##   is the whole taxonomy a two-body field has: one attractor (`sink`), one repulsor
##   (`source`), one of each (`dipole`, the shipped pair), two alike (`binary`). The
##   positions and the gravities are the shipped ones reused, not new numbers.
## coding — WHAT THE ARROW COLOUR CLAIMS. Reused character for character from
##   vector_field_grid, where it asks exactly this question of exactly this kind of
##   picture. Arrow LENGTH already carries |F| at every value, so `uniform` withholds
##   colour without withholding the magnitude.
@export_enum("dipole", "sink", "source", "binary") var poles: String = "dipole"
@export_enum("magnitude", "direction", "banded", "uniform") var coding: String = "magnitude"
## 0 keeps the shipped unseeded scatter — any other value pins the 30 test particles so a
## sweep photographs one field twice, not two particle clouds. See dna.fixture.
@export var seed_value: int = 0

const POLES := ["dipole", "sink", "source", "binary"]
const CODINGS := ["magnitude", "direction", "banded", "uniform"]

var arrow_multimesh: MultiMeshInstance3D
var field_sources: Array[Area3D] = []
var particles: Array[RigidBody3D] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	scale = Vector3(0.8, 0.8, 0.8)
	if seed_value != 0:
		_rng.seed = seed_value
	_create_field_sources()
	_create_arrow_grid()
	_create_test_particles()

# [ [position, gravity], ... ]. The `_:` arm is the shipped pair, so `dipole` builds the
# attractor at (-1.5, 1.5, 0) with +8 and the repulsor at (1.5, 1.5, 0) with -6, in that
# order, exactly as before. Every other value reuses those same two numbers.
func _pole_spec() -> Array:
	match poles:
		"sink":
			return [[Vector3(0, 1.5, 0), 8.0]]
		"source":
			return [[Vector3(0, 1.5, 0), -6.0]]
		"binary":
			return [[Vector3(-1.5, 1.5, 0), 8.0], [Vector3(1.5, 1.5, 0), 8.0]]
	# dipole, and the fallback for any word the code does not know: an unrecognised value
	# renders the shipped field rather than blanking it.
	return [[Vector3(-1.5, 1.5, 0), 8.0], [Vector3(1.5, 1.5, 0), -6.0]]

func _create_field_sources() -> void:
	for entry in _pole_spec():
		var spec: Array = entry
		var pos: Vector3 = spec[0]
		var g: float = spec[1]
		var pull: bool = g > 0.0

		var area := Area3D.new()
		area.name = "Attractor" if pull else "Repulsor"
		area.gravity_space_override = Area3D.SPACE_OVERRIDE_COMBINE
		area.gravity_point = true
		area.gravity = g  # Negative = repulsion
		area.gravity_point_unit_distance = 2.0
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 3.0
		col.shape = shape
		area.add_child(col)
		area.position = pos

		# Visual marker — red pulls, blue pushes, as shipped.
		var marker := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = 0.25
		marker.mesh = ball
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.3, 0.3) if pull else Color(0.3, 0.5, 1.0)
		mat.emission_enabled = true
		mat.emission = (Color(1.0, 0.2, 0.2) if pull else Color(0.2, 0.4, 1.0)) * 1.5
		marker.material_override = mat
		area.add_child(marker)
		add_child(area)
		field_sources.append(area)

func _create_arrow_grid() -> void:
	arrow_multimesh = MultiMeshInstance3D.new()
	arrow_multimesh.name = "ArrowGrid"

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var total := grid_resolution * grid_resolution * grid_resolution
	mm.instance_count = total

	# Arrow mesh (thin cone)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = arrow_scale * 0.5
	cone.height = arrow_scale * 2.0
	mm.mesh = cone

	arrow_multimesh.multimesh = mm

	# Material
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 1.5
	arrow_multimesh.material_override = mat

	add_child(arrow_multimesh)
	_update_arrows()

func _create_test_particles() -> void:
	for i in range(particle_count):
		var rb := RigidBody3D.new()
		rb.mass = 0.1
		rb.linear_damp = 1.0  # Some drag so they don't fly away

		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.04
		col.shape = shape
		rb.add_child(col)

		var mesh_inst := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.06
		sphere.height = 0.12
		mesh_inst.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 1.0, 0.3)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.9, 0.2) * 1.2
		mesh_inst.material_override = mat
		rb.add_child(mesh_inst)

		# Random position in the field
		rb.position = _scatter()
		rb.gravity_scale = 0.0  # Only affected by Area3D fields

		add_child(rb)
		particles.append(rb)

# The shipped scatter when seed_value is 0 — the same global randf_range calls in the same
# order, so every existing placement keeps the random cloud it has always had. A nonzero
# seed swaps in a local RNG, which is what makes two sweep frames comparable: without it
# five values of `poles` are five different particle clouds and the diff is noise.
func _scatter() -> Vector3:
	if seed_value == 0:
		return Vector3(randf_range(-1.5, 1.5), randf_range(0.5, 2.5), randf_range(-1.5, 1.5))
	return Vector3(
		_rng.randf_range(-1.5, 1.5),
		_rng.randf_range(0.5, 2.5),
		_rng.randf_range(-1.5, 1.5)
	)

func _physics_process(_delta: float):
	# Respawn escaped particles
	for rb in particles:
		if rb.position.length() > 5.0:
			rb.position = _scatter()
			rb.linear_velocity = Vector3.ZERO

func _update_arrows() -> void:
	var mm := arrow_multimesh.multimesh
	var idx := 0
	var half := (grid_resolution - 1) * grid_spacing * 0.5

	for x in range(grid_resolution):
		for y in range(grid_resolution):
			for z in range(grid_resolution):
				var pos := Vector3(
					x * grid_spacing - half,
					y * grid_spacing + 0.3,
					z * grid_spacing - half
				)

				# Calculate field vector at this point
				var field := Vector3.ZERO
				for source in field_sources:
					var to_source := source.position - pos
					var dist := to_source.length()
					if dist < 0.1:
						continue
					var strength: float = source.gravity / (dist * dist)
					if source.gravity > 0:
						field += to_source.normalized() * strength
					else:
						field -= to_source.normalized() * abs(strength)

				# Orient arrow along field direction
				var t := Transform3D.IDENTITY
				t.origin = pos
				if field.length() > 0.01:
					var up := Vector3.UP
					if abs(field.normalized().dot(up)) > 0.99:
						up = Vector3.RIGHT
					t = t.looking_at(pos + field.normalized(), up)
					t.basis = t.basis * Basis(Vector3.RIGHT, -PI / 2)  # Point cone along direction

				var mag: float = clamp(field.length(), 0.1, 3.0)
				t.basis = t.basis.scaled(Vector3(1, mag, 1))
				mm.set_instance_transform(idx, t)

				# Color by magnitude — or by whatever `coding` says the colour means.
				# Arrow LENGTH is scaled by mag at every value, so nothing here removes
				# the magnitude from the picture; it only changes what the hue claims.
				var color := Color.from_hsv(0.6 - clamp(mag / 3.0, 0, 0.6), 0.8, 1.0)
				match coding:
					"direction":
						# The optical-flow convention: hue IS the heading, and speed is
						# not in the colour at all. Azimuth only — a hue circle cannot
						# carry two angles, and the lattice is read from the side.
						var d: Vector3 = field.normalized()
						var az: float = (atan2(d.z, d.x) + PI) / TAU
						color = Color.from_hsv(fposmod(az, 1.0), 0.8, 1.0)
					"banded":
						# A legend where there was a ramp: four classes of |F|.
						var band: float = floor(clamp(mag / 3.0, 0.0, 0.999) * 4.0)
						color = Color.from_hsv(0.6 - (band / 3.0) * 0.6, 0.8, 1.0)
					"uniform":
						color = Color.from_hsv(0.6, 0.8, 1.0)
				mm.set_instance_color(idx, color)

				idx += 1

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# Was `pass`, which is why the runner found no turnable knob: four exports existed and a
# map could reach none of them. Still nothing rebuilds unless a word both VALIDATES and
# DIFFERS, and never before _ready has built once — an unknown key is ignored, so a typo
# falls back to the shipped field rather than blanking it.
func apply_grid_config(config: Dictionary) -> void:
	var touched: bool = false
	if config.has("coding"):
		var c: String = str(config["coding"])
		if CODINGS.has(c) and c != coding:
			coding = c
			touched = true
	if config.has("poles"):
		var p: String = str(config["poles"])
		if POLES.has(p) and p != poles:
			poles = p
			touched = true
			if is_node_ready():
				for src in field_sources:
					remove_child(src)
					src.queue_free()
				field_sources.clear()
				_create_field_sources()
	if touched and is_node_ready() and arrow_multimesh != null:
		_update_arrows()
