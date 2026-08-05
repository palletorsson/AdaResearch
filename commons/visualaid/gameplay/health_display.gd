# @identity
# essence: A 3D label showing the player's current health, updated from GameManager.health_updated signal
# desire: To give the player a stable readout of fragility — a number that changes only when the world has acted on them
# critical_parameter: signal connection to GameManager — without it the display lies; with it, every change in health is mirrored instantly
# triggers: Damage events lower the number; healing raises it; map reload resets it; visibility ties health to context
# emerges: A small 3D readout becomes the player's contract with the game — what counts as harm is what changes this label
# needs: Label3D rendering [has], GameManager signal binding [has], reset on map enter [has]
# relationships: Companion to hits_reset_display in forces/Combat_Arena. Both are visual contracts between game state and player perception
# truth: A health display is not a stat — it is a promise that change has consequences and that the world keeps account.
extends Node3D

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-05) — THE FORM OF THE ACCOUNT.
# Twin file: commons/visualaid/gameplay/hits_reset_display.gd, same word, same
# values, same rail. Shared body: commons/visualaid/gameplay/gameplay_readout.gd.
#
# WHY THIS IS NOT PLUMBING. Read literally this script is thirteen lines that
# push a number into a label the .tscn already contains, and the family it sits
# in (speed_display, memory_display, frames_display, draw_calls_display) is
# exactly the shape of thing that should be declined. But the identity block
# above does not claim to report health; it claims "a promise that change has
# consequences and that the world keeps account". THE FORM OF THE ACCOUNT IS THE
# CLAIM, and today it is one hard-coded form — a bare integer, with the whole
# range it belongs to, and the thresholds at which this file changes its verdict
# about you, left off the panel entirely.
#
# So the axis is `readout`, taken verbatim — word and value list — from
# line_interface / xyz_slider_plate / xyz_coordinates / qfep_calibrator /
# qfep_reactor, where it already means "what does this apparatus tell you about
# the value it holds". Two more artifacts join a vocabulary of five rather than
# inventing a sixth word for the same question. They should MEASURE ALIKE, and
# that is the check on the shared word, not a coincidence to explain afterwards.
#
#   none < numeral (legacy default) < gradation < lattice
#
# WHAT THE LATTICE RUNG DRAWS, and why it is worth a rung. Lines 30-35 of the
# shipped file are an if/elif chain on two bare literals: health <= 1.0 is red,
# <= 2.0 is yellow, anything above is green. GameManager ships
# max_player_health = 100.0 and nothing in the project ever changes it, so those
# two verdicts own 2% of the range and NO PLAYER HAS EVER SEEN THEM — the panel
# has been green in every room, every time, since it was written. `lattice`
# draws them at their true positions: two standing gates crowded against the
# left stop of a hundred-unit scale. The instrument finally shows how much
# warning it actually gives, which is none. That is a fact about this design
# that was true before this promotion and invisible until it.
#
# NOTHING BELOW CHANGES WHAT THE PANEL COMPUTES. The signal connection, the
# `%d` of ceil(health), and all three colour branches are byte-identical to the
# shipped file and run at every rung, including `none` — rung 0 says the
# apparatus tells you nothing, not that the law stops applying. The thresholds
# are lifted to named constants but keep their exact values, and they are read
# only to POSITION the gates; the chain that uses them still tests the literals
# it always tested.
#
# DEFAULT: readout = "numeral", which builds no rail and touches no visibility.
# All 3 placements (ForcesArena, Forces_Drone_Game x2) render exactly as before.
# ─────────────────────────────────────────────────────────────────────────────

## AXIS — what this apparatus commits to about the health it holds. Anything
## unrecognised builds as `numeral`, NOT as `none`: a typo must not silently
## delete the readout from a live room. That rule is line.gd's and the
## calibrator's, and it is here for the same reason.
@export_enum("none", "numeral", "gradation", "lattice") var readout: String = "numeral"

const Rail = preload("res://commons/visualaid/gameplay/gameplay_readout.gd")

## Allow-list for the map-token path. An unrecognised token leaves the value alone.
const READOUTS: PackedStringArray = ["none", "numeral", "gradation", "lattice"]

## The two verdicts this file has always carried as bare literals in
## _update_display. Named, not changed — the chain below still tests the same
## numbers, and these exist so `lattice` can draw them where they really are.
const DANGER_AT: float = 1.0
const WARN_AT: float = 2.0

@onready var value_label: Label3D = $DisplayBody/ValueLabel

var _rail: Node3D = null
var _built: bool = false

func _ready() -> void:
    _read_readout()

    # Connect to signal if available, or just poll
    if GameManager.has_signal("health_updated"):
        GameManager.health_updated.connect(_on_health_updated)

    # No-op at `numeral`, so the shipped order — connect, then set — is unchanged
    # for every existing placement.
    _build_readout()
    _built = true

    # Initial set
    _update_display(GameManager.get_health())

func _on_health_updated(new_health: float) -> void:
    _update_display(new_health)

func _update_display(health: float) -> void:
    # Use ceil to show whole numbers if it's hit-based logic
    value_label.text = "%d" % ceil(health)

    # Change color based on health?
    if health <= 1.0:
        value_label.modulate = Color(1, 0, 0, 1) # Red
    elif health <= 2.0:
        value_label.modulate = Color(1, 1, 0, 1) # Yellow
    else:
        value_label.modulate = Color(0, 1, 0, 1) # Green

    # null on the legacy path — one null test per update for the 3 rooms that
    # never asked for a rail
    if _rail != null:
        _sync_index(health)


# ── DNA implementation ───────────────────────────────────────────────────────
# The readout rung, and nothing else, lives below here.

## The token read, and it has to happen HERE rather than in apply_grid_config:
## GridInteractablesComponent stamps every `#key:value` as `config_<key>`
## metadata on the artifact root BEFORE add_child, and only calls
## apply_grid_config a frame later via call_deferred — so a knob that SHAPES the
## build is one frame too late if it is read there.
##
## No ancestor walk, unlike line.gd. health_display.tscn's ROOT carries this
## script, so the metadata lands on this exact node; walking up would only let a
## container's key leak into an artifact that never asked for it.
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
            # rung 0 — the panel and its title stay; the value goes silent. The
            # label is HIDDEN rather than freed so the capture's AABB, which
            # counts Label3D, is identical at every rung and the camera does not
            # move between variants.
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
## — the whole range the value could take, not the part it happens to occupy —
## and the bands hand the shared builder the exact intervals the colour chain
## above owns, so the drawing cannot disagree with the code it illustrates.
func _build_rail(stations: bool) -> void:
    var max_health: float = _max_health()
    var bands: Array = []
    var gates: Array = []
    if stations:
        bands.append({"from": 0.0, "to": DANGER_AT, "hot": true})
        bands.append({"from": DANGER_AT, "to": WARN_AT, "hot": false})
        gates.append(DANGER_AT)
        gates.append(WARN_AT)
    _rail = Rail.build(self, max_health, bands, gates, stations)
    _sync_index(_current_health())


func _sync_index(health: float) -> void:
    Rail.set_value(_rail, health / maxf(_max_health(), 0.001))


func _max_health() -> float:
    if GameManager != null and "max_player_health" in GameManager:
        return float(GameManager.max_player_health)
    return 100.0


func _current_health() -> float:
    if GameManager != null and GameManager.has_method("get_health"):
        return float(GameManager.get_health())
    return _max_health()


## Present for a caller holding this node directly, and as the map path's second
## chance — the token is normally already in via metadata by the time this runs.
## Guarded three ways: a call naming nothing this artifact owns returns before
## touching anything, an unrecognised value is refused rather than collapsing the
## panel to `none`, and a value equal to the current rung rebuilds nothing. A
## call arriving before _ready only records the wish, so the build is never done
## twice or done out of order.
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
