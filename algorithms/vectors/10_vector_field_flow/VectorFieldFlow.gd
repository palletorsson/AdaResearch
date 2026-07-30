extends "res://algorithms/vectors/shared/vector_scene_base.gd"

# @identity
# essence: F(p) = swirl(p) - radial(p). A vector field assigns a direction to every point. The particle reads the field and follows.
# desire: To make an invisible flow visible — 81 arrows breathing in unison, a particle tracing the field's will.
# critical_parameter: The swirl-to-radial ratio in _field_value(). It determines whether the field spirals inward, orbits, or ejects.
# triggers: Automatic — arrows oscillate vertically, particle advects continuously. R → reset particle to origin, Space → freeze velocity.
# emerges: Spiral trajectories from the combination of rotational swirl and inward radial pull. The particle's path is never a straight line.
# needs: MultiMesh arrows [has], particle tracer [has]. Missing: VR slider to blend swirl vs radial, grabbable field source.
# relationships: Applied version of force_field_visualizer (same concept, different rendering). Feeds into weather_vector_field (wind as vector field).
# truth: A vector field is a set of instructions written in space. The particle has no memory and no plan — it only reads the local instruction.

const GRID_RANGE := 4
const GRID_SPACING := 0.9
const FIELD_VERTICAL_OSCILLATION := 0.3
const FIELD_VERTICAL_FREQUENCY := 0.75
const PARTICLE_FOLLOW := 0.35
const PARTICLE_DAMPING := 0.985
const PARTICLE_VERTICAL_LIMIT := 0.35

# ---------------------------------------------------------------------------
# DNA — stage 2 (variation), promoted 2026-07-29
# ---------------------------------------------------------------------------
# The @identity already named the parameter space: "the swirl-to-radial ratio in
# _field_value()... determines whether the field spirals inward, orbits, or
# ejects", and asked for a way to blend the two. These two knobs are that.
#
#   field — what instruction space is written with
#     "spiral"  swirl with a weak inward pull (the historical field, exactly)
#               — the particle circles AND falls: it never repeats a path.
#     "orbit"   pure swirl, no radial term — closed circles. The field keeps
#               you, forever, at the radius you arrived with.
#     "sink"    pure inward radial — no rotation. Every start ends at the
#               centre; the field is a drain and origin is destiny.
#     "source"  pure outward radial — the field is an exile. Nothing stays.
#
#   lattice — how the invisible instruction is made visible
#     "square"  the 9x9 Cartesian grid of arrows (historical).
#     "polar"   concentric rings of samples — shows the field's OWN symmetry
#               instead of the grid's; the square lattice was already an
#               argument about what kind of space this is.
#     "hidden"  no arrows at all. Only the tracer moves, and the field must be
#               inferred from behaviour rather than read off a diagram.
const FIELD_MODES: Array = ["spiral", "orbit", "sink", "source"]
const LATTICES: Array = ["square", "polar", "hidden"]

# Per-mode (swirl gain, radial gain). "spiral" reproduces the pre-promotion
# formula exactly: Vector3(-z, breath, x) - position * 0.1.
const FIELD_GAINS: Dictionary = {
	"spiral": Vector2(1.0, 0.1),
	"orbit": Vector2(1.0, 0.0),
	"sink": Vector2(0.0, 1.0),
	"source": Vector2(0.0, -1.0),
}

@export var field: String = "spiral"
@export var lattice: String = "square"

var field_vectors: Array[Node3D] = []  # kept for compatibility but unused with MultiMesh
var particle: Node3D
var particle_velocity: Vector3 = Vector3.ZERO
var particle_position: Vector3 = Vector3.ZERO
var info_label: Label
var elapsed := 0.0

# MultiMesh for field arrows — replaces 81 line scenes with 2 draw calls
var _field_shaft_mm_instance: MultiMeshInstance3D
var _field_head_mm_instance: MultiMeshInstance3D
var _field_origins: PackedVector3Array = PackedVector3Array()
var _field_count: int = 0

func _ready() -> void:
	super._ready()
	# Match the compact exhibition presentation used by other advanced vector scenes.
	scale = Vector3(0.5, 0.5, 0.5)
	create_axes(4.5)
	_create_field_vectors()
	particle = _create_particle_marker()
	reposition_particle(Vector3.ZERO)
	info_label = create_info_panel(
		"Vector Field Flow",
		Vector3(-3.5, 2.5, 0.0),
		Vector2(2.4, 1.0),
		"F(p) = swirl - radial",
		"Particle follows field vectors"
	)

func _process(delta: float) -> void:
	elapsed += delta
	_update_field_vectors()
	_update_particle(delta)
	_update_info()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			reposition_particle(Vector3.ZERO)
			restart_particle()
		if event.keycode == KEY_SPACE:
			particle_velocity = Vector3.ZERO

func _create_field_vectors() -> void:
	# Compute sample origins for the chosen lattice
	_field_origins.clear()
	match lattice:
		"polar":
			# Concentric rings: the field's own symmetry rather than the grid's.
			_field_origins.append(Vector3.ZERO)
			for ring in range(1, GRID_RANGE + 1):
				var radius: float = float(ring) * GRID_SPACING
				var spokes: int = 4 + ring * 4
				for s in range(spokes):
					var ang: float = TAU * float(s) / float(spokes)
					_field_origins.append(Vector3(cos(ang) * radius, 0.0, sin(ang) * radius))
		"hidden":
			# No arrows: the field is inferred from the tracer, not displayed.
			pass
		_:
			# "square" — the historical 9x9 Cartesian grid.
			for x in range(-GRID_RANGE, GRID_RANGE + 1):
				for z in range(-GRID_RANGE, GRID_RANGE + 1):
					_field_origins.append(Vector3(x * GRID_SPACING, 0.0, z * GRID_SPACING))
	_field_count = _field_origins.size()

	# Arrow shafts — unit cylinder scaled per instance
	var shaft_cyl := CylinderMesh.new()
	shaft_cyl.top_radius = 0.006
	shaft_cyl.bottom_radius = 0.006
	shaft_cyl.height = 1.0
	shaft_cyl.radial_segments = 8
	var shaft_mat := StandardMaterial3D.new()
	shaft_mat.albedo_color = Color(0.3, 0.8, 1.0, 1.0)
	shaft_mat.emission_enabled = true
	shaft_mat.emission = Color(0.3, 0.8, 1.0) * 0.5
	shaft_cyl.material = shaft_mat

	var shaft_mm := MultiMesh.new()
	shaft_mm.transform_format = MultiMesh.TRANSFORM_3D
	shaft_mm.instance_count = _field_count
	shaft_mm.mesh = shaft_cyl

	_field_shaft_mm_instance = MultiMeshInstance3D.new()
	_field_shaft_mm_instance.name = "FieldShaftMM"
	_field_shaft_mm_instance.multimesh = shaft_mm
	add_child(_field_shaft_mm_instance)

	# Arrow heads — small cone
	var head_cone := CylinderMesh.new()
	head_cone.top_radius = 0.0
	head_cone.bottom_radius = 0.025
	head_cone.height = 0.12
	head_cone.radial_segments = 12
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.3, 0.8, 1.0, 1.0)
	head_mat.emission_enabled = true
	head_mat.emission = Color(0.3, 0.8, 1.0) * 0.5
	head_cone.material = head_mat

	var head_mm := MultiMesh.new()
	head_mm.transform_format = MultiMesh.TRANSFORM_3D
	head_mm.instance_count = _field_count
	head_mm.mesh = head_cone

	_field_head_mm_instance = MultiMeshInstance3D.new()
	_field_head_mm_instance.name = "FieldHeadMM"
	_field_head_mm_instance.multimesh = head_mm
	add_child(_field_head_mm_instance)

func _update_field_vectors() -> void:
	if not _field_shaft_mm_instance or not _field_head_mm_instance:
		return
	var shaft_mm := _field_shaft_mm_instance.multimesh
	var head_mm := _field_head_mm_instance.multimesh
	var sc := SCENE_SCALE

	for i in _field_count:
		var origin := _field_origins[i]
		var value := _field_value(origin)
		var mag := value.length()

		# Origin in local space (scene is scaled by SCENE_SCALE in _ready)
		var base := origin * sc

		if mag < 0.001:
			# Hide this instance
			var hidden := Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3(0, -999, 0))
			shaft_mm.set_instance_transform(i, hidden)
			head_mm.set_instance_transform(i, hidden)
			continue

		var dir := value / mag
		var arrow_len := mag * sc  # Scale arrow length to scene scale
		# Build basis: Y axis along direction, height = arrow_len
		var up := Vector3.UP
		if abs(dir.dot(up)) > 0.99:
			up = Vector3.RIGHT
		var right := dir.cross(up).normalized()
		up = right.cross(dir).normalized()

		# Shaft: centered at origin + half arrow length along direction
		var shaft_basis := Basis(right, dir * arrow_len, up)
		var shaft_pos := base + dir * (arrow_len * 0.5)
		shaft_mm.set_instance_transform(i, Transform3D(shaft_basis, shaft_pos))

		# Head: at tip of arrow
		var head_basis := Basis(right, dir, up)  # Unit scale, just oriented
		var head_pos := base + dir * arrow_len
		head_mm.set_instance_transform(i, Transform3D(head_basis, head_pos))

func _field_value(position: Vector3) -> Vector3:
	var gains: Vector2 = FIELD_GAINS.get(field, FIELD_GAINS["spiral"])
	var swirl_gain: float = gains.x
	var radial_gain: float = gains.y
	var swirl = Vector3(
		-position.z * swirl_gain,
		FIELD_VERTICAL_OSCILLATION * sin(elapsed * FIELD_VERTICAL_FREQUENCY),
		position.x * swirl_gain
	)
	var radial = position * radial_gain
	return (swirl - radial).limit_length(2.5)

func _create_particle_marker() -> Node3D:
	var marker = Node3D.new()
	marker.name = "Particle"
	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.06
	sphere.height = 0.12
	sphere.radial_segments = 24
	sphere.rings = 16
	mesh.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.6, 0.4, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.2, 1.0) * 0.5
	mesh.material_override = mat
	marker.add_child(mesh)
	add_child(marker)
	return marker

func _update_particle(delta: float) -> void:
	var sample = _field_value(particle_position)
	# Keep vertical motion compact and readable in VR.
	sample.y *= 0.5
	particle_velocity = particle_velocity.lerp(sample, PARTICLE_FOLLOW)
	particle_velocity *= PARTICLE_DAMPING
	particle_position += particle_velocity * delta
	if absf(particle_position.y) > PARTICLE_VERTICAL_LIMIT:
		particle_position.y = clampf(
			particle_position.y,
			-PARTICLE_VERTICAL_LIMIT,
			PARTICLE_VERTICAL_LIMIT
		)
		particle_velocity.y *= -0.25
	reposition_particle(particle_position)

func reposition_particle(position: Vector3) -> void:
	particle_position = position
	if particle:
		particle.position = particle_position

func restart_particle() -> void:
	particle_velocity = Vector3.ZERO

func _update_info() -> void:
	var field_here = _field_value(particle_position)
	var builder := []
	builder.append("Position = (%.2f, %.2f, %.2f)" % [particle_position.x, particle_position.y, particle_position.z])
	builder.append("Velocity = (%.2f, %.2f, %.2f)" % [particle_velocity.x, particle_velocity.y, particle_velocity.z])
	builder.append("Field(position) = (%.2f, %.2f, %.2f)" % [field_here.x, field_here.y, field_here.z])
	info_label.text = "\n".join(builder)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	# NOTE: deliberately does not chain to VectorSceneBase.apply_grid_config().
	# This scene builds inline in _ready() rather than overriding build_scene(),
	# so the base rebuild() would tear it down and rebuild nothing. That was true
	# before this promotion and is unchanged by it.
	if config == null or config.is_empty():
		return

	if config.has("field"):
		var new_field: String = str(config["field"]).strip_edges().to_lower()
		if FIELD_MODES.has(new_field):
			# Read fresh every frame by _field_value(); no rebuild needed.
			field = new_field

	if config.has("lattice"):
		var new_lattice: String = str(config["lattice"]).strip_edges().to_lower()
		# Only touch the arrows when the value actually CHANGED and the scene has
		# already been built. Placements that pass no genome never get here, so
		# their 81-arrow square grid is bit-identical to before.
		if LATTICES.has(new_lattice) and new_lattice != lattice:
			lattice = new_lattice
			if _field_shaft_mm_instance != null:
				_rebuild_field_arrows()

# Free the two MultiMeshInstance3D arrow layers and lay out the new lattice.
func _rebuild_field_arrows() -> void:
	var layers: Array = [_field_shaft_mm_instance, _field_head_mm_instance]
	for i in range(layers.size()):
		var mm: Node = layers[i]
		if mm != null and is_instance_valid(mm):
			remove_child(mm)
			mm.queue_free()
	_field_shaft_mm_instance = null
	_field_head_mm_instance = null
	_create_field_vectors()
