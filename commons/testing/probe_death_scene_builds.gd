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

	# 3. THE STAGED SHAPE, ON DESKTOP — and this probe asserted the OPPOSITE of the
	#    truth until 2026-09-07, then passed, which is the worst thing a probe can
	#    do. base.tscn carries an XRCamera3D whether or not a headset is attached,
	#    so "is there an XRCamera3D?" is true on the desktop app too. The scene
	#    returned early, built no camera, and the visitor stared through an
	#    untracked rig camera at the origin. The probe called that correct.
	#
	#    Headless IS the desktop case: no OpenXR, so the staged scene MUST build
	#    and aim its own camera. The VR case — where it must not — cannot be tested
	#    from here, and saying so is better than a green tick that means nothing.
	var staged = (load(STAGED) as PackedScene).instantiate()
	get_root().add_child(staged)
	for i in range(3):
		await process_frame
	var inner := staged.get_node_or_null("DeathScene")
	var xr_cam := staged.get_node_or_null("XROrigin3D/XRCamera3D")
	print("")
	# No ternary. One was written here out of habit, one commit after documenting
	# that a ternary's type is not its branches' type — the habit is the point.
	var staged_cam: Camera3D = null
	if inner != null:
		staged_cam = inner.get_node_or_null("DeathCamera") as Camera3D
	print("staged (no OpenXR here): rig camera present=%s, own camera built=%s"
		% [xr_cam != null, staged_cam != null])
	if xr_cam == null:
		print("  FAIL the staged scene carries no rig — scene_loaded would throw"); fails += 1
	if staged_cam == null:
		print("  FAIL no camera on desktop — the visitor sees the inside of a hill")
		fails += 1
	else:
		var to_c: Vector3 = (Vector3(0, 1.5, -5) - staged_cam.global_position).normalized()
		var f2: float = (-staged_cam.global_transform.basis.z).dot(to_c)
		print("staged desktop camera aim: %.3f" % f2)
		if f2 < 0.99:
			print("  FAIL built but never aimed"); fails += 1

	# 4. AND THEN STAGING TAKES THE CAMERA BACK.
	#
	# Building a camera is not keeping one. vrStaging.load_scene does:
	#     $Scene.add_child(current_scene)          -> _ready(), we build ours
	#     await create_timer(tracking_delay)
	#     current_scene.scene_loaded(user_data)    -> scene_base.gd:101,
	#                                                 $XROrigin3D/XRCamera3D.current = true
	# so about a tenth of a second after the death scene aims its camera, the base
	# reclaims the viewport for an UNTRACKED rig camera parked at the origin. On
	# desktop that is a view of the inside of a hill.
	#
	# Neither earlier check could see this: --em-die boots the museum directly
	# (no staging, so scene_loaded never runs) and step 3 above instantiates the
	# scene without driving the staging sequence. This one calls scene_loaded by
	# hand, which is the whole point — it reproduces the ORDER, not just the parts.
	if inner != null and staged.has_method("scene_loaded"):
		staged.call("scene_loaded", null)
		await process_frame
		var vp_cam := get_root().get_camera_3d()
		var ours: bool = vp_cam != null and vp_cam == staged_cam
		print("")
		print("after scene_loaded, the current camera is: %s" % (
			"the death scene's" if ours else str(vp_cam.name if vp_cam != null else "<none>")))
		if not ours:
			print("  FAIL staging reclaimed the viewport — the visitor sees the rig")
			print("       camera at the origin, not the cross")
			fails += 1

	# 5. IS THERE ANYTHING TO STAND ON? (2026-09-07, Palle: "Does the death scene
	#    need a floor collider or is the player dropped below the floor?")
	#
	#    _build_hill makes a PlaneMesh on a MeshInstance3D — a picture of ground,
	#    with no body and no shape. base.tscn:168 mounts an XRToolsPlayerBody under
	#    the rig, and that applies gravity. A mesh is not a floor.
	var shapes := 0
	var stack2: Array[Node] = []
	stack2.append(staged)
	while not stack2.is_empty():
		var n: Node = stack2.pop_back()
		if n is CollisionShape3D and (n.get_parent() is StaticBody3D):
			shapes += 1
		for c in n.get_children():
			stack2.append(c)
	print("")
	print("static colliders under the staged death scene: %d (need >= 1)" % shapes)
	if shapes < 1:
		print("  FAIL nothing to stand on. base.tscn:168 mounts an XRToolsPlayerBody")
		print("       under the rig and it applies gravity, so a headset visitor")
		print("       arrives at their own grave and falls through it.")
		fails += 1

	var rig := staged.get_node_or_null("XROrigin3D") as Node3D
	if rig != null:
		var y0: float = rig.global_position.y
		for i in range(90):                     # ~1.5 s of physics
			await physics_frame
		var drop: float = y0 - rig.global_position.y
		# INFORMATIONAL ONLY, and that is the honest label. XRToolsPlayerBody
		# needs a tracked rig, so gravity does not run headless: this printed
		# 0.00 m with ZERO floor colliders under the scene and would have gone
		# green over exactly the bug it looks like it is testing. The assertion
		# lives on the collider count above, which headless CAN see.
		print("the rig fell %.2f m in 1.5 s — informational: gravity needs a" % drop)
		print("  tracked rig, so headless cannot fail on this and does not try")
	else:
		print("  (no XROrigin3D to drop — cannot measure)")

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)
