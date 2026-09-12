# random_walk_terrarium.gd
# Random walk visualization in a glass terrarium
# Shows 2D and 3D random walks with trails
#
# Algorithm: Simulates random walks (uniform 2D, uniform 3D, and Lévy flight)
# inside a bounded glass terrarium. Each walker takes discrete steps in uniformly
# random directions; boundary reflection keeps walkers contained. Mean squared
# displacement (MSD) is tracked to demonstrate diffusion scaling laws.
#
# QFEP: Random walk as pure E(S) — no memory, no direction, maximum entropy
#
# @identity
# essence: E[|r|²] = n·d·σ² — mean squared displacement scales linearly with step count
# desire: peer into a glass box and watch colored particles wander without purpose or memory
# critical_parameter: walk_mode — switches between WALK_2D (planar), WALK_3D (volumetric), LEVY_FLIGHT (heavy-tailed jumps)
# triggers: mode switch buttons change step generator; each step calls _generate_step() with boundary reflection
# emerges: Levy flights produce dramatically different trail topology — rare giant leaps amid local clusters
# needs: VR mode buttons [has], reset button [has], trail rendering via ImmediateMesh [has]
# relationships: contrasts with random_walk_leash (observed vs felt); feeds random_walk_collection and pixel_cloud
# truth: A random walk has no destination — yet it explores space more honestly than any planned path.

extends Node3D

class_name RandomWalkTerrarium

# --- Constants ---
const WALKER_RADIUS := 0.012
const WALKER_HEIGHT := 0.024
const WALL_THICKNESS := 0.005
const BASE_THICKNESS := 0.01
const BASE_OVERHANG := 0.02
const GLASS_ALPHA := 0.15
const TRAIL_MAX_ALPHA := 0.6
const EMISSION_ENERGY := 0.5
const LEVY_STEP_CAP := 10.0
const LEVY_OFFSET := 0.01
const LEVY_EXPONENT := -0.5
const LABEL_PIXEL_SIZE := 0.002
const STATS_PIXEL_SIZE := 0.0012
const BTN_LABEL_PIXEL_SIZE := 0.001
const BTN_LABEL_Y_OFFSET := -0.022
const BTN_SCALE := Vector3(0.7, 0.7, 0.7)
const PANEL_SIZE := Vector3(0.35, 0.1, 0.01)
const MAX_CATCHUP_STEPS := 5

const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

## Housing — cabinet grammar, VERTICAL dialect (body = "terrarium case").
## You stand and peer INTO the glass, so the plane is vertical: the tank is a
## specimen displayed at viewing height on a cabinet base that carries the sign,
## the stats readout and the keypad. Before this the tank sat on the floor with a
## title floating above it, stats floating beside it, and the keypad at y=-0.08 —
## below the floor.
@export var case_body: bool = true
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "RW-11"
## Height of the cabinet top — the shelf the glass tank stands on.
@export var base_height: float = 0.92

## Half-extents of the terrarium box (x, y, z)
@export var terrarium_size: Vector3 = Vector3(0.5, 0.4, 0.5)

## Number of random walkers to simulate
@export_range(1, 20) var num_walkers: int = 5
## Distance each walker moves per step
@export_range(0.001, 0.1, 0.001) var step_size: float = 0.015
## How many walk steps are taken per second
@export_range(1.0, 120.0, 1.0) var steps_per_second: float = 30.0
## Maximum number of trail points kept per walker
@export_range(10, 1000) var trail_length: int = 200

## Walk mode
enum WalkMode { WALK_2D, WALK_3D, LEVY_FLIGHT }
@export var walk_mode: WalkMode = WalkMode.WALK_3D:
	set(value):
		walk_mode = value
		_reset_walkers()

## AXIS — WHAT THE BOX KEEPS OF WHERE THE WALKER HAS BEEN. The walker itself keeps
## nothing: that is the artifact's own truth statement, "no memory, no direction". So
## every line in this tank is the OBSERVER'S memory, not the specimen's, and choosing
## how much of it to draw is choosing what kind of object a random walk is.
##
##   tail    the legacy lineage, byte for byte: a fading line strip of the last
##           `trail_length` positions per walker, alpha ramping from nothing to 0.6.
##           A walk as a THREAD — recent past bright, older past forgotten at a fixed
##           rate. The picture flatters the walker with a short-term memory it has not
##           got.
##   none    the strips go dark. Five glowing beads drifting in clear glass and no
##           evidence of any of it. What the walker actually experiences: position,
##           and nothing else. The most honest and the emptiest frame.
##   chord   the path is thrown away and the DISPLACEMENT is drawn instead — one thick
##           lit bar from the release point to each walker, plus a translucent shell at
##           the root-mean-square radius, which is the one number the stats readout has
##           been printing all along. The walk as a statistic: only the straight line
##           from start to now survives, and the shell says how far a walk of this many
##           steps is expected to get.
##   cloud   every site any walker has stood on is stamped as a permanent bead and left
##           there, uncapped by trail_length. The tank silts up with the region the
##           walkers have swept. A walk as OCCUPANCY rather than route — the picture
##           forgets the order and keeps the territory, which is the opposite trade to
##           `chord`.
##
## SEE walk_seed. Without it the four values are four different walks and the sweep
## measures noise; with it they are one walk shown four ways, which is the axis.
@export_enum("tail", "none", "chord", "cloud") var memory: String = "tail"
const MEMORIES: PackedStringArray = ["tail", "none", "chord", "cloud"]

## Seed for the step generator. -1 (the default) draws from the global stream exactly
## as before — same calls, same order, byte-identical behaviour. Set it non-negative
## and every launch, every reset and every DNA variant replays the SAME walk, which is
## the precondition for the `memory` axis measuring the drawing rather than the dice.
@export var walk_seed: int = -1

## Colors assigned to each walker (wraps if fewer than num_walkers)
@export var walker_colors: Array[Color] = [
	Color(1.0, 0.3, 0.3),
	Color(0.3, 1.0, 0.4),
	Color(0.3, 0.5, 1.0),
	Color(1.0, 0.8, 0.3),
	Color(0.8, 0.3, 1.0)
]

# State
var _walker_positions: Array[Vector3] = []
var _walker_trails: Array[PackedVector3Array] = []
var _step_timer: float = 0.0
var _total_steps: int = 0

# Visuals
var _glass_box: Node3D
var _cab: Node3D    # the cabinet base
var _tank: Node3D   # lifted stage: glass box + walkers + trails
var _walker_mm: MultiMesh
var _trail_meshes: Array[MeshInstance3D] = []
var _trail_ims: Array[ImmediateMesh] = []
var _trail_mat: StandardMaterial3D
var _info_label: Label3D
var _stats_label: Label3D
var _control_panel: Node3D
var _reset_area: Node

# Seeded stream — stays null on the default path so randf() is untouched.
var _rng: RandomNumberGenerator = null

# MEMORY dressing. All of it hangs off _mem_root under the tank, and none of it is
# ever built while `memory` is "tail".
const CLOUD_CAP := 4000
const CHORD_THICK := 0.008
var _mem_root: Node3D
var _chord_nodes: Array[MeshInstance3D] = []
var _shell: MeshInstance3D
var _cloud_mm: MultiMesh
var _cloud_count: int = 0
var _cloud_step: int = -1


func _ready():
	if case_body:
		_create_case()
	_create_terrarium()
	_create_walkers()
	_create_labels()
	_create_vr_controls()
	_reset_walkers()

func _exit_tree():
	if _reset_area and _reset_area.button_pressed.is_connected(_reset_walkers):
		_reset_area.button_pressed.disconnect(_reset_walkers)

## Where the specimen lives. The tank, its walkers and their trails all ride one
## container lifted to the cabinet top, so the whole exhibit moves together.
## Marked phenomenon: the walkers ARE the subject, and the grammar's no-orphan-text
## rule should measure the cabinet's interface, not the specimen's own space.
func _stage() -> Node3D:
	if not case_body:
		return self
	if _tank == null:
		_tank = Node3D.new()
		_tank.name = "Tank"
		_tank.set_meta("phenomenon", true)
		_tank.position = Vector3(0, base_height, 0)
		add_child(_tank)
	return _tank


## THE CASE. Vertical dialect: a cabinet base the glass tank stands on, carrying
## the sign band under its cap, the stats readout seated in a milled pocket, and
## the keypad on a wedge shoulder — so the exhibit is ONE body, not a tank with
## three things hovering around it.
func _create_case() -> void:
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_body: Color = pal["body"]
	var col_accent: Color = pal["accent"]
	var shell: StandardMaterial3D = HangarKit.finish_body(finish, col_body, wear)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_body.lightened(0.10))
	var dark: StandardMaterial3D = HangarKit.painted_metal(
		Color(0.07, 0.075, 0.09), wear, 0.35, 0.55)
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)

	var w: float = terrarium_size.x + 0.14
	var d: float = terrarium_size.z + 0.14
	var h: float = base_height
	var face_z: float = d * 0.5

	var cab := Node3D.new()
	cab.name = "Cabinet"
	cab.set_meta("housing", true)
	add_child(cab)
	_cab = cab

	# body + cap the tank stands on
	cab.add_child(HangarKit.box(Vector3(0, h * 0.5, 0), Vector3(w, h, d), shell))
	cab.add_child(HangarKit.box(
		Vector3(0, h - 0.018, 0), Vector3(w + 0.045, 0.036, d + 0.045), steel))
	# ember stripe under the cap lip (G7)
	cab.add_child(HangarKit.box(
		Vector3(0, h - 0.046, face_z + 0.006),
		Vector3(w * 0.98, 0.007, 0.006), accent))
	# side flanks
	for sx in [-1.0, 1.0]:
		cab.add_child(HangarKit.box(
			Vector3(sx * (w * 0.5 + 0.016), h * 0.5, 0.0),
			Vector3(0.032, h, d + 0.018), steel))
	# recessed toe kick + grime at the floor (G2)
	cab.add_child(HangarKit.box(
		Vector3(0, 0.03, 0), Vector3(w - 0.10, 0.06, d - 0.10), dark))
	var gb: MeshInstance3D = HangarKit.grime_band(w * 0.88, 0.05, face_z + 0.003, col_body)
	if gb:
		gb.position.y = 0.075
		cab.add_child(gb)
	# bolted flank lines
	cab.add_child(HangarKit.bolts(
		Vector3(-w * 0.5 + 0.024, 0.14, face_z + 0.004),
		Vector3(-w * 0.5 + 0.024, h - 0.10, face_z + 0.004), 5, 0.0055, steel))
	cab.add_child(HangarKit.bolts(
		Vector3(w * 0.5 - 0.024, 0.14, face_z + 0.004),
		Vector3(w * 0.5 - 0.024, h - 0.10, face_z + 0.004), 5, 0.0055, steel))

	# sign band, baked flush into the fascia just under the cap — a case label
	var sign: MeshInstance3D = HangarKit.stencil(
		"RANDOM WALK", Vector2(w * 0.80, 0.030), col_accent.lightened(0.35))
	if sign:
		sign.position = Vector3(0, h - 0.085, face_z + 0.004)
		cab.add_child(sign)
	var code: MeshInstance3D = HangarKit.stencil(
		unit_code, Vector2(0.10, 0.024), col_accent.lightened(0.20))
	if code:
		code.position = Vector3(-w * 0.5 + 0.09, 0.17, face_z + 0.004)
		cab.add_child(code)
	# the family's three-colour bar, low on the fascia
	var bar: Node3D = HangarKit.three_color_bar(w * 0.40, 0.013)
	if bar:
		bar.position = Vector3(0.0, 0.30, face_z + 0.005)
		cab.add_child(bar)

	# stats readout seated in a milled pocket: pocket, lit face, canonical glass,
	# ember lip. The live Label3D reads against it (see _create_labels).
	var scr_w: float = w * 0.72
	var scr_h: float = 0.17
	var scr_y: float = h * 0.62
	cab.add_child(HangarKit.box(
		Vector3(0, scr_y, face_z + 0.002),
		Vector3(scr_w + 0.026, scr_h + 0.030, 0.014), dark))
	cab.add_child(HangarKit.box(
		Vector3(0, scr_y, face_z + 0.008),
		Vector3(scr_w, scr_h, 0.005), HangarKit.emissive(pal["screen"], 0.45)))
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.04, 0.05, 0.08)
	glass_mat.roughness = 0.15
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(0.05, 0.08, 0.12)
	glass_mat.emission_energy_multiplier = 0.5
	cab.add_child(HangarKit.box(
		Vector3(0, scr_y, face_z + 0.0125), Vector3(scr_w, scr_h, 0.004), glass_mat))
	cab.add_child(HangarKit.box(
		Vector3(0, scr_y + scr_h * 0.5 + 0.010, face_z + 0.010),
		Vector3(scr_w + 0.026, 0.005, 0.005), accent))
	var tag: MeshInstance3D = HangarKit.stencil(
		"DISPLACEMENT", Vector2(scr_w * 0.46, 0.016), col_accent.lightened(0.30))
	if tag:
		tag.position = Vector3(-scr_w * 0.25, scr_y + scr_h * 0.5 + 0.026, face_z + 0.004)
		cab.add_child(tag)


## Builds the glass box enclosure: base slab and four transparent walls.
func _create_terrarium():
	_glass_box = Node3D.new()
	_glass_box.name = "GlassBox"
	_stage().add_child(_glass_box)

	# Base (solid)
	var base = MeshInstance3D.new()
	base.name = "Base"
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(terrarium_size.x + BASE_OVERHANG, BASE_THICKNESS, terrarium_size.z + BASE_OVERHANG)
	base.mesh = base_mesh
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.1, 0.1, 0.12)
	base.material_override = base_mat
	base.position = Vector3(0, -BASE_THICKNESS / 2.0, 0)
	_glass_box.add_child(base)

	# Glass walls (shared material)
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.7, 0.85, 1.0, GLASS_ALPHA)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Front/back walls (shared mesh)
	var fb_mesh = BoxMesh.new()
	fb_mesh.size = Vector3(terrarium_size.x, terrarium_size.y, WALL_THICKNESS)
	for z_sign in [-1, 1]:
		var wall = MeshInstance3D.new()
		wall.mesh = fb_mesh
		wall.material_override = glass_mat
		wall.position = Vector3(0, terrarium_size.y / 2.0, z_sign * terrarium_size.z / 2.0)
		_glass_box.add_child(wall)

	# Left/right walls (shared mesh)
	var lr_mesh = BoxMesh.new()
	lr_mesh.size = Vector3(WALL_THICKNESS, terrarium_size.y, terrarium_size.z)
	for x_sign in [-1, 1]:
		var wall = MeshInstance3D.new()
		wall.mesh = lr_mesh
		wall.material_override = glass_mat
		wall.position = Vector3(x_sign * terrarium_size.x / 2.0, terrarium_size.y / 2.0, 0)
		_glass_box.add_child(wall)

## Creates walker spheres via MultiMesh, trail ImmediateMeshes, and state arrays.
func _create_walkers():
	# Walker spheres via MultiMesh (single draw call)
	var sphere := SphereMesh.new()
	sphere.radius = WALKER_RADIUS
	sphere.height = WALKER_HEIGHT

	_walker_mm = MultiMesh.new()
	_walker_mm.transform_format = MultiMesh.TRANSFORM_3D
	_walker_mm.use_colors = true
	_walker_mm.mesh = sphere
	_walker_mm.instance_count = num_walkers

	for i in num_walkers:
		var color = walker_colors[i % walker_colors.size()]
		_walker_mm.set_instance_color(i, color)
		_walker_mm.set_instance_transform(i, Transform3D(Basis(), Vector3.ZERO))

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Walkers"
	mmi.multimesh = _walker_mm
	var walker_mat := StandardMaterial3D.new()
	walker_mat.vertex_color_use_as_albedo = true
	walker_mat.emission_enabled = true
	walker_mat.emission = Color.WHITE
	walker_mat.emission_energy_multiplier = EMISSION_ENERGY
	mmi.material_override = walker_mat
	_stage().add_child(mmi)

	# Shared trail material (reused every frame)
	_trail_mat = StandardMaterial3D.new()
	_trail_mat.vertex_color_use_as_albedo = true
	_trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Pre-size state arrays
	_walker_positions.resize(num_walkers)
	_walker_trails.resize(num_walkers)
	_trail_meshes.resize(num_walkers)
	_trail_ims.resize(num_walkers)

	for i in num_walkers:
		var im := ImmediateMesh.new()
		_trail_ims[i] = im

		var trail_mi := MeshInstance3D.new()
		trail_mi.name = "Trail%d" % i
		trail_mi.mesh = im
		trail_mi.material_override = _trail_mat
		_trail_meshes[i] = trail_mi
		_stage().add_child(trail_mi)

		_walker_positions[i] = Vector3.ZERO
		_walker_trails[i] = PackedVector3Array()

## Adds the title and statistics labels above / beside the terrarium.
func _create_labels():
	if not case_body:
		_info_label = Label3D.new()
		_info_label.name = "InfoLabel"
		_info_label.pixel_size = LABEL_PIXEL_SIZE
		_info_label.font_size = 16
		_info_label.position = Vector3(0, terrarium_size.y + 0.08, 0)
		_info_label.text = "RANDOM WALK"
		add_child(_info_label)

		_stats_label = Label3D.new()
		_stats_label.name = "StatsLabel"
		_stats_label.pixel_size = STATS_PIXEL_SIZE
		_stats_label.font_size = 12
		_stats_label.position = Vector3(terrarium_size.x / 2.0 + 0.1, terrarium_size.y / 2.0, 0)
		add_child(_stats_label)
		return

	# The title is the cabinet's own sign band (baked in _create_case), so there is
	# no floating title. The stats read AGAINST the seated screen instead of hanging
	# beside the tank — inside the body, which is what the rule asks for.
	var w: float = terrarium_size.x + 0.14
	var d: float = terrarium_size.z + 0.14
	_stats_label = Label3D.new()
	_stats_label.name = "StatsLabel"
	_stats_label.pixel_size = STATS_PIXEL_SIZE
	_stats_label.font_size = 12
	_stats_label.modulate = HangarKit.finish_palette(finish)["text"]
	_stats_label.position = Vector3(0, base_height * 0.62, d * 0.5 + 0.020)
	_cab.add_child(_stats_label)

## Creates the VR button panel with mode-switch and reset buttons.
func _create_vr_controls():
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	# Frameless when housed: the wedge shoulder is the faceplate, and RackTemplates'
	# cream plate + copper strip would read as a second manufacturer (G4).
	_control_panel = RackTpl.create_panel("" if case_body else "RANDOM WALK", [
		[
			{"type": "button", "label": "2D"},
			{"type": "button", "label": "3D"},
			{"type": "button", "label": "LEVY"},
		],
		[{"type": "button", "label": "RESET"}],
	], case_body)
	if case_body:
		# Keypad on a WEDGE SHOULDER cantilevered off the fascia just under the cap,
		# so the controls meet the body. Previously this panel sat at y=-0.08 — below
		# the floor, and nowhere near the VR reach band.
		var d: float = terrarium_size.z + 0.14
		var w: float = terrarium_size.x + 0.14
		var face_z: float = d * 0.5
		var shoulder_y: float = base_height - 0.20   # clears the sign band above
		var steel: StandardMaterial3D = HangarKit.worn_metal(
			HangarKit.finish_palette(finish)["body"].lightened(0.10))
		var shoulder: MeshInstance3D = HangarKit.wedge(w * 0.72, 0.11, 0.15, 0.05, steel)
		if shoulder:
			shoulder.position = Vector3(0.0, shoulder_y, face_z - 0.002)
			_cab.add_child(shoulder)
		_control_panel.position = Vector3(0.0, shoulder_y + 0.055, face_z + 0.076)
		_control_panel.rotation_degrees = Vector3(-32, 0, 0)
		HangarKit.harmonize(_control_panel, finish)
		_cab.add_child(_control_panel)
	else:
		_control_panel.position = Vector3(0, -0.08, terrarium_size.z / 2.0 + 0.15)
		_control_panel.rotation_degrees = Vector3(-30, 0, 0)
		add_child(_control_panel)

	# Mode buttons: 2D (Btn_0), 3D (Btn_1), LEVY (Btn_2)
	for i in range(3):
		var btn: Node = _control_panel.find_child("Btn_%d" % i, true, false)
		if btn:
			var mode_idx := i
			var area = btn.get_node_or_null("InteractableAreaButton")
			if area:
				area.button_pressed.connect(func(_b): walk_mode = mode_idx as WalkMode)

	# RESET (Btn_3)
	var reset_btn: Node = _control_panel.find_child("Btn_3", true, false)
	if reset_btn:
		_reset_area = reset_btn.get_node_or_null("InteractableAreaButton")
		if _reset_area:
			_reset_area.button_pressed.connect(_reset_walkers)

func _reset_walkers():
	if _walker_positions.is_empty():
		return
	# Re-seed at the top so a reset replays the SAME walk. At walk_seed = -1 this is
	# skipped entirely and the global stream is untouched — the legacy path.
	if walk_seed >= 0:
		if _rng == null:
			_rng = RandomNumberGenerator.new()
		_rng.seed = walk_seed
	_cloud_count = 0
	_cloud_step = -1
	if _cloud_mm:
		_cloud_mm.visible_instance_count = 0
	_total_steps = 0
	for i in range(num_walkers):
		_walker_positions[i] = Vector3(0, terrarium_size.y / 2.0, 0)
		_walker_trails[i].clear()
		if _walker_mm:
			_walker_mm.set_instance_transform(i, Transform3D(Basis(), _walker_positions[i]))

func _process(delta):
	var interval = 1.0 / maxf(steps_per_second, 0.001)
	_step_timer = minf(_step_timer + delta, interval * MAX_CATCHUP_STEPS)

	while _step_timer >= interval:
		_step_timer -= interval
		_step_all_walkers()

	_update_trails()
	_update_memory()
	_update_stats()

func _step_all_walkers():
	_total_steps += 1

	for i in range(num_walkers):
		var step = _generate_step()
		var new_pos = _walker_positions[i] + step

		# Boundary reflection
		new_pos = _reflect_boundaries(new_pos)

		# Record trail
		_walker_trails[i].append(_walker_positions[i])
		if _walker_trails[i].size() > trail_length:
			_walker_trails[i] = _walker_trails[i].slice(1)

		_walker_positions[i] = new_pos
		_walker_mm.set_instance_transform(i, Transform3D(Basis(), new_pos))

func _generate_step() -> Vector3:
	match walk_mode:
		WalkMode.WALK_2D:
			var angle = _rand() * TAU
			return Vector3(cos(angle), 0, sin(angle)) * step_size

		WalkMode.WALK_3D:
			# Random direction on unit sphere
			var theta = _rand() * TAU
			var phi = acos(2.0 * _rand() - 1.0)
			return Vector3(
				sin(phi) * cos(theta),
				sin(phi) * sin(theta),
				cos(phi)
			) * step_size

		WalkMode.LEVY_FLIGHT:
			# Lévy flight: occasional large jumps
			var angle = _rand() * TAU
			var phi = acos(2.0 * _rand() - 1.0)
			var direction = Vector3(
				sin(phi) * cos(angle),
				sin(phi) * sin(angle),
				cos(phi)
			)
			# Power-law step size
			var u = _rand()
			var levy_step = step_size * pow(u + LEVY_OFFSET, LEVY_EXPONENT)
			levy_step = minf(levy_step, step_size * LEVY_STEP_CAP)
			return direction * levy_step

	return Vector3.ZERO


## THE ONLY DRAW IN THE BUILD PATH. walk_seed = -1 falls straight through to randf(),
## same call, same order, same stream — so the legacy walk is unchanged. Any
## non-negative seed makes the walk replayable, which is what lets four values of
## `memory` be four drawings of ONE walk instead of four different walks.
func _rand() -> float:
	if walk_seed < 0:
		return randf()
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.seed = walk_seed
	return _rng.randf()

func _reflect_boundaries(pos: Vector3) -> Vector3:
	var half = terrarium_size / 2.0

	if pos.x < -half.x: pos.x = -half.x + (-half.x - pos.x)
	if pos.x > half.x: pos.x = half.x - (pos.x - half.x)
	if pos.z < -half.z: pos.z = -half.z + (-half.z - pos.z)
	if pos.z > half.z: pos.z = half.z - (pos.z - half.z)

	if walk_mode != WalkMode.WALK_2D:
		if pos.y < 0: pos.y = -pos.y
		if pos.y > terrarium_size.y: pos.y = terrarium_size.y - (pos.y - terrarium_size.y)
	else:
		pos.y = terrarium_size.y / 2.0

	return pos

## Rebuilds trail line strips from cached ImmediateMeshes (no per-frame allocation).
func _update_trails():
	for i in range(num_walkers):
		var trail = _walker_trails[i]
		if trail.size() < 2:
			_trail_ims[i].clear_surfaces()
			continue

		var color = walker_colors[i % walker_colors.size()]

		_trail_ims[i].clear_surfaces()
		_trail_ims[i].surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

		for j in range(trail.size()):
			var alpha = float(j) / float(trail.size())
			_trail_ims[i].surface_set_color(Color(color.r, color.g, color.b, alpha * TRAIL_MAX_ALPHA))
			_trail_ims[i].surface_add_vertex(trail[j])

		_trail_ims[i].surface_end()

## Computes mean squared displacement and updates the stats label.
func _update_stats():
	var sum_sq_disp = 0.0
	for i in range(num_walkers):
		var disp = _walker_positions[i] - Vector3(0, terrarium_size.y / 2.0, 0)
		sum_sq_disp += disp.length_squared()
	var msd = sum_sq_disp / maxf(num_walkers, 1)

	var mode_names = ["2D", "3D", "Lévy"]
	_stats_label.text = "%s Walk\nSteps: %d\nMSD: %.4f" % [mode_names[walk_mode], _total_steps, msd]

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: walk_mode = WalkMode.WALK_2D
			KEY_2: walk_mode = WalkMode.WALK_3D
			KEY_3: walk_mode = WalkMode.LEVY_FLIGHT
			KEY_R: _reset_walkers()

func set_mode(m: WalkMode):
	walk_mode = m

func reset():
	_reset_walkers()

func apply_grid_config(config_data: Dictionary) -> void:
	var touched := false
	if config_data.has("walk_seed"):
		walk_seed = int(str(config_data["walk_seed"]))
		touched = true
	if config_data.has("memory"):
		# Normalising read — an unknown word keeps the trail already drawn rather than
		# blanking the tank, so a typo in a map token cannot publish an empty box.
		var _m: String = str(config_data["memory"]).strip_edges().to_lower()
		if MEMORIES.has(_m):
			memory = _m
			_clear_memory()
			touched = true
	if touched:
		_reset_walkers()


# ── MEMORY ───────────────────────────────────────────────────────────────────
# One axis, four values, all of it hanging off a root that is never created while the
# value is "tail". `_update_memory` returns on the first line in that case, so the
# legacy path costs nothing and draws nothing new.


## Tear down whatever the previous value built, so switching mid-session cannot leave
## a chord and a cloud in the same tank.
func _clear_memory() -> void:
	_chord_nodes.clear()
	_shell = null
	_cloud_mm = null
	_cloud_count = 0
	_cloud_step = -1
	if _mem_root:
		_mem_root.get_parent().remove_child(_mem_root)
		_mem_root.queue_free()
		_mem_root = null


func _memory_root() -> Node3D:
	if _mem_root == null:
		_mem_root = Node3D.new()
		_mem_root.name = "Memory"
		_stage().add_child(_mem_root)
	return _mem_root


func _update_memory() -> void:
	if memory == "tail":
		return
	# The fading strip IS the default reading of history. Every other value disputes
	# it, so the strips go quiet before anything else is drawn.
	for im in _trail_ims:
		if im:
			im.clear_surfaces()
	match memory:
		"chord":
			_memory_chord()
		"cloud":
			_memory_cloud()
		_:
			pass                              # "none" — the box keeps nothing


## CHORD — the displacement instead of the path: a thick lit bar from the release
## point to each walker, plus a translucent shell at the RMS radius the stats readout
## has been printing all along.
func _memory_chord() -> void:
	var root: Node3D = _memory_root()
	var origin: Vector3 = Vector3(0, terrarium_size.y / 2.0, 0)

	if _chord_nodes.is_empty():
		for i in range(num_walkers):
			var c: Color = walker_colors[i % walker_colors.size()]
			var mi := MeshInstance3D.new()
			mi.name = "Chord%d" % i
			var bm := BoxMesh.new()
			bm.size = Vector3(CHORD_THICK, CHORD_THICK, 1.0)
			mi.mesh = bm
			mi.material_override = _lit_mat(c, 1.25, 1.0)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(mi)
			_chord_nodes.append(mi)

		_shell = MeshInstance3D.new()
		_shell.name = "RmsShell"
		var sm := SphereMesh.new()
		sm.radius = 1.0
		sm.height = 2.0
		sm.radial_segments = 24
		sm.rings = 12
		_shell.mesh = sm
		_shell.material_override = _lit_mat(Color(0.65, 0.85, 1.0), 0.55, 0.16)
		_shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(_shell)

	var sum_sq: float = 0.0
	for i in range(num_walkers):
		if i >= _chord_nodes.size():
			break
		var v: Vector3 = _walker_positions[i] - origin
		var d: float = v.length()
		sum_sq += d * d
		var mi: MeshInstance3D = _chord_nodes[i]
		if d < 0.002:
			mi.layers = 0
			continue
		mi.layers = 1
		var zax: Vector3 = v / d
		var up_ref: Vector3 = Vector3.UP
		if absf(zax.dot(up_ref)) > 0.99:
			up_ref = Vector3.RIGHT
		var xax: Vector3 = up_ref.cross(zax).normalized()
		var yax: Vector3 = zax.cross(xax).normalized()
		mi.transform = Transform3D(Basis(xax, yax, zax * d), origin + v * 0.5)

	if _shell:
		var rms: float = sqrt(sum_sq / maxf(num_walkers, 1))
		if rms < 0.004:
			_shell.layers = 0
		else:
			_shell.layers = 1
			_shell.transform = Transform3D(
				Basis.IDENTITY.scaled(Vector3.ONE * rms), origin)


## CLOUD — every site any walker has stood on, stamped once and left there. Stamped on
## the STEP counter, not per frame, so a paused sim does not silt the tank up twice.
func _memory_cloud() -> void:
	var root: Node3D = _memory_root()
	if _cloud_mm == null:
		var bead := SphereMesh.new()
		bead.radius = 0.010
		bead.height = 0.020
		bead.radial_segments = 8
		bead.rings = 4
		_cloud_mm = MultiMesh.new()
		_cloud_mm.transform_format = MultiMesh.TRANSFORM_3D
		_cloud_mm.use_colors = true
		_cloud_mm.mesh = bead
		_cloud_mm.instance_count = CLOUD_CAP
		_cloud_mm.visible_instance_count = 0
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Cloud"
		mmi.multimesh = _cloud_mm
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.emission_enabled = true
		mat.emission = Color.WHITE
		mat.emission_energy_multiplier = 0.35
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mmi)

	if _total_steps == _cloud_step:
		return
	_cloud_step = _total_steps
	for i in range(num_walkers):
		if _cloud_count >= CLOUD_CAP:
			break
		_cloud_mm.set_instance_transform(_cloud_count,
			Transform3D(Basis(), _walker_positions[i]))
		_cloud_mm.set_instance_color(_cloud_count,
			walker_colors[i % walker_colors.size()])
		_cloud_count += 1
	_cloud_mm.visible_instance_count = _cloud_count


func _lit_mat(c: Color, energy: float, alpha: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(c.r, c.g, c.b, alpha)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = energy
	if alpha < 0.999:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat
