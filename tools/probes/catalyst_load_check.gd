extends SceneTree
## Cold-start smoke test: real runtime scripts with no glow-helper script present.
const Ability := preload("res://commons/hazards/becoming_catalyst/first_catalyst_ability.gd")
const Skull := preload("res://commons/hazards/catalyst_counterpart/flying_skull.gd")
var failures := 0
var checks := 0

func _initialize() -> void: run.call_deferred()

func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok: failures += 1
	print("[catalyst-load] ", "PASS " if ok else "FAIL ", label)

func run() -> void:
	var world := Node3D.new(); root.add_child(world); current_scene = world
	var ability := Ability.new(); world.add_child(ability)
	ability.set_physics_process(false); ability.set_unlocked(true)
	ability.update_hands(Transform3D(Basis.IDENTITY, Vector3(-0.1, 1, 0)), Transform3D(Basis.IDENTITY, Vector3(0.1, 1, 0)), true, true, 0.2)
	check("hand ability constructs its glow and sphere without helper script", ability.formed and ability.left_glow.material_override is ShaderMaterial)
	var skull := Skull.new(); skull.combat_enabled = true; skull.position = Vector3(0, 1, -3)
	world.add_child(skull); skull.set_physics_process(false)
	await physics_frame
	skull.set_active(true); skull.begin_telegraph(Vector3(0, 1, 0))
	skull.advance(skull.WINDUP + 0.01, Vector3(0, 1, 0))
	check("skull loads and fires its first ball", skull.projectiles.size() == 1 and is_instance_valid(skull.projectiles[0]))
	if not skull.projectiles.is_empty():
		var shot: Node3D = skull.projectiles[0]
		check("outgoing ball constructs its own glow", shot.get_child_count() == 3 and shot.get_child(2).material_override is ShaderMaterial)
	var sphere := ability.send_form(Vector3.FORWARD)
	check("formed hand sphere can still fire", sphere != null)
	await physics_frame
	ability.clear_shots(); skull.clear_shots(); world.queue_free()
	await process_frame
	print("CATALYST LOAD ", checks - failures, "/", checks)
	quit(0 if failures == 0 else 1)
