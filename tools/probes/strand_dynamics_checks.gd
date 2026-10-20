# Numerical checks against force balance, frame-rate invariance and slack cable
# behaviour, independent of the Voronoi generator and renderer.
extends RefCounted

const Dynamics = preload("res://commons/context/cellular_spaces/strand_dynamics.gd")

static func run(check: Callable) -> void:
	var spring = Dynamics.new()
	spring.knot_mass = 1.0
	spring.compliance = 0.001
	spring.pretension = 0
	var cable: Array[Vector2i] = [Vector2i(0, 1)]
	spring.setup(PackedVector3Array([Vector3.UP, Vector3.ZERO]), cable, {0: true})
	for i in range(600):
		spring.advance(1.0 / 120.0)
	var length: float = spring.positions[0].distance_to(spring.positions[1])
	check.call("hanging mass extension agrees with mg / stiffness", absf(length - 1.00981) < 0.0002)
	check.call("cable force balances the hanging weight", absf(spring.tensions[0] - 9.81) < 0.05)
	check.call("fixed knot rejects impulse and remains exactly fixed", not spring.apply_impulse(0, Vector3.ONE) and spring.positions[0] == Vector3.UP)
	var slack = Dynamics.new()
	slack.gravity = Vector3.ZERO
	slack.pretension = 0
	slack.setup(PackedVector3Array([Vector3.ZERO, Vector3.RIGHT]), cable, {0: true})
	slack.positions[1] = Vector3.RIGHT * 0.5
	slack.advance(1.0 / 60.0)
	check.call("slack cable produces no compressive force", slack.positions[1] == Vector3.RIGHT * 0.5 and is_zero_approx(slack.tensions[0]))
	var runs: Array = []
	for hz in [30, 60, 90]:
		var model = Dynamics.new()
		model.pretension = 0
		model.setup(PackedVector3Array([Vector3.UP, Vector3.ZERO]), cable, {0: true})
		model.apply_impulse(1, Vector3(0.02, 0, 0))
		for i in range(hz * 3):
			model.advance(1.0 / hz)
		runs.append(model.positions[1])
	check.call("30, 60 and 90 Hz inputs give the same physical response", runs[0].distance_to(runs[1]) < 0.00001 and runs[0].distance_to(runs[2]) < 0.00001)
	slack.reset()
	slack.apply_impulse(1, Vector3(0, 0.02, 0))
	var start_energy: float = slack.metrics().kinetic_energy
	for i in range(360):
		slack.advance(1.0 / 120.0)
	check.call("damping dissipates a tug without disconnecting the cable", slack.metrics().kinetic_energy < start_energy * 0.02 and slack.positions[1].is_finite())
	check.call("a long frame has bounded catch-up work", slack.advance(5.0) == Dynamics.MAX_STEPS and slack.positions[1].is_finite())
	check.call("invalid impulses are rejected", not slack.apply_impulse(-1, Vector3.ONE) and not slack.apply_impulse(1, Vector3(INF, 0, 0)))
