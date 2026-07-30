extends Node3D

# @identity
# essence: f_i = Σ(neighbor_j)[separate(i,j) + align(vel_j) + cohere(pos_j)] — three weighted averages over a local neighborhood
# desire: to reach out a VR hand and feel the flock split and reform around your arm — to be a boulder in a river of agency
# critical_parameter: interaction_radius — at zero, it's a particle cloud; past a threshold, a coherent organism crystallizes from the randomness
# triggers: left trigger attracts boids toward controller; right trigger repels — learner's body becomes a temporary leader with no followers bound by loyalty
# emerges: coordinated lane reversals, vortex rings, and split-rejoin events that no rule specifies — the flock invents maneuvers
# needs: [has] VR controller attract/repel via trigger; [missing] no sliders for separation/alignment/cohesion weights; no on-screen parameter display
# relationships: boids_aquarium wraps the same physics in a compact glass tank with sliders; boid_flocking adds the documentation UI; contrasts with FlowFieldMain (rules vs. field)
# truth: coordination is not agreement — it is geometry; close enough means you are already the same

class_name BoidManager

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — accord
# ═══════════════════════════════════════════════════════════════════
#
# WHICH OF REYNOLDS' THREE RULES THE NEIGHBOURHOOD IS ACTUALLY OBEYING,
# and therefore what standing shape the flock holds. Same word, same
# ladder, same meaning as boids_aquarium — one family, one vocabulary,
# differing only in scale (a 1 m tank there, a 20 m box here).
#
#   school   the shipped loose flock: all three rules at Boid's own
#            defaults (align 1.0 / coh 1.0 / sep 1.5), boids scattered
#            uniformly through the whole 20 x 10 x 20 m spawn box with
#            Boid._ready's own construction of the initial velocity.
#            An irregular room-filling cloud of 0.4 m needles.
#   orb      cohesion wins (coh 4.5 / sep 0.4 / align 0.6). Deposited as
#            a solid 2.0 m-radius ball at box centre with tangential
#            velocities — a 4 m bead hanging in the middle, the outer
#            8 m of the volume completely empty.
#   lane     alignment wins (align 4.5 / coh 0.6 / sep 0.9). Deposited
#            as an 18 x 1.2 x 18 m horizontal slab at mid-height with
#            every velocity +X — fifty-odd needles lying parallel in one
#            1.2 m plane spanning the full width.
#   lattice  separation wins (sep 4.5 / coh 0.0 / align 0.0). Deposited
#            on a regular grid spanning 18 x 6 x 18 m — stacked square
#            ranks with several metres of visible air between every
#            neighbour, filling the box evenly.
#
# NOT A TIME AXIS. Nothing here declares a rate. The axis names the RULE
# the neighbourhood obeys and the STANDING CONFIGURATION that rule holds.
# The three deposited values do carry a low speed cap, but that is the
# mechanism by which a standing shape stands, not the thing declared: the
# capturer's first shot lands about 4 s in and the last about 5.5 s in,
# and at Boid's default 5 m/s floor every deposit would have travelled
# 20+ m and decayed into the same irregular cloud as `school` — three
# twins, one picture, a false declaration. The cap is what keeps the four
# values four. `school` is untouched: it keeps the shipped speeds and the
# shipped drift, because the default must be the pre-promotion look.

## accord — which of Reynolds' three rules the neighbourhood is actually
## obeying, and therefore what standing shape the flock holds.
@export_enum("school", "orb", "lane", "lattice") var accord: String = "school"

## Emission on the boid bodies. `false` is the shipped look (flat magenta
## albedo, no glow) and is what curation_station hands every curated
## artifact. Accepted as a real key: it is applied to each boid's own
## material override, in place, without a rebuild.
@export var emissive: bool = false

const ACCORDS: PackedStringArray = ["school", "orb", "lane", "lattice"]

# ── Deposit geometry (metres) ──────────────────────────────────────
const ORB_RADIUS: float = 2.0            # solid ball at box centre
const ORB_SPEED: float = 0.15            # tangential; holds r over the capture window
const LANE_SPAN: float = 18.0            # X and Z extent of the slab
const LANE_THICKNESS: float = 1.2        # Y extent of the slab
const LANE_SPEED: float = 0.25           # +X, and exactly max_speed so alignment nets zero
const LATTICE_SPAN_XZ: float = 18.0
const LATTICE_SPAN_Y: float = 6.0
const LATTICE_SPEED: float = 0.10        # random heading, near-static

# ── Determinism. Every draw in the build path comes from _rng, which is
# reseeded from one of these constants at the top of each build. The
# global RNG is never touched — seed()/randomize() from inside an
# artifact reseeds the whole process and poisons every other artifact in
# the same run. Two builds of one accord value are identical.
const SEED_SCHOOL: int = 700_101
const SEED_ORB: int = 700_102
const SEED_LANE: int = 700_103
const SEED_LATTICE: int = 700_104

# ── Caption. ONE Label3D, billboard ENABLED so LabelFramer plates it.
# Constant character width at every value so the plate never resizes.
# Sits directly over the flock centre at y = +6.60: the spawn box's top
# face is y = +5.0 and the tallest deposit (lattice) tops out at y = +3.0,
# so the bezel bottom at ~6.36 clears the body by ≥1.36 m and never enters
# the horizontal viewing corridor at any yaw. A single label means no
# stack, no merge. NOT per boid — fifty plated needles would bury the
# flock they describe.
const CAPTION_FORMAT: String = "BOIDS  accord: %-7s"
const CAPTION_Y: float = 6.60
const CAPTION_PIXEL_SIZE: float = 0.005
const CAPTION_FONT_SIZE: int = 70

# Boid prefab to spawn
@export var boid_scene: PackedScene
@export var num_boids = 50

# Spawn area
@export var spawn_area_size = Vector3(20, 10, 20)

# VR related
@export var vr_player_path: NodePath

# Stored reference to VR controller nodes for interaction
@export var left_controller_path: NodePath
@export var right_controller_path: NodePath

# Interaction parameters
@export var interaction_radius = 3.0
@export var attraction_strength = 5.0
@export var repulsion_strength = 8.0

var boids = []
var vr_player = null
var left_controller = null
var right_controller = null

# Controller button states
var left_trigger_pressed = false
var right_trigger_pressed = false

# Only nodes THIS script created. _rebuild_now frees these and nothing
# else — freeing get_children() would destroy the plates, bezels and
# grounding helpers the grid adds around us.
var _spawned: Array[Node] = []
var _caption: Label3D = null
var _built: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	# Get VR references
	if vr_player_path:
		vr_player = get_node_or_null(vr_player_path)

	if left_controller_path:
		left_controller = get_node_or_null(left_controller_path)

	if right_controller_path:
		right_controller = get_node_or_null(right_controller_path)

	_build_all()
	_built = true

	# Connect controller input signals
	_connect_controller_signals()


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

## Synchronous, bounded, and it RETURNS. No await, no call_deferred, no
## unbounded loop, no wait-for-convergence: this artifact is in the named
## headless hang class and a capture that never returns stalls the whole
## pipeline. Worst value costs zero simulation iterations — every accord
## deposits its settled arrangement directly rather than waiting for one
## to emerge.
func _build_all() -> void:
	spawn_boids()
	_build_caption()
	_apply_emissive()


func spawn_boids() -> void:
	if boid_scene == null:
		return
	match accord:
		"orb":
			_spawn_orb()
		"lane":
			_spawn_lane()
		"lattice":
			_spawn_lattice()
		_:
			_spawn_school()


## school — THE SHIPPED FLOCK. Weights and speeds are left at Boid's own
## defaults (never assigned here), positions are uniform through the whole
## spawn box and the initial velocity is built by the same expression
## Boid._ready uses. The only change is the source of the numbers: a
## seeded stream instead of the process RNG, so two builds match. The
## distribution, the box, the weights and the speeds are untouched.
func _spawn_school() -> void:
	_rng.seed = SEED_SCHOOL
	var half: Vector3 = spawn_area_size / 2.0
	for i in range(num_boids):
		var b: Node3D = _make_boid()
		add_child(b)
		_after_add(b)
		b.global_position = Vector3(
			_rng.randf_range(-half.x, half.x),
			_rng.randf_range(-half.y, half.y),
			_rng.randf_range(-half.z, half.z)
		) + self.global_position
		# Boid._ready randomises velocity from the global RNG; rewrite it
		# with the identical construction from the seeded stream.
		var speed: float = _rng.randf_range(_prop(b, "min_speed", 5.0), _prop(b, "max_speed", 10.0))
		_put(b, "velocity", _rand_dir() * speed)
		_register(b)


## orb — cohesion wins. A solid ball of radius 2.0 m at box centre, every
## velocity tangential so the bead turns instead of collapsing.
func _spawn_orb() -> void:
	_rng.seed = SEED_ORB
	var centre: Vector3 = self.global_position
	for i in range(num_boids):
		var b: Node3D = _make_boid()
		_put(b, "alignment_weight", 0.6)
		_put(b, "cohesion_weight", 4.5)
		_put(b, "separation_weight", 0.4)
		_put(b, "min_speed", 0.0)
		_put(b, "max_speed", ORB_SPEED)
		add_child(b)
		_after_add(b)
		var dir: Vector3 = _rand_dir()
		# cube root of a uniform draw fills the ball evenly rather than
		# piling every boid onto the surface.
		var r: float = ORB_RADIUS * pow(_rng.randf(), 1.0 / 3.0)
		b.global_position = centre + dir * r
		var tangent: Vector3 = Vector3.UP.cross(dir)
		if tangent.length() < 0.001:
			tangent = Vector3.RIGHT.cross(dir)
		_put(b, "velocity", tangent.normalized() * ORB_SPEED)
		_register(b)


## lane — alignment wins. A horizontal slab 18 x 1.2 x 18 m at mid-height,
## every velocity +X at exactly max_speed so the alignment term nets to
## zero and the sheet holds its unanimous heading.
func _spawn_lane() -> void:
	_rng.seed = SEED_LANE
	var origin: Vector3 = self.global_position
	var hx: float = LANE_SPAN * 0.5
	var hy: float = LANE_THICKNESS * 0.5
	for i in range(num_boids):
		var b: Node3D = _make_boid()
		_put(b, "alignment_weight", 4.5)
		_put(b, "cohesion_weight", 0.6)
		_put(b, "separation_weight", 0.9)
		_put(b, "min_speed", 0.0)
		_put(b, "max_speed", LANE_SPEED)
		add_child(b)
		_after_add(b)
		b.global_position = origin + Vector3(
			_rng.randf_range(-hx, hx),
			_rng.randf_range(-hy, hy),
			_rng.randf_range(-hx, hx)
		)
		_put(b, "velocity", Vector3(LANE_SPEED, 0.0, 0.0))
		_register(b)


## lattice — separation wins. A regular grid spanning 18 x 6 x 18 m.
##
## The rank count is derived from num_boids rather than hard-coded, so the
## grid is FULL at any population: 50 boids give the canonical 5 x 2 x 5
## with 4.5 / 6.0 / 4.5 m spacing, 100 (what boid_manager.tscn actually
## ships) give 5 x 4 x 5 at 4.5 / 2.0 / 4.5. Hard-coding 5 x 2 x 5 would
## have left the shipped placement with half a lattice and half a heap.
func _spawn_lattice() -> void:
	_rng.seed = SEED_LATTICE
	var origin: Vector3 = self.global_position
	var n: int = max(num_boids, 1)
	var rows: int = clampi(int(round(float(n) / 25.0)), 2, 5)
	var cols: int = max(2, int(ceil(sqrt(float(n) / float(rows)))))
	# Bounded widening: at most a handful of steps, never a search.
	for _pad in range(8):
		if cols * rows * cols >= n:
			break
		cols += 1
	var sx: float = LATTICE_SPAN_XZ / float(max(cols - 1, 1))
	var sy: float = LATTICE_SPAN_Y / float(max(rows - 1, 1))
	var x0: float = -LATTICE_SPAN_XZ * 0.5
	var y0: float = -LATTICE_SPAN_Y * 0.5
	for i in range(n):
		var b: Node3D = _make_boid()
		_put(b, "alignment_weight", 0.0)
		_put(b, "cohesion_weight", 0.0)
		_put(b, "separation_weight", 4.5)
		_put(b, "min_speed", 0.0)
		_put(b, "max_speed", LATTICE_SPEED)
		add_child(b)
		_after_add(b)
		var ix: int = i % cols
		var iz: int = int(i / cols) % cols
		# Clamped so that even an impossible population can never deposit a
		# boid above the 18 x 6 x 18 m block and into the caption's airspace.
		var iy: int = mini(int(i / (cols * cols)), rows - 1)
		b.global_position = origin + Vector3(
			x0 + float(ix) * sx,
			y0 + float(iy) * sy,
			x0 + float(iz) * sx
		)
		_put(b, "velocity", _rand_dir() * LATTICE_SPEED)
		_register(b)


func _make_boid() -> Node3D:
	return boid_scene.instantiate() as Node3D


## Everything that has to happen after the child is in the tree but is not
## deposit-specific.
func _after_add(b: Node3D) -> void:
	if vr_player and b.has_method("set"):
		b.set("vr_player_path", b.get_path_to(vr_player))


func _register(b: Node3D) -> void:
	boids.append(b)
	_spawned.append(b)


## A unit vector from the seeded stream. Never returns zero.
func _rand_dir() -> Vector3:
	var v: Vector3 = Vector3(
		_rng.randf_range(-1.0, 1.0),
		_rng.randf_range(-1.0, 1.0),
		_rng.randf_range(-1.0, 1.0)
	)
	if v.length() < 0.0001:
		return Vector3.FORWARD
	return v.normalized()


func _put(node: Node, key: String, value) -> void:
	if key in node:
		node.set(key, value)


func _prop(node: Node, key: String, fallback: float) -> float:
	if key in node:
		return float(node.get(key))
	return fallback


# ═══════════════════════════════════════════════════════════════════
# CAPTION
# ═══════════════════════════════════════════════════════════════════

## One label, above the flock, billboard ENABLED so LabelFramer turns it
## into an opaque anthracite plate with a bezel. It is not authored on a
## surface of the artifact — there is no surface, a flock is a cloud — so
## claiming the billboard-disabled exemption here would be the dodge.
func _build_caption() -> void:
	var l: Label3D = Label3D.new()
	l.name = "AccordCaption"
	l.text = CAPTION_FORMAT % [accord]
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.pixel_size = CAPTION_PIXEL_SIZE
	l.font_size = CAPTION_FONT_SIZE
	l.outline_size = 0
	l.modulate = Color(0.93, 0.93, 0.95)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector3(0.0, CAPTION_Y, 0.0)
	add_child(l)
	_spawned.append(l)
	_caption = l


# ═══════════════════════════════════════════════════════════════════
# EMISSIVE
# ═══════════════════════════════════════════════════════════════════

## Applied in place to each boid's own material override — no rebuild, so
## the key still bites after the early return in apply_grid_config. The
## trail ribbons are skipped: they carry a script and their own unshaded
## additive-ish material, and lighting them again only washes them out.
func _apply_emissive() -> void:
	for b in _spawned:
		if b is Label3D:
			continue
		_emissive_on_subtree(b)


func _emissive_on_subtree(node: Node) -> void:
	if node is MeshInstance3D and node.get_script() == null:
		var mi: MeshInstance3D = node as MeshInstance3D
		var mat: Material = mi.material_override
		if mat is StandardMaterial3D:
			var sm: StandardMaterial3D = mat as StandardMaterial3D
			sm.emission_enabled = emissive
			if emissive:
				sm.emission = sm.albedo_color
				sm.emission_energy_multiplier = 1.6
	for c in node.get_children():
		_emissive_on_subtree(c)


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

## Called via call_deferred by GridInteractablesComponent, AFTER _ready().
func apply_grid_config(config_data: Dictionary) -> void:
	var before_accord: String = accord
	var before_count: int = num_boids

	if config_data.has("accord"):
		accord = _pick_axis(str(config_data["accord"]), ACCORDS, accord)
	if config_data.has("boids"):
		num_boids = clampi(int(config_data["boids"]), 4, 400)

	# Non-geometry keys are applied IN PLACE, before the returns below.
	# curation_station hands every curated artifact {"emissive": false} and
	# no axis key; an accepted key that only bit inside a rebuild we then
	# early-return past would be a silent lie.
	if config_data.has("emissive"):
		emissive = _coerce_bool(config_data["emissive"], emissive)
		_apply_emissive()

	if not _built:
		return
	if accord == before_accord and num_boids == before_count:
		return

	_rebuild_now()
	print("[BoidManager] Config applied — accord=%s, boids=%d" % [accord, num_boids])


## Accept an axis value only if it names something we actually build. A
## typo in a map token falls back to the shipped look rather than
## stranding the placement with no flock at all.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## bool("false") is TRUE, which inverts the meaning of every string-typed
## flag a map can carry. Coerce properly.
func _coerce_bool(value, fallback: bool) -> bool:
	if value is bool:
		return value
	if value is int or value is float:
		return float(value) != 0.0
	var s: String = str(value).to_lower().strip_edges()
	if s in ["true", "1", "yes", "on"]:
		return true
	if s in ["false", "0", "no", "off", ""]:
		return false
	return fallback


## Synchronous and inline. A deferred rebuild that removes children first
## makes the grid's auto-grounding measure a ZERO AABB and bail, and an
## await can hang a headless run.
func _rebuild_now() -> void:
	for c in _spawned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_spawned.clear()
	boids.clear()
	_caption = null
	_build_all()


func _connect_controller_signals() -> void:
	# Connect controller input signals if using OpenXR
	if left_controller:
		# For OpenXR plugin
		if left_controller.has_signal("button_pressed"):
			left_controller.connect("button_pressed", Callable(self, "_on_left_controller_button_pressed"))
			left_controller.connect("button_released", Callable(self, "_on_left_controller_button_released"))

	if right_controller:
		if right_controller.has_signal("button_pressed"):
			right_controller.connect("button_pressed", Callable(self, "_on_right_controller_button_pressed"))
			right_controller.connect("button_released", Callable(self, "_on_right_controller_button_released"))

func _physics_process(_delta):
	# Handle controller interaction with boids
	_process_controller_interaction()

func _process_controller_interaction() -> void:
	# Process left controller
	if left_controller and left_trigger_pressed:
		var controller_pos = left_controller.global_position
		var controller_forward = -left_controller.global_transform.basis.z.normalized()
		_interact_with_nearby_boids(controller_pos, controller_forward, true)  # true for attract

	# Process right controller
	if right_controller and right_trigger_pressed:
		var controller_pos = right_controller.global_position
		var controller_forward = -right_controller.global_transform.basis.z.normalized()
		_interact_with_nearby_boids(controller_pos, controller_forward, false)  # false for repel

func _interact_with_nearby_boids(controller_pos, _direction, attract) -> void:
	for boid in boids:
		var distance = controller_pos.distance_to(boid.global_position)

		if distance < interaction_radius:
			# Calculate influence based on distance (stronger when closer)
			var influence = 1.0 - (distance / interaction_radius)

			if attract:
				# Direction toward controller
				var force_dir = (controller_pos - boid.global_position).normalized()
				boid.apply_force_from_vr(force_dir, attraction_strength * influence, 0.5)
			else:
				# Direction away from controller
				var force_dir = (boid.global_position - controller_pos).normalized()
				boid.apply_force_from_vr(force_dir, repulsion_strength * influence, 0.5)

# Controller input handlers for OpenXR
func _on_left_controller_button_pressed(button_name) -> void:
	if button_name == "trigger_click" or button_name == "trigger":
		left_trigger_pressed = true

func _on_left_controller_button_released(button_name) -> void:
	if button_name == "trigger_click" or button_name == "trigger":
		left_trigger_pressed = false

func _on_right_controller_button_pressed(button_name) -> void:
	if button_name == "trigger_click" or button_name == "trigger":
		right_trigger_pressed = true

func _on_right_controller_button_released(button_name) -> void:
	if button_name == "trigger_click" or button_name == "trigger":
		right_trigger_pressed = false

# Alternative input method for desktop testing
func _input(event: InputEvent) -> void:
	# For testing without VR hardware
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_SPACE:
			# When space is pressed, make boids attracted to the VR player
			if vr_player:
				for boid in boids:
					var direction = vr_player.global_position - boid.global_position
					boid.apply_force_from_vr(direction, attraction_strength, 1.0)

		if event.pressed and event.keycode == KEY_ESCAPE:
			# When escape is pressed, make boids flee from the VR player
			if vr_player:
				for boid in boids:
					var direction = boid.global_position - vr_player.global_position
					boid.apply_force_from_vr(direction, repulsion_strength, 1.0)

# Return the array of boids for optimization
func get_boids():
	return boids
