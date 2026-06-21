extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MergeConflictToy

## @identity
## name: Merge Conflict Toy — Two Truths, Both Kept
## concept: Paraconsistent engineering
## tier: small
## lineage: post-crisis engineering after the foundations crisis — knowing that no formal
##   system seals shut, we stop demanding a single consistent truth and instead build
##   machines that HOLD contradiction productively. The version-control merge conflict is
##   the everyday paraconsistent artifact: git does not crash on disagreement, it marks
##   the seam and hands both versions to a human who decides in context.
## essence: a held merge conflict, frozen mid-resolution. Two branch ribbons — HEAD and
##   theirs — carry conflicting lines side by side, separated by the conflict markers
##   (<<<< HEAD / ==== / >>>> theirs). Neither line is deleted; neither auto-wins. The
##   warm accent is the unresolved seam between them, pulsing because the decision is
##   still open.
## truth: two truths, both kept; the system holds the conflict instead of crashing on it.
##   Contradiction is not a fault to be auto-resolved — it is information about a choice
##   that has not yet been made.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var slate: Color = Color(0.20, 0.23, 0.30)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var head_color: Color = Color(0.40, 0.85, 0.95)    # HEAD branch — teal
@export var theirs_color: Color = Color(0.98, 0.70, 0.30)  # theirs branch — amber
@export var seam_color: Color = Color(0.98, 0.55, 0.25)    # the unresolved seam
@export var spin_speed: float = 0.45

var _t: float = 0.0
var _seam_mat: StandardMaterial3D
var _head_mat: StandardMaterial3D
var _theirs_mat: StandardMaterial3D


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("spin_speed"):
		spin_speed = float(config["spin_speed"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	# held object — no base; centred near origin, ~0.4 m across.
	var marker_mat: StandardMaterial3D = _glow_mat(wire_purple, 0.7)
	var slate_mat: StandardMaterial3D = _matte_mat(slate, 0.7)
	_head_mat = _glow_mat(head_color, 1.0)
	_theirs_mat = _glow_mat(theirs_color, 1.0)
	_seam_mat = _glow_mat(seam_color, 2.0)

	# backing slab the whole conflict sits on (the file)
	add_child(_box(Vector3(0.0, 0.0, -0.03), Vector3(0.42, 0.34, 0.012), slate_mat))

	# --- conflict marker bars: <<<< HEAD / ==== / >>>> theirs ---
	var marker_y_top: float = 0.13     # <<<<<<< HEAD
	var marker_y_mid: float = 0.0      # =======
	var marker_y_bot: float = -0.13    # >>>>>>> theirs
	add_child(_box(Vector3(0.0, marker_y_top, 0.0), Vector3(0.40, 0.018, 0.012), marker_mat))
	add_child(_box(Vector3(0.0, marker_y_mid, 0.0), Vector3(0.40, 0.018, 0.012), marker_mat))
	add_child(_box(Vector3(0.0, marker_y_bot, 0.0), Vector3(0.40, 0.018, 0.012), marker_mat))

	# --- HEAD branch (top half): three conflicting "lines" as teal bars ---
	var i: int = 0
	while i < 3:
		var yy: float = marker_y_top - 0.028 - float(i) * 0.026
		var w: float = 0.30 - float(i) * 0.04
		add_child(_box(Vector3(-0.02, yy, 0.006), Vector3(w, 0.014, 0.01), _head_mat))
		i += 1

	# --- theirs branch (bottom half): three conflicting "lines" as amber bars ---
	i = 0
	while i < 3:
		var yy: float = marker_y_mid - 0.028 - float(i) * 0.026
		var w: float = 0.22 + float(i) * 0.04
		add_child(_box(Vector3(0.02, yy, 0.006), Vector3(w, 0.014, 0.01), _theirs_mat))
		i += 1

	# --- the seam: a vertical glowing thread joining the two kept versions ---
	add_child(_box(Vector3(0.0, 0.0, 0.018), Vector3(0.008, 0.30, 0.008), _seam_mat))

	# small floating cursor: the human decision that has NOT been made
	add_child(_sphere(Vector3(0.0, 0.0, 0.05), 0.012, _seam_mat))

	# --- labels: the literal conflict syntax (held in hand, readable up close) ---
	add_child(_billboard_label("<<<<<<< HEAD", Vector3(0.0, marker_y_top + 0.012, 0.04), 12, head_color))
	add_child(_billboard_label("=======", Vector3(0.0, marker_y_mid + 0.012, 0.04), 12, cool_white))
	add_child(_billboard_label(">>>>>>> theirs", Vector3(0.0, marker_y_bot + 0.012, 0.04), 12, theirs_color))

	# --- billboard title ---
	add_child(_billboard_label("TWO TRUTHS, BOTH KEPT", Vector3(0.0, 0.27, 0.0), 18, cool_white))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	rotation.y += delta * spin_speed
	# seam pulses — the decision is still open
	var pulse: float = 1.6 + 0.8 * sin(_t * 3.0)
	if _seam_mat:
		_seam_mat.emission_energy_multiplier = pulse if emissive else pulse * 0.3
	# the two branches breathe alternately — neither dominates
	var beat: float = 0.5 + 0.5 * sin(_t * 1.4)
	if _head_mat:
		_head_mat.emission_energy_multiplier = (0.7 + 0.6 * beat) if emissive else 0.3
	if _theirs_mat:
		_theirs_mat.emission_energy_multiplier = (0.7 + 0.6 * (1.0 - beat)) if emissive else 0.3
