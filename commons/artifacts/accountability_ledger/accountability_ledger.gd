extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name AccountabilityLedger

## @identity
## name: Accountability Ledger
## truth: Stay answerable for what you leave out.
##
## Ethical design after incompleteness — APPLIED, device (~1m + readout Label3D).
## A running ledger: it logs each design choice and WHO IT EXCLUDES. A scrolling
## readout lists answerability entries; a fresh entry is stamped at a steady
## interval and pushes the list up. An amber "ON THE RECORD" lamp pulses each
## time a line is committed. Cool/formal housing, constructive amber accent.

@export var log_interval: float = 1.8      # seconds between new ledger entries
@export var visible_lines: int = 6         # entries shown in the readout

const COOL_WHITE := Color(0.90, 0.92, 0.97)
const SLATE := Color(0.34, 0.38, 0.48)
const PURPLE := Color(0.58, 0.42, 0.92)
const TEAL := Color(0.30, 0.82, 0.78)
const AMBER := Color(0.98, 0.72, 0.28)
const PAPER := Color(0.12, 0.13, 0.17)

# Pools to compose plausible "choice -> excluded" log lines.
const CHOICES := [
	"default locale=EN", "age slider 18+", "name field 32ch", "skin tone x3",
	"voice model US", "gesture set right-hand", "font Latin only", "speed over recall",
	"binary gender", "broadband assumed",
]
const EXCLUDED := [
	"non-EN readers", "minors", "long names", "darker tones",
	"non-US accents", "left-handed", "non-Latin scripts", "rare classes",
	"non-binary", "low-bandwidth",
]

var _entries: Array[String] = []
var _line_labels: Array[Label3D] = []
var _lamp: MeshInstance3D = null
var _lamp_mat: StandardMaterial3D = null
var _readout: Label3D = null
var _counter_label: Label3D = null
var _spool: MeshInstance3D = null
var _t: float = 0.0
var _timer: float = 0.0
var _commit_flash: float = 0.0
var _count: int = 0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_entries.clear()
	_line_labels.clear()

	# --- Device housing (cool/formal slate + white console) ----------------
	add_child(_box(Vector3(0, 0.30, 0), Vector3(0.70, 0.60, 0.34), _matte_mat(Color(0.20, 0.21, 0.26), 0.7)))
	# white face plate
	add_child(_box(Vector3(0, 0.42, 0.175), Vector3(0.58, 0.40, 0.02), _matte_mat(COOL_WHITE, 0.6)))
	# purple wireframe frame around the readout — the formal record boundary
	add_child(_box(Vector3(0, 0.62, 0.19), Vector3(0.58, 0.012, 0.012), _glow_mat(PURPLE, 1.4)))
	add_child(_box(Vector3(0, 0.22, 0.19), Vector3(0.58, 0.012, 0.012), _glow_mat(PURPLE, 1.4)))
	add_child(_box(Vector3(-0.29, 0.42, 0.19), Vector3(0.012, 0.40, 0.012), _glow_mat(PURPLE, 1.4)))
	add_child(_box(Vector3(0.29, 0.42, 0.19), Vector3(0.012, 0.40, 0.012), _glow_mat(PURPLE, 1.4)))

	# dark "paper" readout panel the entries scroll across
	add_child(_box(Vector3(0, 0.42, 0.185), Vector3(0.55, 0.38, 0.006), _glass_mat(PAPER, 0.85)))

	# --- Feed spool (teal) on the side — the ongoing record ----------------
	_spool = _cylinder(Vector3(-0.42, 0.42, 0), 0.07, 0.06, _glow_mat(TEAL, 1.3))
	_spool.rotation.z = PI * 0.5
	add_child(_spool)
	add_child(_cylinder(Vector3(-0.42, 0.42, 0), 0.02, 0.10, _steel_mat(SLATE)))

	# --- The amber "ON THE RECORD" lamp ------------------------------------
	_lamp_mat = _glow_mat(AMBER, 1.0)
	_lamp = _sphere(Vector3(0.42, 0.55, 0.0), 0.05, _lamp_mat)
	add_child(_lamp)
	add_child(_cylinder(Vector3(0.42, 0.40, 0), 0.02, 0.24, _steel_mat(SLATE)))
	add_child(_billboard_label("ON THE RECORD", Vector3(0.42, 0.70, 0), 14, AMBER))

	# --- Scrolling readout lines (the device's process) --------------------
	# Each is its own Label3D; we rewrite text + fade as the list scrolls.
	var top_y: float = 0.58
	var line_h: float = (0.58 - 0.26) / float(visible_lines)
	for i in range(visible_lines):
		var ly: float = top_y - line_h * float(i)
		var lab := Label3D.new()
		lab.text = ""
		lab.font_size = 13
		lab.modulate = COOL_WHITE
		lab.outline_size = 6
		lab.no_depth_test = true
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lab.position = Vector3(-0.26, ly, 0.20)
		add_child(lab)
		_line_labels.append(lab)

	# --- A header readout Label3D (applied-tier requirement) ---------------
	_readout = _billboard_label("LEDGER — choice ▸ excluded", Vector3(0, 0.92, 0), 18, TEAL)
	add_child(_readout)
	_counter_label = _billboard_label("entries: 0", Vector3(0, 0.78, 0), 14, AMBER)
	add_child(_counter_label)

	# --- Title -------------------------------------------------------------
	add_child(_billboard_label("ACCOUNTABILITY LEDGER", Vector3(0, 1.08, 0), 26, COOL_WHITE))

	# seed a couple of starting entries so the panel is never blank
	_push_entry()
	_push_entry()
	_refresh_lines()


func _push_entry() -> void:
	var ci: int = _rng.randi_range(0, CHOICES.size() - 1)
	var line: String = CHOICES[ci] + "  ▸  " + EXCLUDED[ci]
	_entries.push_front(line)
	while _entries.size() > visible_lines:
		_entries.pop_back()
	_count += 1
	_commit_flash = 1.0


func _refresh_lines() -> void:
	for i in range(_line_labels.size()):
		var lab: Label3D = _line_labels[i]
		if i < _entries.size():
			lab.text = _entries[i]
			# newest line bright teal, older lines fade toward slate
			var fade: float = 1.0 - float(i) / float(visible_lines)
			var col: Color = TEAL.lerp(SLATE, 1.0 - fade)
			if i == 0:
				col = AMBER
			lab.modulate = col
		else:
			lab.text = ""
	if _counter_label != null:
		_counter_label.text = "entries: " + str(_count)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	_timer += delta

	# Commit a new ledger entry at a steady interval — the running process.
	if _timer >= log_interval:
		_timer = 0.0
		_push_entry()
		_refresh_lines()

	# Lamp pulses bright on each commit, then decays — "ON THE RECORD".
	_commit_flash = maxf(_commit_flash - delta * 1.6, 0.0)
	if _lamp_mat != null:
		var base: float = 0.6 + 0.3 * sin(_t * 2.5)
		var energy: float = base + _commit_flash * 2.4
		_lamp_mat.emission_energy_multiplier = energy if emissive else 0.0
		_lamp_mat.albedo_color = AMBER.lerp(COOL_WHITE, _commit_flash * 0.5)
	if _lamp != null:
		var s: float = 1.0 + _commit_flash * 0.3
		_lamp.scale = Vector3(s, s, s)

	# Feed spool turns continuously — the record never stops advancing.
	if _spool != null:
		_spool.rotation.y = _t * 2.0

	# Newest line gently rises into place (scroll feel).
	if _line_labels.size() > 0:
		var nudge: float = (1.0 - clampf(_timer / log_interval, 0.0, 1.0)) * 0.01
		_line_labels[0].position.y = 0.58 - nudge
