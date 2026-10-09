# @identity
# essence: a bench of identical dark knobs under a hood, three of which are apples, and a rack of oranges a visitor throws at them — a strike pins WHERE the apple was and shoves it somewhere else in the same instant, while a constant-area rectangle on the panel above trades its width for its height
# desire: that finding a thing should cost something, visibly, on a gauge, in the same second the finding happens — so that measurement stops being a free look and becomes a transaction with a price the visitor can read off the wall
# critical_parameter: hood_mode — hood / open / deep. `open` is the artifact's own control condition: take the roof away and the apples are simply visible, nothing needs throwing, and the whole argument evaporates. The instrument only says anything while what it measures is out of sight
# triggers: a thrown orange's body_entered on an apple. IMPACT SPEED sets everything at once — a fast orange resolves the position sharply (a hairline pin, a narrow rectangle) and shoves hard; a slow one barely resolves and barely disturbs. That coupling is Heisenberg's 1927 argument, not decoration on it
# emerges: one lit pin per apple, standing where that apple was when it was last measured and describing nothing presently there, because the act that pinned it also moved it. Three pins, not a growing bed — _pin replaces its own apple's mark, and a pincushion of every past reading would be a tray you can no longer see into
# needs: physics [RigidBody3D apples on layer 1, oranges on layer 3]; the desktop hand's carry-grab and its LMB trigger [present — DesktopInteractionPointer]; XRToolsPickable for the VR hand [present]. A lit room is NOT needed: the concealment here is geometry, never shadow, because hall lighting varies across the museum and an argument that depends on it fails in half the building
# relationships: kin to two_point_ruler, the same room's other observer-effect piece, and it makes the OPPOSITE claim — there the subject stays honest under measurement and the disturbance lands on a bystander you have to look away to catch. Here the disturbance lands on the thing measured, which is Heisenberg's case and not Schrödinger's cat's. Wears the near-black dark_sphere worked out (metallic 0, F0 restored, a clearcoat, a backlight under the albedo) so the corpus has one dark body and not two. Takes nothing from pink_gun but the fact that a thrown thing in this tree already knows how to report what it hit
# truth: you can have where it is, or you can have where it is going, and the reason is not that our instruments are crude. It is that looking is done WITH something, and the something arrives. The bench sells position at the price of momentum and prints the receipt on the wall above; the rectangle's area never changes, and that is the part nobody gets to negotiate.

extends Node3D
class_name OrangeAndApples

## THE SOURCE, and it is Heisenberg's own, from the 1927 paper: you cannot see an
## electron because it is smaller than visible light, so you strike it with a
## gamma ray — and the strike moves it. The retelling this artifact was built
## from puts it as apples and an orange: "a human observer determining the
## location of the three apples by throwing an orange at them; in marking the
## electron's position, the gamma ray changes its momentum."
##
## The analogy is usually told and then dropped. Built, it turns out to have two
## teeth the telling hides, and both are in the geometry here:
##
##   1. THE ORANGE IS BIGGER THAN THE APPLE. ORANGE_R 0.052 against KNOB_R
##      0.045. That is not a joke about fruit — it is the whole reason the
##      disturbance cannot be made small. A probe you can aim is a probe of
##      comparable size to its target, and the analogy is only honest if the
##      thrown thing is not a pea.
##   2. THROW HARDER AND YOU SEE BETTER AND DISTURB MORE, in one motion, from
##      one number. Impact speed sets the pin's thickness, the rectangle's
##      width and the kick's size together (see _strike). Shorter wavelength,
##      finer resolution, larger momentum transfer. There is no setting where
##      you get the first two without the third.
##
## WHY THE APPLES HIDE IN A CROWD RATHER THAN IN THE DARK. The first design put
## three apples in an unlit box. Two problems, and the second is the one that
## settles it: an unlit box photographs as a black rectangle, so the still that
## is this artifact's only evidence would have shown nothing at all; and hall
## lighting in this museum is not a constant — fetish_portal's own note records
## an artifact losing its argument in a room that lit it wrong. So concealment
## is done with GEOMETRY and REPETITION instead: a bed of identical dark knobs
## with three apples among them, under a roof that cuts the sight line to the
## back rows. In a still you can see exactly what the problem is — which of
## these is an apple? — which is the thing an unlit box could not say.

const PbrKit = preload("res://commons/render/pbr_kit.gd")
const TextScreenScript = preload("res://commons/ui/text_screen.gd")
## THE ORANGE IS A PICKABLE, and this is the one in-tree scene rather than a
## hand-rolled RigidBody3D. A bare RigidBody3D would have been grabbable on
## desktop and INVISIBLE TO VR: function_pickup.gd:294 rejects anything without
## a pick_up() method before it ever reaches the grab list, so a plain body can
## never be lifted in the headset. two_point_rule.tscn instances this same scene
## for the same reason.
const PICKABLE := preload("res://addons/godot-xr-tools/objects/pickable.tscn")

# ── THE KNOBS ────────────────────────────────────────────────────────────────
## Three, because the source says three apples. Deliberately NOT a config key:
## a numeric #apples:3 is not in GridInteractablesComponent.CONFIG_PARAM_NAMES
## and would be read as `tutorial_id:rotation` by the shorthand branch — the
## artifact would keep its default and the map token would look correct. The
## six walker params in that list were added after exactly that bug.
const APPLE_COUNT := 3
const KNOB_R := 0.045
const ORANGE_R := 0.052          # bigger than the apple. See the header.

# ── THE BENCH (all figures in the bench's own frame; y = 0 is the floor) ──────
const PLINTH := Vector3(1.20, 0.72, 0.46)
const SLAB := Vector3(1.40, 0.06, 0.58)
const SLAB_TOP := 0.78
const PANEL := Vector3(1.40, 1.12, 0.06)
const PANEL_Z := -0.26           # sits on the slab's back edge
const PANEL_FACE := -0.23        # its front face
const TRAY := Vector3(1.06, 0.02, 0.42)
const TRAY_TOP := 0.80
const TRAY_Z := 0.02
const RIM_H := 0.10
const RIM_T := 0.025

# ── THE READOUT ──────────────────────────────────────────────────────────────
## THE UNCERTAINTY RECTANGLE. Width is the spread on position, height the spread
## on momentum, and WIDTH x HEIGHT IS A CONSTANT — squeeze one and the other has
## to grow. A pair of separate dials would have been the obvious build and would
## have shown two numbers moving in opposite directions, which a visitor has to
## be told to read as a law. One rectangle of fixed area shows the law as a
## shape, and it is the only form of the relation that survives a still.
const AREA := 0.0072             # m^2 on the plate. dx * dp, and it never moves.
const DX_WIDE := 0.34            # position unknown — the resting state
const DX_SHARP := 0.045          # position just bought at full price
const PLATE := Vector3(1.32, 0.54, 0.014)
const PLATE_Y := 1.55
const RAIL_Y := 1.325
## Derived off the panel's own face rather than typed: 8 mm of plate then 10 mm
## of mark. Two transcribed z values here would drift the day the panel moves.
const RAIL_Z := PANEL_FACE + 0.018
const RAIL_HALF := 0.56
const SCALE_Y := 1.56
const BAR_T := 0.006
const GBAR_T := 0.005
## The same rectangle at four widths spanning exactly the live figure's range,
## drawn dim and fixed as a printed scale. So the row above and the figure below
## are not two ideas: the ghosts are what the live one is going to become.
const GHOSTS := [
	Vector2(DX_WIDE, -0.45),
	Vector2(0.19, -0.06),
	Vector2(0.10, 0.22),
	Vector2(DX_SHARP, 0.45),
]

# ── THE THROW ────────────────────────────────────────────────────────────────
## Press begins the charge, release throws. A click that is over in one frame
## still throws, at THROW_MIN — nothing is gated behind knowing about the hold.
const CHARGE_S := 1.10
const THROW_MIN := 4.2
const THROW_MAX := 9.4
const THROW_LIFT := 0.10         # a flat throw sails over the tray rim
## Below this an impact is a jostle on the shelf, not a measurement.
const HIT_MIN_SPEED := 1.2
const SPEED_SOFT := 2.0
const SPEED_HARD := 8.0
const KICK_MIN := 0.06           # N s, on a 0.16 kg apple
const KICK_MAX := 0.30
const STRIKE_COOLDOWN_MS := 180

## OPEN takes the roof away and is the control condition — see critical_parameter.
@export_enum("hood", "open", "deep") var hood_mode: String = "hood"
## How many knobs the three apples hide among. Two of the bed's dimensions,
## because "hard to find" is a fact about the size of the crowd, and a map that
## wants an easier or a hopeless version should be able to say which.
@export_range(2, 9) var bed_cols: int = 6
@export_range(1, 4) var bed_rows: int = 3
## Oranges on the rack. The rack is sized from this, so a bigger magazine is a
## longer shelf and never two oranges spawned inside each other.
@export_range(1, 8) var orange_count: int = 4

## ONE container for everything this build makes, so a rebuild frees exactly its
## own work with one queue_free. The first version tracked parts in a list and
## parented the rack straight to self; apply_grid_config then left a second rack
## standing inside the first, which is invisible in the editor and obvious in a
## still.
var _root: Node3D
var _bench: Node3D
var _live: Node3D                       # the live rectangle + needle, redrawn per strike
var _screen: Node3D
var _apples: Array[RigidBody3D] = []
var _decoys: Array[StaticBody3D] = []
var _oranges: Array[RigidBody3D] = []
var _orange_home: Array[Vector3] = []
var _slots: Array[Vector3] = []         # bench-frame rest positions, one per apple
var _pins: Dictionary = {}              # apple index -> pin node
var _speed: Dictionary = {}             # orange -> its speed at the top of this physics frame
var _last_strike_ms: Dictionary = {}    # apple index -> when
var _charging: Node = null
var _charge_t: float = 0.0
var _pos: float = 0.0                   # last reading, -1..1 across the tray
var _dx: float = DX_WIDE                # spread on that reading, plate metres
var _strikes: int = 0

var _m_stone: StandardMaterial3D
var _m_dark: StandardMaterial3D
var _m_fruit: StandardMaterial3D
var _m_orange: StandardMaterial3D
var _m_dim: StandardMaterial3D
var _m_lit: StandardMaterial3D
var _m_plate: StandardMaterial3D
var _knob_mesh: SphereMesh
var _orange_mesh: SphereMesh


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	# Every key here is either word-valued (mode) or already in
	# GridInteractablesComponent.CONFIG_PARAM_NAMES (rows, cols, count), so none
	# of them can be eaten by the tutorial's `#key:number` shorthand. str() and
	# not String(): String() on a JSON cell throws.
	if config_data.has("mode"):
		var m := str(config_data["mode"]).strip_edges().to_lower()
		if m in ["hood", "open", "deep"]:
			hood_mode = m
	if config_data.has("cols"):
		bed_cols = clampi(_as_int(config_data["cols"], bed_cols), 2, 9)
	if config_data.has("rows"):
		bed_rows = clampi(_as_int(config_data["rows"], bed_rows), 1, 4)
	if config_data.has("count"):
		orange_count = clampi(_as_int(config_data["count"], orange_count), 1, 8)
	if is_inside_tree():
		_build()


func _as_int(v: Variant, fallback: int) -> int:
	match typeof(v):
		TYPE_INT, TYPE_FLOAT:
			return int(v)
		TYPE_STRING, TYPE_STRING_NAME:
			var s := str(v).strip_edges()
			if s.is_valid_int():
				return int(s)
			if s.is_valid_float():
				return int(float(s))
	return fallback


# ══ BUILD ════════════════════════════════════════════════════════════════════

func _build() -> void:
	# Free the previous build and drop every reference in the same breath. A
	# queued node is still a child for the rest of the frame, so anything that
	# read get_children() after this would see the old bench merged with the new
	# one — pink_gun's collider was fitted to exactly that.
	if _root != null and is_instance_valid(_root):
		_root.queue_free()
	_apples.clear()
	_decoys.clear()
	_oranges.clear()
	_orange_home.clear()
	_slots.clear()
	_pins.clear()
	_speed.clear()
	_last_strike_ms.clear()
	_charging = null
	_live = null
	_screen = null
	_pos = 0.0
	_dx = DX_WIDE
	_strikes = 0

	_materials()

	_root = Node3D.new()
	_root.name = "Build"
	add_child(_root)

	_bench = Node3D.new()
	_bench.name = "Bench"
	_bench.position = Vector3(_bench_x(), 0.0, 0.0)
	_root.add_child(_bench)

	_build_bench()
	_build_hood()
	_build_bed()
	_build_readout()
	_build_caption()
	_build_rack()
	_draw_live()


func _materials() -> void:
	_m_stone = PbrKit.concrete(Color(0.44, 0.43, 0.41), 0.28)
	_m_dark = PbrKit.painted_metal(Color(0.125, 0.125, 0.140), 0.12, 0.25, 0.44)
	# THE KNOB SKIN, and every knob wears this ONE instance — a decoy and an
	# apple that differ by a shade are not a crowd, they are a puzzle with the
	# answer painted on. Near-black, never black: dark_sphere's recipe, repeated
	# rather than re-derived. metallic 0 with F0 left at the dielectric 0.5, so
	# the limb keeps its Fresnel; a clearcoat for the second lobe, which is most
	# of what makes a sphere read as a sphere; and a backlight UNDER the albedo
	# to lift the terminator by a shade. Without the last two a dark ball is not
	# a darker object, it is a hole in the tray.
	_m_fruit = PbrKit.hard_plastic(Color(0.078, 0.033, 0.040), 0.66, 0.05)
	_m_fruit.backlight_enabled = true
	_m_fruit.backlight = Color(0.085, 0.028, 0.034)
	_m_orange = PbrKit.hard_plastic(Color(0.94, 0.40, 0.05), 0.48, 0.10)
	_m_dim = PbrKit.painted_metal(Color(0.34, 0.35, 0.37), 0.10, 0.30, 0.50)
	_m_lit = PbrKit.emissive(Color(0.60, 0.90, 1.0), 2.4)
	_m_plate = PbrKit.screen(Color(0.055, 0.065, 0.085), 0.28)

	_knob_mesh = SphereMesh.new()
	_knob_mesh.radius = KNOB_R
	_knob_mesh.height = KNOB_R * 2.0
	_knob_mesh.radial_segments = 22
	_knob_mesh.rings = 12
	_orange_mesh = SphereMesh.new()
	_orange_mesh.radius = ORANGE_R
	_orange_mesh.height = ORANGE_R * 2.0
	_orange_mesh.radial_segments = 22
	_orange_mesh.rings = 12


## THE ASSEMBLY STRADDLES THE ORIGIN, so a map token puts the thing's middle
## where the token is rather than its left-hand end. Derived, not eyeballed: the
## build runs from bench_x - SLAB.x/2 to rack_x + shelf/2, and rack_x is
## bench_x + SLAB.x/2 + 0.10 + shelf/2, so the midpoint is
## bench_x + (0.10 + shelf)/2 and this is what sets it to zero. The first
## version was typed by eye and put the origin 20 cm off, which nothing
## complains about and every placement inherits.
func _bench_x() -> float:
	return -0.05 - _shelf_w() * 0.5


func _rack_x() -> float:
	return _bench_x() + SLAB.x * 0.5 + 0.10 + _shelf_w() * 0.5


func _shelf_w() -> float:
	return orange_count * (ORANGE_R * 2.0 + 0.024) + 0.06


func _build_bench() -> void:
	_solid(_bench, Vector3(0, PLINTH.y * 0.5, 0), PLINTH, _m_stone)
	_solid(_bench, Vector3(0, SLAB_TOP - SLAB.y * 0.5, 0), SLAB, _m_stone)
	_solid(_bench, Vector3(0, SLAB_TOP + PANEL.y * 0.5, PANEL_Z), PANEL, _m_stone)

	# the tray: a floor and four rims. The rims are 10 cm, which is above the
	# knobs' equator and below their crowns, so from a standing eye they clip
	# the front row without hiding it — and they keep a kicked apple in the box.
	_solid(_bench, Vector3(0, TRAY_TOP - TRAY.y * 0.5, TRAY_Z), TRAY, _m_dark)
	var hy := TRAY_TOP + RIM_H * 0.5
	var hx := TRAY.x * 0.5 + RIM_T * 0.5
	var hz := TRAY.z * 0.5 + RIM_T * 0.5
	_solid(_bench, Vector3(0, hy, TRAY_Z - hz), Vector3(TRAY.x + RIM_T * 2.0, RIM_H, RIM_T), _m_dark)
	_solid(_bench, Vector3(0, hy, TRAY_Z + hz), Vector3(TRAY.x + RIM_T * 2.0, RIM_H, RIM_T), _m_dark)
	_solid(_bench, Vector3(-hx, hy, TRAY_Z), Vector3(RIM_T, RIM_H, TRAY.z + RIM_T * 2.0), _m_dark)
	_solid(_bench, Vector3(hx, hy, TRAY_Z), Vector3(RIM_T, RIM_H, TRAY.z + RIM_T * 2.0), _m_dark)


## THE ROOF IS THE CONCEALMENT AND IT IS NOT A LIGHTING TRICK. It cuts the sight
## line into the back of the tray from any standing height; the crowd of decoys
## does the rest. `deep` reaches 16 cm further forward and drops 6 cm — it hides
## more without narrowing the aperture, which is the version that stays
## throwable. Lowering the roof instead was the first attempt and it made the
## slot 9 cm tall, which a 10.4 cm orange cannot enter.
func _build_hood() -> void:
	if hood_mode == "open":
		return
	var roof_y := 1.20
	var roof_d := 0.50
	var roof_z := -0.01
	var cheek_h := 0.30
	if hood_mode == "deep":
		roof_y = 1.14
		roof_d = 0.66
		roof_z = 0.07
		cheek_h = 0.24
	_solid(_bench, Vector3(0, roof_y, roof_z), Vector3(1.24, 0.04, roof_d), _m_dark)
	var cy := roof_y - 0.02 - cheek_h * 0.5
	for s: float in [-1.0, 1.0]:
		_solid(_bench, Vector3(s * 0.6025, cy, roof_z), Vector3(0.035, cheek_h, roof_d), _m_dark)


## THE BED. Every knob is the same mesh with the same material instance; three
## of them are RigidBody3D and the rest are static, and that is the ONLY
## difference. Which three is drawn from a fixed seed, so the artifact builds the
## same way in every capture and every hall — the randomness in this piece lives
## entirely in the kick (see _strike), where being unpredictable is the argument
## rather than a hazard to a still.
func _build_bed() -> void:
	var cols := maxi(2, bed_cols)
	var rows := maxi(1, bed_rows)
	var half_x := TRAY.x * 0.5 - KNOB_R - 0.012
	var half_z := TRAY.z * 0.5 - KNOB_R - 0.012
	var cells: Array[Vector3] = []
	for r in range(rows):
		var fz: float = 0.5 if rows == 1 else float(r) / float(rows - 1)
		for c in range(cols):
			var fx: float = 0.5 if cols == 1 else float(c) / float(cols - 1)
			cells.append(Vector3(
				lerpf(-half_x, half_x, fx),
				TRAY_TOP + KNOB_R,
				TRAY_Z + lerpf(-half_z, half_z, fz)))

	var rng := RandomNumberGenerator.new()
	rng.seed = 1927                     # the year of the paper
	var order: Array[int] = []
	for k in range(cells.size()):
		order.append(k)
	# Fisher-Yates on a seeded rng: rng.randi_range is the only draw in the build
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: int = order[i]
		order[i] = order[j]
		order[j] = t

	# at least one decoy, whatever the grid — a bed of nothing but apples is a
	# bowl of fruit and there is nothing to be uncertain about
	var n_apples: int = mini(APPLE_COUNT, maxi(1, cells.size() - 1))
	for k in range(cells.size()):
		var at: Vector3 = cells[order[k]]
		if k < n_apples:
			_apples.append(_apple(at))
			_slots.append(at)
		else:
			_decoys.append(_decoy(at))


func _apple(at: Vector3) -> RigidBody3D:
	var b := RigidBody3D.new()
	b.name = "Apple%d" % _apples.size()
	b.position = at
	b.mass = 0.16
	# layer 1 so the orange (pickable mask 196615, which covers layer 1) finds
	# it; mask 1|4 so it rests on the tray and answers an orange. NOT layer 3:
	# an apple on the grab layer could be lifted out and read with the hand,
	# which is the one thing this bench must not allow.
	b.collision_layer = 1
	b.collision_mask = 1 | 4
	b.linear_damp = 0.9
	b.angular_damp = 1.6
	b.continuous_cd = true              # a fast orange must not tunnel through a 9 cm ball
	var cs := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = KNOB_R                  # the shape IS the ball, to the millimetre
	cs.shape = sp
	b.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.mesh = _knob_mesh
	mi.material_override = _m_fruit
	b.add_child(mi)
	_bench.add_child(b)
	return b


func _decoy(at: Vector3) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.name = "Knob%d" % _decoys.size()
	b.position = at
	b.collision_layer = 1
	b.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = KNOB_R
	cs.shape = sp
	b.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.mesh = _knob_mesh
	mi.material_override = _m_fruit
	b.add_child(mi)
	_bench.add_child(b)
	return b


func _build_rack() -> void:
	var w := _shelf_w()
	var rx := _rack_x()
	var top := 0.89
	for s: float in [-1.0, 1.0]:
		_solid(_root, Vector3(rx + s * (w * 0.5 - 0.06), 0.43, 0.0), Vector3(0.06, 0.86, 0.06), _m_stone)
	_solid(_root, Vector3(rx, top - 0.015, 0.0), Vector3(w, 0.03, 0.24), _m_stone)
	# a rim, or the first knock rolls the magazine onto the floor
	_solid(_root, Vector3(rx, top + 0.018, -0.126), Vector3(w, 0.035, 0.012), _m_dark)
	_solid(_root, Vector3(rx, top + 0.018, 0.126), Vector3(w, 0.035, 0.012), _m_dark)
	for s: float in [-1.0, 1.0]:
		_solid(_root, Vector3(rx + s * (w * 0.5 - 0.006), top + 0.018, 0.0), Vector3(0.012, 0.035, 0.264), _m_dark)

	var span := w * 0.5 - ORANGE_R - 0.02
	for i in range(orange_count):
		var f: float = 0.5 if orange_count == 1 else float(i) / float(orange_count - 1)
		_orange(Vector3(rx + lerpf(-span, span, f), top + ORANGE_R, 0.0))


func _orange(at: Vector3) -> void:
	var o: RigidBody3D = PICKABLE.instantiate()
	o.name = "Orange%d" % _oranges.size()
	o.position = at
	o.mass = 0.22
	# The pickable ships collision_layer 4 (layer 3) and mask 196615, which is
	# exactly what both hands look for — DesktopInteractionPointer.GRAB_MASK is
	# 393220, layers 3/18/19. Left alone on purpose.
	o.contact_monitor = true
	o.max_contacts_reported = 6
	o.continuous_cd = true
	var cs: CollisionShape3D = o.get_node_or_null("CollisionShape3D")
	if cs != null:
		var sp := SphereShape3D.new()
		sp.radius = ORANGE_R            # the collider is the fruit, not a stand-in
		cs.shape = sp
	var mi := MeshInstance3D.new()
	mi.mesh = _orange_mesh
	mi.material_override = _m_orange
	o.add_child(mi)
	_root.add_child(o)
	_oranges.append(o)
	_orange_home.append(at)
	o.body_entered.connect(_on_orange_touched.bind(o))
	# CONNECTED HERE, BEFORE ANY CLICK, and that is load-bearing rather than
	# tidy: DesktopInteractionPointer._fires refuses to call action() at all
	# unless action_pressed ALREADY has a listener, so a lazy connect on first
	# grab would leave the entire desktop lane dead with nothing to see.
	o.action_pressed.connect(_on_orange_action)
	o.action_released.connect(_on_orange_release)


# ══ THE READOUT ══════════════════════════════════════════════════════════════

func _build_readout() -> void:
	# THE PLATE GETS A COLLIDER AND THE MARKS DO NOT. Backing this with the panel
	# alone would have left the bars standing 22 mm in front of the nearest
	# surface an orange can hit, so a wild throw would pass visibly through the
	# gauge before bouncing. With the plate solid the gap is 7 mm, which is under
	# the fruit's own radius and never seen.
	_solid(_bench, Vector3(0, PLATE_Y, PANEL_FACE + PLATE.z * 0.5), PLATE, _m_plate)
	# the position axis, and it is the BENCH'S axis: a needle at x = -0.3 on this
	# rail stands over the part of the tray the apple was in. A gauge whose
	# abscissa is not the object's own is a gauge you have to be taught to read.
	_flat(_bench, Vector3(0, RAIL_Y, RAIL_Z), Vector3(RAIL_HALF * 2.0, 0.008, 0.008), _m_dim)
	_flat(_bench, Vector3(0, SCALE_Y - 0.004, RAIL_Z), Vector3(RAIL_HALF * 2.0, 0.004, 0.006), _m_dim)
	for g in GHOSTS:
		var gw: float = g.x
		_outline(_bench, g.y, SCALE_Y, gw, AREA / gw, GBAR_T, _m_dim)


## The live figure. Rebuilt rather than nudged: five boxes is cheaper to make
## again than to keep consistent, and a strike happens at most a few times a
## minute.
func _draw_live() -> void:
	if _live != null and is_instance_valid(_live):
		_live.queue_free()
	_live = Node3D.new()
	_live.name = "Reading"
	_bench.add_child(_live)

	var h := AREA / maxf(_dx, 0.004)
	# The rectangle can only stray far from centre when it is NARROW, because
	# an eccentric reading is a sharp one — so it can never overhang the rail.
	# That falls out of the physics rather than being clamped into it.
	var cx: float = _pos * maxf(0.0, RAIL_HALF - _dx * 0.5)
	_outline(_live, cx, RAIL_Y + 0.004, _dx, h, BAR_T, _m_lit)
	# THE NEEDLE HANGS BELOW THE RAIL. Above it, it stands inside the rectangle
	# and at the resting width — a 34 x 2 cm letterbox — the pointer and the
	# figure's top bar are the same three millimetres of plate. One reading, two
	# marks, and they must not be drawn on top of each other.
	var needle: StandardMaterial3D = _m_lit if _strikes > 0 else _m_dim
	_flat(_live, Vector3(cx, RAIL_Y - 0.024, RAIL_Z + 0.002), Vector3(0.006, 0.036, 0.008), needle)


## An outline, four bars, drawn on the plate. Not a filled rectangle: a solid
## panel of emissive at DX_WIDE is a 34 x 2 cm bar of light that reads as a
## strip lamp, and the eye stops measuring it.
func _outline(parent: Node3D, cx: float, base_y: float, w: float, h: float,
		t: float, mat: Material) -> void:
	_flat(parent, Vector3(cx, base_y + t * 0.5, RAIL_Z), Vector3(w, t, 0.007), mat)
	_flat(parent, Vector3(cx, base_y + h - t * 0.5, RAIL_Z), Vector3(w, t, 0.007), mat)
	_flat(parent, Vector3(cx - w * 0.5 + t * 0.5, base_y + h * 0.5, RAIL_Z), Vector3(t, h, 0.007), mat)
	_flat(parent, Vector3(cx + w * 0.5 - t * 0.5, base_y + h * 0.5, RAIL_Z), Vector3(t, h, 0.007), mat)


func _build_caption() -> void:
	_screen = TextScreenScript.new()
	_screen.mode = 0                    # SCREEN — a framed plate, no stand
	_screen.width_m = 0.60
	_screen.title = "OBSERVATION"
	_screen.body = _caption_text()
	_screen.position = Vector3(0.0, 0.44, PLINTH.z * 0.5 + 0.012)
	_bench.add_child(_screen)


## The two percentages are the SAME NUMBER and that is not a copy-paste: it is
## the rectangle written out in words. What you gained on position is what you
## lost on momentum, because the area is fixed. Anyone reading it twice and
## thinking it a bug has read the artifact correctly.
func _caption_text() -> String:
	if _strikes == 0:
		return "three of these are apples.\nthrow an orange to find one.\nwhat you hit, you move."
	var side := "left" if _pos < -0.08 else ("right" if _pos > 0.08 else "middle")
	var pct := roundi(clampf(inverse_lerp(DX_WIDE, DX_SHARP, _dx), 0.0, 1.0) * 100.0)
	return "pinned %s, %d%% certain\nmomentum lost, the same %d%%\nlanded: %d" % [
		side, pct, pct, _strikes]


# ══ THROWING ═════════════════════════════════════════════════════════════════

## The trigger, in both lanes at once: in VR function_pickup calls action() on
## the held body, on desktop DesktopInteractionPointer calls the same method on
## LMB, and both end on pickable.gd emitting this. One connect serves both.
func _on_orange_action(p: Variant) -> void:
	var o := p as RigidBody3D
	if o != null and _oranges.has(o):
		_charging = o
		_charge_t = 0.0


func _on_orange_release(p: Variant) -> void:
	if _charging != null and p == _charging:
		_launch(_charging as RigidBody3D)


## THROWN, NOT DROPPED, and the release has to come first.
##
## DesktopInteractionPointer carries a non-weapon by WRITING its global_transform
## every frame — a lerp of 0.4 toward a point in front of the camera. An orange
## that launched itself while the hand still held it would be dragged straight
## back within three frames and the throw would look broken rather than absent.
## So the hand must let go, and _drop_held is the only release path in that
## file: there is no public drop(). It restores freeze, layer and mask and
## ZEROES the velocity, which is why the velocity is written after it and not
## before.
func _launch(p: RigidBody3D) -> void:
	_charging = null
	if p == null or not is_instance_valid(p):
		return
	var t: float = clampf(_charge_t / CHARGE_S, 0.0, 1.0)
	var speed: float = lerpf(THROW_MIN, THROW_MAX, t)

	var hand := _hand_holding(p)
	if hand != null:
		hand.call("_drop_held")
	elif p.has_method("is_picked_up") and p.call("is_picked_up"):
		p.call("drop")                  # VR: the pickable's own public release

	# ALONG THE LINE OF SIGHT THROUGH THE FRUIT, not along the camera's -Z. On
	# desktop the two agree, because the carried object floats on the crosshair.
	# In VR they do not: the orange is in your hand, off to one side, and a
	# throw that leaves your hand travelling parallel to your gaze goes wide by
	# the width of your shoulders. Eye-through-hand is what pointing is.
	var dir := Vector3.ZERO
	var cam: Camera3D = null
	if is_inside_tree():
		cam = get_viewport().get_camera_3d()
	if cam != null and is_instance_valid(cam):
		dir = p.global_position - cam.global_position
	if dir.length() < 0.20:
		# no camera, or the fruit is in the lens: aim at the tray
		dir = (_bench.global_transform * Vector3(0.0, TRAY_TOP + 0.05, TRAY_Z)) - p.global_position
	if dir.length() < 0.001:
		dir = -global_transform.basis.z
	dir = (dir.normalized() + Vector3.UP * THROW_LIFT).normalized()

	p.freeze = false
	p.linear_velocity = dir * speed
	p.angular_velocity = Vector3(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
	# Seed the speed ledger here rather than waiting for the next
	# _physics_process. The launch happens in _input, AFTER this frame's physics
	# ran, so a contact resolved in the very next step would be read against a
	# stale 0.0 and thrown away as a jostle. Only reachable at point-blank range,
	# and a rule that holds except at point-blank range is not a rule.
	_speed[p] = speed


## The desktop hand carrying `p`, if one is.
##
## The pointer has no class_name and is in no group, so it is found by SHAPE:
## from the active camera, walk up the tree and check each level's children for
## a node that answers is_holding() and is holding this exact orange. In
## desktop_player.tscn the pointer and the camera are siblings under Head, so it
## is found on the SECOND step. The loop does not stop there, though — it walks
## to the tree root if it has to, which in the museum means also scanning the
## scene root's children. That is the price of surviving a rig that nests the
## pointer deeper than this one does, it is has_method() on a few hundred nodes
## at worst, and it happens once per trigger press rather than per frame.
func _hand_holding(p: Node) -> Node:
	if not is_inside_tree():
		return null
	var n: Node = get_viewport().get_camera_3d()
	while n != null:
		for c in n.get_children():
			if c.has_method("is_holding") and c.has_method("_drop_held") and c.get("_held") == p:
				return c
		n = n.get_parent()
	return null


# ══ THE STRIKE ═══════════════════════════════════════════════════════════════

func _on_orange_touched(body: Node, orange: RigidBody3D) -> void:
	# The speed recorded at the TOP of this physics frame, not the one read now:
	# body_entered is emitted after the step has already resolved the bounce, so
	# orange.linear_velocity here is what the fruit is doing on its way back out.
	var v: float = float(_speed.get(orange, 0.0))
	if v < HIT_MIN_SPEED:
		return                          # a jostle on the shelf is not a measurement
	var hit := body as RigidBody3D      # cast, not a raw find: _apples is typed
	var i := _apples.find(hit) if hit != null else -1
	if i >= 0:
		_strike(i, _apples[i], v)
		return
	var knob := body as StaticBody3D
	if knob == null or not _decoys.has(knob):
		return                          # the tray, a rim, the roof — not a knob
	# A MISS IS NOT NOTHING and it is not a reading either: it says only "not
	# that one". The rectangle is left exactly as it was, because a null result
	# on one knob does not sharpen where the apples are by any amount this gauge
	# can draw.
	if _screen != null and is_instance_valid(_screen):
		var tail := "still looking."
		if _strikes > 0:
			tail = "%d found so far." % _strikes
		var line := "nothing there.\n" + tail
		# ONLY WHEN IT CHANGES. `body` is a setter and it re-bakes the entire
		# screen — fresh text textures, the old subtree queue_freed. An orange
		# skittering across the bed emits body_entered on four or five decoys
		# inside a couple of frames, and every one of them writes the SAME
		# sentence, because a miss does not move the count. Four bakes for one
		# message is a hitch you can see. The strike path is left alone: there
		# the line genuinely differs every time.
		if str(_screen.body) != line:
			_screen.body = line


## POSITION IS BOUGHT WITH MOMENTUM, and the price is set by the same number as
## the goods: the impact speed. A fast orange is a short wavelength — it
## resolves the apple to a hairline pin and a narrow rectangle — and it hits
## harder, so the apple leaves faster and in a direction nobody chose. A gentle
## orange barely tells you anything and barely moves it. There is no throw that
## buys the first without paying the second, which is the entire content of the
## 1927 argument and the reason this is one function and not two.
func _strike(i: int, apple: RigidBody3D, v: float) -> void:
	var now := Time.get_ticks_msec()
	if now - int(_last_strike_ms.get(i, -99999)) < STRIKE_COOLDOWN_MS:
		return                          # one contact, one reading
	_last_strike_ms[i] = now
	_strikes += 1

	var t: float = clampf(inverse_lerp(SPEED_SOFT, SPEED_HARD, v), 0.0, 1.0)
	var was := apple.position           # bench frame, which is the readout's frame
	var half_x: float = maxf(0.05, TRAY.x * 0.5 - KNOB_R - 0.012)
	_pos = clampf(was.x / half_x, -1.0, 1.0)
	_dx = lerpf(DX_WIDE, DX_SHARP, t)

	_pin(i, was, lerpf(0.016, 0.0035, t))

	# THE ONLY UNSEEDED DRAW IN THE FILE, and it is the argument rather than a
	# hazard to the still: the kick is not the visitor's aim. Everything the
	# camera photographs on an untouched bench is deterministic; the moment a
	# visitor buys a position, where the apple goes stops being anyone's to say.
	var a := randf() * TAU
	var kick := Vector3(cos(a), 0.55, sin(a)).normalized() * lerpf(KICK_MIN, KICK_MAX, t)
	apple.apply_central_impulse(kick)

	_draw_live()
	if _screen != null and is_instance_valid(_screen):
		_screen.body = _caption_text()


## The pin marks where the apple WAS. It has no collider, deliberately: a mark
## that obstructs is a second object in the tray and would start deflecting
## later throws, so the record of a measurement would begin altering the
## measurements. It will sometimes stand through an apple that has come to rest
## on the same spot, which looks exactly like a specimen pin and is left alone.
func _pin(i: int, at: Vector3, radius: float) -> void:
	if _pins.has(i) and is_instance_valid(_pins[i]):
		(_pins[i] as Node).queue_free()
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = 0.11
	m.radial_segments = 10
	var mi := MeshInstance3D.new()
	mi.name = "Pin%d" % i
	mi.mesh = m
	mi.material_override = _m_lit
	mi.position = Vector3(at.x, TRAY_TOP + 0.055, at.z)
	_bench.add_child(mi)
	_pins[i] = mi


# ══ PER-FRAME: three small jobs, none of them the argument ════════════════════

func _physics_process(delta: float) -> void:
	if _charging != null:
		if is_instance_valid(_charging):
			_charge_t += delta
			# A LOST RELEASE MUST NOT STRAND THE FRUIT. If action_released never
			# arrives — a click that ends while the hand is being reparented, a
			# rig that only sends presses — the orange would sit charged forever
			# and the artifact would be dead in the visitor's hand. Throw it.
			if _charge_t > CHARGE_S + 0.45:
				_launch(_charging as RigidBody3D)
		else:
			_charging = null

	for i in range(_oranges.size()):
		var o: RigidBody3D = _oranges[i]
		if not is_instance_valid(o):
			continue
		_speed[o] = o.linear_velocity.length()
		# A THROW THAT LEAVES THE MUSEUM COSTS THE ARTIFACT AN ORANGE, and after
		# four of those there is nothing left to measure with. Only for fruit
		# that has fallen out of the world — one that came to rest on the floor
		# is exactly where the visitor put it and stays there to be picked up.
		# `freeze` is the tell for "in a hand": both lanes freeze a carried body
		# (DesktopInteractionPointer._grab_held, pickable.pick_up), and yanking
		# an orange out of someone's grip because they leaned over a balcony
		# would be worse than losing it.
		if o.position.y < -1.2 and not o.freeze and i < _orange_home.size():
			o.linear_velocity = Vector3.ZERO
			o.angular_velocity = Vector3.ZERO
			o.position = _orange_home[i]

	# An apple that leaves the world is an artifact that is permanently one
	# apple short, and nothing on screen would say why. Put it back in its slot.
	for i in range(_apples.size()):
		var a: RigidBody3D = _apples[i]
		if not is_instance_valid(a):
			continue
		if a.position.y < TRAY_TOP - 0.45 or absf(a.position.x) > 1.4 or absf(a.position.z - TRAY_Z) > 1.0:
			a.linear_velocity = Vector3.ZERO
			a.angular_velocity = Vector3.ZERO
			a.position = _slots[i] if i < _slots.size() else Vector3(0, TRAY_TOP + KNOB_R, TRAY_Z)


# ══ PARTS ════════════════════════════════════════════════════════════════════

## A part you can walk into, bump or bounce an orange off. The collider is built
## from the same Vector3 as the mesh — never transcribed — so the two cannot
## drift apart. PbrKit.box chamfers 1.5 to 14 mm off each edge, which is the one
## place the shape is fractionally proud of what is drawn; on a bench edge that
## is under the width of the highlight it puts there.
func _solid(parent: Node3D, center: Vector3, size: Vector3, mat: Material) -> void:
	var mi := PbrKit.box(center, size, mat)
	parent.add_child(mi)
	var body := StaticBody3D.new()
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	parent.add_child(body)


## A mark. No collider, because nothing drawn with this is meant to be touched:
## every readout bar stands 7 mm off the plate, and the plate is solid.
func _flat(parent: Node3D, center: Vector3, size: Vector3, mat: Material) -> void:
	parent.add_child(PbrKit.box(center, size, mat))
