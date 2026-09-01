extends SceneTree
## DOES THE HAMMER REACH A WALL WORK?
##
## Palle: "The hammer does not destroy the wall works with the text in VR."
##
## It could not: a showing is instances of a MultiMesh with NO COLLIDER, so no
## shape query returns one however wide the head swings. The museum owns the wall
## works and already answers the laser through on_beam_swept; the hammer now uses
## the same handshake, on_strike_swung.
##
## This stands in for the museum with a node in the "em_lethal" group — the same
## group the laser calls — so the handshake is tested without booting a hall.
## Four checks, two of them negatives.

class FakeMuseum extends Node3D:
	var calls: int = 0
	var last_at: Vector3
	var last_radius: float = 0.0
	var answer: bool = true
	func on_strike_swung(at: Vector3, radius: float) -> bool:
		calls += 1
		last_at = at
		last_radius = radius
		return answer

func _init() -> void:
	var fails := 0
	var mus := FakeMuseum.new()
	mus.add_to_group("em_lethal")
	get_root().add_child(mus)

	var H := load("res://commons/artifacts/line_sledgehammer/line_sledgehammer.tscn")
	var h = H.instantiate()
	# FREEZE BEFORE IT EVER FALLS. The first version froze it two frames after
	# add_child, and in those two frames gravity moved the head ~10 cm — which is
	# a real swing by any measure, so the probe struck a wall work during its own
	# "at rest" check and then blamed the artifact. The head position it reported
	# (y = 0.76 instead of 0.86) is what gave it away.
	h.freeze = true
	get_root().add_child(h)
	h.global_position = Vector3(0, 0, 0)
	await process_frame
	await process_frame

	# 1. NEGATIVE: resting still must not strike a wall work either
	for i in 6:
		await physics_frame
	print("1  at rest: museum asked %d time(s) (must be 0)" % mus.calls)
	if mus.calls != 0:
		print("   FAIL a motionless hammer is taking pictures off walls"); fails += 1

	# 2. a real swing reaches the museum
	for i in 10:
		h.global_position = Vector3(0, 1.0, 1.2 - 0.22 * i)
		await physics_frame
		await physics_frame
		if mus.calls > 0:
			break
	print("2  after a swing: museum asked %d time(s), radius %.2f m"
		% [mus.calls, mus.last_radius])
	if mus.calls == 0:
		print("   FAIL the hammer never asks the museum — wall works stay safe"); fails += 1
	if mus.last_radius <= 0.0:
		print("   FAIL no reach given"); fails += 1

	# 3. the position handed over is the HEAD, not the grip
	var head_y: float = h._head.global_position.y if h._head else -99.0
	print("3  asked about %s; head is at y=%.2f" % [mus.last_at, head_y])
	if absf(mus.last_at.y - head_y) > 0.35:
		print("   FAIL it reported the handle, not the end that hits"); fails += 1

	# 4. NEGATIVE: when the museum says it hit nothing, the hammer must not
	#    claim a strike and go on cooldown
	mus.answer = false
	# WAIT OUT THE COOLDOWN FIRST. A landed strike sets 0.45 s, and the previous
	# version of this check swung for 0.14 s and concluded the hammer was stuck —
	# testing the cooldown it had just triggered, not the refusal path.
	for i in 90:
		await physics_frame
	mus.calls = 0
	for i in 10:
		h.global_position = Vector3(3, 1.0, 1.2 - 0.22 * i)
		await physics_frame
		await physics_frame
	print("4  museum answering 'nothing there': asked %d time(s) (must be >= 1)"
		% mus.calls)
	if mus.calls < 1:
		print("   FAIL one refused swing put the hammer on cooldown"); fails += 1

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)
