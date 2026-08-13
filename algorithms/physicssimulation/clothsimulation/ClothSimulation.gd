extends Node3D

# @identity
# essence: F_spring = k * (|x2-x1| - rest) * dir. A grid of particles connected by springs. Cloth is not an object — it's a negotiation.
# desire: To drape, to ripple, to be grabbed. To show that softness emerges from many stiff connections.
# critical_parameter: k (stiffness) — low k = jelly cloth, high k = rigid sheet. Wind strength shapes the drama.
# triggers: Wind slider → cloth billows, stiffness slider → character changes, VR grab → cloth deforms toward hand
# emerges: Draping from gravity + constraints. Rippling from wind + spring response. Tearing (future) from exceeding spring limits.
# needs: VR wind slider [has], stiffness slider [has], VR grab [has]. Could use: pin/unpin control, tear threshold.
# relationships: Depends on mass_spring_damper (single spring → grid of springs). Feeds into soft_bodies. Lives in PhysicsSim_Springs.
# truth: Elasticity is memory. Every spring encodes where it wants to be. Cloth is a thousand memories negotiating with gravity.

## Cloth Simulation — spring-mass grid with MultiMesh rendering.
## Three cloths: hanging (pinned corners), floating (free), draped (over sphere).
## Structural + shear springs. Wind, gravity, sphere collision, VR grab.

@export var cloth_resolution: int = 8
@export var cloth_stiffness: float = 100.0
@export var cloth_damping: float = 5.0
@export var wind_strength: float = 3.0
@export var gravity_strength: float = 9.8


# --- DNA (stage 2, promoted 2026-08-12) --------------------------------------
#
# THE STIFFNESS SLIDER IS NOT CONNECTED TO ANYTHING. `cloth_stiffness` and
# `cloth_damping` are read exactly twice in this file, both times to seed a
# slider's default position in _setup_controls. No force reads either one. So
# the @identity's declared critical_parameter — "k (stiffness) — low k = jelly
# cloth, high k = rigid sheet" — is wired to nothing, and a player in VR can
# move the STIFFNESS slider all afternoon while no force in the simulation
# reads it. The knob that was actually doing that job shipped unnamed, as two
# hard-coded literals inside _apply_constraints.
#
# relaxation is that knob given the mechanism's own word (the loop's comment
# says "position-based correction"; soft_body_sim.gd calls it "constraint
# relaxation"). It sets the PAIR (iterations, gain).
#
# An under-relaxed position solver does not converge slower to the same drape —
# IT HAS A DIFFERENT FIXED POINT. Each step injects gravity as a position
# increment and each pass corrects only a fraction of the resulting overstretch,
# so equilibrium sits where injection equals correction and the residual stretch
# scales as roughly 1 / (iterations * gain): nudged 2.86, worked 0.67,
# pressed 0.21, held 0.10 in the same units. All four are AT REST and they are
# different lengths. That is what makes this axis a still and not a rate.
#
# Ordinal order is nudged < worked < pressed < held. The registry lists `worked`
# first because apply_dna_block.py puts the export default leftmost.
#
# DELIBERATELY SHARED with verlet_workbench in this same wave: same word, same
# four values, same claim, two different solvers. A shared vocabulary that is
# honest measures ALIKE, so the pair is a cross-check on the harness as much as
# on the design.
@export_enum("nudged", "worked", "pressed", "held") var relaxation: String = "worked"

# ease — the garment trade's word for the difference between the material and
# the space it occupies. _add_spring sets every rest length to the distance the
# particles were BUILT at, which is a decision nobody made: it says the cloth
# has exactly as much material as its own footprint. This scales those rest
# lengths at build time. relaxation is how hard the springs insist on a rest
# length; ease is what that rest length IS. A garment's fall is decided at the
# cutting table, not at the seam.
@export_enum("taut", "plain", "slack", "full") var ease: String = "plain"


# --- determinism fixture -----------------------------------------------------
#
# All three default to the shipped behaviour exactly, and the sweep turns them
# on. THE AXIS IS A RESTING SHAPE AND THIS ARTIFACT DOES NOT REST. Three
# separate things made two runs of the same value differ, each fatal to a
# verdict:
#
#   1. the wind is a DRIVE, not a load. wind_dir rotates forever as
#      (sin(0.7t), 0, cos(0.5t)) and the per-node term is a sine of _time, so
#      at any wind_strength above zero there is no rest shape to photograph —
#      only an instant.
#   2. `_time += delta` and `node.update(delta)` integrate with the RENDER
#      delta, so the state at capture depends on how many frames the machine
#      happened to draw. Two runs on the same machine can differ.
#   3. nothing had settled by the sweep's ~1.45 s anyway: the 0.995 per-step
#      velocity decay still holds 0.995^87 = 65% of any residual after 87
#      frames, and the pendulum period of a 1.5 m cloth is about 2.5 s.
#
# There is no RNG anywhere in this file — no randf, no randi, no
# RandomNumberGenerator — so law 4 has nothing to seed here. Every source of
# run-to-run difference in this artifact is the clock.

## Amplitude of the per-node wind noise. Holds the literal that used to be
## inline in _apply_forces, and it HAS to exist: that line reads
## `wind_dir * (wind_strength + wind_noise)`, so zeroing wind_strength alone
## leaves a +/-0.5 N oscillating force still driving the cloth — a fixture that
## looks like it worked and did not.
@export var wind_noise_amp: float = 0.5

## Fixed 1/60 sub-steps run synchronously at the end of the build, with _time
## held at 0, so the cloth is at its fixed point BEFORE the first frame is
## drawn. 0 = off, which is what ships.
@export var settle_steps: int = 0

## Constant integration step. 0.0 = use the render delta, which is what ships.
@export var fixed_step: float = 0.0


class ClothNode:
	var position: Vector3
	var velocity: Vector3
	var force: Vector3
	var mass: float
	var is_fixed: bool

	func _init(pos: Vector3, m: float, fixed: bool) -> void:
		position = pos
		velocity = Vector3.ZERO
		force = Vector3.ZERO
		mass = m
		is_fixed = fixed

	func apply_force(f: Vector3) -> void:
		if not is_fixed:
			force += f

	func update(delta: float) -> void:
		if is_fixed:
			return
		var acceleration := force / mass
		velocity += acceleration * delta
		velocity *= 0.995  # light damping
		position += velocity * delta
		force = Vector3.ZERO


class ClothPiece:
	var nodes: Array[ClothNode] = []
	var springs: Array[Vector2i] = []  # pairs of node indices
	var rest_lengths: Array[float] = []
	var origin: Vector3
	var cols: int
	var rows: int
	var mm: MultiMesh
	var mm_instance: MultiMeshInstance3D
	var line_mesh: ImmediateMesh
	var line_instance: MeshInstance3D
	var color: Color
	## Rest-length multiplier, set by the owner BEFORE build(). 1.0 is the
	## shipped path and _add_spring does not multiply at all on it.
	var ease_factor: float = 1.0

	func build(resolution: int, size: Vector2, pos: Vector3, c: Color, pin_mode: int) -> void:
		origin = pos
		color = c
		cols = resolution + 1
		rows = resolution + 1
		var spacing_x := size.x / resolution
		var spacing_z := size.y / resolution

		# Create nodes
		for i in rows:
			for j in cols:
				var x := (j - resolution / 2.0) * spacing_x
				var z := (i - resolution / 2.0) * spacing_z
				var node_pos := pos + Vector3(x, 0, z)
				var fixed := false
				match pin_mode:
					0:  # pin top corners
						fixed = (i == 0) and (j == 0 or j == resolution)
					1:  # free
						fixed = false
					2:  # pin top edge
						fixed = (i == 0)
				nodes.append(ClothNode.new(node_pos, 1.0, fixed))

		# Structural + shear springs
		for i in rows:
			for j in cols:
				var idx := i * cols + j
				# Right neighbor
				if j < cols - 1:
					_add_spring(idx, idx + 1)
				# Bottom neighbor
				if i < rows - 1:
					_add_spring(idx, idx + cols)
				# Diagonal (shear)
				if i < rows - 1 and j < cols - 1:
					_add_spring(idx, idx + cols + 1)
				if i < rows - 1 and j > 0:
					_add_spring(idx, idx + cols - 1)

	func _add_spring(a: int, b: int) -> void:
		springs.append(Vector2i(a, b))
		# THE 1.0 PATH IS THE ORIGINAL LINE, not a multiply by one. Branching
		# rather than scaling keeps `plain` bit-identical to what shipped
		# instead of merely landing near it.
		if ease_factor == 1.0:
			rest_lengths.append(nodes[a].position.distance_to(nodes[b].position))
		else:
			rest_lengths.append(nodes[a].position.distance_to(nodes[b].position) * ease_factor)

	func setup_rendering(parent: Node3D) -> void:
		# MultiMesh for nodes
		mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.instance_count = nodes.size()
		mm.visible_instance_count = nodes.size()
		var sphere := SphereMesh.new()
		sphere.radius = 0.03
		sphere.height = 0.06
		sphere.radial_segments = 6
		sphere.rings = 3
		mm.mesh = sphere

		mm_instance = MultiMeshInstance3D.new()
		mm_instance.multimesh = mm
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.emission_enabled = true
		mat.emission_energy_multiplier = 0.3
		mm_instance.material_override = mat
		parent.add_child(mm_instance)

		# ImmediateMesh for springs
		line_mesh = ImmediateMesh.new()
		line_instance = MeshInstance3D.new()
		line_instance.mesh = line_mesh
		var lmat := StandardMaterial3D.new()
		lmat.albedo_color = Color(color.r, color.g, color.b, 0.3)
		lmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		line_instance.material_override = lmat
		parent.add_child(line_instance)

	func render() -> void:
		# Update node positions
		for i in nodes.size():
			var xform := Transform3D.IDENTITY
			xform.origin = nodes[i].position
			mm.set_instance_transform(i, xform)
			var c := color if not nodes[i].is_fixed else Color(1.0, 1.0, 1.0)
			mm.set_instance_color(i, c)

		# Update spring lines
		var lmat := line_instance.material_override
		line_mesh.clear_surfaces()
		line_mesh.surface_begin(Mesh.PRIMITIVE_LINES, lmat)
		for i in springs.size():
			var a := nodes[springs[i].x].position
			var b := nodes[springs[i].y].position
			line_mesh.surface_add_vertex(a)
			line_mesh.surface_add_vertex(b)
		line_mesh.surface_end()


var cloths: Array[ClothPiece] = []
var collision_spheres: Array[Dictionary] = []
var _time := 0.0

# VR interaction
var _left_grab := false
var _right_grab := false

## Every node this script put into the tree. _exit_tree frees these and ONLY
## these. The shipped code freed every child without an owner, which is the same
## set today and a wider one the moment anything else parents a node here.
var _owned: Array[Node] = []
## The subset a config rebuild replaces: the cloth renderers and the collision
## sphere meshes. Labels, the control panel and the VR signal hookups are built
## once and survive a rebuild, so a rebuild cannot connect a controller twice.
var _sim_owned: Array[Node] = []
var _built_signature: Array = []
var _is_built := false


func _ready() -> void:
	scale = Vector3(0.8, 0.8, 0.8)

	_build_sim()

	_setup_labels()
	_setup_controls()
	_setup_vr()

	# Recorded AFTER the build with the values the build actually used, so a
	# deferred config call carrying those same values returns without touching
	# a node. See apply_grid_config.
	_is_built = true
	_built_signature = _build_signature()


## The cloths and their collision spheres — everything a config change rebuilds.
## Synchronous, no call_deferred: the artifact is complete when _ready returns.
func _build_sim() -> void:
	var ef: float = _ease_factor()

	# Three cloths: hanging, free-floating, draped over sphere
	var c1 := ClothPiece.new()
	c1.ease_factor = ef
	c1.build(cloth_resolution, Vector2(1.5, 1.5), Vector3(-3, 2.5, 0), Color(0.9, 0.8, 0.2), 0)
	c1.setup_rendering(self)
	_own_sim(c1.mm_instance)
	_own_sim(c1.line_instance)
	cloths.append(c1)

	var c2 := ClothPiece.new()
	c2.ease_factor = ef
	c2.build(cloth_resolution, Vector2(1.2, 1.2), Vector3(0, 2.0, 0), Color(0.2, 0.8, 0.9), 1)
	c2.setup_rendering(self)
	_own_sim(c2.mm_instance)
	_own_sim(c2.line_instance)
	cloths.append(c2)

	var c3 := ClothPiece.new()
	c3.ease_factor = ef
	c3.build(cloth_resolution, Vector2(1.0, 1.0), Vector3(3, 2.5, 0), Color(0.9, 0.3, 0.8), 2)
	c3.setup_rendering(self)
	_own_sim(c3.mm_instance)
	_own_sim(c3.line_instance)
	cloths.append(c3)

	# Collision spheres
	_add_collision_sphere(Vector3(0, 0.8, 0), 0.4, Color(0.3, 0.9, 0.9))
	_add_collision_sphere(Vector3(3, 1.5, 0), 0.5, Color(0.9, 0.3, 0.3))

	# Pose-pinning pre-pass. settle_steps defaults to 0, so nothing that ships
	# today runs a single extra step.
	if settle_steps > 0:
		_presettle()


## Run the simulation forward at a fixed step, synchronously, before the first
## frame is drawn — so the axis is photographed at a fixed point rather than at
## whatever transient the frame clock happened to land on.
##
## _time is HELD AT 0 for the whole pre-pass, which makes the wind term a
## constant instead of a function of the clock. With the fixture's
## wind_strength and wind_noise_amp both at 0 it is exactly zero, and the only
## forces left are gravity, the springs, the floor clamp and the two collision
## spheres — all of them attractors, none of them time-varying.
func _presettle() -> void:
	var dt: float = fixed_step if fixed_step > 0.0 else 1.0 / 60.0
	var keep: float = _time
	_time = 0.0
	for _step_i in settle_steps:
		for cloth in cloths:
			_apply_forces(cloth)
			_update_physics(cloth, dt)
			_apply_constraints(cloth)
			_handle_collisions(cloth)
	_time = keep
	# Render once so the pre-pass's resting pose is what the sweep's AABB
	# pre-pass measures, not the build-time flat grid.
	for cloth in cloths:
		cloth.render()


func _own(n: Node) -> void:
	if n != null and not _owned.has(n):
		_owned.append(n)


func _own_sim(n: Node) -> void:
	if n == null:
		return
	_own(n)
	if not _sim_owned.has(n):
		_sim_owned.append(n)


## Free by REGISTER — not by name, and not by "every child without an owner".
func _free_register(register: Array[Node]) -> void:
	for n in register:
		if is_instance_valid(n):
			var p: Node = n.get_parent()
			if p != null:
				p.remove_child(n)
			n.queue_free()
	register.clear()


func _add_collision_sphere(pos: Vector3, radius: float, color: Color) -> void:
	collision_spheres.append({"pos": pos, "radius": radius})
	var mesh := MeshInstance3D.new()
	var smesh := SphereMesh.new()
	smesh.radius = radius
	smesh.height = radius * 2.0
	mesh.mesh = smesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.3
	mesh.material_override = mat
	mesh.position = pos
	add_child(mesh)
	_own_sim(mesh)


func _setup_labels() -> void:
	var title := Label3D.new()
	title.text = "Cloth Simulation"
	title.font_size = 20
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.position = Vector3(0.0, 4.5, 3.0)
	title.modulate = Color(1, 1, 1, 0.9)
	add_child(title)
	_own(title)

	var eq := Label3D.new()
	eq.text = "F_spring = k * (|x2-x1| - rest) * dir"
	eq.font_size = 12
	eq.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	eq.position = Vector3(0.0, 3.9, 3.0)
	eq.modulate = Color(1, 1, 1, 0.5)
	add_child(eq)
	_own(eq)

	# Per-cloth labels
	for data in [["Pinned Corners", Vector3(-3, 3.5, 1.5)], ["Free Float", Vector3(0, 3.5, 1.5)], ["Pinned Edge", Vector3(3, 3.5, 1.5)]]:
		var lbl := Label3D.new()
		lbl.text = data[0]
		lbl.font_size = 14
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = data[1]
		lbl.modulate = Color(1, 1, 1, 0.6)
		add_child(lbl)
		_own(lbl)


func _setup_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("CLOTH SIM", [
		[
			{"type": "slider_h", "label": "WIND", "default": wind_strength / 10.0},
			{"type": "slider_h", "label": "STIFFNESS", "default": (cloth_stiffness - 20.0) / 180.0},
		],
		[
			{"type": "slider_h", "label": "DAMPING", "default": cloth_damping / 10.0},
			{"type": "slider_h", "label": "GRAVITY", "default": gravity_strength / 20.0},
		],
		[{"type": "button", "label": "RESET"}],
	])
	panel.position = Vector3(0.0, 1.0, 3.5)
	panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(panel)
	_own(panel)

	var wind_slider: Node = panel.find_child("Param_0", true, false)
	var stiff_slider: Node = panel.find_child("Param_1", true, false)
	var damp_slider: Node = panel.find_child("Param_2", true, false)
	var grav_slider: Node = panel.find_child("Param_3", true, false)

	if wind_slider and wind_slider.has_signal("slider_moved"):
		wind_slider.slider_moved.connect(func(_pos):
			if wind_slider.has_method("get_normalized_value"):
				wind_strength = wind_slider.get_normalized_value() * 10.0
		)
	if stiff_slider and stiff_slider.has_signal("slider_moved"):
		stiff_slider.slider_moved.connect(func(_pos):
			if stiff_slider.has_method("get_normalized_value"):
				cloth_stiffness = 20.0 + stiff_slider.get_normalized_value() * 180.0
		)
	if damp_slider and damp_slider.has_signal("slider_moved"):
		damp_slider.slider_moved.connect(func(_pos):
			if damp_slider.has_method("get_normalized_value"):
				cloth_damping = damp_slider.get_normalized_value() * 10.0
		)
	if grav_slider and grav_slider.has_signal("slider_moved"):
		grav_slider.slider_moved.connect(func(_pos):
			if grav_slider.has_method("get_normalized_value"):
				gravity_strength = grav_slider.get_normalized_value() * 20.0
		)


func _setup_vr() -> void:
	var xr_origin = get_tree().get_first_node_in_group("XROrigin")
	if xr_origin:
		var left = xr_origin.get_node_or_null("LeftController")
		var right = xr_origin.get_node_or_null("RightController")
		if left:
			left.button_pressed.connect(func(b): if b == "trigger_click" or b == "grip_click": _left_grab = true)
			left.button_released.connect(func(b): if b == "trigger_click" or b == "grip_click": _left_grab = false)
		if right:
			right.button_pressed.connect(func(b): if b == "trigger_click" or b == "grip_click": _right_grab = true)
			right.button_released.connect(func(b): if b == "trigger_click" or b == "grip_click": _right_grab = false)


func _process(delta: float) -> void:
	# fixed_step 0.0 is the shipped path: `step` IS `delta`, so `_time += step`
	# and `_update_physics(cloth, step)` are the identical two lines.
	var step: float = fixed_step if fixed_step > 0.0 else delta
	_time += step

	for cloth in cloths:
		_apply_forces(cloth)
		_update_physics(cloth, step)
		_apply_constraints(cloth)
		_handle_collisions(cloth)
		cloth.render()

	_vr_grab()


func _apply_forces(cloth: ClothPiece) -> void:
	var wind_dir := Vector3(sin(_time * 0.7), 0, cos(_time * 0.5)).normalized()
	for node in cloth.nodes:
		node.apply_force(Vector3(0, -gravity_strength * node.mass, 0))
		# Wind with noise. wind_noise_amp defaults to 0.5, the literal that was
		# inline here, and 0.5 is exactly representable — so the shipped path is
		# the same product, not a value that rounds to it.
		var wind_noise := sin(_time * 3.0 + node.position.x * 2.0 + node.position.z) * wind_noise_amp
		node.apply_force(wind_dir * (wind_strength + wind_noise))


func _update_physics(cloth: ClothPiece, delta: float) -> void:
	for node in cloth.nodes:
		node.update(delta)


func _apply_constraints(cloth: ClothPiece) -> void:
	# Spring constraints (position-based correction). The iteration count and the
	# correction gain ARE the relaxation axis; at "worked" they are 3 and 0.5,
	# the two literals this loop shipped with. The per-node symmetric split
	# below (`correction * 0.5` on both bodies) is untouched by the axis — it is
	# mass distribution, not insistence.
	var iterations: int = _relax_iterations()
	var gain: float = _relax_gain()
	for iter in iterations:
		for i in cloth.springs.size():
			var n1 := cloth.nodes[cloth.springs[i].x]
			var n2 := cloth.nodes[cloth.springs[i].y]
			var diff := n2.position - n1.position
			var dist := diff.length()
			if dist < 0.001:
				continue
			var rest := cloth.rest_lengths[i]
			var correction := diff.normalized() * (dist - rest) * gain
			if not n1.is_fixed:
				n1.position += correction * 0.5
			if not n2.is_fixed:
				n2.position -= correction * 0.5


## Relaxation passes per step. "worked" and any unrecognised string fall through
## to 3 — the literal `for iter in 3` this file shipped with.
func _relax_iterations() -> int:
	match relaxation:
		"nudged":
			return 1
		"pressed":
			return 6
		"held":
			return 10
	return 3


## Correction gain. "worked" and any unrecognised string fall through to 0.5 —
## the literal this file shipped with.
func _relax_gain() -> float:
	match relaxation:
		"nudged":
			return 0.35
		"pressed":
			return 0.8
		"held":
			return 1.0
	return 0.5


## Rest-length multiplier. "plain" and any unrecognised string fall through to
## 1.0, and _add_spring skips the multiply entirely on 1.0.
func _ease_factor() -> float:
	match ease:
		"taut":
			return 0.82
		"slack":
			return 1.18
		"full":
			return 1.40
	return 1.0


func _handle_collisions(cloth: ClothPiece) -> void:
	for node in cloth.nodes:
		if node.is_fixed:
			continue
		# Floor
		if node.position.y < 0.0:
			node.position.y = 0.0
			node.velocity.y = 0.0
		# Spheres
		for sphere in collision_spheres:
			var diff: Vector3 = node.position - sphere["pos"]
			var dist: float = diff.length()
			if dist < sphere["radius"]:
				node.position = sphere["pos"] + diff.normalized() * sphere["radius"]
				node.velocity *= 0.5


func _vr_grab() -> void:
	var xr_origin = get_tree().get_first_node_in_group("XROrigin")
	if not xr_origin:
		return

	var controllers := []
	if _left_grab:
		var left = xr_origin.get_node_or_null("LeftController")
		if left:
			controllers.append(to_local(left.global_position))
	if _right_grab:
		var right = xr_origin.get_node_or_null("RightController")
		if right:
			controllers.append(to_local(right.global_position))

	for ctrl_pos in controllers:
		for cloth in cloths:
			for node in cloth.nodes:
				if node.is_fixed:
					continue
				if node.position.distance_to(ctrl_pos) < 0.2:
					node.apply_force((ctrl_pos - node.position).normalized() * 50.0)
					node.velocity *= 0.8


func _exit_tree() -> void:
	# Was: free every child without an owner. Same set today — every child here
	# is made at runtime — but scoped to the register so a node parented by
	# anything else is not this script's to destroy.
	_free_register(_owned)
	_sim_owned.clear()


## Replace the cloths and their spheres, keeping labels, panel and VR hookups.
func _rebuild_sim() -> void:
	for n in _sim_owned:
		_owned.erase(n)
	_free_register(_sim_owned)
	cloths.clear()
	collision_spheres.clear()
	_time = 0.0
	_build_sim()


## Every value the build reads, in one comparable array.
func _build_signature() -> Array:
	return [cloth_resolution, relaxation, ease, settle_steps, fixed_step,
		wind_strength, wind_noise_amp, gravity_strength]


## Config a map token, a composer or the sweep can set. Was a bare `pass`.
##
## RETURNS EARLY WHEN NOTHING MOVED, and that is what keeps every existing
## placement bit-identical. capture_config_sweep sets swept exports BEFORE
## add_child, so _ready builds with them and records the matching signature;
## a later config call carrying those same values returns without touching a
## node. curation_station calls this with {"emissive": false} directly after
## add_child — no axis key, signature unchanged, so it returns too.
func apply_grid_config(config: Dictionary) -> void:
	if config.has("relaxation"):
		relaxation = str(config["relaxation"])
	if config.has("ease"):
		ease = str(config["ease"])
	if config.has("cloth_resolution"):
		cloth_resolution = int(config["cloth_resolution"])
	if config.has("wind_strength"):
		wind_strength = float(config["wind_strength"])
	if config.has("wind_noise_amp"):
		wind_noise_amp = float(config["wind_noise_amp"])
	if config.has("gravity_strength"):
		gravity_strength = float(config["gravity_strength"])
	if config.has("settle_steps"):
		settle_steps = int(config["settle_steps"])
	if config.has("fixed_step"):
		fixed_step = float(config["fixed_step"])

	# Configured before being parented — a composer that sets then adds. There
	# is nothing to rebuild: _ready has not run and will build with the values
	# just written.
	if not _is_built:
		return

	var sig: Array = _build_signature()
	if sig == _built_signature:
		return
	_rebuild_sim()
	_built_signature = sig
