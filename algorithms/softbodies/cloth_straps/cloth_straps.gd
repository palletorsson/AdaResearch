extends Node3D

# @identity
# essence: N parallel SoftBody3D strips pinned to a frame top bar — each strap is a foil-shader cloth that hangs under gravity and collides with player hands
# desire: to create a curtain you walk through with your body — each strap drapes, parts, and swings back, making soft body physics tactile and intimate
# critical_parameter: strap_count — more straps create a denser curtain with more inter-strap collision, fewer straps let each one swing freely
# triggers: player collision (layer 20) displaces individual straps; throwing a rigid ball (ui_accept) demonstrates mass-vs-compliance interaction
# emerges: overlapping straps tangle and bunch when disturbed simultaneously, creating knot-like configurations never coded into the system
# needs: slider_horizontal [missing]; push_button [missing]; Label3D [missing]
# relationships: follows jelly_cube and softmill as cloth-specific soft body; precedes flagdancer which adds bone-driven wind simulation
# truth: a curtain is not a surface — it is an array of constraints negotiating gravity, and parting it reveals that softness is a collective property

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION — cloth_straps, 2026-08-03. ONE AXIS.
#
#   suspension   WHAT THE CLOTH IS HELD UP BY
#                none · gantry · wall · hoop · mast     (default: gantry)
#
# WHAT WAS HARD-CODED. setup_frame() built one structure and only one: a deep-red
# portal — a top bar on two side posts, 0.5 m thick, bottom open — and every
# placement got it. That portal is not neutral. A frame with two legs and an open
# bottom is a DOORWAY: it says the cloth is a threshold, that there is a here and a
# there, and that the whole point is to pass between them. It is the strongest claim
# this artifact makes and it was the only one it could make.
#
# WHY THIS AXIS AND NOT THE CLOTH. The three still-visible questions about a curtain
# are how many straps, how they drape, and what they are pinned by. The first two live
# in the SoftBody3D solver: at 1.1 s of settle a 3.5 m sheet at linear_stiffness 0.34
# is still stretching and swinging, so any axis routed through the cloth would be
# photographed mid-oscillation and would measure the shutter as much as the design.
# The rig is welded to the ground and does not move, which is the only way a still of a
# perpetually perturbed system says anything at all. (Same reasoning, same words, as
# spring_system's own suspension docstring — see below.)
#
# WHY THE WORD IS BORROWED. spring_system already carries
# `suspension = none · gantry · wall · hoop · mast` for exactly this question: what
# does a hanging body hang from, built to meet anchors that never move. The list is
# reused character for character because the five shapes mean here what they mean
# there — held from ABOVE, from BEHIND, from AROUND, from a single point — and a
# shared vocabulary is only worth having if it survives contact with a second body.
# It is NOT `support` (code_display, info_board, exit_sign): that axis is what a thing
# stands ON, and nothing here stands on anything. It is NOT `hang`
# (gallery_winner_showcase): that axis is the ARRANGEMENT of a set of hung objects —
# grid, line, salon, ring — and this axis deliberately leaves the strap rank exactly
# where it was and builds the rig around it.
#
# WHAT EACH VALUE ARGUES:
#   none    Nothing. The straps hang from their own pinned points and the pins are in
#           mid-air. A curtain with no architecture: the cloth as apparition, with
#           nothing to say where it is or why it stops.
#   gantry  THE LEGACY, byte for byte. Top bar on two posts. A doorway: the cloth
#           divides a here from a there and invites you through.
#   wall    A solid plane behind the straps with a head rail and a plinth. The cloth
#           is no longer a threshold but a HANGING — something in front of a surface,
#           to be looked at, not passed. This is the value that forecloses the
#           artifact's own description ("that the player can walk through"), which is
#           why it is worth being able to build: the description was an assumption.
#   hoop    An overhead ring on four legs with a diameter spar the straps hang from.
#           Held from AROUND: the curtain becomes the diameter of a round enclosure —
#           a partition inside a room rather than the boundary of one.
#   mast    One column set behind the rank with a cantilevered head beam and two
#           braces. Held from a single point at one side: the cloth is carried, and
#           you can see the whole load path in one glance.
#
# THE DEFAULT PRESERVES BEHAVIOUR. `gantry` reruns the shipped arithmetic literally —
# same frame_width and frame_height expressions, same 0.5 thickness, same
# Color(0.5, 0.0, 0.1), same box sizes, same positions, same CollisionShape3D per bar,
# same child order, same StaticBody3D named "Frame". All 7 placements are bare tokens
# carrying no config, and GridInteractablesComponent only calls apply_grid_config when
# a token's config is non-empty — so none of them reaches that function at all.
#
# NOT ROUTED THROUGH suspension: strap_count, strap_width, strap_height,
# strap_overlap, the foil shader, the pin layout in the .tscn, the collision layers,
# the ball-throw test, the demo camera and light. The cloth is identical in all five
# values; only what holds it up changes.
#
# NOT PROMOTED, AND WHY. strap_count is the @identity's critical_parameter and it is
# genuinely still-visible (three ribbons versus a membrane), but it is left undeclared
# on purpose: with five suspension values the gallery's default cap of nine variants
# drops any second axis before it renders, so declaring it would add a row to the
# ledger that no sweep ever measures. It remains a plain export — the sweep sets those
# before add_child, so _ready() builds with them — and it is deliberately NOT accepted
# by apply_grid_config, because honouring it at runtime means tearing down and
# respawning every SoftBody3D on a live placement, which is a much larger promise than
# rebuilding a static rig.
# ─────────────────────────────────────────────────────────────────────────────

@export var strap_count: int = 8
@export var strap_width: float = 0.3
@export var strap_height: float = 3.5
@export var strap_overlap: float = 0.05

## AXIS — what the cloth is held up by. gantry is the shipped lineage.
@export_enum("none", "gantry", "wall", "hoop", "mast") var suspension: String = "gantry"

## The allow-list a map token is checked against. An unknown word keeps the shipped
## rig rather than stranding a placement with a body nobody declared.
const SUSPENSIONS: PackedStringArray = ["none", "gantry", "wall", "hoop", "mast"]

## The shipped frame colour. Every value wears it, so the axis is read as SHAPE and
## a sweep cannot mistake a repaint for a structural difference.
const RIG_COLOR := Color(0.5, 0.0, 0.1)

var _rig: StaticBody3D = null
var _built: bool = false


func _ready() -> void:
	setup_scene()
	setup_frame()
	setup_straps()
	_built = true

func setup_scene() -> void:
	# Camera
	var cam = Camera3D.new()
	cam.position = Vector3(0, 2, 6)
	cam.look_at(Vector3(0, 1.5, 0))
	add_child(cam)

	# Light
	var light = DirectionalLight3D.new()
	light.position = Vector3(5, 10, 5)
	light.look_at(Vector3.ZERO)
	light.shadow_enabled = true
	add_child(light)

## Build the rig the straps hang from. Called once from _ready(), and again only when
## apply_grid_config() is handed a suspension value that is genuinely different.
func setup_frame() -> void:
	if is_instance_valid(_rig):
		# Detach BEFORE freeing: queue_free() defers to the end of the frame, so a
		# replacement added first would collide with the old node's name and be
		# silently renamed to @Frame@2.
		var old_parent: Node = _rig.get_parent()
		if old_parent != null:
			old_parent.remove_child(_rig)
		_rig.queue_free()
	_rig = null
	if suspension == "none":
		return

	var frame_width: float = (strap_width - strap_overlap) * strap_count + strap_overlap + 0.4
	var frame_height: float = strap_height + 0.2
	var frame_thickness: float = 0.5

	var frame := StaticBody3D.new()
	# Frame bottom should be at y=0. Frame height is frame_height.
	# Center of frame is at frame_height/2.0.
	frame.position = Vector3(0, frame_height/2.0, 0)
	frame.name = "Frame"

	# Deep Red Material for Frame
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = RIG_COLOR

	match suspension:
		"wall":
			_rig_wall(frame, frame_mat, frame_width, frame_height, frame_thickness)
		"hoop":
			_rig_hoop(frame, frame_mat, frame_width, frame_height, frame_thickness)
		"mast":
			_rig_mast(frame, frame_mat, frame_width, frame_height, frame_thickness)
		_:
			# "gantry" and anything unrecognised: the shipped portal, unchanged.
			_rig_gantry(frame, frame_mat, frame_width, frame_height, frame_thickness)

	add_child(frame)
	_rig = frame

## GANTRY — held from above. THE LEGACY PATH: top bar, two side bars, a collision box
## on each. Every number below was lifted from the shipped setup_frame() verbatim.
func _rig_gantry(frame: StaticBody3D, mat: StandardMaterial3D, frame_width: float,
		frame_height: float, frame_thickness: float) -> void:
	# Top bar
	_bar(frame, Vector3(0, frame_height/2.0, 0),
		Vector3(frame_width + 0.4, 0.2, frame_thickness), mat, true)

	# Side bars
	for x: float in [-frame_width/2.0 - 0.1, frame_width/2.0 + 0.1]:
		_bar(frame, Vector3(x, 0, 0),
			Vector3(0.2, frame_height, frame_thickness), mat, true)

## WALL — held from behind. A ribbed plane the straps hang in FRONT of, with a head
## rail carrying them and a plinth where it meets the floor. The bottom is closed, so
## this is the one value you cannot walk through.
func _rig_wall(frame: StaticBody3D, mat: StandardMaterial3D, frame_width: float,
		frame_height: float, frame_thickness: float) -> void:
	var w: float = frame_width + 0.9
	var back_z: float = -frame_thickness * 0.5 - 0.12

	# The plane itself, floor to head height.
	_bar(frame, Vector3(0, 0, back_z), Vector3(w, frame_height, 0.24), mat, true)
	# Ribs proud of the face, so the plane reads as built rather than as a backdrop.
	for i in range(5):
		var rx: float = (float(i) / 4.0 - 0.5) * w * 0.9
		_bar(frame, Vector3(rx, 0, back_z + 0.19),
			Vector3(0.16, frame_height - 0.5, 0.14), mat, false)
	# Head rail: what the straps actually hang off, cantilevered clear of the face.
	_bar(frame, Vector3(0, frame_height/2.0 - 0.1, back_z * 0.35),
		Vector3(w, 0.24, frame_thickness * 0.8), mat, true)
	# Plinth.
	_bar(frame, Vector3(0, -frame_height/2.0 + 0.11, back_z * 0.6),
		Vector3(w, 0.22, frame_thickness * 0.9), mat, true)

## HOOP — held from around. A ring overhead on four legs, with a spar across its
## diameter that the rank hangs from. The curtain stops being a boundary and becomes a
## partition standing inside a round room.
func _rig_hoop(frame: StaticBody3D, mat: StandardMaterial3D, frame_width: float,
		frame_height: float, frame_thickness: float) -> void:
	var rad: float = frame_width * 0.5 + 0.35
	var ry: float = frame_height / 2.0          # local y of the ring == world frame_height

	# The ring, as 24 chords.
	var seg: int = 24
	for i in range(seg):
		var a0: float = TAU * float(i) / float(seg)
		var a1: float = TAU * float(i + 1) / float(seg)
		_rod(frame, Vector3(cos(a0) * rad, ry, sin(a0) * rad),
			Vector3(cos(a1) * rad, ry, sin(a1) * rad), 0.09, mat)

	# The diameter spar the straps hang from — the only part in the cloth's plane.
	_bar(frame, Vector3(0, ry, 0), Vector3(rad * 2.0, 0.18, frame_thickness * 0.4),
		mat, true)

	# Four legs on the diagonals, clear of the rank, with foot pads.
	for i in range(4):
		var a: float = TAU * float(i) / 4.0 + PI * 0.25
		var fx: float = cos(a) * rad
		var fz: float = sin(a) * rad
		_bar(frame, Vector3(fx, 0, fz), Vector3(0.18, frame_height, 0.18), mat, true)
		_bar(frame, Vector3(fx, -frame_height/2.0 + 0.06, fz),
			Vector3(0.55, 0.12, 0.55), mat, false)

## MAST — held from a single point. One column set behind the rank, a head beam
## cantilevered over it, two braces taking the moment. No side posts: the whole load
## path is legible in one look, and the cloth is carried rather than framed.
func _rig_mast(frame: StaticBody3D, mat: StandardMaterial3D, frame_width: float,
		frame_height: float, frame_thickness: float) -> void:
	var mz: float = -frame_thickness * 0.5 - 0.2
	var top_y: float = frame_height / 2.0

	# Column and base plate.
	_bar(frame, Vector3(0, 0.1, mz), Vector3(0.34, frame_height + 0.2, 0.34), mat, true)
	_bar(frame, Vector3(0, -frame_height/2.0 + 0.07, mz),
		Vector3(1.1, 0.14, 1.1), mat, false)
	# Head beam, over the rank.
	_bar(frame, Vector3(0, top_y, 0),
		Vector3(frame_width + 0.4, 0.2, frame_thickness), mat, true)
	# The short link from column head out to the beam, and the two braces.
	_bar(frame, Vector3(0, top_y + 0.16, mz * 0.5),
		Vector3(0.3, 0.16, absf(mz) + 0.34), mat, false)
	for sx: float in [-1.0, 1.0]:
		_rod(frame, Vector3(0, top_y - 0.95, mz),
			Vector3(sx * (frame_width * 0.5 - 0.1), top_y - 0.12, 0.0), 0.06, mat)

## A box with an optional collision twin, in the shipped order: mesh, then shape.
func _bar(frame: StaticBody3D, pos: Vector3, size: Vector3, mat: StandardMaterial3D,
		solid: bool) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	frame.add_child(mi)
	if not solid:
		return
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	col.shape = bs
	col.position = pos
	frame.add_child(col)

## A rod from a to b. CylinderMesh runs along its own Y, so the basis is built with Y
## on the chord. Visual only — an overhead ring nobody can reach needs no collider.
func _rod(frame: StaticBody3D, a: Vector3, b: Vector3, thick: float,
		mat: StandardMaterial3D) -> void:
	var d: Vector3 = b - a
	var length: float = d.length()
	if length < 0.0001:
		return
	var cyl := CylinderMesh.new()
	cyl.top_radius = thick
	cyl.bottom_radius = thick
	cyl.height = length
	cyl.radial_segments = 8
	cyl.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.material_override = mat
	frame.add_child(mi)
	mi.position = (a + b) * 0.5
	var up: Vector3 = d.normalized()
	var ref: Vector3 = Vector3.RIGHT if absf(up.x) < 0.9 else Vector3.FORWARD
	var xa: Vector3 = ref.cross(up).normalized()
	var za: Vector3 = xa.cross(up).normalized()
	mi.basis = Basis(xa, up, za)

func setup_straps() -> void:
	var template = $SoftBodyStrip
	if not template:
		print("SoftBodyStrip template not found!")
		return

	# Hide the template, we will use duplicates
	template.visible = false
	# Disable physics for template so it doesn't fall
	template.process_mode = Node.PROCESS_MODE_DISABLED

	# Load Foil Shader
	var foil_shader = load("res://commons/resourses/shaders/foil_paper.gdshader")
	var foil_mat = ShaderMaterial.new()
	foil_mat.shader = foil_shader

	var total_width = (strap_width - strap_overlap) * strap_count
	var start_x = -total_width / 2.0 + strap_width / 2.0

	for i in range(strap_count):
		var x = start_x + i * (strap_width - strap_overlap)

		var new_strap = template.duplicate()
		new_strap.visible = true
		new_strap.process_mode = Node.PROCESS_MODE_INHERIT
		# Keep Y and Z from template, only change X
		new_strap.position.x = x

		# Apply Foil Shader
		new_strap.material_override = foil_mat

		# Enable collision with player (Layer 20) and environment (Layer 1)
		# Layer 20 is bit 19 (1 << 19 = 524288)
		new_strap.collision_layer = 1
		new_strap.collision_mask = 1 | 524288

		add_child(new_strap)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		# Throw a ball to test interaction
		var ball = RigidBody3D.new()
		var mesh = SphereMesh.new()
		mesh.radius = 0.3
		mesh.height = 0.6
		var mi = MeshInstance3D.new()
		mi.mesh = mesh
		ball.add_child(mi)
		var col = CollisionShape3D.new()
		col.shape = SphereShape3D.new()
		(col.shape as SphereShape3D).radius = 0.3
		ball.add_child(col)

		ball.position = Vector3(0, 1.5, 4)
		ball.mass = 5.0
		add_child(ball)
		ball.apply_central_impulse(Vector3(0, 0, -20))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## GUARDED ON PURPOSE. An unconditional rebuild here would tear the rig out from under
## every shipped placement the moment any config key arrived — including keys this
## artifact does not own. So: an unknown or absent value returns before anything is
## touched, an unchanged value returns too, and the straps are never rebuilt at all.
func apply_grid_config(config: Dictionary) -> void:
	var want: String = suspension
	if config.has("suspension"):
		var raw: String = str(config["suspension"]).strip_edges().to_lower()
		# A typo must never publish a silent variant.
		if SUSPENSIONS.has(raw):
			want = raw
	if want == suspension:
		return
	suspension = want
	if not _built:
		# _ready() has not run yet; it will build with the new value on its own.
		return
	setup_frame()
