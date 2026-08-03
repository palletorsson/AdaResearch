@tool
extends Node3D

# Parametric Pendulum Waves
# Array of pendulums with carefully chosen lengths creating wave patterns
# Famous physics demonstration: "pendulum snake" or "pendulum wave"

@export_group("Pendulum Array")
@export var num_pendulums: int = 15
@export var pendulum_spacing: float = 0.3
@export var base_height: float = 2.5

@export_group("Length Variation")
@export var shortest_length: float = 0.8
@export var longest_length: float = 1.5
@export var length_profile: String = "Linear"  # Linear, Quadratic, or Custom

@export_group("Physics")
@export var gravity: float = 9.8
@export var damping: float = 0.998
@export var release_all: bool = false  # Release all pendulums at once

@export_group("Visualization")
@export var bob_radius: float = 0.08
@export var rod_thickness: float = 0.02
@export var show_pivot_bar: bool = true
@export var trail_length: int = 100
@export var color_by_index: bool = true

@export_group("Animation")
@export var auto_release: bool = true
@export var release_angle: float = 0.5  # Initial angle in radians (about 30°)
@export var show_phase_info: bool = true

@export_group("DNA")
## AXIS — WHAT OF THE SETTING-OUT IS STILL STANDING. A pendulum wave is not a discovery, it
## is a piece of arithmetic built in steel: fifteen lengths chosen so the periods form an
## arithmetic sequence, and the "wave" that runs along the bobs is an artefact of that
## choice, not a property of pendulums. The shipped rig shows a plain grey bar and hides
## every trace of the calculation, so the wave arrives looking like nature. A rig that shows
## its setting-out admits the pattern was SET OUT, by someone, to a measure.
##
## Adopted word for word — and value for value — from [[facade_builder]], which asks the
## identical question of a composed elevation ("what of the making is still standing on the
## finished face"). Same word, same four moments, because a room holding a facade whose
## construction grid is still drawn on it should not hold a pendulum rig that pretends it
## grew.
##
##   none      the legacy lineage, byte for byte — the pivot bar alone, no apparatus
##   datum     the setting-out lines left on the rig: a back-board carrying the pivot datum,
##             a station tick under every pendulum, and the LENGTH LADDER drawn as a stepped
##             rule that touches each bob's rest height in turn — the arithmetic built
##             instead of erased
##   scaffold  the working platform still up — standards, two lifts of ledgers, a board deck
##             and toe board running the whole front at waist height, the rig caught
##             mid-erection with the bobs swinging over the boards
##   gantry    the lifting frame: two towers standing past the ends of the bar, a head beam
##             over the top and a hoist block on a chain above the centre station — the
##             machinery that PUT the bobs at those lengths, not the array that resulted
##
## STRICTLY ADDITIVE and appearance only. "none" builds nothing at all and is the default,
## so all six existing placements render exactly as before. Nothing here touches the length
## formula, the periods, the release, the damping or the integration — it is staged AROUND
## the array and stops there.
@export_enum("none", "datum", "scaffold", "gantry") var armature: String = "none"
const ARMATURES: PackedStringArray = ["none", "datum", "scaffold", "gantry"]

# Internal data
var pendulums: Array[Dictionary] = []
var time_since_release: float = 0.0
var is_released: bool = false
var trail_points: Array[Array] = []

func _ready() -> void:
	_build_pendulum_array()
	if auto_release:
		_release_pendulums()
	# DNA, LAST: the armature is appended after the whole legacy array exists, so no node
	# above it changes index, position or parent. "none" builds nothing at all.
	var _a: String = str(armature).strip_edges().to_lower()
	armature = _a if ARMATURES.has(_a) else "none"
	_build_armature()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if release_all and not is_released:
		_release_pendulums()
		release_all = false

	if is_released:
		time_since_release += delta
		_update_pendulums(delta)
		_update_visualization()

func _build_pendulum_array() -> void:
	# Clear existing
	for child in get_children():
		child.queue_free()

	pendulums.clear()
	trail_points.clear()

	# Create pivot bar
	if show_pivot_bar:
		_create_pivot_bar()

	# Calculate pendulum lengths using parametric formula
	# T = 2π√(L/g)
	# For wave effect: choose lengths so periods form arithmetic sequence
	var target_cycles_in_time = 60.0  # seconds for full recurrence
	var min_oscillations = 51  # Minimum number of complete cycles
	var max_oscillations = min_oscillations + num_pendulums - 1

	for i in range(num_pendulums):
		var fraction = float(i) / max(1.0, float(num_pendulums - 1))

		# Calculate oscillations for this pendulum
		var oscillations = lerp(float(min_oscillations), float(max_oscillations), fraction)

		# Period: time for one complete swing
		var period = target_cycles_in_time / oscillations

		# From T = 2π√(L/g), we get L = (T/(2π))² * g
		var length = pow(period / TAU, 2.0) * gravity

		# Clamp to reasonable values
		length = clamp(length, shortest_length, longest_length)

		var pendulum_data = {
			"index": i,
			"length": length,
			"angle": 0.0,  # Current angle (radians)
			"angular_velocity": 0.0,
			"angular_acceleration": 0.0,
			"oscillations": oscillations,
			"period": period,
			"pivot_position": Vector3(
				(i - (num_pendulums - 1) / 2.0) * pendulum_spacing,
				base_height,
				0.0
			)
		}

		pendulums.append(pendulum_data)
		trail_points.append([])

		# Create visual components
		_create_pendulum_visual(pendulum_data)

func _create_pivot_bar() -> void:
	"""Create horizontal bar showing pivot points"""
	var bar_width = num_pendulums * pendulum_spacing + pendulum_spacing
	var bar = MeshInstance3D.new()
	bar.name = "PivotBar"

	var box = BoxMesh.new()
	box.size = Vector3(bar_width, 0.05, 0.05)
	bar.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.3)
	mat.metallic = 0.0
	mat.roughness = 1.0
	bar.material_override = mat

	bar.position = Vector3(0, base_height, 0)
	add_child(bar)

func _create_pendulum_visual(pend: Dictionary) -> void:
	"""Create rod and bob for pendulum"""
	var container = Node3D.new()
	container.name = "Pendulum_%d" % pend.index
	container.position = pend.pivot_position
	add_child(container)

	# Bob (sphere at end)
	var bob = MeshInstance3D.new()
	bob.name = "Bob"

	var sphere = SphereMesh.new()
	sphere.radius = bob_radius
	sphere.height = bob_radius * 2.0
	bob.mesh = sphere

	var color: Color
	if color_by_index:
		var hue = float(pend.index) / float(num_pendulums)
		color = Color.from_hsv(hue, 0.8, 1.0)
	else:
		color = Color(0.9, 0.3, 0.3)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.5
	mat.emission_energy_multiplier = 0.8
	mat.metallic = 0.0
	mat.roughness = 1.0
	bob.material_override = mat

	container.add_child(bob)

	# Rod (cylinder from pivot to bob)
	var rod = MeshInstance3D.new()
	rod.name = "Rod"

	var cylinder = CylinderMesh.new()
	cylinder.top_radius = rod_thickness
	cylinder.bottom_radius = rod_thickness
	cylinder.height = pend.length
	rod.mesh = cylinder

	var rod_mat = StandardMaterial3D.new()
	rod_mat.albedo_color = Color(0.5, 0.5, 0.5, 0.7)
	rod_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rod_mat.metallic = 0.0
	rod_mat.roughness = 1.0
	rod.material_override = rod_mat

	container.add_child(rod)

func _release_pendulums() -> void:
	"""Release all pendulums from starting angle"""
	for pend in pendulums:
		pend.angle = release_angle
		pend.angular_velocity = 0.0

	is_released = true
	time_since_release = 0.0

func _update_pendulums(delta: float) -> void:
	"""Update pendulum physics using simple harmonic approximation"""
	for pend in pendulums:
		# For small angles: θ'' = -(g/L) * θ
		# This gives simple harmonic motion with ω = √(g/L)

		# Angular acceleration from gravity
		pend.angular_acceleration = -(gravity / pend.length) * sin(pend.angle)

		# Update using Euler integration (or use more accurate integrator)
		pend.angular_velocity += pend.angular_acceleration * delta
		pend.angular_velocity *= damping  # Apply damping
		pend.angle += pend.angular_velocity * delta

func _update_visualization() -> void:
	"""Update visual position of pendulums"""
	for i in range(pendulums.size()):
		var pend = pendulums[i]
		var container_name = "Pendulum_%d" % i
		var container = get_node_or_null(NodePath(container_name))

		if not container:
			continue

		# Calculate bob position
		var angle = pend.angle
		var length = pend.length
		var bob_offset = Vector3(
			sin(angle) * length,
			-cos(angle) * length,
			0.0
		)

		# Update bob
		var bob = container.get_node_or_null("Bob")
		if bob:
			bob.position = bob_offset

			# Update trail
			var world_pos = container.global_position + bob_offset
			trail_points[i].append(world_pos)
			if trail_points[i].size() > trail_length:
				trail_points[i].pop_front()

		# Update rod position and rotation
		var rod = container.get_node_or_null("Rod")
		if rod:
			rod.position = bob_offset * 0.5
			rod.rotation.z = angle

func get_bob_position(index: int) -> Vector3:
	"""Get world position of specific pendulum bob"""
	if index >= 0 and index < pendulums.size():
		var pend = pendulums[index]
		var container_name = "Pendulum_%d" % index
		var container = get_node_or_null(NodePath(container_name))
		if container:
			var angle = pend.angle
			var length = pend.length
			var bob_offset = Vector3(sin(angle) * length, -cos(angle) * length, 0.0)
			return container.global_position + bob_offset
	return Vector3.ZERO

func get_wave_phase() -> float:
	"""Get current phase of the wave pattern (0 to 1)"""
	# The wave repeats when all pendulums return to start
	# This happens at the least common multiple of all periods
	if pendulums.size() == 0:
		return 0.0

	var first_period = pendulums[0].period if pendulums.size() > 0 else 1.0
	return fmod(time_since_release / first_period, 1.0)

func reset() -> void:
	"""Reset all pendulums to starting position"""
	is_released = false
	time_since_release = 0.0
	for pend in pendulums:
		pend.angle = 0.0
		pend.angular_velocity = 0.0
	for trail in trail_points:
		trail.clear()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	# Was a no-op stub, so a map token could never reach anything on this artifact. It now
	# reads exactly one key. An absent or unknown "armature" leaves the shipped value alone,
	# which keeps every existing placement on the legacy path.
	if config.has("armature"):
		var want: String = str(config["armature"]).strip_edges().to_lower()
		if ARMATURES.has(want) and want != armature:
			armature = want
			_build_armature()


# ── ARMATURE ─────────────────────────────────────────────────────────────────
# One axis, four moments, shared word for word with facade_builder.gd. Everything below runs
# AFTER the legacy _ready() body and lives inside one host node, so removing that single node
# restores the shipped rig exactly. Nothing here reads or writes the pendulum dictionaries,
# the lengths, the periods or the integration — it only MEASURES the array that is already
# there, so the drawing can be true to the build rather than to a second copy of the formula.

const ARM_HOST := "Armature"
const ARM_BOARD_Z := -0.30      # the setting-out board stands behind the swing plane
const ARM_LINE_Z := -0.275      # marks drawn on its face
const ARM_DECK_Z := 0.44        # the scaffold deck and front standards, clear of the bobs
const ARM_TOWER_LIFT := 0.70    # how far a gantry tower stands past the end of the bar


func _build_armature() -> void:
	var old: Node = get_node_or_null(ARM_HOST)
	if old != null:
		remove_child(old)
		old.queue_free()
	if armature == "none" or not ARMATURES.has(armature):
		return                          # the legacy lineage builds nothing at all
	var host := Node3D.new()
	host.name = ARM_HOST
	add_child(host)

	var n: int = maxi(num_pendulums, 1)
	var half: float = float(n - 1) * 0.5 * pendulum_spacing
	var bar_w: float = float(n) * pendulum_spacing + pendulum_spacing
	match armature:
		"datum":
			_armature_datum(host, half, bar_w)
		"scaffold":
			_armature_scaffold(host, half, bar_w)
		"gantry":
			_armature_gantry(host, half, bar_w)
		_:
			pass


## DATUM — the drawing left on the rig. A pale board stands behind the swing plane carrying
## the pivot datum as one continuous line, a station tick under every pendulum, and the
## LENGTH LADDER: a short mark at each station drawn at that pendulum's rest height, risers
## joining mark to mark. The lengths are an arithmetic sequence, so the ladder is a smooth
## monotone stair — the calculation that makes the wave, drawn instead of erased.
func _armature_datum(host: Node3D, half: float, bar_w: float) -> void:
	var board: StandardMaterial3D = _arm_mat(Color(0.845, 0.832, 0.795), 0.92, 0.0)
	var ink: StandardMaterial3D = _arm_mat(Color(0.115, 0.120, 0.145), 0.85, 0.0)
	var faint: StandardMaterial3D = _arm_mat(Color(0.520, 0.520, 0.545), 0.90, 0.0)
	var rule: StandardMaterial3D = _arm_emissive(Color(0.90, 0.42, 0.10), 0.9)

	var bh: float = base_height + 0.34
	_arm_box(host, Vector3(0, bh * 0.5, ARM_BOARD_Z), Vector3(bar_w + 0.36, bh, 0.024), board)

	# The pivot datum: one line the whole width, at exactly the height the pivots sit.
	_arm_box(host, Vector3(0, base_height, ARM_LINE_Z), Vector3(bar_w + 0.30, 0.022, 0.012), ink)
	# The ground line, so the datum is a height ABOVE something and not a floating claim.
	_arm_box(host, Vector3(0, 0.012, ARM_LINE_Z), Vector3(bar_w + 0.30, 0.016, 0.012), faint)

	# Station ticks: one vertical rule per pendulum, dropped from the datum to its own bob.
	# Read off the built array so the drawing cannot disagree with the rig.
	var prev_y: float = -1.0
	var prev_x: float = 0.0
	for i in range(pendulums.size()):
		var pend: Dictionary = pendulums[i]
		var pivot: Vector3 = pend["pivot_position"]
		var px: float = pivot.x
		var rest_y: float = base_height - float(pend["length"])
		var drop: float = maxf(base_height - rest_y, 0.02)
		_arm_box(host, Vector3(px, rest_y + drop * 0.5, ARM_LINE_Z),
			Vector3(0.008, drop, 0.010), faint)
		# The rest-height mark for this station.
		_arm_box(host, Vector3(px, rest_y, ARM_LINE_Z + 0.004),
			Vector3(pendulum_spacing * 0.78, 0.016, 0.012), rule)
		# The riser joining this mark to the previous one — the stair of the sequence.
		if prev_y >= 0.0:
			var mid_x: float = (px + prev_x) * 0.5
			var span: float = absf(rest_y - prev_y)
			if span > 0.001:
				_arm_box(host, Vector3(mid_x, (rest_y + prev_y) * 0.5, ARM_LINE_Z + 0.004),
					Vector3(0.010, span, 0.012), rule)
		prev_y = rest_y
		prev_x = px

	# Two witness marks squaring the board to the bar — the setting-out's own corners.
	for sx in [-1.0, 1.0]:
		var sf: float = float(sx)
		_arm_box(host, Vector3(sf * (half + pendulum_spacing), base_height, ARM_LINE_Z + 0.004),
			Vector3(0.020, 0.16, 0.012), ink)


## SCAFFOLD — the working platform still up. Standards every metre and a half in two rows
## front and back of the swing plane, two lifts of ledgers, transoms tying the rows, a board
## deck running the whole front at waist height and a toe board along its outer edge. The rig
## caught mid-erection, the bobs swinging over somebody's boards.
func _armature_scaffold(host: Node3D, half: float, _bar_w: float) -> void:
	var tube: StandardMaterial3D = _arm_mat(Color(0.470, 0.485, 0.510), 0.42, 0.70)
	var plank: StandardMaterial3D = _arm_mat(Color(0.560, 0.450, 0.290), 0.88, 0.0)
	var band: StandardMaterial3D = _arm_mat(Color(0.880, 0.560, 0.090), 0.70, 0.10)

	var top: float = base_height + 0.60
	var reach: float = half + pendulum_spacing
	var bays: int = maxi(int(round((reach * 2.0) / 1.5)), 2)
	var deck_y: float = maxf(base_height - longest_length - 0.42, 0.35)

	# Standards, two rows clear of the swing plane in Z.
	for b in range(bays + 1):
		var sx: float = -reach + (reach * 2.0) * (float(b) / float(bays))
		for sz in [-ARM_DECK_Z, ARM_DECK_Z]:
			var zf: float = float(sz)
			_arm_box(host, Vector3(sx, top * 0.5, zf), Vector3(0.048, top, 0.048), tube)
			_arm_box(host, Vector3(sx, 0.012, zf), Vector3(0.16, 0.024, 0.16), tube)
		# Transom tying the two rows at deck level.
		_arm_box(host, Vector3(sx, deck_y + 0.06, 0), Vector3(0.040, 0.040, ARM_DECK_Z * 2.0), tube)

	# Ledgers: three lifts, both rows, the whole run.
	for lift in [deck_y + 0.06, base_height - 0.30, top - 0.14]:
		var ly: float = float(lift)
		for sz2 in [-ARM_DECK_Z, ARM_DECK_Z]:
			var zg: float = float(sz2)
			_arm_box(host, Vector3(0, ly, zg), Vector3(reach * 2.0 + 0.10, 0.038, 0.038), tube)

	# The board deck: four planks laid across the front bay, plus the toe board.
	for k in range(4):
		var pz: float = ARM_DECK_Z - 0.06 - float(k) * 0.115
		_arm_box(host, Vector3(0, deck_y + 0.12, pz),
			Vector3(reach * 2.0 - 0.02, 0.030, 0.108), plank)
	_arm_box(host, Vector3(0, deck_y + 0.20, ARM_DECK_Z - 0.005),
		Vector3(reach * 2.0 - 0.02, 0.130, 0.026), plank)
	# Guard band along the top ledger — the only warm colour on the frame.
	_arm_box(host, Vector3(0, top - 0.14, ARM_DECK_Z + 0.03),
		Vector3(reach * 2.0 + 0.10, 0.050, 0.014), band)


## GANTRY — the lifting frame. Two braced towers stand past the ends of the bar, a lattice
## head beam runs between them over the array, and a hoist block hangs on a chain above the
## centre station. Not the array that resulted: the machinery that PUT fifteen different
## lengths where they are.
func _armature_gantry(host: Node3D, half: float, _bar_w: float) -> void:
	var steel: StandardMaterial3D = _arm_mat(Color(0.400, 0.415, 0.450), 0.40, 0.76)
	var paint: StandardMaterial3D = _arm_mat(Color(0.880, 0.560, 0.090), 0.66, 0.15)
	var dark: StandardMaterial3D = _arm_mat(Color(0.130, 0.135, 0.155), 0.75, 0.30)

	var tx: float = half + ARM_TOWER_LIFT
	var top: float = base_height + 0.78
	var leg: float = 0.30                      # half the tower's footprint

	for sx in [-1.0, 1.0]:
		var sf: float = float(sx)
		var cx: float = sf * tx
		# Four legs and a base plate.
		for ox in [-leg, leg]:
			for oz in [-leg, leg]:
				_arm_box(host, Vector3(cx + float(ox), top * 0.5, float(oz)),
					Vector3(0.055, top, 0.055), steel)
		_arm_box(host, Vector3(cx, 0.020, 0), Vector3(leg * 2.4, 0.040, leg * 2.4), dark)
		# Cross bracing on the face that reads from the sweep's camera (yaw 0.62 puts the
		# +Z face toward it): five lifts of diagonals, each long enough to actually reach
		# corner to corner of its bay (bay 0.60 wide x top*0.18 tall, so leg*2.8 at 45°).
		for k in range(5):
			var y0: float = top * (0.08 + 0.18 * float(k))
			var diag: MeshInstance3D = _arm_make_box(
				Vector3(cx, y0 + top * 0.09, leg), Vector3(0.034, leg * 2.80, 0.034), steel)
			diag.rotation.z = PI * 0.25 if (k % 2) == 0 else -PI * 0.25
			host.add_child(diag)
			_arm_box(host, Vector3(cx, y0, 0), Vector3(leg * 2.0, 0.034, 0.034), steel)

	# Head beam: two chords with verticals between them, spanning tower to tower.
	var span: float = tx * 2.0 + leg * 2.0
	for cy in [top - 0.10, top - 0.42]:
		_arm_box(host, Vector3(0, float(cy), 0), Vector3(span, 0.070, 0.070), paint)
	var posts: int = maxi(int(span / 0.55), 4)
	for p in range(posts + 1):
		var ux: float = -span * 0.5 + span * (float(p) / float(posts))
		_arm_box(host, Vector3(ux, top - 0.26, 0), Vector3(0.036, 0.320, 0.036), steel)

	# The hoist: a trolley on the lower chord, a chain, a block and a hook over the centre.
	_arm_box(host, Vector3(0, top - 0.50, 0), Vector3(0.230, 0.110, 0.190), paint)
	var links: int = 6
	for l in range(links):
		var ly: float = top - 0.58 - float(l) * 0.075
		var link: MeshInstance3D = _arm_make_box(Vector3(0, ly, 0),
			Vector3(0.030, 0.062, 0.030), dark)
		link.rotation.y = PI * 0.25 if (l % 2) == 0 else 0.0
		host.add_child(link)
	_arm_box(host, Vector3(0, top - 1.06, 0), Vector3(0.150, 0.150, 0.110), dark)
	_arm_box(host, Vector3(0, top - 1.18, 0), Vector3(0.048, 0.130, 0.048), steel)


# ── armature helpers ─────────────────────────────────────────────────────────

func _arm_make_box(centre: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = centre
	return mi


func _arm_box(host: Node3D, centre: Vector3, size: Vector3, mat: Material) -> void:
	host.add_child(_arm_make_box(centre, size, mat))


func _arm_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _arm_emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m
