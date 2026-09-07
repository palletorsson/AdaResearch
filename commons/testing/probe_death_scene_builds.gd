extends SceneTree
## JUST BUILD THE DEATH SCENE. That is the whole probe.
##
## 2026-09-07. Four separate faults reached Palle's headset from death_scene.gd
## in one afternoon, one per round trip:
##
##   1. a plain Node3D root, which staging refuses outright
##   2. no XR rig, so scene_loaded() had no camera to make current
##   3. look_at() before add_child() — refused quietly, the camera never aimed
##   4. `var s: Array[Node] = [x] if c else []` — a ternary is an untyped Array,
##      which throws on assignment AT RUNTIME
##
## EVERY ONE OF THEM DIES IN THE FIRST SECOND OF THIS. Not one of them was a
## parse error, so check_compile passed all four; they need the script actually
## RUN. It could not be run, because a `const MUSEUM = preload(...)` at the top
## dragged in endless_museum.gd, which names GameManager, which a SceneTree probe
## has no autoloads for. That preload is a load() now and this file exists.
##
## The lesson is not about death scenes: a script that cannot be instantiated in
## a probe will be debugged in a headset instead, one round trip per bug.

const DEATH := "res://commons/scenes/death_scene.gd"
const STAGED := "res://commons/scenes/death_scene_staged.tscn"


func _init() -> void:
	var fails := 0

	# 1. THE SCRIPT RUNS AT ALL. _ready() builds ~70 nodes, aims a camera and
	#    walks the tree; three of the four faults above were in that path.
	var s: GDScript = load(DEATH) as GDScript
	if s == null:
		print("  FAIL death_scene.gd will not load — a probe cannot reach it again")
		quit(1)
		return
	var d = s.new()
	get_root().add_child(d)
	for i in range(3):
		await process_frame
	print("death scene built: %d children" % d.get_child_count())
	if d.get_child_count() < 10:
		print("  FAIL it built almost nothing — _ready threw partway"); fails += 1

	# the pieces a visitor is supposed to see
	for want in ["YouDied", "ContinueButton", "Hill", "CrossVertical"]:
		if d.get_node_or_null(want) == null:
			print("  FAIL missing %s" % want); fails += 1
	print("cross, hill, YOU DIED and the button are all present")

	# 2. OFF A RIG it makes its own camera, and that camera must be AIMED.
	#    look_at before add_child left it staring down the -Z axis at nothing.
	var cam := d.get_node_or_null("DeathCamera") as Camera3D
	print("")
	if cam == null:
		print("  FAIL no desktop camera where there is no XR camera"); fails += 1
	else:
		var to_cross: Vector3 = (Vector3(0, 1.5, -5) - cam.global_position).normalized()
		var facing: float = (-cam.global_transform.basis.z).dot(to_cross)
		print("desktop camera aim at the cross: %.3f (1.0 = looking straight at it)" % facing)
		if facing < 0.99:
			print("  FAIL the camera never aimed — look_at was refused"); fails += 1

	# 3. THE STAGED SHAPE. Under base.tscn there IS an XRCamera3D, so the scene
	#    must NOT build a second current camera and steal the viewport.
	var staged = (load(STAGED) as PackedScene).instantiate()
	get_root().add_child(staged)
	for i in range(3):
		await process_frame
	var inner := staged.get_node_or_null("DeathScene")
	var xr_cam := staged.get_node_or_null("XROrigin3D/XRCamera3D")
	print("")
	print("staged: rig camera present=%s, death scene built its own=%s"
		% [xr_cam != null, inner != null and inner.get_node_or_null("DeathCamera") != null])
	if xr_cam == null:
		print("  FAIL the staged scene carries no rig — scene_loaded would throw"); fails += 1
	if inner != null and inner.get_node_or_null("DeathCamera") != null:
		print("  FAIL it made a flat camera beside the XR one — that steals the eye")
		fails += 1

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)
