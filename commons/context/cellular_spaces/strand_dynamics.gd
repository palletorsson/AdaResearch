# strand_dynamics.gd
# Shared knot particles and tension-only XPBD cables. Anchors have zero inverse
# mass; every incident strand reads the same particle, so a knot cannot split.
# Units: metres, kilograms, seconds, newtons. No bending or strand self-collision.
# Formulation: Macklin, Muller & Chentanez (2016), https://mmacklin.com/xpbd.pdf
extends RefCounted

const STEP: float = 1.0 / 120.0
const MAX_STEPS: int = 6 # Bound catch-up work after a stalled frame.

var gravity := Vector3(0, -9.81, 0)
var knot_mass: float = 0.02
var compliance: float = 0.00002 # m/N; reciprocal of axial spring stiffness
var pretension: float = 2.0 # N, used only to choose slightly shorter rest lengths
var damping: float = 1.8 # velocity decay per second
var iterations: int = 6
var positions := PackedVector3Array()
var velocities := PackedVector3Array()
var rest_positions := PackedVector3Array()
var inverse_mass := PackedFloat32Array()
var rest_lengths := PackedFloat32Array()
var tensions := PackedFloat32Array()
var segments: Array[Vector2i] = []
var elapsed: float = 0.0
## Optional room sweep: (previous_position, predicted_position) -> safe position.
var contact_resolver: Callable
var _previous := PackedVector3Array()
var _multipliers := PackedFloat32Array()
var _accumulator: float = 0.0

## Keep graph IDs intact; fixed IDs are actual surface attachments.
func setup(points: PackedVector3Array, connections: Array[Vector2i], fixed: Dictionary) -> void:
	rest_positions = points.duplicate()
	segments.assign(connections)
	inverse_mass.resize(points.size())
	inverse_mass.fill(1.0 / maxf(knot_mass, 0.0001))
	for id: int in fixed:
		inverse_mass[id] = 0.0
	rest_lengths.resize(segments.size())
	for i in range(segments.size()):
		var edge := segments[i]
		var length := points[edge.x].distance_to(points[edge.y])
		rest_lengths[i] = maxf(length * 0.8, length - maxf(pretension, 0.0) * compliance)
	reset()

## Return to the unrelaxed Voronoi construction without changing rest lengths.
func reset() -> void:
	positions = rest_positions.duplicate()
	_previous = positions.duplicate()
	velocities.resize(positions.size())
	velocities.fill(Vector3.ZERO)
	_multipliers.resize(segments.size())
	_multipliers.fill(0.0)
	tensions.resize(segments.size())
	tensions.fill(0.0)
	_accumulator = 0.0
	elapsed = 0.0

## Apply a real impulse (N s) to a free knot; anchors cannot be displaced.
func apply_impulse(id: int, impulse: Vector3) -> bool:
	if id < 0 or id >= positions.size() or inverse_mass[id] == 0 or not impulse.is_finite():
		return false
	velocities[id] += impulse * inverse_mass[id]
	return true

## Fixed steps make the response independent of display refresh rate.
func advance(delta: float) -> int:
	if not is_finite(delta) or delta <= 0:
		return 0
	_accumulator = minf(_accumulator + delta, STEP * MAX_STEPS)
	var steps := 0
	while _accumulator >= STEP - 0.000000001:
		_substep()
		_accumulator = maxf(0, _accumulator - STEP)
		elapsed += STEP
		steps += 1
	return steps

func _substep() -> void:
	var decay := exp(-maxf(0, damping) * STEP)
	for i in range(positions.size()):
		_previous[i] = positions[i]
		if inverse_mass[i] == 0.0:
			positions[i] = rest_positions[i]
			velocities[i] = Vector3.ZERO
		else:
			velocities[i] = velocities[i] * decay + gravity * STEP
			positions[i] += velocities[i] * STEP
	_multipliers.fill(0.0)
	var alpha := maxf(0, compliance) / (STEP * STEP)
	for pass_index in range(iterations):
		# Alternate order to reduce a persistent directional bias in the solve.
		for offset in range(segments.size()):
			var i := offset if pass_index % 2 == 0 else segments.size() - 1 - offset
			var edge := segments[i]
			var wa := inverse_mass[edge.x]
			var wb := inverse_mass[edge.y]
			if wa + wb == 0:
				continue
			var delta := positions[edge.y] - positions[edge.x]
			var length := delta.length()
			if length < 0.0000001:
				continue
			var c := length - rest_lengths[i]
			var change := (-c - alpha * _multipliers[i]) / (wa + wb + alpha)
			# Cables pull when stretched, but cannot push when slack.
			var next := minf(0, _multipliers[i] + change)
			change = next - _multipliers[i]
			_multipliers[i] = next
			var correction := delta * (change / length)
			positions[edge.x] -= correction * wa
			positions[edge.y] += correction * wb
	for i in range(positions.size()):
		if inverse_mass[i] == 0:
			continue
		if contact_resolver.is_valid() and _previous[i].distance_squared_to(positions[i]) > 0.0000000001:
			positions[i] = contact_resolver.call(_previous[i], positions[i])
		velocities[i] = (positions[i] - _previous[i]) / STEP
	for i in range(segments.size()):
		tensions[i] = -_multipliers[i] / (STEP * STEP)

## Diagnostics use the simulated material units; these are not silk measurements.
func metrics() -> Dictionary:
	var energy := 0.0
	var extension := 0.0
	var peak := 0.0
	for i in range(positions.size()):
		if inverse_mass[i] > 0:
			energy += 0.5 / inverse_mass[i] * velocities[i].length_squared()
	for i in range(segments.size()):
		var edge := segments[i]
		extension = maxf(extension, positions[edge.x].distance_to(positions[edge.y]) - rest_lengths[i])
		peak = maxf(peak, tensions[i])
	return {"kinetic_energy": energy, "max_extension": extension, "peak_tension": peak}
