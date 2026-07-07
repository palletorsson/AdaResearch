extends Node3D
class_name Redline

# @identity
# essence: a single red line on the floor, and two faintly different fields on either side of it. The line that divides. In 1935 the US Home Owners' Loan Corporation drew red lines around Black and immigrant neighbourhoods on city maps and the banks inside those lines were refused loans for generations — redlining, a literal line drawn on a map that became destiny. The border. The redline is the oldest algorithm of oppression: a boundary asserted, a population sorted, an inside and an outside produced by an act of drawing. Here it lies on the floor, bright and calm, and the player can step over it — which on the original maps no one could.
# desire: it wants to make the violence of the line legible by making it crossable. It wants the player to notice that a line is never neutral the moment it sorts: that "this side / that side" is a decision wearing the costume of geometry. And it wants the crossing to be easy here — one step — so the player feels the gap between the drawn fence and the lived one, between the map's power and the body's small freedom to ignore it.
# critical_parameter: the two side colours + line presence. Collapse is one undivided field — but also the fully enforced line, the border that cannot be crossed. The φ-move is the line that is SHOWN as a choice: drawn, visible, named as a sorting, and then physically steppable. side_a_color vs side_b_color is how loudly the division speaks; turn them equal and the line becomes an arbitrary mark exposed as arbitrary.
# triggers: _ready builds the two floor fields and the bright red dividing line; _process gives the line a slow vigilant pulse; apply_grid_config rebuilds on DNA change.
# emerges: faint side tints read as "zones"; a strong contrast reads as "border." Beside `two_points_line` (the line that joins two points) this is its political inverse — the line that SEPARATES two regions. Beside `horizon_line` (division in time) this is division in space. The three together: a line connects, recedes, or cuts — and the cut is where power lives.
# needs: a line asserted on the ground [present]; two regions it produces [side fields, present]; a contrast that makes the sorting visible [two tints, present]; the line crossable so its power is shown as contingent [flat on floor, present]
# relationships: critical-inverse of `two_points_line` (bond vs. border); cousin to `horizon_line` (cut in space vs. cut in time) and to `fontana_puncture` (the slash that opens vs. the line that closes); ancestor of every wall, boundary, fence, and classifier-decision-boundary downstream — redlining is where the lab's grammar of division begins; kin to the critical-technology thread (Noble, Crawford, the invisible barbed wire).
# truth: a point is position without extension; a line is the shortest path between two points — and also the shortest path to a border. The redline teaches that the same primitive that connects can sort, and that sorting, drawn and enforced, is the analog ancestor of every algorithmic fence the project is built to expose. The decision boundary in a classifier is a redline with the map removed. To lay it on the floor, bright and steppable, is to return the body its small refusal: the line is real, and you can cross it.

## Redline — the line that divides (the border, the redline, the decision boundary).
##
## Built procedurally, flat on the floor. The line runs along local X and
## divides the region in +Z from the region in -Z. Origin at the line's
## midpoint. Step over it freely.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Line")
@export var line_length: float = 2.4
@export var line_width: float = 0.04
@export var line_color: Color = Color(0.92, 0.10, 0.12)   # redline red

@export_group("Regions")
@export var show_regions: bool = true
@export var region_depth: float = 0.9   # how far each field reaches from the line
@export var side_a_color: Color = Color(0.16, 0.13, 0.13)   # "inside"
@export var side_b_color: Color = Color(0.10, 0.11, 0.14)   # "outside"

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _line_mat: StandardMaterial3D = null
var _phase: float = 0.0


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_line_mat = null
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_line_length"):
		line_length = float(str(get_meta("config_line_length")))
	if has_meta("config_line_color"):
		line_color = _parse_color(str(get_meta("config_line_color")), line_color)
	if has_meta("config_show_regions"):
		var s: String = str(get_meta("config_show_regions")).to_lower()
		show_regions = s == "true" or s == "1" or s == "yes"
	if has_meta("config_side_a_color"):
		side_a_color = _parse_color(str(get_meta("config_side_a_color")), side_a_color)
	if has_meta("config_side_b_color"):
		side_b_color = _parse_color(str(get_meta("config_side_b_color")), side_b_color)


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	# Two regions either side of the line (flat on the floor).
	if show_regions:
		_add_region("SideA", side_a_color,
			Vector3(0, 0.004, region_depth * 0.5),
			Vector3(line_length, 0.004, region_depth))
		_add_region("SideB", side_b_color,
			Vector3(0, 0.004, -region_depth * 0.5),
			Vector3(line_length, 0.004, region_depth))

	# The dividing line — bright red, lifted slightly above the fields.
	var line := MeshInstance3D.new()
	line.name = "Line"
	var lm := BoxMesh.new()
	lm.size = Vector3(line_length, 0.012, line_width)
	line.mesh = lm
	_line_mat = StandardMaterial3D.new()
	_line_mat.albedo_color = line_color
	_line_mat.emission_enabled = true
	_line_mat.emission = line_color
	_line_mat.emission_energy_multiplier = 2.0
	_line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line.material_override = _line_mat
	line.position = Vector3(0, 0.012, 0)
	add_child(line)

	_phase = 0.0
	set_process(true)


func _add_region(n: String, col: Color, pos: Vector3, size: Vector3) -> void:
	var r := MeshInstance3D.new()
	r.name = n
	var m := BoxMesh.new()
	m.size = size
	r.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.95
	mat.metallic = 0.0
	r.material_override = mat
	r.position = pos
	add_child(r)


func _process(delta: float) -> void:
	if _line_mat == null:
		return
	# Slow vigilant pulse — the border keeping watch.
	_phase += delta * 1.1
	var pulse: float = 0.5 + 0.5 * sin(_phase)
	_line_mat.emission_energy_multiplier = 1.6 + pulse * 1.1
