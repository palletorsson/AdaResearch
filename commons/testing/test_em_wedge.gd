extends SceneTree
## GATE: THE WEDGE IS THE WAY UP (2026-08-20).
## Positive: a capsule walked at a 0.4 m stage ACROSS its wedge ends ON the stage.
## Negative: the same capsule walked at the same stage where there is NO wedge
## does not climb — a bare step is a wall to a CharacterBody3D, which is the whole
## reason the wedge (the corpus's third most-placed body) matters.
## The museum's own controller is stood down for the test (_player = null) so one
## mover drives the body: this measures the GEOMETRY, not the input handling.
func _initialize() -> void: call_deferred("_run")

const G := 11.0

func _run() -> void:
	var fails: Array[String] = []
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	m.set("_first_chapter", "primitives")
	m.set("start_map", "Point_Triangle_Context")
	get_root().add_child(m)
	await create_timer(4.0).timeout
	var w: CharacterBody3D = m.get("_player")
	var wedges: Array = m.find_children("Wedge_*", "Node3D", true, false)
	print("[test] wedges built: %d (6 on the stage's north side + 2 the pearl placed)" % wedges.size())
	if wedges.size() < 8:
		fails.append("expected 8 wedges (6 stage + 2 free), found %d" % wedges.size())
	m.set("_player", null)                      # one mover only
	await physics_frame

	var vest: int = 4
	# the free wedges are at tile (1,7) and (1,8) facing east -> world z 11.5 / 12.5,
	# approached from x smaller. Walk +x across one of them.
	var up: float = await _walk(w, Vector3(1.0, 0.6, float(vest + 7) + 0.5), Vector3(1, 0, 0), 200)
	print("[test] ACROSS the free wedge (1,7): ended y %.3f x %.2f" % [up, w.position.x])
	if up < 0.32:
		fails.append("the wedge did not carry the body up: y %.3f, wanted ~0.40" % up)

	# the negative half: the stage's east flank at tile x 8, where nothing was placed
	var blocked: float = await _walk(w, Vector3(10.5, 0.6, float(vest + 8) + 0.5), Vector3(-1, 0, 0), 200)
	print("[test] AT the bare 0.4 m step (stage's east flank, no wedge): ended y %.3f x %.2f" % [blocked, w.position.x])
	if blocked > 0.32:
		fails.append("a bare 0.4 m step was climbed with no wedge (y %.3f) — the negative half does not bite" % blocked)

	if fails.is_empty():
		print("EM WEDGE: PASS — the wedge carries the body up (%.2f m), the bare step turns it away (%.2f m)" % [up, blocked])
	else:
		print("EM WEDGE: FAIL %d" % fails.size())
		for f in fails: print("  - " + f)
	quit(0 if fails.is_empty() else 1)


func _walk(w: CharacterBody3D, from: Vector3, dir: Vector3, frames: int) -> float:
	w.position = from
	w.velocity = Vector3.ZERO
	var dt: float = 1.0 / 60.0
	for i in range(frames):
		var vy: float = 0.0 if w.is_on_floor() else w.velocity.y - G * dt
		w.velocity = Vector3(dir.x * 2.5, vy, dir.z * 2.5)
		w.move_and_slide()
		await physics_frame
	return w.position.y
