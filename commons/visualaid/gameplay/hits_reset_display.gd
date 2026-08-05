# @identity
# essence: A 3D readout that mirrors player health and reflects the reset state — companion display to health_display
# desire: To name the moment of reset as visible — to show that being hit and being whole are tracked, not assumed
# critical_parameter: GameManager signal binding — the display is only honest while connected
# triggers: Damage updates the value; restart restores baseline; visibility tracks active map context
# emerges: A readout that pairs with health_display to make state legible — together they read as a small instrument panel
# needs: Label3D [has], GameManager signal [has], reset behavior [has]
# relationships: Twin of health_display in forces/Combat_Arena. Same pattern, different role
# truth: A reset is not a return to nothing — it is the act of restoring an expected state, and the readout is the witness.
extends Node3D

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-05) — THE FORM OF THE ACCOUNT.
# Twin file: commons/visualaid/gameplay/health_display.gd. Same word, same value
# list, same shared body (commons/visualaid/gameplay/gameplay_readout.gd), read
# the long note there and in the twin — this file records only what differs.
#
# WHAT DIFFERS, AND WHY THE PAIR IS WORTH BOTH DECLARATIONS. The twin counts
# down what remains; this one counts up what has been taken, and prints it as
# "N / max" — a claim about how much warning you get before the map resets. At
# rung 3 that claim becomes drawable, and the two panels come out MIRRORED:
#
#   health_display   hot band 0..1 of 100     — 1% of the scale is "red"
#   hits_reset_display  hot band 2..100       — 98% of the scale is "red"
#
# Same word, same builder, same ladder, opposite pictures — because the two
# files really do privilege opposite ends of one number. That asymmetry has been
# in the corpus since both were written and could not be seen from either panel.
# It is not a vocabulary drift: both rungs draw "the set of values the code
# changes its verdict at", which is what `lattice` means everywhere it is
# declared.
#
# A SECOND THING THIS MAKES VISIBLE, reported and NOT fixed. The comment on
# _update_display below says "we already have a Health display (3 -> 0)" and the
# thresholds are written for a three-hit game. GameManager ships
# max_player_health = 100.0 and nothing in the project calls set_max_health, so
# this panel has read "0 / 100" in every room it has ever stood in, and every
# hit after the second is inside the same red verdict. Changing that would move
# three live placements and is not a DNA promotion's business; drawing it is.
#
# DEFAULT: readout = "numeral", which builds no rail and touches no visibility.
# All 3 placements (ForcesArena, Forces_Drone_Game x2) render exactly as before.
# ─────────────────────────────────────────────────────────────────────────────

## AXIS — what this apparatus commits to about the count it holds. Anything
## unrecognised builds as `numeral`, NOT as `none`: a typo must not silently
## delete the readout from a live room.
@export_enum("none", "numeral", "gradation", "lattice") var readout: String = "numeral"

const Rail = preload("res://commons/visualaid/gameplay/gameplay_readout.gd")

## Allow-list for the map-token path. An unrecognised token leaves the value alone.
const READOUTS: PackedStringArray = ["none", "numeral", "gradation", "lattice"]

## The two verdicts this file has always carried as bare literals in
## _update_display, counted in HITS TAKEN. Named, not changed — the chain below
## still tests the same numbers.
const WARN_AT: float = 1.0
const DANGER_AT: float = 2.0

@onready var value_label: Label3D = $DisplayBody/ValueLabel

var _rail: Node3D = null
var _built: bool = false

func _ready() -> void:
	_read_readout()

	if GameManager.has_signal("health_updated"):
		GameManager.health_updated.connect(_on_health_updated)

	# No-op at `numeral`, so the shipped order — connect, then set — is unchanged
	# for every existing placement.
	_build_readout()
	_built = true

	_update_display(GameManager.get_health())

func _on_health_updated(new_health: float) -> void:
	_update_display(new_health)

func _update_display(health: float) -> void:
	# "Hits To Reset" implies countdown.
	# But we already have a Health display (3 -> 0).
	# Let's make this one show how many hits we have TAKEN (0 -> 3) to show progress towards failure.
	var hits_taken = max(0, GameManager.max_player_health - health)
	value_label.text = "%d / %d" % [ceil(hits_taken), int(GameManager.max_player_health)]

	if hits_taken >= 2:
		value_label.modulate = Color(1, 0, 0, 1) # Red danger
	elif hits_taken >= 1:
		value_label.modulate = Color(1, 1, 0, 1) # Warning
	else:
		value_label.modulate = Color(1, 0.6, 0, 1) # Normal orange

	# null on the legacy path — one null test per update for the 3 rooms that
	# never asked for a rail
	if _rail != null:
		_sync_index(float(hits_taken))


# ── DNA implementation ───────────────────────────────────────────────────────
# The readout rung, and nothing else, lives below here.

## The token read, at build time rather than in apply_grid_config, and without an
## ancestor walk. See the twin for the full reasoning: the metadata lands on this
## node because hits_reset_display.tscn's ROOT carries this script.
func _read_readout() -> void:
	var raw: String = readout
	if has_meta("config_readout"):
		raw = str(get_meta("config_readout"))
	elif has_meta("readout"):
		raw = str(get_meta("readout"))
	var want: String = Rail.readout_name(raw)
	readout = want if READOUTS.has(want) else "numeral"


func _build_readout() -> void:
	match readout:
		"none":
			# rung 0 — the panel and its title stay; the count goes silent. Hidden
			# rather than freed, so the capture's AABB is identical at every rung.
			if value_label != null:
				value_label.visible = false
		"numeral":
			pass                      # rung 1 — the legacy lineage, 3 rooms
		"gradation":
			_build_rail(false)
		"lattice":
			_build_rail(true)
		_:
			pass                      # an unrecognised word reads as the legacy numeral


## RUNG 2, and RUNG 3 when `stations` is true. The scale runs 0..max_player_health
## in HITS TAKEN, so the index starts hard left where the twin's starts hard
## right, and the bands hand the shared builder the exact intervals the colour
## chain above owns.
func _build_rail(stations: bool) -> void:
	var max_hits: float = _max_hits()
	var bands: Array = []
	var gates: Array = []
	if stations:
		bands.append({"from": WARN_AT, "to": DANGER_AT, "hot": false})
		bands.append({"from": DANGER_AT, "to": max_hits, "hot": true})
		gates.append(WARN_AT)
		gates.append(DANGER_AT)
	_rail = Rail.build(self, max_hits, bands, gates, stations)
	_sync_index(_current_hits())


func _sync_index(hits_taken: float) -> void:
	Rail.set_value(_rail, hits_taken / maxf(_max_hits(), 0.001))


func _max_hits() -> float:
	if GameManager != null and "max_player_health" in GameManager:
		return float(GameManager.max_player_health)
	return 100.0


func _current_hits() -> float:
	if GameManager != null and GameManager.has_method("get_health"):
		return maxf(0.0, _max_hits() - float(GameManager.get_health()))
	return 0.0


## Present for a caller holding this node directly, and as the map path's second
## chance. Guarded exactly as the twin is: nothing happens for a call that does
## not name this axis, for a value the allow-list refuses, for a value already in
## force, or for a call that beats _ready to the artifact.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("readout"):
		return
	var want: String = Rail.readout_name(str(config_data["readout"]))
	if not READOUTS.has(want):
		return
	if want == readout:
		return
	if not _built:
		readout = want
		return
	readout = want
	if _rail != null:
		remove_child(_rail)
		_rail.queue_free()
		_rail = null
	if value_label != null:
		value_label.visible = readout != "none"
	_build_readout()
