extends Node3D
class_name LabScales

# @identity
# essence: a classical two-pan balance scale — a polished brass base disc with
#   a short vertical column, a horizontal beam crossing the top of the column,
#   and at each end of the beam a hanging chain holding a flat brass pan; on
#   each pan a stack of small dark steel weight cubes sized to the pan's load.
#   The beam tilts around the column's pivot in proportion to the load
#   imbalance — left heavier tilts left-down, right heavier tilts right-down,
#   perfect equality holds the beam horizontal. A small pointer arrow at the
#   top of the column reads the tilt against an implied zero. In the lab's
#   grammar the scale is the ALGORITHM OF EQUILIBRIUM / ARGMIN — the
#   minimisation principle in object form.
# desire: every lab that teaches optimisation needs an artifact that proves
#   "balanced" is not an aesthetic but a SEARCH OUTCOME — the configuration
#   the system settles into when the loss is minimised. The scale wants to be
#   the simplest possible gradient-descent solver you can put on a shelf: two
#   weights, one degree of freedom, one stable answer
# critical_parameter: left_load and right_load — together they ARE the loss
#   landscape. The beam's tilt IS the gradient. tilt_from_loads=true makes the
#   prop COMPUTE its own equilibrium from the inputs (the scale is a physical
#   solver). tilt_from_loads=false lets a teacher OVERRIDE the answer to
#   demonstrate an off-optimum state (the scale is a physical assertion)
# triggers: _ready() builds base + column + tilted beam + chains + pans + load
#   stacks + pointer + accent stripe; apply_grid_config rebuilds
# emerges: equal loads → beam horizontal → reads BALANCED / OPTIMUM. Unequal
#   loads → beam tilted → reads DESCENDING TOWARD THE HEAVIER SIDE → reads
#   GRADIENT. Same prop, the tilt angle IS the magnitude of the loss
# relationships: peer to pendulum (both name an EQUILIBRIUM — the pendulum is
#   dynamic-stable, the scale is static-stable); sibling to probability_box
#   (both make a hidden quantity LEGIBLE in physical position — the box shows
#   distribution as a histogram, the scale shows imbalance as a tilt); cousin
#   to oscilloscope (both DISPLAY the result of a continuous computation in
#   a single shape on the face of the prop)
# truth: optimisation is the rule that says any system with a loss and a
#   degree of freedom will find the configuration that minimises the loss
#   given the chance. The scale IS that rule embodied — the beam is the
#   degree of freedom, the loads ARE the loss, and equilibrium IS the argmin.
#   The pans do not LIE about which side is heavier; they JUST tilt.

## A two-pan balance scale — brass base, column, tilted beam, hanging pans,
## stacked weights.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTER of
## the base disc. The beam tilts in the XY plane (rotated around the Z
## axis at the top of the column). +tilt_degrees rotates the beam so the
## LEFT side goes DOWN (left heavier). When tilt_from_loads=true the
## tilt is computed from left_load - right_load; tilt_degrees is ignored.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var base_radius: float = 0.10
@export var column_height: float = 0.15
@export var beam_length: float = 0.32
@export var pan_radius: float = 0.060

@export_group("Loads")
@export var left_load: float = 1.0
@export var right_load: float = 1.0
@export var tilt_degrees: float = 0.0
@export var tilt_from_loads: bool = true

@export_group("Color")
@export var base_color: Color = Color(0.85, 0.65, 0.20)
@export var beam_color: Color = Color(0.85, 0.65, 0.20)
@export var pan_color: Color = Color(0.85, 0.65, 0.20)
@export var weight_color: Color = Color(0.18, 0.18, 0.22)
@export var accent_color: Color = Color(1.0, 0.45, 0.10)

# ── Constants ─────────────────────────────────────────────────────────

const BASE_HEIGHT: float = 0.018
const COLUMN_RADIUS: float = 0.014
const BEAM_THICKNESS: float = 0.020
const BEAM_DEPTH: float = 0.020
const PAN_THICKNESS: float = 0.006
const CHAIN_SEGMENTS: int = 3
const CHAIN_SEGMENT_THICKNESS: float = 0.0035
const CHAIN_TOTAL_DROP: float = 0.060
const WEIGHT_UNIT_SIZE: float = 0.022
const POINTER_LENGTH: float = 0.030
const POINTER_THICKNESS: float = 0.0030
const ACCENT_STRIP_HEIGHT: float = 0.004
const TILT_GAIN_DEG_PER_UNIT: float = 12.0
const MAX_TILT_DEG: float = 30.0

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_scales()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_scales()


func _read_metadata_overrides() -> void:
	if has_meta("config_base_radius"):
		base_radius = float(str(get_meta("config_base_radius")))
	if has_meta("config_column_height"):
		column_height = float(str(get_meta("config_column_height")))
	if has_meta("config_beam_length"):
		beam_length = float(str(get_meta("config_beam_length")))
	if has_meta("config_pan_radius"):
		pan_radius = float(str(get_meta("config_pan_radius")))
	if has_meta("config_left_load"):
		left_load = float(str(get_meta("config_left_load")))
	if has_meta("config_right_load"):
		right_load = float(str(get_meta("config_right_load")))
	if has_meta("config_tilt_degrees"):
		tilt_degrees = float(str(get_meta("config_tilt_degrees")))
	if has_meta("config_tilt_from_loads"):
		tilt_from_loads = _parse_bool(str(get_meta("config_tilt_from_loads")), tilt_from_loads)
	if has_meta("config_base_color"):
		base_color = _parse_color(str(get_meta("config_base_color")), base_color)
	if has_meta("config_beam_color"):
		beam_color = _parse_color(str(get_meta("config_beam_color")), beam_color)
	if has_meta("config_pan_color"):
		pan_color = _parse_color(str(get_meta("config_pan_color")), pan_color)
	if has_meta("config_weight_color"):
		weight_color = _parse_color(str(get_meta("config_weight_color")), weight_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_scales() -> void:
	_built = true
	_build_base()
	_build_column()
	_build_accent_stripe()
	_build_beam_assembly()


func _effective_tilt_radians() -> float:
	if tilt_from_loads:
		var diff: float = left_load - right_load
		var raw_deg: float = diff * TILT_GAIN_DEG_PER_UNIT
		var clamped_deg: float = clampf(raw_deg, -MAX_TILT_DEG, MAX_TILT_DEG)
		return deg_to_rad(clamped_deg)
	return deg_to_rad(clampf(tilt_degrees, -MAX_TILT_DEG, MAX_TILT_DEG))


func _build_base() -> void:
	var base := MeshInstance3D.new()
	base.name = "Base"
	var mesh := CylinderMesh.new()
	mesh.top_radius = base_radius
	mesh.bottom_radius = base_radius * 1.05
	mesh.height = BASE_HEIGHT
	base.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_color
	mat.roughness = 0.30
	mat.metallic = 0.85
	base.material_override = mat
	base.position = Vector3(0.0, BASE_HEIGHT * 0.5, 0.0)
	add_child(base)


func _build_column() -> void:
	var col := MeshInstance3D.new()
	col.name = "Column"
	var mesh := CylinderMesh.new()
	mesh.top_radius = COLUMN_RADIUS
	mesh.bottom_radius = COLUMN_RADIUS * 1.15
	mesh.height = column_height
	col.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_color
	mat.roughness = 0.30
	mat.metallic = 0.85
	col.material_override = mat
	col.position = Vector3(0.0, BASE_HEIGHT + column_height * 0.5, 0.0)
	add_child(col)


func _build_accent_stripe() -> void:
	var strip := MeshInstance3D.new()
	strip.name = "AccentStripe"
	var mesh := TorusMesh.new()
	mesh.inner_radius = base_radius * 0.9
	mesh.outer_radius = base_radius * 0.96
	mesh.ring_segments = 6
	mesh.rings = 28
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	strip.position = Vector3(0.0, BASE_HEIGHT - ACCENT_STRIP_HEIGHT * 0.5, 0.0)
	add_child(strip)


func _build_beam_assembly() -> void:
	# Pivot node at the top of the column, rotated by the effective tilt.
	# +tilt rotates so the LEFT end (-X side) goes DOWN — matching "left heavier".
	var pivot := Node3D.new()
	pivot.name = "BeamPivot"
	pivot.position = Vector3(0.0, BASE_HEIGHT + column_height, 0.0)
	var tilt_rad: float = _effective_tilt_radians()
	# Rotation around Z by +tilt sends +X-end UP, -X-end DOWN. We want the
	# OPPOSITE: left heavier (-X side) DOWN. So negate.
	pivot.rotation = Vector3(0.0, 0.0, -tilt_rad)
	add_child(pivot)

	# Beam.
	var beam := MeshInstance3D.new()
	beam.name = "Beam"
	var beam_mesh := BoxMesh.new()
	beam_mesh.size = Vector3(beam_length, BEAM_THICKNESS, BEAM_DEPTH)
	beam.mesh = beam_mesh
	var beam_mat := StandardMaterial3D.new()
	beam_mat.albedo_color = beam_color
	beam_mat.roughness = 0.30
	beam_mat.metallic = 0.85
	beam.material_override = beam_mat
	beam.position = Vector3(0.0, 0.0, 0.0)
	pivot.add_child(beam)

	# Pointer arrow at the column's top, pointing UP, but BELONGS to the column
	# (does NOT tilt) — added separately so the tilt is READ against the
	# stationary pointer. Place it back on the parent, not on the pivot.
	_build_pointer()

	# Left side assembly (chain + pan + weights).
	var left_x: float = -beam_length * 0.5
	_build_chain_and_pan(pivot, left_x, "Left", left_load)

	# Right side assembly.
	var right_x: float = beam_length * 0.5
	_build_chain_and_pan(pivot, right_x, "Right", right_load)


func _build_pointer() -> void:
	# A small triangular pointer at the top of the column, pointing up, dark.
	# Does NOT tilt with the beam — reads the tilt against the stationary up.
	var pointer := MeshInstance3D.new()
	pointer.name = "Pointer"
	var mesh := PrismMesh.new()
	mesh.size = Vector3(POINTER_THICKNESS * 4.0, POINTER_LENGTH, POINTER_THICKNESS * 2.0)
	mesh.left_to_right = 0.5
	pointer.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = weight_color
	mat.roughness = 0.4
	mat.metallic = 0.6
	pointer.material_override = mat
	pointer.position = Vector3(0.0, BASE_HEIGHT + column_height + POINTER_LENGTH * 0.5 + 0.004, 0.0)
	add_child(pointer)


func _build_chain_and_pan(parent: Node3D, x_pos: float, side_name: String, load_amount: float) -> void:
	# Chain hangs DOWN from the beam (in parent's local space). 3 segments.
	var seg_h: float = CHAIN_TOTAL_DROP / float(CHAIN_SEGMENTS)
	var top_y: float = -BEAM_THICKNESS * 0.5
	for i in range(CHAIN_SEGMENTS):
		var seg := MeshInstance3D.new()
		seg.name = "Chain_%s_%d" % [side_name, i]
		var sm := BoxMesh.new()
		sm.size = Vector3(CHAIN_SEGMENT_THICKNESS, seg_h * 0.85, CHAIN_SEGMENT_THICKNESS)
		seg.mesh = sm
		var smat := StandardMaterial3D.new()
		smat.albedo_color = beam_color
		smat.roughness = 0.35
		smat.metallic = 0.85
		seg.material_override = smat
		seg.position = Vector3(x_pos, top_y - seg_h * (float(i) + 0.5), 0.0)
		parent.add_child(seg)

	# Pan: thin disc at the bottom of the chain.
	var pan_y: float = top_y - CHAIN_TOTAL_DROP - PAN_THICKNESS * 0.5
	var pan := MeshInstance3D.new()
	pan.name = "Pan_%s" % side_name
	var pm := CylinderMesh.new()
	pm.top_radius = pan_radius
	pm.bottom_radius = pan_radius * 0.95
	pm.height = PAN_THICKNESS
	pan.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = pan_color
	pmat.roughness = 0.25
	pmat.metallic = 0.85
	pmat.emission_enabled = true
	pmat.emission = pan_color * 0.4
	pmat.emission_energy_multiplier = 0.10
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	pan.material_override = pmat
	pan.position = Vector3(x_pos, pan_y, 0.0)
	parent.add_child(pan)

	# Weights on the pan — small dark cubes stacked, count proportional to load.
	_build_weight_stack(parent, x_pos, pan_y + PAN_THICKNESS * 0.5, side_name, load_amount)


func _build_weight_stack(parent: Node3D, x_pos: float, pan_top_y: float, side_name: String, load_amount: float) -> void:
	# Render load_amount as a tower of unit cubes. Negative or zero loads
	# render nothing. Fractional loads add a partial-height final cube.
	var load_clamped: float = max(0.0, load_amount)
	if load_clamped <= 0.001:
		return
	var full_cubes: int = int(floor(load_clamped))
	var fractional: float = load_clamped - float(full_cubes)
	# Pack the tower; full cubes fit on the pan with a small lateral spread if
	# load > 4. For load <= 4, stack vertically. For larger loads, arrange in
	# a 2-column pile.
	var size: float = WEIGHT_UNIT_SIZE
	var stack_columns: int = 1
	if full_cubes > 4:
		stack_columns = 2
	for i in range(full_cubes):
		var col_idx: int = i % stack_columns
		var row_idx: int = i / stack_columns
		var dx: float = 0.0
		if stack_columns > 1:
			dx = (float(col_idx) - 0.5) * size * 1.05
		var cube := MeshInstance3D.new()
		cube.name = "Weight_%s_%d" % [side_name, i]
		var cm := BoxMesh.new()
		cm.size = Vector3(size, size, size)
		cube.mesh = cm
		var cmat := StandardMaterial3D.new()
		cmat.albedo_color = weight_color
		cmat.roughness = 0.55
		cmat.metallic = 0.30
		cube.material_override = cmat
		cube.position = Vector3(x_pos + dx, pan_top_y + size * 0.5 + size * float(row_idx), 0.0)
		parent.add_child(cube)

	# Fractional cube on top.
	if fractional > 0.05:
		var frac_h: float = size * clampf(fractional, 0.05, 1.0)
		var col_idx2: int = full_cubes % stack_columns
		var row_idx2: int = full_cubes / stack_columns
		var dx2: float = 0.0
		if stack_columns > 1:
			dx2 = (float(col_idx2) - 0.5) * size * 1.05
		var frac_cube := MeshInstance3D.new()
		frac_cube.name = "Weight_%s_frac" % side_name
		var fm := BoxMesh.new()
		fm.size = Vector3(size, frac_h, size)
		frac_cube.mesh = fm
		var fmat := StandardMaterial3D.new()
		fmat.albedo_color = weight_color
		fmat.roughness = 0.55
		fmat.metallic = 0.30
		frac_cube.material_override = fmat
		frac_cube.position = Vector3(x_pos + dx2, pan_top_y + frac_h * 0.5 + size * float(row_idx2), 0.0)
		parent.add_child(frac_cube)


# ── Helpers ───────────────────────────────────────────────────────────

func _parse_color(s: String, fallback: Color) -> Color:
	var parts := s.split(",")
	if parts.size() < 3:
		return fallback
	var r := float(parts[0])
	var g := float(parts[1])
	var b := float(parts[2])
	var a := 1.0
	if parts.size() >= 4:
		a = float(parts[3])
	return Color(r, g, b, a)


func _parse_bool(s: String, fallback: bool) -> bool:
	var v := s.to_lower()
	if v in ["true", "1", "yes", "on"]:
		return true
	if v in ["false", "0", "no", "off"]:
		return false
	return fallback
