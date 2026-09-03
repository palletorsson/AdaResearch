# probe_act5_controls.gd — the two controls Vectors_Act5_ForceAsPlace turns on.
#
# THE YAW FADER was dead where a visitor first finds it. Both horizontal terms
# of the field carry a cos(pitch), and the machine ships with PITCH parked on
# its bottom stop, where cos is zero. Dragging YAW across its whole travel
# changed nothing, and nothing said so. The default is not the fault - shipping
# as gravity is the room's first lesson - so the fix is feedback: a ghost arrow
# holding the azimuth, and a readout line that says the fader is idle and why.
#
# THE TEST CUBE could not fall. gravity_scale shipped at 0.0, which makes a
# clean straight-flying probe and a useless demonstration in a room about
# falling. It has weight now, and a way home, because a chasm map has no floor
# to catch it and no reset cube.
#
#   godot --path . --xr-mode off --no-window --log-file <f> \
#     --script res://commons/testing/probe_act5_controls.gd

extends SceneTree

const MACHINE := "res://commons/artifacts/vector_machine/vector_machine.tscn"
const CUBE := "res://commons/artifacts/force_cube/force_cube.tscn"
const SETTLE := 0.8

var _fails: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	print("  FAIL: %s" % msg)
	_fails += 1


func _run() -> void:
	await _yaw()
	await _cube()
	print("")
	print("PROBE OK" if _fails == 0 else "PROBE FAILED (%d)" % _fails)
	quit(0 if _fails == 0 else 1)


func _yaw() -> void:
	print("--- vector_machine: is the yaw fader legible at the pole? ---")
	var m: Node3D = (ResourceLoader.load(MACHINE) as PackedScene).instantiate() as Node3D
	root.add_child(m)
	await process_frame
	await create_timer(SETTLE).timeout

	# as shipped: pitch on the bottom stop
	var v0: Vector3 = m.call("current_vector")
	print("shipped field = (%.2f, %.2f, %.2f)" % [v0.x, v0.y, v0.z])
	if absf(v0.y + 9.8) > 0.4 or Vector2(v0.x, v0.z).length() > 0.2:
		_fail("the machine no longer ships as gravity straight down; that default is the room's first lesson")

	var idle_at_pole: bool = m.call("_yaw_idle")
	if not idle_at_pole:
		_fail("_yaw_idle says the fader bites at the bottom stop, but cos(pitch) is zero there")

	# turning yaw at the pole must not move the field ...
	m.call("_set_slider", 1, 0.5)
	await process_frame
	var v1: Vector3 = m.call("current_vector")
	if v0.distance_to(v1) > 0.05:
		_fail("the field moved when yaw turned at the pole; the maths says it cannot")

	# ... but the machine must SAY so, and must show the azimuth it is holding
	var deg: float = m.call("_yaw_deg")
	print("yaw fader at mid travel reads %.0f degrees (the direction across this chasm)" % deg)
	if absf(deg - 180.0) > 1.0:
		_fail("mid travel is %.0f degrees, expected 180" % deg)
	var ghost: Vector3 = m.call("_yaw_ghost")
	print("ghost points (%.2f, %.2f, %.2f)" % [ghost.x, ghost.y, ghost.z])
	if absf(ghost.y) > 0.001 or ghost.length() < 0.9:
		_fail("the ghost is not a unit horizontal direction")

	# and lifting pitch must make that same azimuth bite
	m.call("_set_slider", 0, 0.5)
	await process_frame
	var v2: Vector3 = m.call("current_vector")
	print("pitch lifted to level: field = (%.2f, %.2f, %.2f)" % [v2.x, v2.y, v2.z])
	if Vector2(v2.x, v2.z).length() < 1.0:
		_fail("with pitch level the field is still vertical; yaw never took effect")
	if m.call("_yaw_idle"):
		_fail("_yaw_idle still true with pitch level")
	# the azimuth it was holding is the one it used
	if v2.z > -1.0:
		_fail("yaw 180 should send the field along -Z; got z = %.2f" % v2.z)
	m.queue_free()
	await process_frame


func _cube() -> void:
	print("")
	print("--- force_cube: does the probe have weight, and a way back? ---")
	var c: RigidBody3D = (ResourceLoader.load(CUBE) as PackedScene).instantiate() as RigidBody3D
	root.add_child(c)
	c.global_position = Vector3(0.0, 10.0, 0.0)
	await process_frame
	await create_timer(SETTLE).timeout

	print("gravity_scale = %.2f" % c.gravity_scale)
	if c.gravity_scale <= 0.0:
		_fail("the cube is still weightless; it cannot demonstrate falling")
	if not c.freeze:
		_fail("the cube should ship frozen, waiting to be picked up")

	# home is captured on the first frame, not in _ready
	var home: Vector3 = (c.get("_home") as Transform3D).origin
	print("home captured at y %.2f (placed at 10.00)" % home.y)
	if absf(home.y - 10.0) > 0.05:
		_fail("home is %.2f, not where the cube was placed" % home.y)

	# released and dropped past the recovery depth, it must come back
	c.freeze = false
	c.global_position = Vector3(0.0, 10.0 - float(c.get("recover_below_m")) - 1.0, 0.0)
	c.linear_velocity = Vector3(0.0, -3.0, 0.0)
	await process_frame
	await process_frame
	print("after falling past the limit, y = %.2f, frozen = %s"
		% [c.global_position.y, str(c.freeze)])
	if absf(c.global_position.y - 10.0) > 0.05:
		_fail("a cube that fell out of the room did not come home")
	if not c.freeze:
		_fail("the recovered cube should be at rest again")
	if c.linear_velocity.length() > 0.01:
		_fail("the recovered cube kept its velocity")

	# and a cube that has merely been dropped a little must NOT teleport
	c.freeze = false
	c.global_position = Vector3(0.0, 9.0, 0.0)
	await process_frame
	await process_frame
	if absf(c.global_position.y - 10.0) < 0.05:
		_fail("a cube one metre down was recovered; the limit is meant to be %.1f m"
			% float(c.get("recover_below_m")))
	c.queue_free()
	await process_frame
