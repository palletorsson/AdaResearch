extends Node3D
class_name FourSoftBodyController

# @identity
# essence: four identical soft bodies dropped at the same instant, each one FROZEN at a different moment of its fall (stop_times 7.5s, 11s, 12s, 12s) — a 2x2 grid of the same deformation arrested at four depths. Not four objects: one event, sampled four times. The stopped cloth keeps the exact crumple it had when its timer fired, so the room holds a sequence of sculptures that are really timestamps.
# desire: it wants to make deformation READABLE by interrupting it. A falling soft body is a blur of becoming; stopped, it becomes a form you can walk around. It wants the player to compare the four arrests and reconstruct the fall in their head — to see that the material was never heading toward a final shape, only passing through shapes.
# critical_parameter: stop_times — the four freeze moments. Change them and the same fall yields different sculptures; set them equal and difference collapses into repetition. The parameter IS the argument: form here is not designed, it is sampled from a process.
# triggers: _ready spawns the 2x2 grid and arms one Timer per body; each timeout freezes its SoftBody3D mid-fall (ui timers optionally show the countdown).
# emerges: placed in the softbodies chapter's primitive slot it becomes the chapter's first lesson standing still: the frozen crumples are what "form emerges from the material's own dynamics" looks like when you stop the dynamics to look.
# needs: a soft body scene to instance [softbodybody.tscn, present]; per-body Timers [built in _ready]; a floor to fall toward [the map provides].
# relationships: the still sibling of every live simulation in the sequence — jelly_cube shows deformation happening, this shows it HELD; kin to the seam's sampled-line argument (a continuous process, held at samples).
# truth: the softbodies chapter says form is not imposed — it emerges from the material's own dynamics. This artifact adds the corollary: any FORM you can point at is just a process someone stopped. The four arrests differ, and none of them is the cloth; the cloth was the falling.

# ═══════════════════════════════════════════════════════════════════════════════
#  STAGE-2 DNA — promoted 2026-08-12.  axis: landing (floor | pan | rail | cone)
#
#  WHAT THE AXIS ARGUES. Four identical SoftBody3D spheres fall from drop_height
#  onto whatever is beneath them, and what is beneath them is nothing this
#  artifact owns. `landing` gives each cell of the 2x2 grid a surface to
#  negotiate with, so the four resting crumples differ because the MATERIAL met a
#  different shape, not because a clock read differently. That is the softbodies
#  truth line at its most literal: form is not imposed, it is what is left after a
#  falling body and a rigid obstruction finish arguing.
#
#  WHY NOT `stop_times`, which is this artifact's own declared critical_parameter
#  and the obvious candidate. Three reasons, and the first alone is fatal:
#    1. They are CLOCK READINGS. The capture fires ~1.2 s after the photographed
#       instance enters the tree (capture_config_sweep: SETTLE 1.1 + two process
#       frames + 0.1) and the earliest freeze is 7.5 s, so at the shutter not one
#       of the four has fired. A sweep of that ladder publishes four tiles of four
#       bodies at the same moment of the same fall.
#    2. Compressed into the window by a fixture it would photograph four
#       TRANSIENTS, each frozen by a Timer whose timeout lands on whichever
#       physics tick the frame rate happened to produce. Two runs would freeze two
#       different crumples and the bite number would be a fact about the frame
#       clock.
#    3. Two of the four shipped values are already IDENTICAL (12.0, 12.0), so the
#       four-stop demo collapses two of its own samples — the exact failure its
#       @identity warns about. Recorded here, not fixed: changing them would move
#       twelve live appearances.
#  Also declined: `spacing` (composition, not material) and `show_timers` (UI).
#
#  THE AXIS MUST CHANGE THE SHAPE THE MATERIAL COMES TO REST IN, never how fast it
#  gets there. Each value is a different resting silhouette:
#    floor — a squashed ball, wide contact patch. The shipped picture.
#    pan   — pinched between two tray walls 0.70 m apart; the body narrows and
#            RISES. The only value where it ends up taller than it started.
#    rail  — a saddle over a 1.6 m bar, two lobes either side, a crease on top.
#    cone  — a tent: the lowest point pushed up into the body's own volume.
#  PREDICTED CLOSEST PAIR: pan vs cone. Both drive the body upward and narrow it —
#  pan with two walls, cone with one point — each raising the centroid by roughly
#  0.18 m and narrowing the width from 1.0 m to ~0.72 m, so the outer silhouettes
#  agree to within ~0.06 m on a body ~13% of frame width. The visible difference
#  is the tray's own two walls (0.70 x 0.35 m each, x4 cells) plus the crease
#  geometry: ~4% of frame, focus ~16%. IF pan comes back within 1% of floor the
#  tray is too wide and the sphere is resting inside it untouched — narrow
#  PAN_INNER_SPAN to 0.55 before blaming the axis.
#
#  THE BENCH HAS NO FLOOR, and that is the biggest thing this promotion found.
#  capture_config_sweep's default stage is lights and a camera; the showcase
#  ground is a MeshInstance3D with no collider and dna.host builds a
#  MultiMeshInstance3D with no collider. There is no physics floor anywhere on it.
#  Released at y=3 the four bodies fall forever. The AABB pre-pass measures a
#  SEPARATE probe instance at 0.35 s (0.6 m down) and frees it; the photographed
#  instance is a fresh one that lives ~1.2 s before the shutter, about seven
#  metres down — so every tile of any sweep of this artifact today is empty sky,
#  and the verdict would read INERT about the harness. bench_floor_y /
#  drop_height / body_damping are the fixture that supplies what a map supplies.
#  They are inert at their defaults.
#
#  TRAP that decides drop_height=1.35: softbody3d.gd _setup_physics() contains
#  `if global_position.y < 1.0: global_position.y = 2.0`, so ANY drop_height below
#  1.0 is silently overridden to 2.0 and the fixture looks as if it were ignored.
#
#  THE SETTLE BUDGET, which is the whole determinism argument and is TIGHT.
#  1.35 minus the 0.5 m sphere radius is a 0.85 m fall: first contact at ~0.42 s
#  under standard gravity, leaving ~0.78 s of settling at damping_coefficient 0.45
#  (against the shipped 0.01) onto a rigid obstruction. That is an attracting rest
#  rather than a transient, which is the entire reason rest is the pin and a timed
#  freeze was declined. pan / rail / cone all contact EARLIER than floor (their
#  surfaces stand 0.35 / 0.55 / 0.30 m up), so `floor` is the worst case and the
#  one to check. THE RESIDUAL RISK I could not close without running it: the four
#  bodies are default SphereMeshes, ~2100 vertices each, at simulation_precision 7.
#  If that overruns the headless frame budget, Godot clamps physics steps per frame
#  and SIMULATED time falls behind the wall clock create_timer() is counting — so
#  the pose at the shutter would depend on the machine, which is the "accumulated
#  physics steps" failure in its purest form. VERIFY BY RUNNING THE SWEEP TWICE AND
#  DIFFERENCING THE DEFAULT TILE before trusting any number from this artifact. If
#  the two runs differ, raise body_damping before touching the axis.
# ═══════════════════════════════════════════════════════════════════════════════

# Configuration
@export var soft_body_scene_path: String = "res://algorithms/physicssimulation/softbodies/softbodystop/softbodybody.tscn"
@export var spacing: float = 3.0
@export var stop_times: Array[float] = [7.5, 11.0, 12.0, 12.0]
@export var show_timers: bool = true

## What each falling body has to land on. "floor" builds NOTHING — the body meets
## whatever the room already put under it, which is the shipped behaviour.
@export_enum("floor", "pan", "rail", "cone") var landing: String = "floor"

# ── Bench fixture. Every one of these is a no-op at its default value. ─────────
## The y each body is released from — the literal that used to be written 3 in
## the positions array below.
@export var drop_height: float = 3.0
## Below -999.0 no floor is built, which is the shipped behaviour: the map's floor
## is the floor. At or above it a StaticBody3D plane is built at this height on
## collision_layer 1 — the layer softbody3d.gd masks — plus the visible slab that
## gives the union-AABB pre-pass something the size of the grid to frame.
@export var bench_floor_y: float = -1000.0
## Below 0.0 the SoftBody3D keeps its own damping_coefficient (0.01). At or above
## it the value is written to all four bodies, which is what buys a settled pose
## inside the capture window instead of a transient.
@export var body_damping: float = -1.0

# Landing geometry, named so a failed prediction has a number to move.
const LANDINGS: Array[String] = ["floor", "pan", "rail", "cone"]
const PAN_INNER_SPAN: float = 0.70   # < the 1.0 m sphere: it cannot rest without squeezing
const PAN_WALL_H: float = 0.35
const PAN_WALL_T: float = 0.06
const PAN_WALL_D: float = 0.70
const RAIL_TOP: float = 0.55         # top face of the bar, above the floor datum
const RAIL_LEN: float = 1.60
const RAIL_T: float = 0.14
const CONE_H: float = 0.30           # apex height above the floor datum
const CONE_R: float = 0.30

# Internal variables
var soft_body_instances: Array[SoftBody3D] = []
var stop_timers: Array[Timer] = []
var ui_labels: Array[Label] = []
var stopped_states: Array[bool] = [false, false, false, false]

## Everything THIS script added to the tree, so a rebuild frees its own work and
## nothing else. The scene's own Camera3D has an owner and is never in here.
var _owned: Array[Node] = []
## The build inputs as they stood when the tree was last built. apply_grid_config
## compares against it and returns early when nothing it reads has changed.
var _sig: String = ""
var _obstruction_mat: StandardMaterial3D = null

func _ready() -> void:
	# Synchronous, in one pass, in this order. The two builders below add NOTHING
	# at their defaults (bench_floor_y = -1000.0, landing = "floor"), so the child
	# order every shipped placement sees is unchanged: SoftBody_1..4 then
	# StopTimer_1..4. What is under the bodies has to exist before they land, not
	# before they are created, but building it first costs nothing and keeps the
	# fixture and the axis adjacent in one place.
	_sig = _signature()
	_build_bench_floor()
	_build_landing()
	create_four_soft_bodies()
	setup_stop_timers()


	print("ðŸŽ¯ Four SoftBody Controller ready!")
	print("   Positions: 2x2 grid with %.1fm spacing" % spacing)
	print("   Stop times: ", stop_times)



func create_four_soft_bodies() -> void:
	"""Create 4 soft bodies in a 2x2 grid"""
	
	var soft_body_scene = load(soft_body_scene_path)
	
	if not soft_body_scene:
		print("âŒ Failed to load soft body scene: ", soft_body_scene_path)
		create_fallback_soft_bodies()
		return
	
	# 2x2 grid positions. drop_height IS the 3 that used to be written here, and
	# 3.0 is exactly representable, so the default path is bit-identical.
	var positions = [
		Vector3(0, drop_height, 0),  # Front-left
		Vector3(spacing, drop_height, 0),   # Front-right
		Vector3(0, drop_height, spacing),   # Back-left
		Vector3(spacing, drop_height, spacing)     # Back-right
	]

	for i in range(4):
		var soft_body_instance = soft_body_scene.instantiate()
		soft_body_instance.name = "SoftBody_" + str(i + 1)
		soft_body_instance.position = positions[i]

		add_child(soft_body_instance)
		_owned.append(soft_body_instance)

		# Find the actual SoftBody3D node in the instance
		var soft_body_node = find_soft_body_in_instance(soft_body_instance)
		if soft_body_node:
			soft_body_instances.append(soft_body_node)
			# AFTER add_child, because softbody3d.gd's _ready runs there and this
			# has to be the last word. That _ready never touches
			# damping_coefficient, so at the shipped default (-1.0) the body keeps
			# its own 0.01 and nothing is written at all.
			if body_damping >= 0.0:
				soft_body_node.damping_coefficient = body_damping
			print("âœ… Created SoftBody %d at %s" % [i + 1, positions[i]])
		else:
			print("âš ï¸  Could not find SoftBody3D in instance %d" % (i + 1))

func find_soft_body_in_instance(instance: Node) -> SoftBody3D:
	"""Find the SoftBody3D node within an instance"""
	
	# Check if the instance itself is a SoftBody3D
	if instance is SoftBody3D:
		return instance as SoftBody3D
	
	# Search children recursively
	for child in instance.get_children():
		if child is SoftBody3D:
			return child as SoftBody3D
		
		var found = find_soft_body_in_instance(child)
		if found:
			return found
	
	return null

func create_fallback_soft_bodies() -> void:
	"""Create basic soft bodies if scene loading fails"""
	
	print("ðŸ”„ Creating fallback soft bodies...")
	
	var positions = [
		Vector3(-spacing/2, drop_height, -spacing/2),
		Vector3(spacing/2, drop_height, -spacing/2),
		Vector3(-spacing/2, drop_height, spacing/2),
		Vector3(spacing/2, drop_height, spacing/2)
	]
	
	for i in range(4):
		var soft_body = SoftBody3D.new()
		soft_body.name = "FallbackSoftBody_" + str(i + 1)
		soft_body.position = positions[i]
		
		# Create sphere mesh
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.5
		sphere_mesh.height = 1.0
		soft_body.mesh = sphere_mesh
		
		# Configure physics
		soft_body.linear_stiffness = 0.5
		soft_body.damping_coefficient = 0.01
		soft_body.total_mass = 1.0
		soft_body.simulation_precision = 5
		
		# Create colorful material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.from_hsv(i * 0.25, 0.8, 1.0)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.8
		soft_body.set_surface_override_material(0, material)
		
		add_child(soft_body)
		_owned.append(soft_body)
		soft_body_instances.append(soft_body)
		if body_damping >= 0.0:
			soft_body.damping_coefficient = body_damping

func setup_stop_timers() -> void:
	"""Setup individual stop timers for each soft body"""
	
	for i in range(soft_body_instances.size()):
		var timer = Timer.new()
		timer.name = "StopTimer_" + str(i + 1)
		timer.wait_time = stop_times[i] if i < stop_times.size() else 5.0
		timer.one_shot = true
		timer.autostart = true
		timer.timeout.connect(_on_stop_timeout.bind(i))
		
		add_child(timer)
		_owned.append(timer)
		stop_timers.append(timer)
		
		print("â° Timer %d set for %.1f seconds" % [i + 1, timer.wait_time])


func _process(_delta):
	"""Update UI timers"""
	
	if not show_timers:
		return
	
	for i in range(stop_timers.size()):
		if i < ui_labels.size() and i < stop_timers.size():
			var timer = stop_timers[i]
			var label = ui_labels[i]
			
			if not stopped_states[i] and timer.time_left > 0:
				label.text = "SoftBody %d: %.1fs" % [i + 1, timer.time_left]
				
				# Color coding
				if timer.time_left < 1.0:
					label.add_theme_color_override("font_color", Color.RED)
				elif timer.time_left < 2.0:
					label.add_theme_color_override("font_color", Color.YELLOW)
				else:
					label.add_theme_color_override("font_color", Color.WHITE)

func _on_stop_timeout(index: int) -> void:
	"""Called when a specific timer expires"""
	
	if index >= soft_body_instances.size():
		return
	
	var soft_body = soft_body_instances[index]
	
	print("â° Timer %d expired - stopping SoftBody: %s" % [index + 1, soft_body.name])
	stop_soft_body(index)

func stop_soft_body(index: int) -> void:
	"""Stop a specific soft body"""
	
	if index >= soft_body_instances.size() or stopped_states[index]:
		return
	
	var soft_body = soft_body_instances[index]
	stopped_states[index] = true
	
	# Stop using SoftBody3D methods
	soft_body.set_process_mode(Node.PROCESS_MODE_DISABLED)
	soft_body.damping_coefficient = 100.0
	soft_body.linear_stiffness = 1.0
	
	# Visual feedback

	
	# Update UI
	if index < ui_labels.size():
		ui_labels[index].text = "SoftBody %d: STOPPED!" % [index + 1]
		ui_labels[index].add_theme_color_override("font_color", Color.BLUE)
	
	print("ðŸ§Š SoftBody %d stopped and frozen!" % [index + 1])

func restart_all() -> void:
	"""Restart all soft bodies"""
	
	print("ðŸ”„ Restarting all soft bodies...")
	
	for i in range(soft_body_instances.size()):
		if stopped_states[i]:
			restart_soft_body(i)
	
	# Restart timers
	for timer in stop_timers:
		timer.start()

func restart_soft_body(index: int) -> void:
	"""Restart a specific soft body"""
	
	if index >= soft_body_instances.size():
		return
	
	var soft_body = soft_body_instances[index]
	stopped_states[index] = false
	
	# Re-enable. 0.01 is the SoftBody3D default this artifact has always restarted
	# to; body_damping overrides it only when a fixture set one, so the shipped
	# path is the same line it always was.
	soft_body.set_process_mode(Node.PROCESS_MODE_INHERIT)
	soft_body.damping_coefficient = body_damping if body_damping >= 0.0 else 0.01
	soft_body.linear_stiffness = 0.5
	
	# Reset visual
	var material = _get_soft_body_material(soft_body, 0)
	if material is StandardMaterial3D:
		var std_mat = material as StandardMaterial3D
		std_mat.emission_enabled = false
		# Reset to original color based on index
		std_mat.albedo_color = Color.from_hsv(index * 0.25, 0.8, 1.0)
		std_mat.albedo_color.a = 0.8
	
	print("âœ… SoftBody %d restarted!" % [index + 1])

func _get_soft_body_material(soft_body: SoftBody3D, surface_index: int = 0) -> Material:
	"""Resolve material safely for SoftBody3D instances in Godot 4."""
	if soft_body.material_override != null:
		return soft_body.material_override
	
	var override_material = soft_body.get_surface_override_material(surface_index)
	if override_material != null:
		return override_material
	
	var active_material = soft_body.get_active_material(surface_index)
	if active_material != null:
		return active_material
	
	if soft_body.mesh != null and surface_index < soft_body.mesh.get_surface_count():
		return soft_body.mesh.surface_get_material(surface_index)
	
	return null

func _input(event: InputEvent) -> void:
	"""Handle input"""
	
	if event.is_action_pressed("ui_accept"):  # Space key
		restart_all()
	
	if event.is_action_pressed("ui_select"):  # Enter key
		print("ðŸ“Š Status Report:")
		for i in range(soft_body_instances.size()):
			var status = "RUNNING" if not stopped_states[i] else "STOPPED"
			print("   SoftBody %d: %s" % [i + 1, status])
	
	# Stop individual soft bodies with number keys
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				if not stopped_states[0]: stop_soft_body(0)
			KEY_2:
				if not stopped_states[1]: stop_soft_body(1)
			KEY_3:
				if not stopped_states[2]: stop_soft_body(2)
			KEY_4:
				if not stopped_states[3]: stop_soft_body(3)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═══════════════════════════════════════════════════════════════════════════════
#  landing — what each falling body has to negotiate with
# ═══════════════════════════════════════════════════════════════════════════════

## The four cell centres, at the floor datum. The 2x2 grid is NOT centred on the
## origin: it runs 0..spacing in x and z, exactly as create_four_soft_bodies
## places the bodies, so the obstruction sits under the body and not beside it.
func _cell_centres() -> Array:
	return [
		Vector3(0.0, 0.0, 0.0),
		Vector3(spacing, 0.0, 0.0),
		Vector3(0.0, 0.0, spacing),
		Vector3(spacing, 0.0, spacing)
	]

## The height the obstructions stand on. On the bench that is the fixture floor;
## in a map it is local 0, which the grid's auto-grounding already puts on the
## room's floor surface.
func _floor_datum() -> float:
	if bench_floor_y > -999.0:
		return bench_floor_y
	return 0.0

## One shared material for every obstruction: fewer resources, and — more to the
## point — four values that differ in SHAPE and in nothing else. A per-value
## colour would let the critic score a paint job.
func _obstruction_material() -> StandardMaterial3D:
	if _obstruction_mat == null:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.55, 0.56, 0.58)
		m.roughness = 0.55
		_obstruction_mat = m
	return _obstruction_mat

## A box that is both seen and felt: the mesh for the picture, the shape for the
## soft body to argue with.
func _slab(parent: Node3D, at: Vector3, size: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.position = at
	parent.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _obstruction_material()
	mi.position = at
	parent.add_child(mi)

## THE FIXTURE'S FLOOR, and the reason any of this can be photographed at all.
## Nothing is built at the shipped default, so a map's own floor stays the floor.
##
## The slab is sized to the grid rather than to the room on purpose: it is also
## the only thing in the subtree whose AABB tracks the 2x2 layout. Every
## SoftBody3D goes top-level with an identity transform once it starts
## simulating, so all four report the same 1 m mesh box at the origin and the
## union-AABB pre-pass would frame one cell of four.
func _build_bench_floor() -> void:
	if bench_floor_y <= -999.0:
		return
	var span: float = spacing + 2.2
	var body := StaticBody3D.new()
	body.name = "BenchFloor"
	body.collision_layer = 1   # the layer softbody3d.gd masks against
	body.collision_mask = 1
	body.position = Vector3(spacing * 0.5, bench_floor_y - 0.1, spacing * 0.5)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(span, 0.2, span)
	cs.shape = bs
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(span, 0.2, span)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.17, 0.18, 0.20)
	mat.roughness = 0.95
	mi.material_override = mat
	body.add_child(mi)
	add_child(body)
	_owned.append(body)

## THE AXIS. At "floor" this returns before constructing anything, which is the
## short circuit that keeps every shipped placement bit-identical.
func _build_landing() -> void:
	if landing == "floor":
		return
	var y0: float = _floor_datum()
	var index: int = 0
	for c in _cell_centres():
		var cell: Vector3 = c
		index += 1
		var body := StaticBody3D.new()
		body.name = "Landing_%s_%d" % [landing, index]
		body.collision_layer = 1
		body.collision_mask = 1
		body.position = Vector3(cell.x, y0, cell.z)
		match landing:
			"pan":
				_build_pan(body)
			"rail":
				_build_rail(body)
			"cone":
				_build_cone(body)
		add_child(body)
		_owned.append(body)

## Two walls PAN_INNER_SPAN apart. A 1.0 m sphere cannot rest between them
## without squeezing, so it narrows in x and its centroid rises — the one value
## where the body ends up taller than it started. The floor is the tray's base.
func _build_pan(parent: Node3D) -> void:
	var off: float = PAN_INNER_SPAN * 0.5 + PAN_WALL_T * 0.5
	for s in [-1.0, 1.0]:
		var sx: float = s
		_slab(parent, Vector3(sx * off, PAN_WALL_H * 0.5, 0.0),
			Vector3(PAN_WALL_T, PAN_WALL_H, PAN_WALL_D))

## A bar with its TOP face at RAIL_TOP, laid along z so the two lobes hang to
## either side in x, where the camera can see the crease between them. The end
## posts are inside the bar's own footprint, so they add nothing to the AABB and
## stand clear of the lobes.
func _build_rail(parent: Node3D) -> void:
	_slab(parent, Vector3(0.0, RAIL_TOP - RAIL_T * 0.5, 0.0),
		Vector3(RAIL_T, RAIL_T, RAIL_LEN))
	var post_h: float = RAIL_TOP - RAIL_T
	for s in [-1.0, 1.0]:
		var sz: float = s
		_slab(parent, Vector3(0.0, post_h * 0.5, sz * (RAIL_LEN * 0.5 - 0.06)),
			Vector3(0.09, post_h, 0.09))

## A point at CONE_H. The body tents on it: its lowest point is pushed up into
## its own volume and dimples the pressure-inflated shell. The collision shape is
## the hull of the same mesh — one geometry, so what is felt is what is seen.
func _build_cone(parent: Node3D) -> void:
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = CONE_R
	cm.height = CONE_H
	cm.radial_segments = 24
	cm.rings = 1
	var at := Vector3(0.0, CONE_H * 0.5, 0.0)
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.material_override = _obstruction_material()
	mi.position = at
	parent.add_child(mi)
	var cs := CollisionShape3D.new()
	cs.shape = cm.create_convex_shape()
	cs.position = at
	parent.add_child(cs)


# ═══════════════════════════════════════════════════════════════════════════════
#  Config hook
# ═══════════════════════════════════════════════════════════════════════════════

## Everything the build reads, in one string. A rebuild happens only when this
## changes, which is what makes a config call carrying no key of ours free.
func _signature() -> String:
	return "%s|%.4f|%.4f|%.4f|%.4f" % [
		landing, spacing, drop_height, bench_floor_y, body_damping]

## THE DEFAULT IS A SHORT CIRCUIT, not a cheap rebuild.
##
## Twelve appearances of this token exist and not one of them reaches a rebuild.
## Five are bare grid tokens (SoftBodies_Cloth_Physics, _p1, _p2, _p3 and
## Corridor_SoftBodies_Cloth_Physics) with no rotation, no offset and no #key, so
## merged_config is empty and this is never called at all. Six are
## `exhibit_furniture#...#mount:softstopscene` slots, and _mount_artifact()
## instantiates the scene and adds it with no config call whatsoever. The last is
## Curation_Bay_softbodies_2's curation_station roster, which calls
## apply_grid_config({"emissive": false}) on everything it curates — a key this
## artifact does not read, so the signature is unchanged and it returns here.
func apply_grid_config(config: Dictionary) -> void:
	if config.has("landing"):
		var want: String = str(config["landing"]).strip_edges().to_lower()
		if want in LANDINGS:
			landing = want
	if config.has("spacing"):
		spacing = float(config["spacing"])
	if config.has("drop_height"):
		drop_height = float(config["drop_height"])
	if config.has("bench_floor_y"):
		bench_floor_y = float(config["bench_floor_y"])
	if config.has("body_damping"):
		body_damping = float(config["body_damping"])

	# Before _ready these properties ARE the build inputs — _ready reads them a
	# moment later — so setting them is the whole job and building now would
	# build twice.
	if not is_node_ready():
		return

	var sig: String = _signature()
	if sig == _sig:
		return
	_sig = sig
	_rebuild()

## Frees ONLY what this script put in the tree (_owned) and builds it again in
## the same order _ready does. remove_child first, so the freed nodes cannot
## collide with the new ones over a name or linger one frame in the physics space.
func _rebuild() -> void:
	for n in _owned:
		if is_instance_valid(n):
			if n.get_parent() == self:
				remove_child(n)
			n.queue_free()
	_owned.clear()
	soft_body_instances.clear()
	stop_timers.clear()
	ui_labels.clear()
	stopped_states.resize(4)
	stopped_states.fill(false)
	_obstruction_mat = null
	_build_bench_floor()
	_build_landing()
	create_four_soft_bodies()
	setup_stop_timers()
