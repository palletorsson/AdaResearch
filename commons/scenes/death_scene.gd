# death_scene.gd — "You Died" scene with cross on hill and biome
#
# Shows after health reaches 0. Atmospheric hilltop with a cross,
# full biome surroundings, "You Died" text, and a Continue button
# that returns to the lab/menu.

## STAGING WILL ONLY LOAD A SCENE BASE — AND THE BASE BRINGS THE RIG (2026-09-07).
##
##     Trying to assign value of type 'death_scene.gd' to a variable of type
##     'scene_base.gd'.  vrStaging.gd:718 @ load_scene()
##
## XRToolsStaging assigns what it instantiates into `current_scene`, which is
## typed XRToolsSceneBase, so a plain Node3D root is refused at the assignment
## and the transition dies right there. This scene was only ever reached by
## change_scene_to_file before, which does not care; sending it through staging
## — which is what stops the headset losing its rig — is what surfaced it.
##
## Making THIS script the scene base was the wrong half of the fix, and the
## headset said so on the next run:
##
##     scene_base.gd:101 @ scene_loaded():
##     Node not found: "XROrigin3D/XRCamera3D" (relative to ".../DeathScene")
##
## scene_base.scene_loaded() makes its own camera current, so every staged scene
## must CONTAIN an XR rig — each one brings its own, through base.tscn. A death
## scene with no rig has no camera at all in the headset, which is the black
## screen again by a new road.
##
## So this follows the museum's shape exactly: death_scene_staged.tscn roots on
## base.tscn (the scene base, with the rig) and hangs this script on a child.
## Plain Node3D again, and death_scene.tscn stays as it was for anything that
## loads it without staging.
extends Node3D

var _continue_pressed := false

func _ready() -> void:
	_build_environment()
	_build_hill()
	_build_cross()
	_build_biome()
	_build_ui()
	_build_camera()
	_build_light()


func _build_environment() -> void:
	var env := WorldEnvironment.new()
	env.name = "DeathEnv"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.15, 0.1, 0.2)
	environment.ambient_light_color = Color(0.3, 0.25, 0.35)
	environment.ambient_light_energy = 0.4
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.2, 0.15, 0.25)
	environment.fog_density = 0.03
	env.environment = environment
	add_child(env)


func _build_hill() -> void:
	# Flat green hill
	var hill := MeshInstance3D.new()
	hill.name = "Hill"
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	plane.subdivide_depth = 16
	plane.subdivide_width = 16
	hill.mesh = plane

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.3, 0.1)
	mat.roughness = 0.9
	hill.material_override = mat
	add_child(hill)


func _build_cross() -> void:
	# Vertical beam
	var vertical := MeshInstance3D.new()
	vertical.name = "CrossVertical"
	var v_mesh := BoxMesh.new()
	v_mesh.size = Vector3(0.15, 2.5, 0.15)
	vertical.mesh = v_mesh
	vertical.position = Vector3(0, 1.25, -5)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.3, 0.2)
	mat.roughness = 0.8
	vertical.material_override = mat
	add_child(vertical)

	# Horizontal beam
	var horizontal := MeshInstance3D.new()
	horizontal.name = "CrossHorizontal"
	var h_mesh := BoxMesh.new()
	h_mesh.size = Vector3(1.2, 0.12, 0.12)
	horizontal.mesh = h_mesh
	horizontal.position = Vector3(0, 1.8, -5)
	horizontal.material_override = mat
	add_child(horizontal)


func _build_biome() -> void:
	# Scatter some simple trees and grass around the hill
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	for i in 20:
		var angle := rng.randf() * TAU
		var dist := rng.randf_range(6.0, 18.0)
		var pos := Vector3(cos(angle) * dist, 0, sin(angle) * dist - 5)

		# Trees
		var tree := MeshInstance3D.new()
		tree.name = "Tree%d" % i
		var trunk := CylinderMesh.new()
		trunk.height = rng.randf_range(1.5, 3.5)
		trunk.top_radius = 0.05
		trunk.bottom_radius = 0.12
		trunk.radial_segments = 5
		tree.mesh = trunk
		tree.position = pos + Vector3(0, trunk.height * 0.5, 0)

		var t_mat := StandardMaterial3D.new()
		t_mat.albedo_color = Color(0.2 + rng.randf() * 0.1, 0.35 + rng.randf() * 0.15, 0.1)
		tree.material_override = t_mat
		add_child(tree)

		# Canopy
		var canopy := MeshInstance3D.new()
		canopy.name = "Canopy%d" % i
		var sphere := SphereMesh.new()
		sphere.radius = rng.randf_range(0.4, 1.0)
		sphere.height = sphere.radius * 1.5
		canopy.mesh = sphere
		canopy.position = pos + Vector3(0, trunk.height + sphere.radius * 0.3, 0)

		var c_mat := StandardMaterial3D.new()
		c_mat.albedo_color = Color(0.1 + rng.randf() * 0.15, 0.3 + rng.randf() * 0.2, 0.05)
		canopy.material_override = c_mat
		add_child(canopy)

	# Grass patches
	for i in 40:
		var angle := rng.randf() * TAU
		var dist := rng.randf_range(2.0, 15.0)
		var pos := Vector3(cos(angle) * dist, 0.01, sin(angle) * dist - 5)

		var grass := MeshInstance3D.new()
		grass.name = "Grass%d" % i
		var quad := QuadMesh.new()
		quad.size = Vector2(0.15, rng.randf_range(0.2, 0.4))
		grass.mesh = quad
		grass.position = pos + Vector3(0, quad.size.y * 0.5, 0)

		var g_mat := StandardMaterial3D.new()
		g_mat.albedo_color = Color(0.2, 0.5 + rng.randf() * 0.2, 0.1, 0.8)
		g_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		g_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		grass.material_override = g_mat
		add_child(grass)


func _build_ui() -> void:
	# "YOU DIED" text floating above the cross
	var title := Label3D.new()
	title.name = "YouDied"
	title.text = "YOU DIED"
	title.font_size = 96
	title.pixel_size = 0.005
	title.position = Vector3(0, 3.5, -5)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color(0.8, 0.15, 0.1)
	title.outline_size = 8
	add_child(title)

	# "Continue" button (3D label — trigger click or gaze to activate)
	var btn := Label3D.new()
	btn.name = "ContinueButton"
	btn.text = "[ Continue ]"
	btn.font_size = 48
	btn.pixel_size = 0.004
	btn.position = Vector3(0, 1.5, -3)
	btn.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	btn.modulate = Color(0.7, 0.7, 0.8)
	btn.outline_size = 4
	add_child(btn)

	# Make the continue button clickable via Area3D
	var area := Area3D.new()
	area.name = "ContinueArea"
	area.position = Vector3(0, 1.5, -3)
	area.collision_layer = 0
	area.collision_mask = 0xFFFFF
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.5, 0.5, 0.3)
	col.shape = box
	area.add_child(col)
	add_child(area)

	# Auto-continue after 5 seconds (fallback if VR pointer doesn't work)
	get_tree().create_timer(5.0).timeout.connect(_on_continue)


func _build_camera() -> void:
	# NOT IN A HEADSET. Staged, this scene sits under base.tscn's XROrigin3D and
	# the XRCamera3D is the eye; a plain Camera3D marked `current` would seize the
	# viewport from it and hand the visitor a flat window in a stereo display.
	if _find_xr_camera() != null:
		return
	# Desktop camera looking at the cross
	var cam := Camera3D.new()
	cam.name = "DeathCamera"
	cam.position = Vector3(2, 2, -1)
	cam.fov = 60
	# ADDED FIRST, AIMED SECOND. look_at needs a tree to be global in:
	#   death_scene.gd:203 @ _build_camera(): Node not inside tree.
	# The same shape as DeathEffect's particles firing at the world origin — a
	# transform call made before the node has a parent is refused, quietly.
	add_child(cam)
	cam.look_at(Vector3(0, 1.5, -5), Vector3.UP)
	cam.current = true


func _find_xr_camera() -> Camera3D:
	# BUILT, NOT TERNARIED. `var s: Array[Node] = [x] if c else []` looks fine and
	# compiles fine, and throws at RUNTIME:
	#   Trying to assign an array of type "Array" to a variable of type "Array[Node]"
	# because a ternary's result is an untyped Array whatever its branches hold —
	# an array LITERAL infers to the typed array, a ternary over two of them does
	# not. check_compile cannot see it; only running it can, which is why this
	# reached a headset.
	if not is_inside_tree():
		return null
	var stack: Array[Node] = []
	stack.append(get_tree().get_root())
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is XRCamera3D:
			return n as Camera3D
		for c in n.get_children():
			stack.append(c)
	return null


func _build_light() -> void:
	var light := DirectionalLight3D.new()
	light.name = "MoonLight"
	light.light_color = Color(0.5, 0.45, 0.6)
	light.light_energy = 0.6
	light.rotation_degrees = Vector3(-40, -30, 0)
	light.shadow_enabled = true
	add_child(light)


## LOADED WHEN NEEDED, NOT PRELOADED — and that is a testability decision, not a
## style one. endless_museum.gd names GameManager, so a `const MUSEUM =
## preload(...)` here made THIS file unloadable in a `extends SceneTree` probe,
## which has no autoloads. Four separate runtime faults reached a headset from
## this script in one afternoon — a rigless staged scene, a look_at before
## add_child, a flat camera stealing the viewport, and a typed array built from a
## ternary — and every one of them would have died in the first second of a probe
## that could simply instantiate it. It could not, because of this line.
##
## The cost of lazy loading is one load() on a button press. The cost of the
## preload was four round trips through Palle.
const MUSEUM_SCRIPT := "res://commons/scenes/endless_museum.gd"
const MUSEUM_SCENE := "res://commons/scenes/endless_museum_staged.tscn"
const MUSEUM_FALLBACK_SCENE := "res://commons/scenes/endless_museum.tscn"


func _on_continue() -> void:
	if _continue_pressed:
		return
	_continue_pressed = true

	# BACK TO THE HALL YOU DIED IN (2026-09-07, Palle: "click to reload back to
	# the same map"). The museum set these statics on its way out; open_at is the
	# same handover the main menu uses, so there is one door into the building and
	# the death scene is not a second implementation of it.
	var museum: GDScript = load(MUSEUM_SCRIPT) as GDScript
	if museum != null and bool(museum.get("return_after_death")):
		museum.set("return_after_death", false)    # spent — a later death re-arms it
		var staging := _find_staging()
		if staging != null:
			print("[death-scene] back into the museum at %s" % str(museum.get("menu_chapter")))
			staging.load_scene(MUSEUM_SCENE)
			return
		# No staging is a dev boot of this scene on its own. The plain museum
		# scene reads the same statics, so the return still lands.
		push_warning("[death-scene] no XRToolsStaging — returning to the museum without it")
		get_tree().change_scene_to_file(MUSEUM_FALLBACK_SCENE)
		return

	# Return to lab/main menu
	var scene_mgr = get_node_or_null("/root/SceneManager")
	if scene_mgr and scene_mgr.has_method("go_to_lab"):
		scene_mgr.go_to_lab()
	else:
		get_tree().change_scene_to_file("res://commons/scenes/lab.tscn")


func _find_staging() -> XRToolsStaging:
	var n: Node = self
	while n != null:
		if n is XRToolsStaging:
			return n as XRToolsStaging
		n = n.get_parent()
	return null
