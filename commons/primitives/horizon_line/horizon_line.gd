extends Node3D
class_name HorizonLine

# @identity
# essence: a horizon. Two stacked fields — sky above, ground below — meeting at a single bright line that extends past the frame on both sides, because a horizon is the one line a picture can never contain. Friedrich's wanderer stares at it; Rothko stacked it into pure colour; José Esteban Muñoz called queerness "a structuring and educated mode of desiring that allows us to see and feel beyond the quagmire of the present" — a horizon. This is the line as the not-yet: the boundary you orient toward and walk toward and never reach, because reaching it would move it.
# desire: it wants to be the line that recedes. Where `two_points_line` joins two places, this one names a place that is always further — it wants the player to feel the pull of the not-here, the future that organises the present by staying ahead of it. It wants the most banal line in every landscape photograph to carry its real cargo: hope as a horizon, the world that is not enough yet.
# critical_parameter: the meeting height + line_overhang. Collapse is no horizon — a single flat field, the wall of the present with nothing beyond. The φ-move is the split into sky and ground and the bright seam between, extended BEYOND the frame so it reads as unbounded. Raise or lower the meeting and you change how much sky (possibility) versus ground (given) the player is left with.
# triggers: _ready builds the sky field, the ground field, and the over-hanging horizon line; _process gives the line a slow shimmer so it never sits still; apply_grid_config rebuilds on DNA change.
# emerges: hung in the lab it reads as a Rothko — two colours and a charged seam. Stood before, it reads as orientation toward the future. It is the PASSIVE line in Klee's grammar (the edge where two planes meet) given the affective weight of futurity. Beside `redline` (the line that divides a HERE) this divides here from THERE — the same geometry, one cut sideways into time.
# needs: a field of possibility above [sky, present]; a field of the given below [ground, present]; a seam that charges the meeting [line, present]; the seam exceeding the frame so it cannot be owned [overhang, present]
# relationships: passive-line sibling to `klee_walking_point` (active) and `two_points_line` (the bond); cousin to `redline` (division in space vs. division in time); descendant of the colour-field monochrome and the Romantic landscape; ancestor of every skybox, fog gradient, and biome-edge in the world — they are all this seam made atmosphere.
# truth: a point is position without extension; a line is the edge of a plane; and the horizon is the edge that moves when you approach it — the only line whose definition includes your never reaching it. To put it in the lab is to install futurity as a primitive: the claim that the most elementary geometry already contains desire, that the line between earth and sky is also the line between the world as given and the world as not-yet.

## The horizon line — the line you reach toward and never arrive at.
##
## Built procedurally as a wall panel: sky field over ground field, with
## a bright seam line that overhangs the frame. Origin at the seam centre;
## front faces +Z (hang it like a painting).

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Panel")
@export var panel_width: float = 2.0
@export var panel_height: float = 1.5
## Vertical position of the seam within the panel, 0 = centre.
## Positive raises the horizon (more ground), negative lowers it (more sky).
@export var seam_offset: float = 0.0

@export_group("Material")
@export var sky_color: Color = Color(0.62, 0.78, 0.95)
@export var ground_color: Color = Color(0.20, 0.17, 0.22)
@export var line_color: Color = Color(1.0, 0.95, 0.80)
@export var line_thickness: float = 0.03
## How far the horizon line extends past the panel on each side.
@export var line_overhang: float = 0.35

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
	if has_meta("config_panel_width"):
		panel_width = float(str(get_meta("config_panel_width")))
	if has_meta("config_panel_height"):
		panel_height = float(str(get_meta("config_panel_height")))
	if has_meta("config_seam_offset"):
		seam_offset = float(str(get_meta("config_seam_offset")))
	if has_meta("config_sky_color"):
		sky_color = _parse_color(str(get_meta("config_sky_color")), sky_color)
	if has_meta("config_ground_color"):
		ground_color = _parse_color(str(get_meta("config_ground_color")), ground_color)
	if has_meta("config_line_color"):
		line_color = _parse_color(str(get_meta("config_line_color")), line_color)


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	var hw: float = panel_width * 0.5
	var hh: float = panel_height * 0.5
	var seam_y: float = clampf(seam_offset, -hh + 0.05, hh - 0.05)
	var depth: float = 0.03

	# Sky field (above the seam).
	var sky_h: float = hh - seam_y
	if sky_h > 0.001:
		_add_field("Sky", sky_color,
			Vector3(0, seam_y + sky_h * 0.5, 0),
			Vector3(panel_width, sky_h, depth))

	# Ground field (below the seam).
	var ground_h: float = hh + seam_y
	if ground_h > 0.001:
		_add_field("Ground", ground_color,
			Vector3(0, seam_y - ground_h * 0.5, 0),
			Vector3(panel_width, ground_h, depth))

	# The horizon line — bright, overhanging the frame on both sides.
	var line := MeshInstance3D.new()
	line.name = "Horizon"
	var lm := BoxMesh.new()
	lm.size = Vector3(panel_width + line_overhang * 2.0, line_thickness, depth * 1.4)
	line.mesh = lm
	_line_mat = StandardMaterial3D.new()
	_line_mat.albedo_color = line_color
	_line_mat.emission_enabled = true
	_line_mat.emission = line_color
	_line_mat.emission_energy_multiplier = 2.0
	_line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line.material_override = _line_mat
	line.position = Vector3(0, seam_y, depth * 0.2)
	add_child(line)

	_phase = 0.0
	set_process(true)


func _add_field(n: String, col: Color, pos: Vector3, size: Vector3) -> void:
	var f := MeshInstance3D.new()
	f.name = n
	var m := BoxMesh.new()
	m.size = size
	f.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.9
	mat.metallic = 0.0
	f.material_override = mat
	f.position = pos
	add_child(f)


func _process(delta: float) -> void:
	if _line_mat == null:
		return
	# Slow shimmer — the horizon never quite holds still.
	_phase += delta * 0.8
	var pulse: float = 0.5 + 0.5 * sin(_phase)
	_line_mat.emission_energy_multiplier = 1.5 + pulse * 1.3
