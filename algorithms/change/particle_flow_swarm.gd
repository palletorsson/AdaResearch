# Particle Flow Swarm — particles following a vector field
#
# Pairs with vector_field_grid: the same field, but instead of static arrows we see
# many small particles being carried along by it. Particles that drift off the plane
# re-spawn at the opposite side, so the flow visualization is continuous. Trails fade
# to suggest streamlines without saving them all — this line described an intention for
# a long time and no code; `trace` (2026-08-05) implements it by integrating the field
# BACKWARDS from each head rather than by recording where anything has been.
#
# Demonstrates that a vector field acts on whatever rides it. Foreshadows forces and the
# integration phase (where settling = riding a gradient field).
#
# @qfep_term: F (the field) + Δ(S,t) (the riding).
#
# @identity
# essence: many small particles carried along the same stream-function field vector_field_grid draws, re-spawning across the plane so the flow reads as continuous streamlines
# desire: to show that a vector field acts on whatever rides it — the field's effect, not just its shape
# critical_parameter: particle_count — the swarm density; too few and streamlines never form, too many and the MultiMesh floods the plane into a blur
# triggers: _ready() builds a MultiMesh and spawns particles; _process advances each along the local field vector and re-spawns those that drift off-domain
# emerges: streamlines without stored trails — the field made kinetic, foreshadowing settling-as-riding-a-gradient in the integration phase
# needs: MultiMeshInstance3D [present]; particle integrator over the field [present]; apply_grid_config for particle_count [present]; class_name ParticleFlowSwarm [present]; @identity [present, 2026-07-12]
# relationships: rides the field that vector_field_grid displays; foreshadows forces and gradient_descent; sibling in the change sequence
# truth: a field is invisible until a body moves through it — the particle is how the field speaks.

extends Node3D
class_name ParticleFlowSwarm

@export_category("Flow Settings")
@export var particle_color: Color = Color(0.7, 0.95, 1.0, 1.0)
@export var hot_color: Color = Color(1.0, 0.7, 0.4, 1.0)
@export var particle_count: int = 220
@export var domain_x: float = 2.4
@export var domain_z: float = 1.6
@export var step_scale: float = 0.012
@export var k: float = 2.5

## --- DNA (stage 2, promoted 2026-08-05) ---------------------------------------
## WHICH RULE THE PARTICLES RIDE. The word, the five values and their arithmetic are
## taken character for character from vector_field_grid (registry change.json,
## promoted 2026-08-03), which DRAWS the field these particles ride. The pairing is
## the whole point of both artifacts, so a map that says `field:sink` to one and not
## the other has broken the pair; saying it to both keeps them one exhibit.
@export_enum("cells", "orbit", "sink", "saddle", "shear") var field: String = "cells"
## HOW MUCH OF EACH PARTICLE'S PATH IS ADMITTED INTO THE PICTURE. This is the swarm's
## OWN question — the one thing it can say that the grid of arrows cannot, because a
## body has a history and an arrow does not.
##   points     - where the bodies are now, and nothing else (shipped)
##   wake       - a short upstream tail behind each head: where it just came from
##   streamline - a long thread with no head emphasis at all; the particle stops
##                being a body and becomes the field's integral curve
## The tail is INTEGRATED BACKWARDS from the head at capture time rather than
## recorded, so it needs no history and is identical on frame one and frame one
## thousand. It is therefore a streamline of the instantaneous field, not a
## pathline — the two differ under `cells`, which scrolls, and coincide under the
## four steady fields.
@export_enum("points", "wake", "streamline") var trace: String = "points"
## 0 keeps the shipped GLOBAL randf_range spawn, unseeded, so two swarms in one room
## are still two different clouds. Non-zero switches to a private RNG and pins the
## draw, which is what the DNA bench needs and no map asks for.
@export var flow_seed: int = 0
## Fixed-delta integration steps run once in _ready. 0 is shipped: the cloud starts
## where it was spawned. The bench needs the field to have ACTED before the shutter.
@export var warmup_steps: int = 0
## 0.0 parks the swarm so a still is reproducible. 1.0 is shipped.
@export var time_scale: float = 1.0

const FIELDS: Array[String] = ["cells", "orbit", "sink", "saddle", "shear"]
const TRACES: Array[String] = ["points", "wake", "streamline"]
## Tail instances per particle, per trace value.
const TRACE_TAIL := {"points": 0, "wake": 8, "streamline": 44}

var _particles: Array = []
var _multi_mesh_inst: MultiMeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	_build_multimesh()
	_spawn_particles()
	if warmup_steps > 0:
		for i in warmup_steps:
			_t += 1.0 / 60.0
			_step_particles(1.0 / 60.0)
		_write_to_multimesh()


func apply_grid_config(config_data: Dictionary) -> void:
	var rebuild: bool = false
	if config_data.has("particle_count"):
		particle_count = int(config_data["particle_count"])
		rebuild = true
	# field is read fresh every frame by _field_at, so it never needs a rebuild and is
	# safe before or after _ready. An unknown word is ignored rather than assigned, so
	# a typo falls back to the shipped flow instead of stopping it.
	if config_data.has("field"):
		var want_field: String = str(config_data["field"])
		if FIELDS.has(want_field):
			field = want_field
	# trace DOES need one, because it changes the MultiMesh instance count — but only
	# when the value actually changed, so a config call naming nothing this artifact
	# owns tears nothing down.
	if config_data.has("trace"):
		var want_trace: String = str(config_data["trace"])
		if TRACES.has(want_trace) and want_trace != trace:
			trace = want_trace
			rebuild = true
	if rebuild:
		if is_instance_valid(_multi_mesh_inst):
			_multi_mesh_inst.queue_free()
		_particles.clear()
		_build_multimesh()
		_spawn_particles()


func _process(delta: float) -> void:
	if time_scale <= 0.0:
		return
	_t += delta * time_scale
	_step_particles(delta)
	_write_to_multimesh()


func _build_multimesh() -> void:
	_multi_mesh_inst = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var sphere := SphereMesh.new()
	sphere.radius = 0.025
	sphere.height = 0.05
	mm.mesh = sphere
	# At trace=points this is `particle_count`, the shipped line.
	mm.instance_count = particle_count * (1 + _tail_len())
	_multi_mesh_inst.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = particle_color
	mat.emission_enabled = true
	mat.emission = particle_color
	mat.emission_energy_multiplier = 1.5
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Apply via mesh's material_override.
	_multi_mesh_inst.material_override = mat
	add_child(_multi_mesh_inst)


func _tail_len() -> int:
	return int(TRACE_TAIL.get(trace, 0))


func _spawn_particles() -> void:
	var rng := RandomNumberGenerator.new()
	if flow_seed != 0:
		rng.seed = flow_seed
	for i in particle_count:
		var px: float
		var pz: float
		if flow_seed != 0:
			px = rng.randf_range(-domain_x * 0.5, domain_x * 0.5)
			pz = rng.randf_range(-domain_z * 0.5, domain_z * 0.5)
		else:
			# the shipped calls, in the shipped order, on the shipped global RNG
			px = randf_range(-domain_x * 0.5, domain_x * 0.5)
			pz = randf_range(-domain_z * 0.5, domain_z * 0.5)
		_particles.append({"x": px, "z": pz})


func _field_at(x: float, z: float) -> Vector3:
	# k is the shipped wavenumber of the stream function; the four linear fields reuse
	# it as their gain, exactly as vector_field_grid does, so |v| spans the same range
	# at every value and the speed tint keeps meaning one thing across the axis.
	match field:
		"orbit":
			# ẋ = (-z, x) — a centre. Closed circles: kept at the radius you arrived with.
			return Vector3(-z, 0.0, x) * k
		"sink":
			# ẋ = -p — a stable node. Every trajectory ends at the origin.
			return Vector3(-x, 0.0, -z) * k
		"saddle":
			# ẋ = (x, -z) — one hyperbolic point, the cell the default field tiles.
			return Vector3(x, 0.0, -z) * k
		"shear":
			# ẋ = (z, 0) — parallel layers sliding past each other at different speeds.
			return Vector3(z, 0.0, 0.0) * k
		_:
			# Same field as vector_field_grid: v = (∂Ψ/∂z, -∂Ψ/∂x), Ψ = sin(x*k + t)cos(z*k + t)
			var phase := _t * 0.4
			var psi_dz: float = -sin(x * k + phase) * sin(z * k + phase) * k
			var psi_dx: float = cos(x * k + phase) * cos(z * k + phase) * k
			return Vector3(psi_dz, 0.0, -psi_dx)


func _step_particles(delta: float) -> void:
	for p in _particles:
		var v := _field_at(p["x"], p["z"])
		p["x"] += v.x * step_scale
		p["z"] += v.z * step_scale
		# Wrap-around domain.
		if p["x"] > domain_x * 0.5:
			p["x"] -= domain_x
		elif p["x"] < -domain_x * 0.5:
			p["x"] += domain_x
		if p["z"] > domain_z * 0.5:
			p["z"] -= domain_z
		elif p["z"] < -domain_z * 0.5:
			p["z"] += domain_z


## A particle's instance transform. At scale 1.0 this returns the shipped line
## untouched — short circuit rather than recompute, so the 26 rooms standing on the
## default never pay for a Basis they do not use.
func _instance_xf(x: float, z: float, s: float) -> Transform3D:
	if s == 1.0:
		return Transform3D(Basis(), Vector3(x, 0.08, z))
	return Transform3D(Basis().scaled(Vector3.ONE * s), Vector3(x, 0.08, z))


func _write_to_multimesh() -> void:
	if not is_instance_valid(_multi_mesh_inst):
		return
	var mm := _multi_mesh_inst.multimesh
	var tail: int = _tail_len()
	var stride: int = 1 + tail
	# Under streamline the head is not privileged: the curve is the object.
	var head_scale: float = 0.34 if trace == "streamline" else 1.0
	for i in min(particle_count, _particles.size()):
		var p: Dictionary = _particles[i]
		var x: float = p["x"]
		var z: float = p["z"]
		var v := _field_at(x, z)
		var speed: float = v.length()
		var t_speed: float = clamp(speed / 3.5, 0.0, 1.0)
		var col := particle_color.lerp(hot_color, t_speed)
		var base: int = i * stride
		mm.set_instance_color(base, col)
		mm.set_instance_transform(base, _instance_xf(x, z, head_scale))
		if tail == 0:
			continue
		# Walk UPSTREAM from the head with the same integrator, so the tail is the path
		# the particle actually took. A tail point that leaves the domain is parked at
		# zero scale rather than wrapped: the swarm's wrap-around is a bookkeeping trick
		# for keeping the plane populated, and drawing a wrapped tail would claim the
		# particle crossed the far edge. It also keeps the measured AABB identical at
		# every value, so the sweep's fixed camera cannot drift.
		var qx: float = x
		var qz: float = z
		var live: bool = true
		for s in tail:
			if live:
				var vv := _field_at(qx, qz)
				var nx: float = qx - vv.x * step_scale
				var nz: float = qz - vv.z * step_scale
				if absf(nx) > domain_x * 0.5 or absf(nz) > domain_z * 0.5:
					# stop AT the last point inside the domain, so the parked
					# instances below cannot push the measured AABB outward
					live = false
				else:
					qx = nx
					qz = nz
			var sc: float = 0.0
			if live:
				if trace == "streamline":
					sc = 0.30
				else:
					sc = lerpf(0.75, 0.25, float(s) / float(maxi(tail - 1, 1)))
			mm.set_instance_color(base + 1 + s, col)
			mm.set_instance_transform(base + 1 + s, _instance_xf(qx, qz, sc))
